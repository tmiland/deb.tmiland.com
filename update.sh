#!/usr/bin/env bash

set -e
set -v

export KEYNAME=7C44CFE8E3B971486A2E0A280A2998CB2E6D61E0

(
    set -e
    set -v

    cd ./debian/

    # Packages & Packages.gz
    dpkg-scanpackages --multiversion . > Packages
    gzip -k -f Packages

    # Release, Release.gpg & InRelease
    apt-ftparchive release . > Release
    gpg --default-key "${KEYNAME}" -abs -o - Release > Release.gpg
    gpg --default-key "${KEYNAME}" --clearsign -o - Release > InRelease
)
