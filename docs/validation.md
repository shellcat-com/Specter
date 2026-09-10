# Validation record

Recorded 2026-09-10 for the native-terminal implementation following foundation commit `5523bc2`. These are development baselines, not comparative performance claims.

## Environment

Apple M3 MacBook Air, 16 GB RAM, arm64, macOS 26.3.1; Xcode 26.3 and Swift 6.2.4. The deployment target is macOS 14, but macOS 14/15 runtime behavior has not been verified. Other tasks were running during measurements and system load was high, so throughput is not an uncontended hardware baseline.

## Automated checks

Run `./scripts/check.sh`: strict swift-format lint, Swift Testing, Clang static analysis for both C components, release compilation, app packaging and local ad-hoc signing. The core suite passes 28 tests across five suites, including:

- Fragmented VT/UTF-8 input, malformed sequences, cursor/state transitions, alternate screen, colors, title/URL/paste policy, wrapped search and selection.
- The official Unicode 17 grapheme-break corpus, wide cells and reflow.
- Real PTY startup, resize, exit, missing-helper failure and 100 repeated session lifecycles.
- Offscreen Metal rendering and dirty-row updates; native view hit testing and IME composition; profile migration.

The Xcode Release scheme also builds with:

```sh
xcodebuild -project Specter.xcodeproj -scheme Specter \
  -configuration Release -arch arm64 ONLY_ACTIVE_ARCH=YES \
  CONFIGURATION_BUILD_DIR=/private/tmp/specter-xcode-products \
  -derivedDataPath .build/Xcode build
```

Core validation uses an exported Git index to avoid mixing concurrent, unfinished theme-gallery work into this baseline. Raw logs remain local in `.artifacts/`.

## Parser and memory baseline

Build release, then run:

```sh
.build/release/SpecterBench
/usr/bin/time -l .build/release/SpecterBench --million
.build/release/SpecterBench --fuzz 600
```

| Synthetic workload | Result |
|---|---|
| 20,000 SGR text lines, 1,240,000 bytes | 0.474 seconds; 2.50 MiB/s |
| 1,000,000 SGR text lines, 62,000,000 bytes | 28.937 seconds; 2.04 MiB/s |
| Million-line maximum resident set | 72,318,976 bytes (68.97 MiB) |
| Million-line peak memory footprint | 66,843,648 bytes (63.75 MiB) |
| Retained rows after million-line run | 5,765, constrained by storage accounting |

These workloads exercise the parser and bounded screen/scrollback at 120 × 40 with a 10,000-row configured cap. They do not measure end-to-end PTY or GPU throughput. The storage cap can retain fewer rows than the row-count cap.

The Shell menu exports bounded local frame-encoding durations, input-event-to-presentation-callback samples, and glyph-atlas counters. These are diagnostic software measurements, not physical input-to-photon latency. End-to-end throughput, resize distributions and continuous-output frame distributions still need an isolated Instruments run before performance targets can be claimed.

The final deterministic mutation run used seed `0x53504543544552`, completed 635,749 iterations in 600 seconds and reported zero crashes. This is bounded fuzz coverage, not proof that every malformed stream is safe.

## Lifecycle and runtime evidence

Compile and run the application-death probe:

```sh
xcrun clang -dynamiclib -O2 -I Sources/PTYBridge/include \
  Sources/PTYBridge/PTYBridge.c -o .artifacts/libPTYProbe.dylib
python3 scripts/lifecycle-probe.py
```

The probe force-killed the application-side process with SIGKILL and verified both helper and shell disappeared within the five-second deadline. This does not promise cleanup of processes that deliberately detach from the terminal session.

Manual checks used synthetic content in the actual Metal-backed app:

- Login-shell commands, `tty`, resize, colors, CJK, combining marks and emoji.
- `vim -Nu NONE -n`: insert text, quit, recover primary screen.
- `top`: full-screen display, interrupt and recover primary screen.
- `seq 1 150 | less`: page forward and quit.
- Find text, native tabs, independent split PTYs, and native settings/theme changes.

The committed screenshots show the real application. The offscreen GPU test image remains a separate local artifact. Live testing found and fixed G1 charset designation, split drawable sizing, shifted-pane hit testing and packaged resource lookup defects. Xcode compiles the shader into `default.metallib`; SwiftPM packages shader source. The renderer supports both formats.

AppKit text accessibility and IME composition have automated coverage. Spoken VoiceOver, additional IMEs, notification delivery, external displays and older supported macOS versions still need hands-on validation. Full VT conformance is outside this bounded compatibility milestone; see [compatibility](compatibility.md).

## Local packaging environment

The synced Documents workspace reattaches Finder/file-provider metadata to app bundles after signing. The final Xcode build used an unsynced build-products directory; strict code-sign verification passed and the packaged app launched a real shell. For copied bundles, clearing generated extended attributes outside the synced directory also permits verification. This is a local ad-hoc development build; distribution signing and notarization were not performed.
