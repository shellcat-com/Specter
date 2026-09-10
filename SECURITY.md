# Security policy

Specter runs local shells with your user privileges. Shells execute commands you enter and their normal startup files. Specter does not sandbox those programs or read history, email, credentials or unrelated files itself.

Terminal output is untrusted. The parser bounds CSI fields, OSC/control strings and grapheme clusters. Screen allocation, scrollback, pending input and glyph atlases have explicit limits. Unknown escape sequences are ignored; unsupported control strings are discarded through their terminator. OSC 52 clipboard reads and writes are disabled. OSC 8 links permit only HTTP(S), reject credentials and controls, and require a deliberate click plus a destination confirmation. Window titles have controls and directional formatting removed.

Paste containing line breaks or controls prompts for confirmation. ESC and other command controls are removed, including embedded bracketed-paste terminators. Bracketed paste is used when the application requests it. This cannot determine whether a shell command is safe; review what you paste.

Secure Keyboard Entry is an explicit menu toggle. It is held only while the terminal is active and focused and released on deactivation, window focus loss and close. Specter cannot reliably identify arbitrary password prompts.

No terminal-content logs, telemetry, cloud connections or output persistence are enabled. In-memory performance counters contain timings and counts. Export is explicit. Background bell notifications are opt-in and contain no terminal output. Quick Look opens only a file selected in the native file picker.

The helper detects application-side socket closure, hangs up owned terminal process groups and reaps its shell. Processes that deliberately detach into another session are outside this lifecycle boundary. Restoration starts fresh shells; it never replays commands or restores process memory.

Report suspected vulnerabilities through [GitHub private vulnerability reporting](https://github.com/shellcat-com/Specter/security/advisories/new). Include a minimal synthetic byte fixture, expected behavior, observed behavior, OS version and revision. Do not include credentials, clipboard contents or real session transcripts. Do not publish sensitive reports in public issues.
