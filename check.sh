#!/usr/bin/env bash

# email=debian-desktop@tmiland.com

GH_TOKEN=$(cat "${HOME}"/.credentials/.ghtoken)
GH_USER=tmiland

# Detect absolute and full path as well as filename of this script
cd "$(dirname "$0")" || exit
CURRDIR=$(pwd)
cd - > /dev/null || exit

publish_release() {
  . ./update.sh
  git add -A
  git commit -m "Update $APP_NAME version to $NEW_VERSION"
  git push -u origin master
  #git tag -a "$NEW_VERSION" -m "Update $APP_NAME version from $CUR_VERSION to $NEW_VERSION"
  git push --tags origin master
}
# GitHubDesktop() {
#   github_dektop_repo=shiftkey/desktop
#   cd "${CURRDIR}" || exit
#   github_desktop_CUR_VERSION="$(find ./debian/ -name "GitHubDesktop-linux-*.deb" | sed 's/.*-\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
#   github_desktop_NEW_VERSION="$(curl -sSL https://api.github.com/repos/$github_dektop_repo/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
#   echo "Current GitHub Desktop Version: $github_desktop_CUR_VERSION => New Version: $github_desktop_NEW_VERSION"
#
#   if [[ "$github_desktop_CUR_VERSION" < "$github_desktop_NEW_VERSION" ]]; then
#
#     echo "Downloading new github-desktop version $github_desktop_NEW_VERSION" | mail -s "Downloading new github-desktop version $github_desktop_NEW_VERSION" $email
#     cd "${CURRDIR}" || exit
#     curl -sSL https://api.github.com/repos/$github_dektop_repo/releases \
  #       | grep "browser_download_url.*deb" \
  #       | cut -d : -f 2,3 \
  #       | tr -d \" \
  #       | head -n 1 \
  #       | wget -qi -
#
#     DEB_FILE="$(find . -name "GitHubDesktop-linux*-$github_desktop_NEW_VERSION-linux*.deb" 2>/dev/null)"
#     mv "$DEB_FILE" ./debian/
#     . ./update.sh
#     git add -A
#     git commit -m "Update github-desktop version to $github_desktop_NEW_VERSION"
#     git push -u origin master
#     #git tag -a "$github_desktop_NEW_VERSION" -m "Update github-desktop version from $github_desktop_CUR_VERSION to $github_desktop_NEW_VERSION"
#     git push --tags origin master
#     exit
#
#   else
#     echo "Latest GitHub Desktop version already installed"
#   fi
# }

gnuzilla() {
  APP_NAME=Icecat
  ICECAT_REPO_DIR="../GNU-IceCat"
  cd "${CURRDIR}" || exit
  ICECAT_CUR_VERSION=$(echo $(grep -Poh "(?<=Version: )([0-9]|\.)*(?=\s|$)" "${ICECAT_REPO_DIR}"/amd64/DEBIAN/*))
  ICECAT_NEW_VERSION=$(curl -s https://icecatbrowser.org/all_downloads.html |
    grep -Po 'b>\K.*(?=</b)' |
    head -n 1 |
    sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' |
    # Stript trailing .
  sed 's/.$//')
  echo "Current $APP_NAME Version: $ICECAT_CUR_VERSION => New Version: $ICECAT_NEW_VERSION"
  if dpkg --compare-versions "$ICECAT_CUR_VERSION" lt "$ICECAT_NEW_VERSION"
  then
    echo "Downloading new $APP_NAME version $ICECAT_NEW_VERSION"
    cd "${ICECAT_REPO_DIR}" || exit
    ./package.sh
    cd - || exit 1
    DEB_FILE="$(find "${ICECAT_REPO_DIR}" -name "icecat_${ICECAT_NEW_VERSION}_amd64.deb" 2>/dev/null)"
    mv "$DEB_FILE" ./debian/
    publish_release
    exit
  else
    echo "Latest $APP_NAME version already installed"
  fi
}

snapweb() {
  APP_NAME=snapweb
  REPO=badaix/$APP_NAME
  cd "${CURRDIR}" || exit
  CUR_VERSION="$(find . -name ""$APP_NAME"_*.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
  echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
  if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
    echo "Downloading new $APP_NAME version $NEW_VERSION"
    cd "${CURRDIR}" || exit
    curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
      | grep "browser_download_url.*$APP_NAME.*deb" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | head -n 1 \
      | wget -qi -
    DEB_FILE="$(ls -l | grep -oP "$APP_NAME"_"$NEW_VERSION.*\.deb" 2>/dev/null)"
    mv "$DEB_FILE" ./debian/
    publish_release
    exit
  else
    echo "Latest $APP_NAME version already downloaded..."
  fi
}

snapserver() {
  APP_NAME=snapserver
  REPO=badaix/snapcast
  cd "${CURRDIR}" || exit
  CUR_VERSION="$(find . -name ""$APP_NAME"_*.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
  echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
  if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
    echo "Downloading new $APP_NAME version $NEW_VERSION"
    cd "${CURRDIR}" || exit
    curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
      | grep "browser_download_url.*$APP_NAME.*deb" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | head -n 1 \
      | wget -qi -
    DEB_FILE="$(find . -name "\"$APP_NAME\"_$NEW_VERSION-1_amd64_$(lsb_release -sc).deb" 2>/dev/null)"
    mv "$DEB_FILE" ./debian/
    publish_release
    exit
  else
    echo "Latest $APP_NAME version already downloaded..."
  fi
}

snapclient() {
  APP_NAME=snapclient
  REPO=badaix/snapcast
  cd "${CURRDIR}" || exit
  CUR_VERSION="$(find . -name ""$APP_NAME"_*.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
  echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
  if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
    echo "Downloading new $APP_NAME version $NEW_VERSION"
    cd "${CURRDIR}" || exit
    curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
      | grep "browser_download_url.*$APP_NAME.*deb" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | head -n 1 \
      | wget -qi -
    DEB_FILE="$(find . -name "\"$APP_NAME\"_$NEW_VERSION-1_amd64_$(lsb_release -sc).deb" 2>/dev/null)"
    mv "$DEB_FILE" ./debian/
    publish_release
    exit
  else
    echo "Latest $APP_NAME version already downloaded..."
  fi
}

snapclient_with_pulse() {
  APP_NAME=snapclient-with-pulse
  REPO=badaix/snapcast
  cd "${CURRDIR}" || exit
  CUR_VERSION="$(find . -name ""$APP_NAME"_*with-pulse.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
  echo "Current snapclient with pulse Version: $CUR_VERSION => New Version: $NEW_VERSION"
  if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
    echo "Downloading new snapclient version $NEW_VERSION"
    cd "${CURRDIR}" || exit
    curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
      | grep "browser_download_url.*snapclient.*_with-pulse.deb" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | head -n 1 \
      | wget -qi -
    DEB_FILE="$(find . -name "\"$APP_NAME\"_$NEW_VERSION-1_amd64_$(lsb_release -sc)_with-pulse.deb" 2>/dev/null)"
    # https://www.baeldung.com/linux/package-deb-change-repack
    # Change package name to "snapclient-with-pulse"
    mkdir ./debtmp
    dpkg-deb -R "$DEB_FILE" ./debtmp
    sed -i "s|Package: snapclient|Package: snapclient-with-pulse|g" ./debtmp/DEBIAN/control
    cd ./debtmp/
    find . -type f -not -path "./DEBIAN/*" -exec md5sum {} + | sort -k 2 | sed 's/\.\/\(.*\)/\1/' > DEBIAN/md5sums
    cd .. || exit 0
    dpkg-deb -b ./debtmp "$DEB_FILE"
    rm -rf ./debtmp
    ###############
    mv "$DEB_FILE" ./debian/
    publish_release
    exit
  else
    echo "Latest $APP_NAME version already downloaded..."
  fi
}

# download_file() {
#   echo "Downloading $APP_NAME version $NEW_VERSION"
#   cd "${CURRDIR}" || exit
#   curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/"$REPO"/releases \
#     | grep "browser_download_url.*$FILE_NAME" \
#     | cut -d : -f 2,3 \
#     | tr -d \" \
#     | head -n 1 \
#     | wget -qi -
# }



timeshift() {
  APP_NAME=timeshift
  FILE_NAME=packages.tar.gz
  REPO=linuxmint/$APP_NAME
  cd "${CURRDIR}" || exit

  CUR_VERSION="$(find . -type f -name "$APP_NAME*.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/"$REPO"/releases |
  grep -oP '"browser_download_url":.*amd64.changes' |
  head -n 1 |
  sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/')"
  
  if [ -z "$CUR_VERSION"  ]; then
    echo "Downloading Latest $APP_NAME version..."
    curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/"$REPO"/releases |
    jq -r '.[] | select(.tag_name == "master.lmde6") | .assets[] | .browser_download_url' |
    head -n 1 |
    wget -qi -
    tar -xzvf packages.tar.gz
    DEB_FILE="$(find ./packages -type f -name "\"$APP_NAME\"_\"$NEW_VERSION\"_amd64.deb" 2>/dev/null)"
    mv "$DEB_FILE" ./debian/
    rm -rf ./packages
    publish_release
    exit
  else
  echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
  if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]
  then
    echo "Downloading $APP_NAME version $NEW_VERSION"
    cd "${CURRDIR}" || exit
    curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/"$REPO"/releases |
    jq -r '.[] | select(.tag_name == "master.lmde6") | .assets[] | .browser_download_url' |
    head -n 1 |
    wget -qi -
    tar -xzvf packages.tar.gz
    DEB_FILE="$(find ./packages -type f -name "\"$APP_NAME\"_\"$NEW_VERSION\"_amd64.deb" 2>/dev/null)"
    mv "$DEB_FILE" ./debian/
    rm -rf ./packages
    rm ./packages.tar.gz
    publish_release
    exit
  else
    echo "Latest $APP_NAME version already downloaded..."
  fi
fi
}

#GitHubDesktop
gnuzilla
snapweb
snapserver
snapclient
snapclient_with_pulse
timeshift