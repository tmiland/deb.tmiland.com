#!/usr/bin/env bash
#
# update-repo.sh — apt repo update engine
#
# Reads packages/*.pkg, downloads new upstream .deb releases,
# regenerates and signs repo metadata, smoke-tests it with apt,
# and commits + pushes if anything changed.
#
# Usage:
#   ./update-repo.sh                       check all packages, publish updates
#   ./update-repo.sh --regen-only          only regen metadata (after manual deb add)
#   ./update-repo.sh --no-push             update without pushing
#   ./update-repo.sh --message "..."       custom commit message
#   ./update-repo.sh --force <name>        force full pipeline for one package (test)
#
# Package config (packages/<name>.pkg, simple TOML subset):
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
CONFIG_EXT="${CONFIG_EXT:-pkg}" # package config file extension
REPACK_SIZE_THRESHOLD=$((25 * 1000 * 1000))

# Work dir on the repo's disk (a full /tmp tmpfs can break big downloads)
TMP_ROOT="$ROOT/.tmp"
mkdir -p "$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT

REGEN_ONLY=0
PUSH=1
COMMIT_MSG=""
FORCE_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --regen-only) REGEN_ONLY=1; shift ;;
    --no-push)    PUSH=0; shift ;;
    --message)    COMMIT_MSG="$2"; shift 2 ;;
    --message=*)  COMMIT_MSG="${1#--message=}"; shift ;;
    --force)      FORCE_NAME="${2:-}"; [ -n "$FORCE_NAME" ] || { echo "--force requires a package name" >&2; exit 2; }; shift 2 ;;
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
  grep -Eo '[0-9]+(\.[0-9]+)+' <<<"$1" | head -n 1 || true
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

repack_stub() { # repack_stub <deb> <repo> <app-name> <asset-regex> [apt-name] [payload-dir] [hide-list] [summary]
  local deb=$1 repo=$2 app=$3 asset_re=$4 apt_name=$5 payload_dir=$6 hide=$7 summary=$8 asset_esc tmp
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
  if [ -n "$summary" ]; then # some upstream controls ship an empty Description
    awk '/^Description:/{skip=1; next} skip == 1 && /^[[:space:]]/{next} skip == 1 {skip=0} {print}' \
      "$tmp/DEBIAN/control" > "$tmp/DEBIAN/control.new"
    printf 'Description: %s\n' "$summary" >> "$tmp/DEBIAN/control.new"
    mv "$tmp/DEBIAN/control.new" "$tmp/DEBIAN/control"
  fi
  cp "$ROOT/postinst" "$tmp/DEBIAN/postinst"
  sed -i "s|^REPO=.*|REPO=$repo|" "$tmp/DEBIAN/postinst"
  sed -i "s|^APP_NAME=.*|APP_NAME=$app|" "$tmp/DEBIAN/postinst"
  sed -i "s|^ASSET=.*|ASSET=$asset_esc|" "$tmp/DEBIAN/postinst"
  sed -i "s|^HIDE=.*|HIDE=$hide|" "$tmp/DEBIAN/postinst"
  # Optional payload (launcher files etc.); postinst still re-downloads the real deb
  if [ -n "$payload_dir" ] && [ -d "$payload_dir" ]; then
    cp -a "$payload_dir/." "$tmp/"
    find "$tmp" -type d -exec chmod 755 {} +
    find "$tmp" -not -path "$tmp/DEBIAN/*" -type f -exec chmod 644 {} +
  fi
  ( cd "$tmp" \
    && find . -type f -not -path "./DEBIAN/*" -exec md5sum {} + 2>/dev/null \
      | sort -k 2 | sed 's/\.\/\(.*\)/\1/' > DEBIAN/md5sums )
  dpkg-deb -b --root-owner-group "$tmp" "$deb"
  rm -rf "$tmp"
}

process_package() { # process_package <toml-file>
  local cfg=$1
  local name repo asset_re keep pkg_name hide summary payload_dir filekey
  name=$(conf_get "$cfg" name); [ -z "$name" ] && name=$(basename "$cfg" ".$CONFIG_EXT")
  repo=$(conf_get "$cfg" repo)
  asset_re=$(conf_get "$cfg" asset)
  keep=$(conf_get "$cfg" keep_versions)
  pkg_name=$(conf_get "$cfg" package) # optional apt package name override
  hide=$(conf_get "$cfg" hide) # optional desktop files to hide after install
  summary=$(conf_get "$cfg" summary) # optional description for empty upstream controls
  payload_dir="$PACKAGES_DIR/$(basename "$cfg" ".$CONFIG_EXT").payload"
  [ -d "$payload_dir" ] || payload_dir="" # optional launcher files for stubs

  filekey="${pkg_name:-$name}" # matches debian/ filenames (normalized: name_ver_arch.deb)

  local source_type
  source_type=$(conf_get "$cfg" source)
  if [ "$source_type" != "url" ] && { [ -z "$repo" ] || [ -z "$asset_re" ]; }; then
    echo "!! $cfg: missing 'repo' or 'asset', skipping" >&2
    return 0
  fi

  local json line url rel_tag new_ver cur_ver
  if [ "$source_type" = "url" ]; then
    # direct-download source: version is parsed from the redirect target
    url=$(conf_get "$cfg" url)
    if [ -z "$url" ]; then
      echo "!! $cfg: source=url requires 'url', skipping" >&2
      return 0
    fi
    url=$(curl -sIL -o /dev/null -w '%{url_effective}' --max-time 60 "$url" || true)
    if [ -z "$url" ]; then
      echo "!! $name: could not resolve download URL, skipping" >&2
      return 0
    fi
    new_ver=$(version_from "$url")
  else
    json=$(gh_curl "https://api.github.com/repos/$repo/releases")
    # grab the first matching asset together with its release tag
    line=$(jq -r --arg re "$asset_re" \
      '.[] | .tag_name as $t | .assets[]? | select(.name | test($re)) | "\(.browser_download_url) \($t)"' \
      <<<"$json" | head -n 1 || true)
    url=${line%% *}
    rel_tag=${line#"$url"}; rel_tag=${rel_tag# }
    new_ver=$(version_from "$(basename "$url")")
    # some assets have unversioned filenames — fall back to the release tag
    [ -z "$new_ver" ] && [ -n "$rel_tag" ] && new_ver=$(version_from "$rel_tag")
  fi
  if [ "$source_type" != "url" ] && [ -z "$url" ]; then
    echo "-- $name: no upstream .deb asset matches '$asset_re', skipping"
    return 0
  fi
  cur_ver=$(current_version "$filekey")

  echo "-- $name: current=${cur_ver:-none} latest=${new_ver:-unknown}"

  if [ -z "$new_ver" ]; then
    echo "!! $name: could not extract version from asset name, skipping" >&2
    return 0
  fi
  # --force skips the up-to-date short-circuit for the named package
  if [ -z "$FORCE_NAME" ] && [ -n "$cur_ver" ] && ! dpkg --compare-versions "$cur_ver" lt "$new_ver"; then
    return 0
  fi

  echo "-- $name: downloading $new_ver"
  local tmpdir deb
  tmpdir=$(mktemp -d -p "$TMP_ROOT")
  deb="$tmpdir/$(basename "$url")"
  # plain curl for url sources — never send the GitHub token to third parties
  if [ "$source_type" = "url" ]; then
    curl -sSL -o "$deb" "$url"
  else
    gh_curl -o "$deb" "$url"
  fi
  if [ ! -s "$deb" ]; then
    echo "!! $name: download failed or empty, skipping" >&2
    rm -rf "$tmpdir"
    return 0
  fi
  if [ "$source_type" = "url" ]; then
    # the deb's control is authoritative when the redirect hides the version
    local ctrl_ver
    ctrl_ver=$(dpkg-deb -f "$deb" Version 2>/dev/null || true)
    if [ -n "$ctrl_ver" ] && [ "$ctrl_ver" != "$new_ver" ]; then
      echo "-- $name: control version $ctrl_ver differs from URL-detected $new_ver, using $ctrl_ver"
      new_ver=$ctrl_ver
    fi
  else
  # Verify against the upstream .sha256 when the release ships one
  local sha_url="${url}.sha256"
  if gh_curl -f -o "$tmpdir/checksum.sha256" "$sha_url" 2>/dev/null; then
    if ! grep -q "$(sha256sum "$deb" | awk '{print $1}')" "$tmpdir/checksum.sha256"; then
      echo "!! $name: sha256 mismatch against $sha_url, skipping" >&2
      rm -rf "$tmpdir"
      return 0
    fi
    echo "-- $name: sha256 verified"
  else
    echo "-- $name: no upstream checksum file, skipping verification"
  fi
  fi
  if [ "$(stat -c%s "$deb")" -gt "$REPACK_SIZE_THRESHOLD" ]; then
    echo "-- $name: >25MB, repacking as install-stub"
    repack_stub "$deb" "$repo" "${pkg_name:-$name}" "$asset_re" "$pkg_name" "$payload_dir" "$hide" "$summary"
  fi
  # normalize the filename so version tracking works even for unversioned
  # upstream asset names (name_version_arch.deb)
  local arch
  arch=$(dpkg-deb -f "$deb" Architecture)
  mv "$deb" "$DEB_DIR/${filekey}_${new_ver}_${arch}.deb"
  rm -rf "$tmpdir"
  UPDATED+=("$filekey to $new_ver")

  if [ -n "$keep" ] && [ "$keep" -gt 0 ] 2>/dev/null; then
    prune_versions "$filekey" "$keep"
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

check_size() { # refuse to publish a repo that would break GitHub Pages limits
  local mb limit="${MAX_DEB_DIR_MB:-500}"
  mb=$(du -sm --exclude=.git "$ROOT" | awk '{print $1}')
  if [ "$mb" -gt "$limit" ]; then
    echo "!! Repo is ${mb}MB (limit ${limit}MB) — prune old debs before publishing" >&2
    return 1
  fi
  echo "-- repo size: ${mb}MB (limit ${limit}MB)"
}

commit_and_push() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    # match the signing key UID so GitHub marks auto-commits as verified
    git config user.name "Tommy Miland"
    git config user.email "tmiland@tmiland.com"
    git config commit.gpgsign true
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
  if ! check_size; then
    exit 1 # committed locally, but never pushed
  fi
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
    local cfg found=0 stem
    for cfg in "$PACKAGES_DIR"/*."$CONFIG_EXT"; do
      [ -e "$cfg" ] || { echo "!! No packages found in $PACKAGES_DIR" >&2; exit 1; }
      stem=$(basename "$cfg" ".$CONFIG_EXT")
      if [ -n "$FORCE_NAME" ] && [ "$FORCE_NAME" != "$stem" ] \
        && [ "$FORCE_NAME" != "$(conf_get "$cfg" name)" ]; then
        continue
      fi
      found=1
      process_package "$cfg"
    done
    [ "$found" -eq 1 ] || { echo "!! No package matches --force '$FORCE_NAME'" >&2; exit 1; }
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
