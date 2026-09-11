# Download and install Specter

**Your shell. Your colors. Your Mac.**

Specter is a **developer preview for Apple silicon**. Choose the prebuilt ZIP (no Xcode needed) or the source installer below (full Xcode required).

## Download the prebuilt preview

[Download Specter 0.1.0-preview.1 for Apple silicon](https://github.com/shellcat-com/Specter/releases/download/v0.1.0-preview.1/Specter-0.1.0-preview.1-arm64.zip) · [Release notes and SHA-256 checksum](https://github.com/shellcat-com/Specter/releases/tag/v0.1.0-preview.1)

1. Download the ZIP and `SHA256SUMS.txt` from that release. In the download folder, run `shasum -a 256 -c SHA256SUMS.txt` to check file integrity. This is not proof of publisher identity.
2. Extract the ZIP, then move the complete **Specter.app** into Applications.
3. Open Specter. **This tester build is ad-hoc signed, without Developer ID or Apple notarization. macOS may block it.** Read [Apple’s guidance for downloaded apps](https://support.apple.com/en-us/102445) and only make an app-specific exception if you trust the source. Do not disable system-wide protections. Building from reviewed source is another option.

The deployment target is macOS 14+; runtime validation currently covers an M3 Mac on macOS 26.3.1. This is not a broadly validated stable release. No Intel build is provided.

The app runs locally. You do not need a Specter account, a hosted server, or this website to remain open. Network commands and external AI tools need their own connections and accounts. The site and GitHub download remain available when the maintainer’s computer is off.

Updates are manual: save work, quit Specter, keep a backup of your previous app, and replace it with the next release. The source installer below also supports safe replacement with `--replace`.

[Download source ZIP](https://github.com/shellcat-com/Specter/archive/refs/heads/main.zip) · [Browse source](https://github.com/shellcat-com/Specter) · [Compatibility](compatibility.md)

## 1. Get your Mac ready

| You need | Details |
| --- | --- |
| Mac | Apple silicon; macOS 14 or later is the deployment target. |
| Development tools | Full Xcode with the macOS SDK, Swift 6, and Metal tools. Command Line Tools alone may not be enough. |
| Tested toolchain | Xcode 26.3 / Swift 6.2.4 on an M3 Mac running macOS 26.3.1. Other supported-target OS versions have not been runtime-verified. |
| Accounts | No Specter account, paid Apple developer membership, or Developer ID certificate is needed for the local build. |

Install Xcode from Apple and open it once to finish its component setup. In **Xcode → Settings → Locations**, select the installed Xcode version under Command Line Tools. Use a version of Xcode compatible with your macOS version.

In your current terminal, check that the tools are available:

```sh
xcodebuild -version
xcrun swift --version
xcrun --find metal
```

If a command fails, finish Xcode setup before continuing. The project does not require Homebrew, Node.js, Python, or XcodeGen just to build the app.

## Quick install from GitHub

After Xcode setup, paste this command into your existing terminal:

```sh
mkdir -p "$HOME/Developer" && git clone https://github.com/shellcat-com/Specter.git "$HOME/Developer/Specter" && "$HOME/Developer/Specter/scripts/install.sh"
```

This downloads the source into `~/Developer/Specter`, builds it on your Mac, verifies the local app signature, and installs it in `~/Applications/Specter.app`. It can take several minutes. It requires no administrator password and does not launch the app automatically.

```sh
open "$HOME/Applications/Specter.app"
```

If the source folder already exists, use your checkout instead:

```sh
cd ~/Developer/Specter
./scripts/install.sh
```

An existing app is left intact unless you pass `--replace`; see the update instructions below. The installer only builds the checkout you downloaded. You can inspect `scripts/install.sh` and the source before running it, or use the manual steps below. This is a source installation, not a prebuilt binary, Homebrew package, or notarized release.

## 2. Download the source

**With Git — easiest to update later:** run these commands in your current terminal. If `~/Developer/Specter` already exists, use your existing checkout or choose a different directory instead of cloning over it.

```sh
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/shellcat-com/Specter.git
cd Specter
```

**Without Git:** [download the source ZIP](https://github.com/shellcat-com/Specter/archive/refs/heads/main.zip), double-click it to extract it, and move the extracted `Specter-main` folder into `~/Developer`. Then run:

```sh
cd ~/Developer/Specter-main
```

Use a local folder outside iCloud Drive, Dropbox, or another sync service to avoid signing problems from attached file metadata. A source ZIP contains code, not a prebuilt application.

## 3. Build and open

From the folder containing `Package.swift` and `scripts/`, run:

```sh
./scripts/build-app.sh
open .build/Specter.app
```

The script compiles a release build, includes the PTY helper, Metal resources, 130 themes, terminfo, and offline handbook, then signs the complete bundle ad hoc for local use. A successful build ends with `Built …/Specter.app`.

Keep the whole `Specter.app` bundle together. Opening only its inner executable is not an installation.

## 4. Keep it in Applications

In Finder, choose **Go → Go to Folder** and enter the full path to your checkout’s `.build` folder, such as `~/Developer/Specter/.build`. Drag **Specter.app** into Applications. If replacing an earlier copy, quit Specter first and confirm Finder’s replacement prompt.

Open it from Applications, then use the Dock icon’s **Options → Keep in Dock**. Specter does not change your system defaults, login shell, or shell startup files.

## 5. Make it yours

Try a simple command in the new terminal:

```sh
printf 'Hello from Specter\n'
stty size
```

| Start here | Shortcut |
| --- | --- |
| Choose from 130 themes | ⇧⌘T |
| Open Settings for fonts, profiles, and shell settings | ⌘, |
| Open another tab | ⌘T |
| Split right / below | ⌘D / ⇧⌘D |
| Find any open session | ⇧⌘P |
| Read offline documentation | Help → Specter Handbook |

For twelve sessions, open six tabs and split each once, or open twelve tabs. Each pane runs its own shell. Read the [session guide](handbook.md#sessions) for layout and lifecycle details.

Try your usual editor, pager, SSH workflow, input method, and accessibility tools before making this preview your main terminal. See [current compatibility and limitations](compatibility.md).

## Update your copy

Save work and quit Specter. For an unmodified Git checkout:

```sh
git pull --ff-only && ./scripts/install.sh --replace
```

The installer builds and verifies the new app before replacing the installed copy. It keeps the previous app beside it as `Specter.backup.<date-time>.<process-id>.app`. After checking the new version, you may move the backup to the Trash. To roll back, quit Specter, move the new app aside, and rename the backup to `Specter.app`. If Git reports local changes or divergent history, preserve your edits and resolve them before updating; do not discard them just to install an update. ZIP users can download and extract a fresh source copy and run `./scripts/install.sh --replace` from that folder. There is no automatic updater yet.

To choose another installation folder, use the same destination for installation and updates:

```sh
./scripts/install.sh --destination /Applications
./scripts/install.sh --destination /Applications --replace
```

The directory must be writable by your user. Do not run the installer with `sudo`; use the default `~/Applications` when the shared Applications folder is not writable. Quit all running Specter copies before installing or updating.

## Troubleshooting

| What happened | What to do |
| --- | --- |
| `xcodebuild` requires Xcode or a tool is missing | Open Xcode, finish first-launch setup, and select it in Settings → Locations → Command Line Tools. |
| Metal compiler or toolchain is missing | Complete Xcode’s component installation. Read the error for any additional Metal toolchain component required by that Xcode version. |
| `scripts/build-app.sh` or `Package.swift` cannot be found | Change into the extracted or cloned Specter directory first. |
| Signing rejects a resource fork or Finder metadata | Move the source outside synced folders, or use the alternate output command below. |
| Installer reports an installation lock | Let the other installation finish. If an installer was interrupted and none is running, remove only the empty `.specter-install.lock` directory in the destination, then retry. |
| App opens but a profile cannot start a shell | In Settings, check the shell executable and starting directory. Empty fields use your login shell and home folder for new sessions. |
| A terminal application renders incorrectly | Check [compatibility](compatibility.md) and [open an issue](https://github.com/shellcat-com/Specter/issues/new/choose) with a small synthetic reproduction and your OS/toolchain versions. Omit private terminal contents. |
| macOS blocks a downloaded app | The prebuilt tester ZIP is not notarized; the source route builds locally. Verify the source and follow macOS’s displayed guidance. Do not disable system-wide protections. |

To package outside a synced checkout:

```sh
SPECTER_APP_OUTPUT=/private/tmp/Specter.app ./scripts/build-app.sh
open /private/tmp/Specter.app
```

Copy that complete bundle into Applications to keep it; temporary folders are not permanent installation locations.

## Uninstall

Quit Specter and move its application bundle to the Trash. Local profile preferences are separate from the app bundle. Your shell configuration, project files, and other terminals are not removed.

## Next steps

[Handbook](handbook.md) · [Themes](handbook.md#themes) · [Keyboard shortcuts](handbook.md#shortcuts) · [Report an issue](https://github.com/shellcat-com/Specter/issues/new/choose) · [Contribute](../CONTRIBUTING.md)
