# Architecture decisions

The engine owns parser, modes, grid and scrollback. A session serial queue owns PTY reads and engine mutation. Main-thread AppKit views receive coalesced immutable screen snapshots. Core Text shapes text into cell-constrained glyphs; Metal batches atlas-backed quads. No terminal bytes are discarded to improve frame rate.

A standalone C helper owns shell lifecycle. Swift uses posix_spawn to start it. The helper creates the PTY, forks before starting any threads, establishes the controlling terminal and executes the login shell. A private socket transfers the master descriptor and detects application death. The helper reaps its shell. Deliberately detached processes are outside terminal ownership.

Support target: macOS 14+, arm64. Local execution may use ad-hoc signing. No distribution signing or publication is authorized.

The planned milestones are foundation, working terminal, native tabs/splits, profiles/themes, metadata restoration/integration, then measured compatibility/performance expansion. AI and email integrations are deferred.
