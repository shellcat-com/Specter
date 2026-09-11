# Access and recovery

Bookmark these addresses outside the project folder:

| What you need | Address |
| --- | --- |
| Main website | https://specter-terminal-umber.vercel.app |
| Backup website | https://shellcat-com.github.io/Specter/ |
| Source code and history | https://github.com/shellcat-com/Specter |
| App download and checksum | https://github.com/shellcat-com/Specter/releases/tag/v0.1.0-preview.1 |
| Source ZIP | https://github.com/shellcat-com/Specter/archive/refs/heads/main.zip |
| This recovery guide | https://github.com/shellcat-com/Specter/blob/main/docs/recovery.md |

The websites and GitHub downloads run on hosted infrastructure. Turning off your Mac or deleting your local source checkout does not delete them. The two websites publish the same checked `website/` directory from `main`. If one host is unavailable, use the other address. This is a manual fallback, not automatic failover or a guarantee of uninterrupted service.

## Restore after deleting the local project

For the app alone, download the ZIP and checksum from the release above, follow [installation](install.md), and keep the complete app in Applications. The preview is ad-hoc signed and not notarized; macOS may block a downloaded copy. An app kept only inside the deleted checkout's `.build` directory is deleted with that checkout.

To recover the source and tracked history, choose a destination that does not already exist:

```sh
mkdir -p "$HOME/Developer"
git clone https://github.com/shellcat-com/Specter.git "$HOME/Developer/Specter"
cd "$HOME/Developer/Specter"
git log -1 --oneline
```

The clone includes the app source, website, theme and companion resources, documentation, public demo media, scripts, and release tags. With the toolchain described in [installation](install.md), run `./scripts/build-app.sh` to regenerate the app. Use `scripts/serve-website.sh` to preview the recovered website locally. Neither recovery path needs this Codex task or its worktrees.

## What is not in GitHub

Git does not save uncommitted or untracked edits. `.build/`, `.artifacts/`, local worktrees, host login credentials, and local preferences are excluded. Review `git status --short` and push wanted commits before deleting any future checkout. A linked Git worktree depends on its original repository and is not an independent backup.

Specter profiles, custom themes, favorites, and optional layout preferences live on your Mac. Export wanted custom themes and use your normal Mac backup for personal settings and shell/project files. Terminal contents, running shells, and command history are not backed up by this repository. Raw development captures are deliberately excluded from publication.

## Keep an independent backup

For protection against deleting the GitHub repository or losing the hosting accounts, keep an additional copy on another disk or a backup service you control:

```sh
git clone --mirror https://github.com/shellcat-com/Specter.git Specter.git
git -C Specter.git bundle create ../Specter.bundle --all
git -C Specter.git bundle verify ../Specter.bundle
```

Also save the release ZIP and `SHA256SUMS.txt`; Git bundles do not contain release attachments, issues, account settings, or deployments. A bundle restores into a new directory with `git clone Specter.bundle Specter-restored`. Set its origin back to GitHub before future fetches or pushes. Keep this independent backup outside any folder you intend to delete.

Do not delete the GitHub repository, Vercel project, or their accounts if you want their existing links to continue working. Hosting access remains subject to account access, provider availability, and plan limits. See [hosting](hosting.md) for deployment and release maintenance.
