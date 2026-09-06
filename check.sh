#!/usr/bin/env bash

# email=debian-desktop@tmiland.com

GH_TOKEN=$(cat "${HOME}"/.credentials/.ghtoken)
GH_USER=tmiland

# Detect absolute and full path as well as filename of this script
cd "$(dirname "$0")" || exit
CURRDIR=$(pwd)
cd - > /dev/null || exit

download_release() {
  cd "${CURRDIR}" || exit
  URL=$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/"$REPO"/releases 2>/dev/null \
      | grep -i -m 1 "browser_download_url.*$APP_NAME.*deb" \
      | cut -d'"' -f4)
  if [ -z "$URL" ]; then
    echo "No .deb download URL found for $APP_NAME, skipping..."
    return 1
  fi
    DEB_FILE="${URL##*/}"
    wget --quiet --continue --show-progress --progress=bar:force:noscroll "${URL}" -O "${DEB_FILE}"
    if [ ! -s "$DEB_FILE" ]; then
      echo "Download of $APP_NAME failed ($DEB_FILE is empty), skipping..."
      rm -f "$DEB_FILE"
      return 1
    fi
    if [[ $(stat -c%s "$DEB_FILE" 2>/dev/null) -gt 25000000 ]]
    then
      # https://www.baeldung.com/linux/package-deb-change-repack
      mkdir ./debtmp
      dpkg-deb -R "$DEB_FILE" ./debtmp
      cp -rp ./postinst ./debtmp/DEBIAN/postinst
      sed -i "s|REPO=|REPO=$REPO|g" ./debtmp/DEBIAN/postinst
      sed -i "s|APP_NAME=|APP_NAME=$APP_NAME|g" ./debtmp/DEBIAN/postinst
      cd ./debtmp/
      find . -type f -not -path "./DEBIAN/*" -exec md5sum {} + | sort -k 2 | sed 's/\.\/\(.*\)/\1/' > DEBIAN/md5sums
      # Remove everything but leave DEBIAN folder
      find . -mindepth 1 -maxdepth 1 -type d -not -name DEBIAN \
       -exec rm -rf '{}' \;
      cd .. || exit 0
      dpkg-deb -b --root-owner-group ./debtmp "$DEB_FILE"
      rm -rf ./debtmp
    fi
    mv "$DEB_FILE" ./debian/
}

publish_release() {
  . ./update.sh
  git add -A
  git commit -m "Update $APP_NAME version to $NEW_VERSION"
  git push -u origin master
  #git tag -a "$NEW_VERSION" -m "Update $APP_NAME version from $CUR_VERSION to $NEW_VERSION"
  git push --tags origin master
}

get_release() {
  for APP in 01-main/packages/*; do
    if [ -f "$APP" ]; then
      unset NEW_VERSION URL
      # shellcheck source=/dev/null
      . "$APP"

      if [ -z "$NEW_VERSION" ]; then
        NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/"$REPO"/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
      fi

      APP_NAME=$(basename "$APP")

      cd "${CURRDIR}" || exit

      CUR_VERSION="$(find ./debian -maxdepth 1 -type f -name "${APP_NAME}*.deb" -printf '%f\n' | grep -Eo '[0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}' | sort -V | tail -n 1)"

      echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"

      if [ -z "$CUR_VERSION" ] || dpkg --compare-versions "$CUR_VERSION" lt "$NEW_VERSION" 2>/dev/null; then
        echo "Downloading new $APP_NAME version $NEW_VERSION"

        if download_release; then
          publish_release
        else
          echo "Failed to download new $APP_NAME version $NEW_VERSION, not publishing..."
        fi
      else
        echo "Latest $APP_NAME version already downloaded..."
      fi
    fi
    sleep 0.5
  done
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
    # curl -sSL https://api.github.com/repos/$github_dektop_repo/releases \
    #     | grep "browser_download_url.*deb" \
    #     | cut -d : -f 2,3 \
    #     | tr -d \" \
    #     | head -n 1 \
    #     | wget -qi -
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
  ICECAT_CUR_VERSION=$(grep -Poh "(?<=Version: )([0-9]|\.)*(?=\s|$)" "${ICECAT_REPO_DIR}"/amd64/DEBIAN/*)
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

# snapweb() {
#   APP_NAME=snapweb
#   REPO=badaix/$APP_NAME
#   cd "${CURRDIR}" || exit
#   CUR_VERSION="$(find . -name ""$APP_NAME"_*.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
#   NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
#   echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
#   if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
#     echo "Downloading new $APP_NAME version $NEW_VERSION"
#     cd "${CURRDIR}" || exit
#     curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
  #       | grep "browser_download_url.*$APP_NAME.*deb" \
  #       | cut -d : -f 2,3 \
  #       | tr -d \" \
  #       | head -n 1 \
  #       | wget -qi -
#     DEB_FILE="$(ls -l | grep -oP "$APP_NAME"_"$NEW_VERSION.*\.deb" 2>/dev/null)"
#     mv "$DEB_FILE" ./debian/
#     publish_release
#     exit
#   else
#     echo "Latest $APP_NAME version already downloaded..."
#   fi
# }

# snapserver() {
#   cd "${CURRDIR}" || exit
#   echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
#   if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
#     echo "Downloading new $APP_NAME version $NEW_VERSION"
#     cd "${CURRDIR}" || exit
#     curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
  #       | grep "browser_download_url.*$APP_NAME.*deb" \
  #       | cut -d : -f 2,3 \
  #       | tr -d \" \
  #       | head -n 1 \
  #       | wget -qi -
#     DEB_FILE="$(find . -name "\"$APP_NAME\"_$NEW_VERSION-1_amd64_$(lsb_release -sc).deb" 2>/dev/null)"
#     mv "$DEB_FILE" ./debian/
#     publish_release
#     exit
#   else
#     echo "Latest $APP_NAME version already downloaded..."
#   fi
# }

# snapclient() {
#   APP_NAME=snapclient
#   REPO=badaix/snapcast
#   cd "${CURRDIR}" || exit
#   CUR_VERSION="$(find . -name ""$APP_NAME"_*.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
#   NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
#   echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
#   if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
#     echo "Downloading new $APP_NAME version $NEW_VERSION"
#     cd "${CURRDIR}" || exit
#     curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
  #       | grep "browser_download_url.*$APP_NAME.*deb" \
  #       | cut -d : -f 2,3 \
  #       | tr -d \" \
  #       | head -n 1 \
  #       | wget -qi -
#     DEB_FILE="$(find . -name "\"$APP_NAME\"_$NEW_VERSION-1_amd64_$(lsb_release -sc).deb" 2>/dev/null)"
#     mv "$DEB_FILE" ./debian/
#     publish_release
#     exit
#   else
#     echo "Latest $APP_NAME version already downloaded..."
#   fi
# }

# snapclient_with_pulse() {
#   APP_NAME=snapclient-with-pulse
#   REPO=badaix/snapcast
#   cd "${CURRDIR}" || exit
#   CUR_VERSION="$(find . -name "snapclient_*with-pulse.deb" | sed 's/.*_\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
#   NEW_VERSION="$(curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
#   echo "Current $APP_NAME Version: $CUR_VERSION => New Version: $NEW_VERSION"
#   if [[ "$CUR_VERSION" < "$NEW_VERSION" ]]; then
#     echo "Downloading new $APP_NAME version $NEW_VERSION"
#     cd "${CURRDIR}" || exit
#     curl --user "$GH_USER:$GH_TOKEN" -sSL https://api.github.com/repos/$REPO/releases \
  #       | grep "browser_download_url.*snapclient.*_with-pulse.deb" \
  #       | cut -d : -f 2,3 \
  #       | tr -d \" \
  #       | head -n 1 \
  #       | wget -qi -
#     DEB_FILE="$(find . -name "snapclient_"$NEW_VERSION"-1_amd64_*_with-pulse.deb" 2>/dev/null)"
#     # https://www.baeldung.com/linux/package-deb-change-repack
#     # Change package name to "snapclient-with-pulse"
#     mkdir ./debtmp
#     dpkg-deb -R "$DEB_FILE" ./debtmp
#     sed -i "s|Package: snapclient|Package: snapclient-with-pulse|g" ./debtmp/DEBIAN/control
#     cd ./debtmp/
#     find . -type f -not -path "./DEBIAN/*" -exec md5sum {} + | sort -k 2 | sed 's/\.\/\(.*\)/\1/' > DEBIAN/md5sums
#     cd .. || exit 0
#     dpkg-deb -b ./debtmp "$DEB_FILE"
#     rm -rf ./debtmp
#     ###############
#     mv "$DEB_FILE" ./debian/
#     publish_release
#     exit
#   else
#     echo "Latest $APP_NAME version already downloaded..."
#   fi
# }


#GitHubDesktop
gnuzilla
# snapweb
# snapserver
# snapclient
# snapclient_with_pulse
get_release

exit 0
