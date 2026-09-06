#!/usr/bin/env bash
#
# update-icecat.sh — local-only updater for the icecat package
#
# GNU IceCat has no .deb release assets upstream, so the deb is built
# from a local checkout of ../GNU-IceCat (git clone tmiland/GNU-IceCat).
# Run this on your machine when you want a new IceCat release published;
# it hands off to update-repo.sh for metadata + commit + push.
#
# Environment:
#   ICECAT_REPO_DIR  path to the GNU-IceCat checkout (default: ../GNU-IceCat)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICECAT_REPO_DIR="${ICECAT_REPO_DIR:-$ROOT/../GNU-IceCat}"

if [ ! -x "$ICECAT_REPO_DIR/package.sh" ]; then
  echo "!! $ICECAT_REPO_DIR/package.sh not found." >&2
  echo "   git clone https://github.com/tmiland/GNU-IceCat $ICECAT_REPO_DIR" >&2
  exit 1
fi

cd "$ROOT"

CUR_VERSION=$(grep -Poh "(?<=Version: )([0-9]|\.)*(?=\s|$)" "$ICECAT_REPO_DIR"/amd64/DEBIAN/*)
NEW_VERSION=$(curl -s https://icecatbrowser.org/all_downloads.html |
  grep -Po 'b>\K.*(?=</b)' |
  head -n 1 |
  sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' |
  sed 's/\.$//')

echo "Current icecat version: ${CUR_VERSION:-none} => new: ${NEW_VERSION:-unknown}"

if [ -z "$NEW_VERSION" ]; then
  echo "!! Could not determine latest upstream version, aborting" >&2
  exit 1
fi
if [ -n "$CUR_VERSION" ] && ! dpkg --compare-versions "$CUR_VERSION" lt "$NEW_VERSION"; then
  echo "Latest icecat version already published"
  exit 0
fi

echo "Building icecat $NEW_VERSION (this takes a while)..."
( cd "$ICECAT_REPO_DIR" && ./package.sh )

DEB_FILE=$(find "$ICECAT_REPO_DIR" -type f -name "icecat_${NEW_VERSION}_amd64.deb" | head -n 1)
if [ -z "$DEB_FILE" ]; then
  echo "!! Built deb not found (icecat_${NEW_VERSION}_amd64.deb), aborting" >&2
  exit 1
fi

mv "$DEB_FILE" "$ROOT/debian/"

"$ROOT/update-repo.sh" --regen-only --message "Update icecat version to $NEW_VERSION"
