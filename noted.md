# noted.md

Repo notes — architecture, gotchas and session log.
APT package repo served via GitHub Pages from `master` root → <https://deb.tmiland.com>

## Commands

```shell
shellcheck update-repo.sh postinst update-icecat.sh   # lint (must be clean)
./update-repo.sh --no-push                            # dry run, commits locally
./update-repo.sh --regen-only --message "..."         # regen metadata only (after manual deb add)
```

Never run plain `./update-repo.sh` casually — it commits **and pushes to the live repo**.

## Architecture

- `packages/*.toml` — declarative package configs:
  - `name` (matches deb filenames in `debian/`, defaults to file stem)
  - `repo` + `asset` (anchored regex matching the GitHub release .deb)
  - `package` (optional: override apt package name in stub repacks)
  - `hide` (optional: desktop files removed post-install, keep one launcher)
  - `keep_versions` (optional: prune old debs)
- `packages/<name>.payload/` — optional files built into stub debs
  (e.g. `usr/share/applications/github-desktop.desktop`)
- `update-repo.sh` — engine, also run hourly by
  `.github/workflows/update-repo.yml` (GPG key from secret
  `APT_GPG_PRIVATE_KEY`, passphrase-less key `7C44CFE8E3B971486A2E0A280A2998CB2E6D61E0`)
- `update-icecat.sh` — local-only icecat builder (kept for when an upstream
  source returns; currently unused, icecat removed from repo)
- `postinst` — template sed-substituted into stubs (`REPO`, `APP_NAME`,
  `ASSET`, `HIDE` placeholders)
- `01-main/` is legacy, local-only (gitignored)

### Key invariants

- Metadata regen + commit happens **only when a deb actually changed** —
  unconditional regen creates timestamp-churn spam commits (the old cron did
  this hourly for months)
- Version compare: `dpkg --compare-versions`; version sort: `sort -V` —
  never lexicographic (`25.9.0 > 25.12.4` as strings)
- Match package files with `find -iname` — asset filenames often differ in
  case/hyphens from apt names (`DesktopPlus-v…` vs `github-desktop`)
- Debs >25 MB are repacked as **control-only install stubs** (GitHub's 100 MB
  file limit + Pages size); postinst re-downloads the real deb at install
  time
- Smoke test after regen: `apt-get update` against a throwaway `file://`
  apt state — validates Release signature, hashes and Packages parsing

## Gotchas (learned the hard way)

- Asset regex `$` anchor works in jq `test()` but **not** in the postinst
  grep of raw JSON (lines end with a closing `"`) — the engine strips the
  anchor for the postinst copy and postinst requires a trailing quote
- `/tmp` may be a full tmpfs — the engine uses repo-local `.tmp/`
  (trap-cleaned), never `/tmp`
- `dpkg-deb -R` on a 105 MB deb extracts ~400 MB — use `dpkg-deb -e`
  (control files only) for stub repacks
- `apt-cache show` depends on the system dpkg status — not a valid
  repo smoke test; grep the apt-stored list file instead
- Invidious-Updater upstream stopped shipping .deb assets — package is
  manual; icecat is unavailable (icecatbrowser.org down, GNU releases
  stopped 2019) — README recommends LibreWolf meanwhile

## Session log

### 2026-09-06 — debugging, history cleanup, modernization

- **Root-cause debugging**: hourly cron (`check.sh`) scraped
  `NEW_VERSION=25.12.4` from latest linuxmint/timeshift release but
  downloaded the pinned `master.lmde6` tarball (25.07.7) → expected deb
  never existed → silent failure → metadata-only junk commits every hour
  for months (6424 of 6567 commits were cron spam)
- **Timeshift removed** from the repo at user's request
- **History rewritten**: 6567 commits → 1 (`Initial commit`, identical
  tree, force-push, 25 stale tags deleted; local `.git` 1.7 GB → 3.1 MB
  after reflog expire + gc + dropping a junk stash)
- **Modernization**: declarative TOML configs + `update-repo.sh` engine +
  hourly GitHub Actions workflow; local cron disabled; GPG key added as
  repo secret; README rewritten (usage + "Managing packages")
- **Engine hardening** (each found by end-to-end testing):
  version-regex fix (`[0-9]+(\.[0-9]+)+`), TOML `'literal'` string
  parsing, `dpkg --compare-versions`, `find -iname`, download failure
  guards, smoke test (apt signature + list verification)
- **Icecat saga**: `icecatbrowser.org` down → the icecat package was an
  install-time-download stub, i.e. broken for users; no maintained
  .deb alternative exists (GNU 2019, losuler/OBS dead, no PPA/Flathub);
  removed from repo, `update-icecat.sh` kept ready, README recommends
  LibreWolf (`repo.librewolf.net`, verified live + signed)
- **GitHub Desktop**: added from `shiftkey/desktop`, then switched to the
  actively maintained fork `desktop-plus/desktop-plus` (3.6.5.1)
  - old shiftkey stub was broken at install time (postinst grep for
    `github-desktop` never matched `GitHubDesktop-…` asset names) →
    replaced with engine-sedded `ASSET` regex in postinst
  - apt package name kept as `github-desktop` via `package` override →
    seamless `apt upgrade` for existing users
  - upgrade removed the old `github-desktop.desktop`, leaving users with
    no launcher → payload mechanism added; stub now ships
    `usr/share/applications/github-desktop.desktop` and `hide = 'desktop-plus.desktop'`
    removes the upstream duplicate (single "GitHub Desktop" shortcut)
