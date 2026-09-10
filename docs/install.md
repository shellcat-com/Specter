# Download and install Specter

**Your shell. Your colors. Your Mac.**

Specter is currently a **source-build developer preview** for Apple silicon. There is no ready-to-install DMG or notarized app download yet. The website’s Download button brings you here so you can get the source and build the app locally.

[Download source ZIP](https://github.com/shellcat-com/Specter/archive/refs/heads/main.zip) · [Browse the source](https://github.com/shellcat-com/Specter) · [Release page](https://github.com/shellcat-com/Specter/releases) · [Compatibility](compatibility.md)

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
git pull --ff-only
./scripts/build-app.sh
```

Then replace the installed app with the new `.build/Specter.app` in Finder. If Git reports local changes or divergent history, preserve your edits and resolve them before updating; do not discard them just to install an update. ZIP users can download and extract a fresh source copy, build it, and replace the installed app. There is no automatic updater yet.

## Troubleshooting

| What happened | What to do |
| --- | --- |
| `xcodebuild` requires Xcode or a tool is missing | Open Xcode, finish first-launch setup, and select it in Settings → Locations → Command Line Tools. |
| Metal compiler or toolchain is missing | Complete Xcode’s component installation. Read the error for any additional Metal toolchain component required by that Xcode version. |
| `scripts/build-app.sh` or `Package.swift` cannot be found | Change into the extracted or cloned Specter directory first. |
| Signing rejects a resource fork or Finder metadata | Move the source outside synced folders, or use the alternate output command below. |
| App opens but a profile cannot start a shell | In Settings, check the shell executable and starting directory. Empty fields use your login shell and home folder for new sessions. |
| A terminal application renders incorrectly | Check [compatibility](compatibility.md) and [open an issue](https://github.com/shellcat-com/Specter/issues/new/choose) with a small synthetic reproduction and your OS/toolchain versions. Omit private terminal contents. |
| macOS blocks a downloaded app | This guide builds locally; the project does not yet distribute a notarized installer. Verify the source and follow macOS’s displayed guidance. Do not disable system-wide protections. |

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
