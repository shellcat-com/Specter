# Durable access validation — September 11, 2026

Base revision: `dca64f164ca6624822108da103bff7abb150e487`. Work was isolated on `codex/durable-access`. This milestone adds GitHub Pages deployment and recovery documentation; native app and website content are unchanged.

## Checks and recovery exercise

- `scripts/check.sh` passed formatting, all 40 Swift tests in eight suites, C static analysis, release app build, and all 11 source-installer tests. Toolchain: Xcode 26.3 (17C529), Swift 6.2.4, Apple silicon, macOS 26.3.1 (25D771280a). Log: `.artifacts/durable-access/check.log`.
- `python3 scripts/check-website.py` passed all three pages, thirteen chapters, and 130 matching app/web/download themes; minimum default text contrast was 10.56:1. `git diff --cached --check` passed, and the staged workflow and documentation were reviewed.
- A separate HTTPS clone from GitHub, outside the project and its worktrees, passed `git fsck --full` and the website checker. All pre-existing worktrees had clean status. The previously unpushed `codex/command-install` commit had the same tree as its published counterpart and was also pushed, preserving that branch's original history.
- Unauthenticated release downloads passed `shasum -a 256 -c SHA256SUMS.txt`. The extracted app passed `codesign --verify --deep --strict`. ZIP SHA-256: `e747fa33bb37301b25401c6ccf1f88ac5731b1d5e96c17e8843e75587c0862f7`.
- Fifteen unauthenticated Vercel page/resource downloads returned HTTP 200 and matched checkout files byte-for-byte, including the three HTML pages, JS/CSS, catalogs, one theme download, video, poster, and captions. Raw results: `.artifacts/durable-access/vercel-http.json`.
- The live Vercel homepage rendered in the in-app browser with navigation, companion selectors, themes, installation instructions, and the versioned GitHub download link. This is a website exercise, not a fresh native app runtime test.

## Boundaries

Restoration covers tracked source, resources, public media, documentation, and the published app attachment. It does not recover private preferences, shell history, live sessions, unpublished edits, or ignored raw captures. Signature verification does not establish notarization or clean-machine installation. An independent copy on the same Mac protects against deleting the project folder, not loss of the entire disk. Provider outages and deletion of remote accounts remain outside this guarantee.
