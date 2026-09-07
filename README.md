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
| — | `AppFlowy` | <i>An Open Source Alternative to Notion</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/sharkdp/bat) | `bat` | <i>cat(1) clone with wings.</i> |
| [www.usebruno.com](https://www.usebruno.com) | `bruno` | <i></i> |
| [wiki.debian.org/Teams/Dpkg](https://wiki.debian.org/Teams/Dpkg) | `dpkg` | <i>Debian package management system</i> |
| [wiki.debian.org/Teams/Dpkg](https://wiki.debian.org/Teams/Dpkg) | `dpkg-repack` | <i>Debian package archiving tool</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/jgraph/drawio) | `draw.io` | <i></i> |
| [fribbledom.com/](https://fribbledom.com/) | `duf` | <i>Disk Usage/Free Utility</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/junegunn/fzf) | `fzf` | <i>Command-line fuzzy finder</i> |
| [desktop-plus.org](https://desktop-plus.org) | `github-desktop` | <i>GitHub Desktop fork with advanced functionality and improvements.</i> |
| [goose-docs.ai/](https://goose-docs.ai/) | `goose` | <i>Goose App</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/gohugoio/hugo) | `hugo` | <i>A fast and flexible Static Site Generator written in Go.</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/zeit/hyper#readme) | `hyper` | <i></i> |
| — | `ImHex` | <i>ImHex Hex Editor</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/tmiland/Invidious-Updater) | `Invidious-Updater` | <i>Script to install and update Invidious</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/laurent22/joplin#readme) | `joplin` | <i></i> |
| [search.cpan.org/dist/Term-Spinner-Color/](http://search.cpan.org/dist/Term-Spinner-Color/) | `libterm-spinner-color-perl` | <i>A terminal spinner/progress bar with Unicode, color, and no non-core dependencies.</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/mmaher88/logitune) | `logitune` | <i>Logitech device configurator for Linux</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/marktext/marktext) | `marktext` | <i></i> |
| [opencode.ai](https://opencode.ai) | `opencode` | <i></i> |
| — | `pandoc` | <i>general markup converter</i> |
| [rustdesk.com](https://rustdesk.com) | `rustdesk` | <i>A remote control software.</i> |
| [b3log.org/siyuan](https://b3log.org/siyuan) | `siyuan` | <i></i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/badaix/snapweb) | `snapweb` | <i>Web client for Snapcast</i> |
| [spotube.krtirtho.dev](https://spotube.krtirtho.dev) | `spotube` | <i>Open source extensible music streaming platform and app, based on BYOMM (Bring your own music metadata) concept</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/mfat/sshpilot) | `sshpilot` | <i>modern, lightweight SSH connection manager</i> |
| — | `stirling-pdf` | <i>Stirling-PDF Desktop Application</i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/Eugeny/tabby#readme) | `tabby-terminal` | <i></i> |
| [<img src="./.github/github.png" align="top" width="20" />](https://github.com/tmiland/TeamSpeak3-Client) | `teamspeak3-client` | <i>VoIP chat for online gaming</i> |

# Managing packages

Each tracked package is a declarative config in ```packages/<name>.toml```:

```toml
repo = 'owner/name'        # GitHub repo that publishes releases
asset = 'pkg_.*_all\.deb'  # regex matching the .deb release asset
keep_versions = 2          # optional: only keep the newest N debs
package = 'apt-name'       # optional: override apt package name (stub repacks)
```

To add an app: drop a new ```.toml``` in ```packages/``` and commit — the
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
