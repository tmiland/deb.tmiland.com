# deb
 A PPA repository for deb packages:
 
 - [GitHub Desktop - The Linux Fork](https://github.com/shiftkey/desktop)

 # Usage

 ```bash
 curl -SsL https://tmiland.github.io/deb/debian/KEY.gpg | sudo apt-key add -
 sudo curl -SsL -o /etc/apt/sources.list.d/tmiland.list https://tmiland.github.io/deb/debian/tmiland.list
 sudo apt update
 ```
