#!/usr/bin/env bash

set -e
set -v

# Detect absolute and full path as well as filename of this script
cd "$(dirname "$0")" || exit
CURRDIR=$(pwd)
cd - > /dev/null || exit

export KEYNAME=7C44CFE8E3B971486A2E0A280A2998CB2E6D61E0

(
    set -e
    set -v
    cd "${CURRDIR}" || exit
    cd ./debian/

    # Packages & Packages.gz
    dpkg-scanpackages --multiversion . > Packages
    gzip -k -f Packages

    # Release, Release.gpg & InRelease
    apt-ftparchive release . > Release
    gpg --default-key "${KEYNAME}" -abs -o - Release > Release.gpg
    gpg --default-key "${KEYNAME}" --clearsign -o - Release > InRelease
)
