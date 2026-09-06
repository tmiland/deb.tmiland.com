# deb
 A PPA repository for deb packages:
  
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

Package names: ```icecat``` ```teamspeak3-client``` ```invidious-updater```

**Note**
Package ```gnu-icecat``` has changed to ```icecat```

To reinstall:

sudo apt remove ```gnu-icecat``` && sudo apt install ```icecat```

# Managing packages

Each tracked package is a declarative config in ```packages/<name>.toml```:

```toml
repo = 'owner/name'        # GitHub repo that publishes releases
asset = 'pkg_.*_all\.deb'  # regex matching the .deb release asset
keep_versions = 2          # optional: only keep the newest N debs
```

To add an app: drop a new ```.toml``` in ```packages/``` and commit — the
[update workflow](.github/workflows/update-repo.yml) picks it up on the next
run (hourly, or manual via *Actions → Update apt repo → Run workflow*).

The workflow checks every package, downloads new versions, regenerates and
signs the repo metadata, smoke-tests it with apt, and pushes to `master`
(served via GitHub Pages).

Two packages are special:

- **icecat** — upstream has no .deb release assets, so it is built locally
  from a checkout of [GNU-IceCat](https://github.com/tmiland/GNU-IceCat) and
  published with ```./update-icecat.sh```.
- **invidious-updater** — upstream no longer publishes .deb assets; the
  package is updated manually when needed.

 # Credits
 
- [assafmo/ppa](https://github.com/assafmo/ppa)
- [Hosting your own PPA repository on GitHub](https://assafmo.github.io/2019/05/02/ppa-repo-hosted-on-github.html)

## Donations
<a href="https://coindrop.to/tmiland" target="_blank"><img src="https://coindrop.to/embed-button.png" style="border-radius: 10px; height: 57px !important;width: 229px !important;" alt="Coindrop.to me"></img></a>

### License

[![MIT License Image](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/MIT_logo.svg/220px-MIT_logo.svg.png)](https://github.com/tmiland/deb/blob/master/LICENSE)

[MIT License](https://github.com/tmiland/deb/blob/master/LICENSE)
