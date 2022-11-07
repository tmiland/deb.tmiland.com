# deb
 A PPA repository for deb packages:
 
 - [GitHub Desktop - The Linux Fork](https://github.com/shiftkey/desktop)
 - [TeamSpeak3 Client](https://github.com/tmiland/TeamSpeak3-Client)
 - [GNU-IceCat](https://www.gnu.org/software/gnuzilla/)
 - [Invidious-Updater (And Installer)](https://github.com/tmiland/Invidious-Updater)

 # Usage

 ### Repository

 ```shell
 $ sudo curl -SsL -o /etc/apt/sources.list.d/tmiland.list https://deb.tmiland.com/debian/tmiland.list
 ```

 ```shell
 $ curl -SsL https://deb.tmiland.com/debian/KEY.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/tmiland-archive-keyring.gpg >/dev/null
 ```

 ```shell
 $ sudo apt update
 ```
 
 ```shell
 $ sudo apt install {package-name}
 ```

Package names: ```github-desktop``` ```icecat``` ```teamspeak3-client``` ```invidious-updater```

**Note**
Package ```gnu-icecat``` has changed to ```icecat```

To reinstall:

sudo apt remove ```gnu-icecat``` && sudo apt install ```icecat```

 # Credits
 
- [assafmo/ppa](https://github.com/assafmo/ppa)
- [Hosting your own PPA repository on GitHub](https://assafmo.github.io/2019/05/02/ppa-repo-hosted-on-github.html)

## Donations
<a href="https://coindrop.to/tmiland" target="_blank"><img src="https://coindrop.to/embed-button.png" style="border-radius: 10px; height: 57px !important;width: 229px !important;" alt="Coindrop.to me"></img></a>

## Web Hosting

Sign up for web hosting using this link, and receive $200 in credit over 60 days.

<a href="https://www.digitalocean.com/?refcode=f1f2b475fca0&amp;utm_campaign=Referral_Invite&amp;utm_medium=Referral_Program&amp;utm_source=badge"><img src="https://web-platforms.sfo2.digitaloceanspaces.com/WWW/Badge%203.svg" alt="DigitalOcean Referral Badge"></a>

### License

[![MIT License Image](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/MIT_logo.svg/220px-MIT_logo.svg.png)](https://github.com/tmiland/deb/blob/master/LICENSE)

[MIT License](https://github.com/tmiland/deb/blob/master/LICENSE)
