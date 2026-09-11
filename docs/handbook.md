# Specter handbook

Generated from `website/guides.js` with `node scripts/export-handbook.mjs`.

- [Welcome to Specter](#overview)
- [Build & install](#install)
- [Tabs, splits & sessions](#sessions)
- [Themes & appearance](#themes)
- [Profiles & configuration](#profiles)
- [Keyboard & text](#shortcuts)
- [Restore a workspace](#restoration)
- [Compatibility & roadmap](#compatibility)
- [SSH & everyday use](#ssh)
- [Privacy & security](#privacy)
- [Troubleshooting](#troubleshooting)
- [Under the surface](#architecture)
- [Design & credits](#credits)

<a id="overview"></a>

## Welcome to Specter

### A place for your work.

Specter is a native macOS terminal for Apple silicon. It runs your shell through a real POSIX pseudoterminal, renders with Metal, and gives you 130 original themes, native tabs, split panes, and profiles.

> Specter is a developer preview. Its terminal implementation is still growing. Read the compatibility guide and try your everyday tools before making it your primary terminal.

#### Start with a working shell

Follow the [build guide](#install), launch Specter, and type a command. By default it starts your login shell in your home directory. Your shell handles its own startup files.

#### Make the space yours

- Press `⇧⌘T` to open the Theme Gallery.
- Press `⌘T` for a tab, or `⌘D` for a split.
- Press `⇧⌘P` to find any open session.
- Open Settings with `⌘,` to configure profiles, type, and appearance.

#### Read offline, too

Choose Help → Specter Handbook in the app to open the included handbook in your browser. It is self-contained and needs no network connection to read.

#### Read what matters next

[Organize sessions](#sessions) · [Choose a theme](#themes) · [Check compatibility](#compatibility)

---

<a id="install"></a>

## Build & install

### Up and running.

Build Specter locally on an Apple silicon Mac running macOS 14 or later, with Xcode and a Swift 6 toolchain. This preview does not offer a signed, notarized public download or an automatic updater.

[Download and installation guide on GitHub →](https://github.com/shellcat-com/Specter/blob/main/docs/install.md) — Xcode setup, source downloads, and troubleshooting.

#### Install from your terminal

After setting up Xcode and Metal tools, run this in your current terminal:

```sh
mkdir -p "$HOME/Developer" && git clone https://github.com/shellcat-com/Specter.git "$HOME/Developer/Specter" && "$HOME/Developer/Specter/scripts/install.sh"
```

This downloads source into `~/Developer/Specter`, builds locally, verifies the app signature, and installs in `~/Applications`. No administrator password is needed. If the source folder exists, run `./scripts/install.sh` from that checkout instead.

```sh
open "$HOME/Applications/Specter.app"
```

#### Update your copy

Save your work and quit Specter. From another terminal, update an unmodified checkout and reinstall:

```sh
cd ~/Developer/Specter
git pull --ff-only && ./scripts/install.sh --replace
```

The previous app is kept alongside the new one as a dated backup. To roll back, quit Specter, move the new app aside, and rename the backup to Specter.app. The installer never changes your shell configuration. Use `--destination /Applications` for a shared installation if that folder is writable by your user; use the same destination when updating.

#### Build without installing

```sh
scripts/build-app.sh
open .build/Specter.app
```

The bundle includes the PTY helper, Metal resources, themes, terminfo, and offline handbook. Signing is local and ad hoc.

#### Building in a synced folder

If signing reports a resource fork or Finder metadata error in an iCloud-synced checkout, package outside that folder:

```sh
SPECTER_APP_OUTPUT=/private/tmp/Specter.app scripts/build-app.sh
open /private/tmp/Specter.app
```

This changes only the output location. Signing remains local and ad hoc.

#### First launch

A fresh terminal opens using your login shell. Check basic input with:

```sh
printf 'Hello from Specter\n'
printf '\033[32mColor works\033[0m\n'
stty size
```

#### Validate the source

```sh
scripts/check.sh
swift run SpecterBench
swift run SpecterBench --fuzz 600
```

A passing build does not establish compatibility with every terminal application. The benchmark uses synthetic input and is not a comparison with other terminals.

---

<a id="sessions"></a>

## Tabs, splits & sessions

### Room for every moving part.

Each terminal pane owns an independent PTY and shell. Use more than ten simultaneous sessions across tabs and windows without squeezing them all into one view.

#### Open and arrange

| Action | Shortcut |
| --- | --- |
| New window | ⌘N |
| New tab | ⌘T |
| Split right | ⌘D |
| Split below | ⇧⌘D |
| Next pane | Control–Tab |
| Next / previous tab | ⇧⌘] / ⇧⌘[ |

There are up to eight panes per tab. Splits use one shared orientation within that tab: splitting below changes the group to a vertical stack, while splitting right arranges the group side by side. Nested split trees are not implemented.

#### Find a session

Open Window → Session Overview, or press `⇧⌘P`. Search by session number, profile, or window title, then select the session to focus it. The overview lists sessions when opened; reopen it to refresh the list.

#### A practical twelve-session workspace

Create six tabs and split each once, or create twelve tabs. Give separate profiles to your server, tests, and scratch work. Use the overview to jump directly to a pane. Resource use grows with scrollback, terminal size, and the programs you run.

#### Close with care

`⌘W` closes the active pane, or its tab/window when it is the last pane. Closing stops the owned shell session. Save work in editors before closing. Programs deliberately detached from the terminal are outside Specter’s lifecycle ownership.

---

<a id="themes"></a>

## Themes & appearance

### Find your atmosphere.

The 130-theme collection includes ten Specter originals and twenty color families with six treatments each: Midnight, Nocturne, Velvet, Dawn, Daylight, and Parchment. These are coordinated original variations, not imported community themes.

#### Browse and apply

Open Specter → Theme Gallery, or press `⇧⌘T`. Search by name, choose Light or Dark, or save favorites with the star button. Selecting a preview immediately applies its colors to the selected profile and that profile’s open terminals. The header names the profile being edited.

Use “Follow system appearance” to select Specter Night and Specter Day automatically as your Mac’s appearance changes. Individual light/dark pair customization is not implemented.

#### A companion for every terminal

Choose from twelve original pixel companions: Wisp, Moth, Kettle, Mimic, Orbit, Moss, Bytebat, Cinder, Jelly, Origami, Imp, and Rover. Wisp is the default. Click Companions… above the shell or press `⇧⌘M` to open the native visual gallery. The options menu beside it offers quick design, motion, and animation controls.

Each terminal keeps its own companion, even when several terminals use the same profile. Open another window (`⌘N`), tab (`⌘T`), or split (`⌘D`) and choose a different character. In a split, the single strip follows the pane you focus. The gallery stays attached to the terminal that opened it. Session Overview (`⇧⌘P`) includes each terminal’s companion name.

Choose Idle, Busy, or Celebrate motion. These are decorative choices, not shell command status. Settings → Companion defaults for new terminals sets the initial choice for future terminals using that profile; existing terminals keep their own choices. If window restoration is enabled, each pane’s companion, motion, and animation setting are restored with fresh shells.

Animation runs at eight updates per second outside shell output. Pause preserves the current pose; inactive terminal windows and hidden views stop playback, and macOS Reduce Motion uses a still pose. Off removes the strip. Press `⇧⌘M` or choose Specter → Companions… to bring it back. Existing Specter, Comet, Sprout, and Pixel defaults migrate to Wisp, Cinder, Moss, and Rover, preserving Off and the animation setting.

#### Open with a look

Shell → New Window with Theme and New Tab with Theme offer Basic (follow system), Dark, and Light choices across all 130 palettes and your custom themes. A theme choice creates a named profile with the default login shell, or reuses a matching named profile. Shell → New Window with Profile and New Tab with Profile launch your saved setups. The normal ⌘N and ⌘T shortcuts continue to use the profile selected in Settings.

#### Edit colors visually

In the Theme Gallery, select a palette and choose Customize current. Change the name, background, text, cursor, selection, or any of sixteen ANSI colors with native color pickers or hexadecimal fields. The preview and default-text contrast update while you edit. Save & Apply creates a new custom palette; Cancel discards the draft. Built-in palettes remain available. Custom colors are not automatically contrast-corrected: aim for at least 7:1 default text contrast and check ANSI colors separately.

#### Download, import, export

Use the [web theme browser](../website/themes.html) to preview a palette and download its JSON. In Settings → Appearance, choose Import theme. Built-in themes already exist in the app; importing the identical file selects that theme. Use Customize current for a visual editor, or export a theme, give it a new unique ID and name, edit its colors, and import the file.

Files are limited to 64 KiB. The schema requires version 1, an ID and name, background, foreground, cursor, selection, an isDark boolean, and exactly sixteen ANSI palette colors. Colors use six-digit `#RRGGBB` notation. A custom theme cannot replace a built-in ID with different colors.

#### Type and cursor

Settings lets you choose an installed font, a size from 8 to 40 points, programming ligatures, and a block, bar, or underline cursor. Font coverage and ligatures depend on your chosen font.

#### Readable by default

The included themes are checked for a minimum 7:1 contrast ratio between default text and background. ANSI colors, application-provided colors, and custom imports need separate contrast review. Reduced Motion disables the app’s cursor blink and website animation.

---

<a id="profiles"></a>

## Profiles & configuration

### A setup for each kind of work.

Open Settings with `⌘,`. Add a profile with the plus button, name it, and configure its shell, initial directory, type, cursor, theme, and scrollback.

#### What applies when

| Setting | Behavior |
| --- | --- |
| Theme, font, cursor | Updates matching open terminals. |
| Shell and working directory | Applies to new sessions. Existing processes keep running. |
| Scrollback | Used when a session is created; reopen the session to apply a new limit. |

Leave shell and directory blank to use your login shell and home directory. Provide a path to a shell executable, not a command with arguments. Profile settings are stored locally in the app’s preferences.

#### Know the limits

Scrollback is configurable from 1,000 to 100,000 rows per session. It is held in memory. Specter does not import Ghostty or iTerm configuration files, and does not edit your shell startup files. Keyboard shortcuts currently use the fixed native menu bindings.

---

<a id="shortcuts"></a>

## Keyboard & text

### Stay on the keyboard.

| Action | Shortcut |
| --- | --- |
| Settings | ⌘, |
| Theme Gallery | ⇧⌘T |
| Session Overview | ⇧⌘P |
| New window / tab | ⌘N / ⌘T |
| Split right / below | ⌘D / ⇧⌘D |
| Close pane | ⌘W |
| Copy / paste / select all | ⌘C / ⌘V / ⌘A |
| Find / find next | ⌘F / ⌘G |
| Next pane | Control–Tab |
| Next / previous tab | ⇧⌘] / ⇧⌘[ |
| Quit | ⌘Q |

#### Selection and mouse reporting

Drag to select text. Hold Shift while dragging when an application has enabled mouse reporting. Find searches retained scrollback; use Previous and Next to navigate matches. Your shell’s history remains a separate feature managed by the shell.

#### Paste

Pasting is an explicit user action. Multiline paste asks for confirmation. When the running application enables bracketed paste, Specter sends the corresponding bracketed input. Large input actions are bounded and rejected as a whole when the input queue cannot accept them.

#### Input methods

Specter uses the native text input client for marked-text composition. Font fallback and Unicode cell handling are covered by synthetic tests. Full bidirectional layout and every input-method workflow have not been certified.

---

<a id="restoration"></a>

## Restore a workspace

### Return to a familiar layout.

Enable “Reopen window layouts with fresh shells” in Settings. Restoration stores window geometry, tab grouping, split orientation, profile identifiers, and each pane’s companion choice, motion, and animation setting. It starts fresh shell processes on the next launch.

> Restoration does not resume running jobs or recover terminal output. It does not save commands, passwords, screen contents, or scrollback.

The current restoration limit is twelve window/tab records with up to eight panes each. New shells start in the profile’s configured directory. Shell-reported working directories and process trees are not restored. Close and save important work deliberately before quitting.

#### Turn it off

Disable restoration in Settings to start with a fresh window. Profile and theme preferences are retained separately.

---

<a id="compatibility"></a>

## Compatibility & roadmap

### Know what’s here.

Specter implements its own terminal core. Ghostty’s documentation is a useful reference, but it is not a promise of Specter feature parity.

| Area | Current Specter behavior |
| --- | --- |
| Platform | macOS 14+ target, Apple silicon. No Linux or Windows build. |
| Terminal basics | Cursor movement, erase, insert/delete, scroll regions, alternate screen, attributes, 16/256/RGB colors, application cursor keys and bracketed paste. |
| Text | UTF-8 decoding, Unicode grapheme handling, wide cells, reflow, Core Text fallback and optional ligatures. Full bidi layout is unsupported. |
| Native workspace | Windows, tabs, one-axis splits, session overview, profiles, search and selection. |
| Appearance | 130 original themes, favorites, visual palette editing, safe JSON import/export, system light/dark selection, and twelve optional animated pixel companions. |
| Shell integration | Real login shells; no automatic injection of prompt hooks, command navigation, or SSH wrappers. |
| Graphics protocols | Kitty image protocol, sixel and image escape sequences are not implemented. |
| Extended protocols | Kitty keyboard, synchronized-output mode, OSC 133 prompt navigation, and automatic appearance reports are not implemented. |
| Customization | Native settings; no Ghostty config compatibility, arbitrary shaders, terminal wallpapers, global quick terminal, or AppleScript dictionary. |
| Distribution | Local ad-hoc build; no public notarized release or auto-updater. |

#### Before making it your main terminal

Exercise your editor, pager, multiplexer, SSH host, shell prompt, keyboard layout, and accessibility workflow. Report a minimal synthetic reproduction when something fails. A working prompt does not establish complete compatibility with an interactive application.

#### Next priorities

- Broaden real application compatibility and accessibility evidence.
- Improve split layouts and session lifecycle controls.
- Add explicit, opt-in shell integration with documented boundaries.
- Evaluate modern keyboard and rendering protocols with conformance tests.
- Prepare signed distribution after release approval.

---

<a id="ssh"></a>

## SSH & everyday use

### Your usual command line.

Specter runs programs you start in the shell, including the system SSH client. It does not keep a host list, access credentials on its own, or automatically copy configuration to remote computers.

#### Remote terminal capabilities

Specter bundles a conservative terminfo entry for local programs. A remote host may not know that entry. If the remote program reports an unknown terminal, a conservative one-session fallback is:

```sh
TERM=xterm-256color ssh your-host
```

Replace `your-host` with a host you normally use. This tells remote programs to use the xterm-256color capability description; it does not establish complete xterm compatibility. Do not add a persistent override until you have checked your own tools.

#### Using Specter as your main terminal

Keep it in your Dock and open your day-to-day commands there. Specter does not silently change system defaults or your login shell. There is currently no built-in Finder “Open in Specter” service or default-terminal registration flow.

#### Move gradually

Start with a familiar project. Test editing, full-screen redraw, resizing, copy/paste, international text, and long-running jobs. Keep your current terminal available until those workflows meet your needs.

---

<a id="privacy"></a>

## Privacy & security

### Your terminal stays yours.

The terminal MVP has no accounts, cloud service, AI integration, email integration, telemetry, or automatic terminal-content logging. Programs you intentionally run can use the network according to their own behavior.

#### Untrusted output

Escape sequences are parsed as terminal input, never executed as shell commands. OSC clipboard access is disabled. URLs are not opened automatically. Theme files contain palette data, not commands or scripts.

#### Explicit actions

Copy and paste happen through user actions. Quick Look uses a file you select in an open panel. Secure Keyboard Entry can be enabled from the Specter menu. Background bell notifications are optional and use generic notification text.

#### Local settings

Profiles and themes are stored in preferences. Optional restoration stores layout metadata. Your login shell may read its own configuration and maintain its own history; that behavior belongs to the shell.

#### This website

The site uses local assets and scripts, has no analytics or account system, and makes no third-party requests. Theme downloads contain only static palette JSON. Search text is not sent to a server.

---

<a id="troubleshooting"></a>

## Troubleshooting

### Get back to work.

#### The shell won’t start

Check your profile’s shell and directory. Use an executable path such as `/bin/zsh`, not a command line. Confirm the directory exists. Build and launch the complete app bundle so the PTY helper is present. After correcting the profile, create a new session or use Restart shell.

#### Characters are missing or misaligned

Try Menlo or another installed monospace font with the needed glyphs. Check your font size and disable ligatures to narrow the issue. Include synthetic text, chosen font, app revision, and expected cell layout in a bug report.

#### A fullscreen program draws incorrectly

Try resizing once, then reduce the issue to a synthetic reproduction. Check the [unsupported protocols](#compatibility). Do not assume a graphics or extended keyboard protocol is available.

#### A theme file is rejected

Check the JSON schema, six-digit colors, sixteen palette entries, a unique ID, and the 64 KiB limit. A modified theme must use a new ID rather than a built-in ID. The web catalog’s unmodified files match the included themes.

#### Performance feels slow

Reduce scrollback or the number of active panes while diagnosing. Shell → Export Performance Report saves local renderer counters through a file picker. These counters are diagnostic data, not proof of GPU timing. Use Instruments for actual memory or GPU measurements.

---

<a id="architecture"></a>

## Under the surface

### Native from the inside out.

TerminalCore owns parser state, the grid, modes, and bounded scrollback. It is independent of UI and GPU frameworks. A serial session queue owns PTY reads and terminal mutation.

#### From bytes to pixels

A small C launcher creates the PTY, starts the login shell, and owns its lifecycle. Swift receives the master descriptor. Immutable screen snapshots cross to AppKit, Core Text shapes text, and Metal draws atlas-backed cells. Rendering can coalesce snapshots; PTY bytes are not dropped to catch up.

#### Boundaries that matter

Session input queues are bounded. Oversized input actions are rejected atomically. Terminal output is untrusted. UI effects require explicit handling, and clipboard or external navigation are not implicit escape-sequence effects.

#### Evidence over claims

The repository includes parser and Unicode tests, PTY lifecycle checks, Metal snapshot tests, and synthetic benchmarks. Offscreen snapshots are distinct from screenshots of the running app. Local evidence records the toolchain, commands, actual results, and limits of testing.

---

<a id="credits"></a>

## Design & credits

### Thoughtful references. Original work.

Specter’s website draws on the calm editorial spacing of [Cursor](https://cursor.com) and the product focus and documentation organization of [Ghostty](https://ghostty.org/docs). Neither company endorses Specter. Their trademarks, testimonials, product screenshots, and proprietary typefaces are not used as Specter assets.

The neutral studio backdrop, mark, orbital artwork, and theme collection are original Specter assets. An earlier generated dawn landscape is retained in the source archive but is no longer displayed. UI text uses system fonts.

The engineering workflow adapts module boundaries, local evidence, isolated work, and clear writing from the reviewed [michaelshimeles/skills](https://github.com/michaelshimeles/skills) repository. Greptile workflows and automatic uploads are excluded.

Specter source is MIT licensed. Unicode data retains the Unicode license in the repository. See DESIGN.md and the research notes for the design system and reference review.
