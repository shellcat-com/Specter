# Durable access validation — September 11, 2026

Base revision: `dca64f164ca6624822108da103bff7abb150e487`. Work was isolated on `codex/durable-access`. This milestone adds GitHub Pages deployment and recovery documentation; native app and website content are unchanged.

## Checks and recovery exercise

- `scripts/check.sh` passed formatting, all 40 Swift tests in eight suites, C static analysis, release app build, and all 11 source-installer tests. Toolchain: Xcode 26.3 (17C529), Swift 6.2.4, Apple silicon, macOS 26.3.1 (25D771280a). Log: `.artifacts/durable-access/check.log`.
- `python3 scripts/check-website.py` passed all three pages, thirteen chapters, and 130 matching app/web/download themes; minimum default text contrast was 10.56:1. `git diff --cached --check` passed, and the staged workflow and documentation were reviewed.
- A separate HTTPS clone from GitHub, outside the project and its worktrees, passed `git fsck --full` and the website checker. All pre-existing worktrees had clean status. The previously unpushed `codex/command-install` commit had the same tree as its published counterpart and was also pushed, preserving that branch's original history.
- Unauthenticated release downloads passed `shasum -a 256 -c SHA256SUMS.txt`. The extracted app passed `codesign --verify --deep --strict`. ZIP SHA-256: `e747fa33bb37301b25401c6ccf1f88ac5731b1d5e96c17e8843e75587c0862f7`.
- Fifteen unauthenticated Vercel page/resource downloads returned HTTP 200 and matched checkout files byte-for-byte, including the three HTML pages, JS/CSS, catalogs, one theme download, video, poster, and captions. Raw results: `.artifacts/durable-access/vercel-http.json`.
- The live Vercel homepage rendered in the in-app browser with navigation, companion selectors, themes, installation instructions, and the versioned GitHub download link. This is a website exercise, not a fresh native app runtime test.

## Published hosting and independent backup

Deployment revision: `95cc1a5ebb30978b39f73fd91cf007d5f930e682`. Both the main-branch site check and [GitHub Pages deployment](https://github.com/shellcat-com/Specter/actions/runs/34572149202) succeeded. Vercel automatically promoted the same revision; its production alias reported Ready.

The backup website at https://shellcat-com.github.io/Specter/ rendered successfully. Searching for Alpine Dawn produced one result; selecting it updated the preview and the correct `/Specter/themes/alpine-dawn.json` download link. Handbook chapter navigation and the installation guide rendered correctly under the `/Specter/` path.

All 147 files in `website/` were downloaded from GitHub Pages without authentication and returned HTTP 200 with SHA-256 hashes matching source. This includes all 130 individual theme downloads and the full demo video. Raw results: `.artifacts/durable-access/pages-http.json`.

`scripts/install.sh` installed a complete locally signed app outside the source checkout in the user's Applications folder. Signature verification passed. The installed bundle has no symlinks back into the checkout, includes its helper, handbook, and terminfo, and its executable links only system libraries and frameworks. This confirms packaging independence, not a fresh interactive runtime test. Log: `.artifacts/durable-access/install.log`.

A GitHub mirror, complete Git bundle, downloaded preview ZIP, and checksums were saved outside the project directory. The bundle passed `git bundle verify`; a separate clone from the bundle passed `git fsck --full`. The mirror includes published branches and the preview tag. GitHub PR merge refs may appear as dangling objects in a normal clone; they are not corruption or missing source.

`swift run -c release SpecterBench` completed its synthetic 20,000-line workload with 5,765 retained rows. It is not an interactive latency or comparative performance measurement. Log: `.artifacts/durable-access/bench.log`.

`swift run -c release SpecterBench --fuzz 600` completed the full 600-second parser mutation run: seed `0x53504543544552`, 490,271 iterations, zero crashes. Log: `.artifacts/durable-access/fuzz.log`.

## Recovery limits

Restoration covers tracked source, resources, public media, documentation, and the published app attachment. It does not recover private preferences, shell history, live sessions, unpublished edits, or ignored raw captures. Signature verification does not establish notarization or clean-machine installation. An independent copy on the same Mac protects against deleting the project folder, not loss of the entire disk. Provider outages and deletion of remote accounts remain outside this guarantee.
