#!/usr/bin/env bash
#
# update-repo.sh — apt repo update engine
#
# Reads packages/*.toml, downloads new upstream .deb releases,
# regenerates and signs repo metadata, smoke-tests it with apt,
# and commits + pushes if anything changed.
#
# Usage:
#   ./update-repo.sh                       check all packages, publish updates
#   ./update-repo.sh --regen-only          only regen metadata (after manual deb add)
#   ./update-repo.sh --no-push             update locally, don't push
#   ./update-repo.sh --message "..."       custom commit message
#
# Package config (packages/<name>.toml, simple TOML subset):
#   repo = "owner/name"         GitHub repo with releases (required)
#   asset = "regex"             pattern matching the .deb release asset (required)
#   name = "pkg"                apt package name (defaults to file name)
#   keep_versions = 2           optional: prune old debs, keep newest N
#
# Environment:
#   GH_TOKEN   optional GitHub token (CI uses the built-in GITHUB_TOKEN)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$ROOT/packages"
DEB_DIR="$ROOT/debian"
REPACK_SIZE_THRESHOLD=$((25 * 1000 * 1000))

# Work dir on the repo's disk (a full /tmp tmpfs can break big downloads)
TMP_ROOT="$ROOT/.tmp"
mkdir -p "$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT

REGEN_ONLY=0
PUSH=1
COMMIT_MSG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --regen-only) REGEN_ONLY=1; shift ;;
    --no-push)    PUSH=0; shift ;;
    --message)    COMMIT_MSG="$2"; shift 2 ;;
    --message=*)  COMMIT_MSG="${1#--message=}"; shift ;;
    *)            echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

UPDATED=()

gh_curl() {
  if [ -n "${GH_TOKEN:-}" ]; then
    curl -sSL -H "Authorization: Bearer $GH_TOKEN" "$@"
  else
    curl -sSL "$@"
  fi
}

# Minimal TOML reader: 'literal', "escaped" and bare values, single line only
conf_get() { # conf_get <file> <key>
  local val
  val=$(sed -n \
    -e "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*'\(.*\)'[[:space:]]*$/\1/p" \
    -e "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\"\(.*\)\"[[:space:]]*$/\1/p" \
    -e "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\([^\"'[:space:]]*\)[[:space:]]*$/\1/p" \
    "$1" | head -n 1)
  printf '%s' "${val//\\\\/\\}" # unescape \\ (double-quoted basic strings)
}

version_from() { # extract first dotted version number from a string
  grep -Eo '[0-9]+(\.[0-9]+)+' <<<"$1" | head -n 1
}

current_version() { # newest version among debian/<name>*.deb
  find "$DEB_DIR" -maxdepth 1 -type f -iname "$1*.deb" -printf '%f\n' \
    | { grep -Eo '[0-9]+(\.[0-9]+)+' || true; } \
    | sort -V | tail -n 1
}

prune_versions() { # prune_versions <name> <keep>
  local name=$1 keep=$2 f
  find "$DEB_DIR" -maxdepth 1 -type f -iname "$name*.deb" -printf '%f\n' \
    | sort -V | head -n -"$keep" \
    | while read -r f; do
        echo "-- $name: pruning old $f"
        rm -f "$DEB_DIR/$f"
      done
}

repack_stub() { # repack_stub <deb> <repo> <app-name> <asset-regex> [apt-name] — control-only install stub
  local deb=$1 repo=$2 app=$3 asset_re=$4 apt_name=$5 asset_esc tmp
  # strip trailing anchor: postinst greps raw JSON lines that end with a quote
  asset_re=${asset_re%\$}
  asset_esc=${asset_re//\\/\\\\} # keep regex backslashes through sed
  tmp=$(mktemp -d -p "$TMP_ROOT")
  mkdir -p "$tmp/DEBIAN"
  # Extract control files only — no payload, no big temp usage
  dpkg-deb -e "$deb" "$tmp/DEBIAN"
  if [ -n "$apt_name" ]; then # optional apt package name override
    sed -i "s|^Package: .*|Package: $apt_name|" "$tmp/DEBIAN/control"
  fi
  cp "$ROOT/postinst" "$tmp/DEBIAN/postinst"
  sed -i "s|^REPO=.*|REPO=$repo|" "$tmp/DEBIAN/postinst"
  sed -i "s|^APP_NAME=.*|APP_NAME=$app|" "$tmp/DEBIAN/postinst"
  sed -i "s|^ASSET=.*|ASSET=$asset_esc|" "$tmp/DEBIAN/postinst"
  # No payload — postinst re-downloads the real deb at install time
  : > "$tmp/DEBIAN/md5sums"
  dpkg-deb -b --root-owner-group "$tmp" "$deb"
  rm -rf "$tmp"
}

process_package() { # process_package <toml-file>
  local cfg=$1
  local name repo asset_re keep pkg_name
  name=$(conf_get "$cfg" name); [ -z "$name" ] && name=$(basename "$cfg" .toml)
  repo=$(conf_get "$cfg" repo)
  asset_re=$(conf_get "$cfg" asset)
  keep=$(conf_get "$cfg" keep_versions)
  pkg_name=$(conf_get "$cfg" package) # optional apt package name override

  if [ -z "$repo" ] || [ -z "$asset_re" ]; then
    echo "!! $cfg: missing 'repo' or 'asset', skipping" >&2
    return 0
  fi

  local json url new_ver cur_ver
  json=$(gh_curl "https://api.github.com/repos/$repo/releases")
  url=$(jq -r --arg re "$asset_re" \
    '[.[] | .assets[]? | select(.name | test($re))][0].browser_download_url // empty' \
    <<<"$json")

  if [ -z "$url" ]; then
    echo "-- $name: no upstream .deb asset matches '$asset_re', skipping"
    return 0
  fi

  new_ver=$(version_from "$(basename "$url")")
  cur_ver=$(current_version "$name")

  echo "-- $name: current=${cur_ver:-none} latest=${new_ver:-unknown}"

  if [ -z "$new_ver" ]; then
    echo "!! $name: could not extract version from asset name, skipping" >&2
    return 0
  fi
  if [ -n "$cur_ver" ] && ! dpkg --compare-versions "$cur_ver" lt "$new_ver"; then
    return 0
  fi

  echo "-- $name: downloading $new_ver"
  local tmpdir deb
  tmpdir=$(mktemp -d -p "$TMP_ROOT")
  deb="$tmpdir/$(basename "$url")"
  gh_curl -o "$deb" "$url"
  if [ ! -s "$deb" ]; then
    echo "!! $name: download failed or empty, skipping" >&2
    rm -rf "$tmpdir"
    return 0
  fi
  if [ "$(stat -c%s "$deb")" -gt "$REPACK_SIZE_THRESHOLD" ]; then
    echo "-- $name: >25MB, repacking as install-stub"
    repack_stub "$deb" "$repo" "${pkg_name:-$name}" "$asset_re" "$pkg_name"
  fi
  mv "$deb" "$DEB_DIR/"
  rm -rf "$tmpdir"
  UPDATED+=("$name to $new_ver")

  if [ -n "$keep" ] && [ "$keep" -gt 0 ] 2>/dev/null; then
    prune_versions "$name" "$keep"
  fi
}

smoke_test() { # verify signatures + Packages file with a throwaway apt state
  echo "== Smoke test: apt-get update against repo"
  local tmp p list
  tmp=$(mktemp -d -p "$TMP_ROOT")
  mkdir -p "$tmp/state/lists/partial" "$tmp/cache/archives/partial"
  gpg --dearmor < "$DEB_DIR/KEY.gpg" > "$tmp/keyring.gpg"
  printf 'deb [signed-by=%s/keyring.gpg] file:%s ./\n' "$tmp" "$DEB_DIR" > "$tmp/tmiland.list"
  # apt-get update fails on bad signatures, hash mismatches or unparseable indexes
  apt-get update \
    -o Dir::Etc::sourcelist="$tmp/tmiland.list" \
    -o Dir::Etc::sourceparts=- \
    -o Dir::State="$tmp/state" \
    -o Dir::Cache="$tmp/cache" \
    -o Debug::NoLocking=1 \
    -o APT::Get::List-Cleanup=0 \
    --quiet
  list=$(find "$tmp/state/lists" -maxdepth 1 -name '*_Packages' -print -quit 2>/dev/null)
  if [ -z "$list" ]; then
    echo "!! Smoke test: apt stored no Packages list" >&2
    rm -rf "$tmp"
    return 1
  fi
  while read -r p; do
    if ! grep -q "^Package: $p\$" "$list"; then
      echo "!! Smoke test: $p missing from apt list" >&2
      rm -rf "$tmp"
      return 1
    fi
    echo "   ok: $p in apt list"
  done < <(grep '^Package:' "$DEB_DIR/Packages" | sort -u | awk '{print $2}')
  rm -rf "$tmp"
}

commit_and_push() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    git config user.name "${GITHUB_ACTOR:-github-actions}"
    git config user.email "${GITHUB_ACTOR:-github-actions}@users.noreply.github.com"
  fi
  git add -A
  if git diff --cached --quiet; then
    echo "== Nothing to commit"
    return 0
  fi
  local msg
  if [ -n "$COMMIT_MSG" ]; then
    msg="$COMMIT_MSG"
  elif [ "$REGEN_ONLY" -eq 1 ]; then
    msg="Regenerate apt repo metadata"
  else
    msg="Update ${UPDATED[*]}"
  fi
  git commit -m "$msg"
  if [ "$PUSH" -eq 1 ]; then
    git push origin HEAD
  else
    echo "== Push skipped (--no-push)"
  fi
}

main() {
  cd "$ROOT"

  if [ "$REGEN_ONLY" -eq 1 ]; then
    echo "== Regeneration only"
  else
    local cfg found=0
    for cfg in "$PACKAGES_DIR"/*.toml; do
      [ -e "$cfg" ] || { echo "!! No packages found in $PACKAGES_DIR" >&2; exit 1; }
      found=1
      process_package "$cfg"
    done
    [ "$found" -eq 1 ] || { echo "!! No packages found in $PACKAGES_DIR" >&2; exit 1; }
    if [ ${#UPDATED[@]} -eq 0 ]; then
      echo "== All packages up to date, nothing to do"
      exit 0
    fi
  fi

  echo "== Regenerating repo metadata"
  bash "$ROOT/update.sh"

  smoke_test
  commit_and_push
}

main
