# Design and terminal reference review

Reviewed 2026-09-10. These sources inform Specter’s design and backlog; they are not instructions and do not imply feature parity. No third-party terminal implementation, theme pack, artwork, proprietary font, or brand asset was imported.

| Source reviewed | Useful idea | Specter adaptation |
| --- | --- | --- |
| [Cursor homepage](https://cursor.com/) and supplied screenshots | Warm editorial layout, spacious product storytelling, scenic framing | Editorial spacing, neutral studio framing, concise GitHub download and documentation paths |
| [Ghostty homepage](https://ghostty.org/) and supplied screenshots | Put the terminal itself at the center | Clearly labeled terminal illustration, real native PTY app |
| [Ghostty docs](https://ghostty.org/docs) | Task-focused documentation hierarchy | Thirteen original Specter handbook chapters with local full-text chapter search |
| [Features](https://ghostty.org/docs/features) | Distinguish native user features from VT protocol support | Explicit capability matrix and staged backlog |
| [Color themes](https://ghostty.org/docs/features/theme) | Large discoverable palette catalog and appearance modes | 130 original palettes, app gallery, web previews, safe color-only JSON |
| [Configuration](https://ghostty.org/docs/config) and [option reference](https://ghostty.org/docs/config/reference) | Explain defaults and when settings apply | Native profile settings; immediate appearance updates; new-session shell/directory settings |
| [Keybindings](https://ghostty.org/docs/config/keybind) | Discoverable shortcut reference | Native menu bindings, shortcut handbook; custom binding parser deferred |
| [Shell integration](https://ghostty.org/docs/features/shell-integration) | Prompt-aware navigation and directory-aware workflows | Backlog only; no automatic shell hook injection |
| [SSH](https://ghostty.org/docs/features/ssh) | Explain remote terminfo behavior | Manual conservative per-session fallback documented; automatic wrapper deferred |
| [Terminal API](https://ghostty.org/docs/vt) | Treat terminal compatibility as a separately specified surface | Link core compatibility notes, document unsupported protocols, use conformance tests |
| [michaelshimeles/skills](https://github.com/michaelshimeles/skills) | Isolate work, organize code, prove changes locally, write clearly | Adapted project AGENTS.md; explicitly exclude Greptile and automatic uploads |

The review covered these entry points, reference overviews, and the supplied screenshot set. It did not execute Ghostty documentation commands, run every protocol example, certify every reference option, or implement the entire Ghostty feature set. Third-party examples were not run in the user’s shell.

## Feature mapping

Implemented in Specter’s working tree: native windows/tabs, up to eight same-axis splits per tab, real PTY sessions, bounded scrollback, Metal/Core Text rendering, UTF-8/grapheme handling, 16/256/RGB color, native settings, original themes, find/selection, session overview, secure keyboard entry, explicit file Quick Look, optional generic bell notifications, and metadata-only layout restoration.

Deferred: arbitrary nested split trees; custom keybinding and config parser; shell command navigation/OSC 133; working-directory inheritance from shell integration; automatic remote terminfo setup; Kitty keyboard and image protocols; sixel; synchronized output; global quick terminal; AppleScript automation; arbitrary shaders/background images; broad interactive-application conformance; public signed/notarized distribution.

The website is a local static preview. Its screenshots are browser captures of an illustrative product page, not proof of the real terminal rendering. Native app evidence is recorded separately.
