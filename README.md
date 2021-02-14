# deb
 A PPA repository for deb packages:
 
 - [GitHub Desktop - The Linux Fork](https://github.com/shiftkey/desktop)

 # Usage

 ```bash
 curl -SsL https://tmiland.github.io/deb/debian/KEY.gpg | sudo apt-key add -
 sudo curl -SsL -o /etc/apt/sources.list.d/tmiland.list https://tmiland.github.io/deb/debian/tmiland.list
 sudo apt update
 sudo apt install github-desktop
 ```
 
 # Credits
 
- [assafmo/ppa](https://github.com/assafmo/ppa)
- [Hosting your own PPA repository on GitHub](https://assafmo.github.io/2019/05/02/ppa-repo-hosted-on-github.html)
