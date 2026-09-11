# Twelve native pixel companions

Validated September 10, 2026, on Apple silicon, macOS 26.3.1 (a), build 25D771280a, Apple Swift 6.2.4. Base revision `2a8a6b2`, branch `codex/mascot-integration`. The final revision is the commit containing this record. macOS 14 is a deployment target, not a hardware-tested claim.

All twelve approved characters are native choices in the face menu, Settings, and a visual gallery. Wisp is the default. Idle, Busy, and Celebrate are explicit decorative motions, never inferred shell status. The gallery captures the target profile ID at opening.

The bounded JSON resource matches the study and ANSI demo. Native loading validates the version, dimensions, frame counts, colors and pixel alphabet before caching three paths per frame. Drawing stays outside the PTY and Metal terminal path on an eight-Hz SwiftUI timeline. The existing terminal activity state, animation toggle, view removal and Reduce Motion pause playback. Settings/gallery previews also observe native control-active state. Reduce Motion shows frame zero. A local clock preserves the pose across pauses without catching up.

Old Specter/Comet/Sprout/Pixel preferences migrate to Wisp/Cinder/Moss/Rover. Off and disabled animation remain unchanged. New theme-derived profiles inherit the selected companion and motion.

## Checks

| Command | Actual result |
| --- | --- |
| `scripts/check.sh` | Passed formatting, 37 Swift tests in seven suites, C static analysis, release app/helper build and local ad-hoc signing. |
| `swift run SpecterBench` | 20,000 synthetic lines, 1,240,000 bytes, 1.4687 seconds, 0.8052 MiB/s, 5,765 retained rows. Debug parser workload, not mascot/GPU performance. |
| `swift run SpecterBench --fuzz 600` | 118,021 iterations, 600 seconds, zero crashes, seed `0x53504543544552`. |
| `python3 design/mascots/generate.py` | Native resource generated from the approved source without sprite redesign. |
| `node scripts/export-handbook.mjs` | Regenerated Markdown and offline HTML handbooks. |
| `python3 scripts/check-website.py` | Passed static links/resources and all 130 matching app/web/download palettes. |
| `codesign --verify --strict <isolated-preview.app>` | Passed after removing copy-created extended attributes and locally ad-hoc signing the isolated bundle. |

New tests cover catalog completeness, migration, round trips, unknown-motion fallback, malformed/oversize catalogs, and clock pause/resume/wrap behavior.

## Actual native app

The release app was copied under bundle ID `app.specter.pixelvalidation20260910` with isolated preferences. Three demo profiles run an explicit wrapper that executes `/bin/zsh -f` with an empty inherited environment and synthetic HOME, ZDOTDIR, prompt and output. No existing user sessions or preferences were captured or changed.

Native UI observations verified:

- All twelve quick-picker entries, Off, and all three motions.
- Every gallery choice and its selected label/description.
- The selected sprite, including Rover with Busy and Wisp with Celebrate.
- Pause, Off disabling motion controls, and Off removing the strip without collapsing the terminal window. The gallery remains usable while Off.
- Opening the gallery from Settings while Off and restoring Wisp.
- Actual PTY input/output: `printf 'native mascot check: shell input works\\n'` produced the expected output in terminal accessibility content.
- Native-menu Quit and relaunch: PID changed from 72520 to 77199. Wisp, Celebrate and animation disabled persisted; the other two profiles retained their values.

The gallery was visually inspected in the running app. CUA captures did not reliably show Metal terminal text; later screenshots failed as the disk became nearly full. No new working-terminal screenshot or full visual text-rendering validation is claimed. The unchanged renderer passed automated tests, and shell I/O was verified through actual PTY-backed accessibility content.

## Evidence and limits

Raw build/test/benchmark/fuzz logs, isolated preferences, the synthetic shell, and its signed app remain in `.artifacts/mascot-integration/`. Reproducible study/debug/compiler caches were removed to recover space; sources, logs, and the release app were retained. The disk remained nearly full, limiting further captures.

A global macOS Reduce Motion toggle, a new split-profile-focus runtime exercise, VoiceOver audit, memory soak, and GPU/animation-rate measurement are not claimed. The standalone ANSI demo remains explicitly launched; the native companion never writes it into the shell. No uploads, pushes, notarization, or public release.
