# deb
[![Update apt repo](https://github.com/tmiland/deb.tmiland.com/actions/workflows/update-repo.yml/badge.svg)](https://github.com/tmiland/deb.tmiland.com/actions/workflows/update-repo.yml)

 A PPA repository for deb packages:
  
  - [TeamSpeak3 Client](https://github.com/tmiland/TeamSpeak3-Client)
  - [GitHub Desktop](https://github.com/desktop-plus/desktop-plus) (Linux builds, maintained fork)
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

# Supported Software

The software below can be installed, updated and removed using this repository:

| Source   | Package Name   | Description   |
| :------: | :------------- | :------------ |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/AppFlowy-IO/AppFlowy) | `AppFlowy` | <i>An Open Source Alternative to Notion</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/sharkdp/bat) | `bat` | <i>cat(1) clone with wings.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/usebruno/bruno) | `bruno` | <i>Opensource API Client for Exploring and Testing APIs</i> |
| [<img src="./img/debian.png" align="top" width="20" />](https://wiki.debian.org/Teams/Dpkg) | `dpkg` | <i>Debian package management system</i> |
| [<img src="./img/debian.png" align="top" width="20" />](https://wiki.debian.org/Teams/Dpkg) | `dpkg-repack` | <i>Debian package archiving tool</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/jgraph/drawio-desktop) | `draw.io` | <i>draw.io desktop</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/muesli/duf) | `duf` | <i>Disk Usage/Free Utility</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/junegunn/fzf) | `fzf` | <i>Command-line fuzzy finder</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/desktop-plus/desktop-plus) | `github-desktop` | <i>GitHub Desktop fork with advanced functionality and improvements.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/block/goose) | `goose` | <i>Goose App</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/gohugoio/hugo) | `hugo` | <i>A fast and flexible Static Site Generator written in Go.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/vercel/hyper) | `hyper` | <i>A terminal built on web technologies</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/WerWolv/ImHex) | `ImHex` | <i>ImHex Hex Editor</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/tmiland/Invidious-Updater) | `Invidious-Updater` | <i>Script to install and update Invidious</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/laurent22/joplin) | `joplin` | <i>Joplin for Desktop</i> |
| [<img src="./img/direct.png" align="top" width="20" />](http://search.cpan.org/dist/Term-Spinner-Color/) | `libterm-spinner-color-perl` | <i>A terminal spinner/progress bar with Unicode, color, and no non-core dependencies.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/mmaher88/logitune) | `logitune` | <i>Logitech device configurator for Linux</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/marktext/marktext) | `marktext` | <i>A simple and elegant open-source markdown editor that focused on speed and usability.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/anomalyco/opencode) | `opencode` | <i>The open source coding agent.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/jgm/pandoc) | `pandoc` | <i>general markup converter</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/rustdesk/rustdesk) | `rustdesk` | <i>A remote control software.</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/siyuan-note/siyuan) | `siyuan` | <i>From thought to insight, with agents</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/badaix/snapweb) | `snapweb` | <i>Web client for Snapcast</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/KRTirtho/spotube) | `spotube` | <i>Open source extensible music streaming platform and app, based on BYOMM (Bring your own music metadata) concept</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/mfat/sshpilot) | `sshpilot` | <i>modern, lightweight SSH connection manager</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/Stirling-Tools/Stirling-PDF) | `stirling-pdf` | <i>Stirling-PDF Desktop Application</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/Eugeny/tabby) | `tabby-terminal` | <i>A terminal for a modern age</i> |
| [<img src="./img/github.png" align="top" width="20" />](https://github.com/tmiland/TeamSpeak3-Client) | `teamspeak3-client` | <i>VoIP chat for online gaming</i> |

**Legend**

- <img src="./img/github.png" align="top" width="16" /> managed from GitHub releases
- <img src="./img/debian.png" align="top" width="16" /> Debian packages
- <img src="./img/direct.png" align="top" width="16" /> other source

# Managing packages

Each tracked package is a declarative config in ```packages/<name>.pkg```:

```toml
repo = 'owner/name'        # GitHub repo that publishes releases
asset = 'pkg_.*_all\.deb'  # regex matching the .deb release asset
keep_versions = 2          # optional: only keep the newest N debs
package = 'apt-name'       # optional: override apt package name (stub repacks)
```

To add an app: drop a new ```.pkg``` in ```packages/``` and commit — the
[update workflow](.github/workflows/update-repo.yml) picks it up on the next
run (hourly, or manual via *Actions → Update apt repo → Run workflow*).

The workflow checks every package, downloads new versions, regenerates and
signs the repo metadata, smoke-tests it with apt, and pushes to `master`
(served via GitHub Pages).

Two packages are special:

- **icecat** — currently **unavailable**: the package was an installer-stub
  that downloads binaries from icecatbrowser.org at install time, and that
  site is down (and GNU's own releases stopped in 2019). The icecat debs are
  therefore removed from the repo until a working upstream source exists.
  `update-icecat.sh` remains in place to re-publish it when that happens.

  As a free, actively maintained alternative in the same spirit (libre,
  privacy-hardened, no telemetry), use [LibreWolf](https://librewolf.net)'s
  official signed apt repository instead:

  ```shell
  sudo apt update && sudo apt install extrepo -y
  sudo extrepo enable librewolf
  sudo apt update && sudo apt install librewolf -y
  ```
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
