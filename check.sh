#!/usr/bin/env bash

email=root

# Detect absolute and full path as well as filename of this script
cd "$(dirname "$0")" || exit
CURRDIR=$(pwd)
cd - > /dev/null || exit

GitHubDesktop() {
  github_dektop_repo=shiftkey/desktop
  cd "${CURRDIR}" || exit
  github_desktop_CUR_VERSION="$(find ./debian/ -name "GitHubDesktop-linux-*.deb" | sed 's/.*-\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  github_desktop_NEW_VERSION="$(curl -s https://api.github.com/repos/$github_dektop_repo/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
  echo "Current GitHub Desktop Version: $github_desktop_CUR_VERSION => New Version: $github_desktop_NEW_VERSION"

  if [[ "$github_desktop_CUR_VERSION" < "$github_desktop_NEW_VERSION" ]]; then

    echo "Downloading new github-desktop version $github_desktop_NEW_VERSION" | mail -s "Downloading new github-desktop version $github_desktop_NEW_VERSION" $email
    cd "${CURRDIR}" || exit
    curl -s https://api.github.com/repos/$github_dektop_repo/releases \
      | grep "browser_download_url.*deb" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | head -n 1 \
      | wget -qi -

    deb_file="$(find . -name "GitHubDesktop-linux-$github_desktop_NEW_VERSION-linux1.deb" 2>/dev/null)"
    mv $deb_file ./debian/
    . ./update.sh
    git add -A
    git commit -m "Update github-desktop version to $github_desktop_NEW_VERSION"
    git push -u origin master
    git tag -a "$github_desktop_NEW_VERSION" -m "Update github-desktop version from $github_desktop_CUR_VERSION to $github_desktop_NEW_VERSION"
    git push --tags origin master
    exit

  else
    echo "Latest GitHub Desktop version already installed"
  fi
}

gnuzilla() {
  ICECATE_URL=https://download.opensuse.org/repositories/home:/losuler:/icecat/Debian_10/amd64
  cd "${CURRDIR}" || exit
  ICECAT_CUR_VERSION="$(find ./debian/ -name "icecat_*.deb" | cut -d _ -f 2 | sort -rnk3 | head -n 1)"
  ICECAT_NEW_VERSION="$(curl -s $ICECATE_URL | grep -oP 'href="icecat_\K[0-9]+\.[0-9]+\.[0-9](-[0-9])?' | sort -rnk3 | head -n 1)"
  echo "Current Icecat Version: $ICECAT_CUR_VERSION => New Version: $ICECAT_NEW_VERSION"
  
  if [[ "$ICECAT_CUR_VERSION" < "$ICECAT_NEW_VERSION" ]]; then
    echo "Downloading new Icecat version $ICECAT_NEW_VERSION" | mail -s "Downloading new Icecat version $ICECAT_NEW_VERSION" $email
    cd "${CURRDIR}" || exit
    wget $ICECATE_URL/icecat_"$ICECAT_NEW_VERSION"_amd64.deb
    
    deb_file="$(find . -name "icecat_"$ICECAT_NEW_VERSION"_amd64.deb" 2>/dev/null)"
    mv $deb_file ./debian/
    . ./update.sh
    git add -A
    git commit -m "Update Icecat version to $ICECAT_NEW_VERSION"
    git push -u origin master
    git tag -a "$ICECAT_NEW_VERSION" -m "Update Icecat version from $ICECAT_CUR_VERSION to $ICECAT_NEW_VERSION"
    git push --tags origin master
    exit
  else
    echo "Latest Icecat version already installed"
  fi
}

GitHubDesktop
gnuzilla
