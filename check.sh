#!/usr/bin/env bash

email=root

GitHubDesktop() {
  github_dektop_repo=shiftkey/desktop
  github_desktop_CUR_VERSION="$(find ./debian/ -name "GitHubDesktop-linux-*.deb" | sed 's/.*-\([0-9\.][0-9\.]*\).*/\1/' | sort -rnk3 | head -n 1)"
  github_desktop_NEW_VERSION="$(curl -s https://api.github.com/repos/$github_dektop_repo/releases | grep '"tag_name":' | sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' | head -n 1)"
  echo "Current GitHub Desktop Version: $github_desktop_CUR_VERSION => New Version: $github_desktop_NEW_VERSION"

  if [[ "$github_desktop_CUR_VERSION" < "$github_desktop_NEW_VERSION" ]]; then

    echo "Downloading new github-desktop version $github_desktop_NEW_VERSION" | mail -s "Downloading new github-desktop version $github_desktop_NEW_VERSION" $email

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

GitHubDesktop
