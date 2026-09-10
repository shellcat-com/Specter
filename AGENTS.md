# Specter engineering guide

Specter is a native macOS terminal emulator. Target macOS 14+ on Apple silicon with Swift 6, AppKit, SwiftUI, Core Text, Metal and POSIX PTYs. Keep TerminalCore independent of UI and GPU frameworks. C is limited to the PTY boundary and launcher.

## Working rules

- Use explicit inputs, structured errors, serial session ownership and bounded buffers. Never drop PTY bytes to catch up with rendering.
- Treat escape sequences as untrusted. Never execute them as commands. No OSC clipboard access, automatic URL opening, telemetry, terminal-content logging, or implicit history/file/credential access.
- No cloud services, accounts, AI or email integration in the terminal MVP.
- Use native controls and accessibility. Never substitute a fake command interface for a PTY.
- Work on a codex/ branch. This empty repository is bootstrapped in its current checkout; later independent work uses isolated worktrees based on an existing commit.
- Do not push, publish, create a release, notarize or use Developer ID signing without explicit approval. Local ad-hoc signing is authorized.
- Each coherent milestone ends with checks, actual app exercise where applicable, truthful local evidence, documented limitations, staged-diff review and one conventional commit.
- No Greptile workflows or automatic evidence uploads. Respect licenses before importing code, themes or assets.

## Checks

Run `scripts/check.sh` for formatting, Swift tests, C static analysis and release app build. Run `scripts/build-app.sh` to build the app and helper. Run `swift run SpecterBench` for synthetic benchmarks and `swift run SpecterBench --fuzz 600` for extended parser mutation tests. Use Instruments for memory and GPU investigation. Tests and captures must use synthetic content; don't record a user's existing terminal sessions.

## Evidence and documentation

Record command, toolchain, revision, expected behavior and actual result. A build is not a runtime test. An offscreen rendering snapshot is not a screenshot of a working app. Don't invent benchmarks or claim macOS versions tested without hardware evidence. Keep raw artifacts in `.artifacts/`; commit only reviewed public-safe documentation media. Document unsupported terminal sequences and restoration boundaries.

## Adapted guidance

Reviewed michaelshimeles/skills on 2026-09-09: code-structure informs module boundaries; evidence-driven-testing and before-and-after inform local proof; new-feature informs branch isolation; unslop informs clear prose. Its tests directory contains recorder tests, not a SKILL.md. Do not import its web-specific commands, public upload steps, automatic pushes or Greptile rules.
