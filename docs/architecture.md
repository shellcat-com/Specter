# Architecture decisions

The engine owns parser, modes, grid and scrollback. A session serial queue owns PTY reads and engine mutation. Main-thread AppKit views receive coalesced immutable screen snapshots. Core Text shapes text into cell-constrained glyphs; Metal batches atlas-backed quads. No terminal bytes are discarded to improve frame rate.

A standalone C helper owns shell lifecycle. Swift uses posix_spawn to start it. The helper creates the PTY, forks before starting any threads, establishes the controlling terminal and executes the login shell. A private socket transfers the master descriptor and detects application death. The helper reaps its shell. Deliberately detached processes are outside terminal ownership.

Support target: macOS 14+, arm64. Local execution may use ad-hoc signing. No distribution signing or publication is authorized.

The current implementation includes the terminal engine, native tabs and splits, profiles and themes, independent companions, and optional metadata restoration. Next work centers on measured compatibility, accessibility, and performance expansion. AI, email, accounts, and cloud services are outside the terminal MVP.

## Implementation details

- The PTY bridge uses a close-on-exec Unix socket and SCM_RIGHTS to hand the master to Swift. The helper uses forkpty in a separate, single-threaded C process and a kqueue to watch shell exit/application lifetime. Normal control keys travel through the PTY line discipline.
- SnapshotMailbox limits main-thread backlog to one pending immutable snapshot. The session reads at most eight 32 KiB chunks per queue turn so input, resize and stop requests can run under output pressure.
- Unicode 17 grapheme and width tables are generated from official UCD files. The complete GraphemeBreakTest corpus is part of the deterministic suite. AppKit/Core Text supplies actual glyph coverage.
- Scrollback is a ring bounded by row count and accounted storage. The primary screen reflows soft-wrapped text; the alternate screen remains a cursor-addressable grid.
- Four 2048-pixel RGBA atlas pages cap GPU glyph texture storage at 64 MiB. In-flight command buffers retain textures across atlas resets. A persistent backing texture receives dirty-row updates, then is copied into each drawable. Explicit frame scheduling handles split resize and avoids an idle render loop.
- SwiftUI owns profiles and settings; AppKit owns windows, terminal interaction, selection, search controls and menus. Session metadata restoration is opt-in. No output or commands are persisted.

## Discovered regressions

Live top testing exposed incorrect G1 designation activating line drawing; separate G0/G1 designation and shift state fixed it, with a regression fixture. Split testing exposed stale drawable scaling; explicit backing-pixel sizing and frame scheduling fixed it. A shifted-pane hit-test regression now has a native view test.
