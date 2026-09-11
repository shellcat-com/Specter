# Terminal compatibility

Specter 0.1 is a development implementation of a bounded VT100/xterm subset. Its bundled `specter` terminfo describes the base capabilities. It is not a claim of complete xterm, Ghostty or modern terminal-protocol compatibility. Remote machines need this terminfo installed to use TERM=specter; setting TERM=xterm-256color is an explicit compatibility workaround that may expose unsupported behavior.

| Area | Implemented |
|---|---|
| Text | Incremental UTF-8, malformed-byte replacement, Unicode 17 extended grapheme segmentation, CJK width, emoji clusters, Core Text fallback |
| Cursor | CUP/HVP, relative/absolute movement, save/restore, origin mode, delayed wrap, visibility |
| Screen | Erase, insert/delete characters and lines, scroll regions, reverse index, primary/alternate buffers, primary soft-wrap reflow |
| Attributes | Bold, faint, italic, underline, inverse, strikeout; ANSI, 256-color and RGB semicolon SGR |
| Input | IME composition, dead keys, control keys, navigation/function keys, application cursor mode, bracketed paste |
| Mouse | Press/release and drag reports, SGR encoding, wheel reports in SGR mode; Shift bypasses reporting for selection |
| Other | G0/G1 DEC line drawing, tabs, device/status replies, focus reports, sanitized titles and OSC 8 links |
| Native | Selection/copy/paste, case-insensitive search, tabs, uniform-axis splits, profiles, themes, explicit secure input, metadata restoration |

Known limits:

- Kitty keyboard protocol, full application-keypad encoding, synchronized output, sixel/Kitty/iTerm image protocols, OSC 133 shell integration, and complete DECRQSS/DECRQM reporting are not implemented.
- SGR colon subparameters and several uncommon DEC modes are unsupported. Device replies are deliberately conservative.
- Mouse motion without a pressed button is not emitted. Legacy mouse wheel encoding is not implemented; SGR wheel reporting is supported.
- Unicode width is Specter's documented policy, not a guarantee that every program's wcwidth tables agree. Ambiguous characters use one cell. The official Unicode 17 GraphemeBreakTest corpus passes; visual glyph availability depends on installed fonts and macOS.
- Programming ligatures cover common operator sequences in fonts that supply those ligatures. They do not change cell widths. General complex-script run shaping and bidirectional layout need broader visual conformance work.
- Alternate-screen resize uses grid semantics. Saved primary contents are normalized when returning from an alternate screen that was resized. This edge case needs broader editor regression coverage.
- Splits share one axis per tab; arbitrary nested split trees and saved divider ratios are not supported.
- Restoration preserves window frames, tab groups, split direction, profile identifiers, and each pane’s companion choice, motion, and animation setting. On launch it reads at most twelve window/tab records with eight panes each; it does not restore divider ratios. It starts new login shells using profile directories, not the last directory inferred from terminal output. No terminal output is saved.
- AppKit text accessibility, ranges, selection exposure and IME paths are implemented. End-to-end spoken VoiceOver review and additional input-method testing remain release gates.
- Runtime validation currently covers Apple M3 and macOS 26.3.1. macOS 14/15, other GPUs and external display configurations are unverified.

Resource limits: 1000×1000 cells; 10,000 history rows by default, capped additionally by 64 MiB of accounted row storage; 8 KiB control strings; 32 CSI parameters; 1 KiB grapheme payloads; 1 MiB pending input; four 2048×2048 RGBA atlas pages. Storage accounting is not a promise that total process RSS is 64 MiB.
