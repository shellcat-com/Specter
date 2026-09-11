# Specter mascot studies

Twelve original pixel characters, now integrated into the native companion gallery and pickers. Each uses a 24 × 24 pixel canvas, three colors plus transparency, and twelve frames in each of three states: idle, working, and celebrate. Playback is eight frames per second. These replace the four earlier vector companions. The native default is Wisp; all twelve designs and all three decorative motions are available per profile.

The reference is the compact character-cell silhouette shown in [Anthropic's Claude Code issue #24926](https://github.com/anthropics/claude-code/issues/24926), reviewed September 10, 2026. The design principles are a recognizable silhouette, oversized eyes, very few colors, and movement that survives a monospaced grid. No Claude artwork, source code, names, or animation assets were imported. All sprite drawings and frame transformations are authored in `generate.py`.

| Character | Shape | Signature movement |
| --- | --- | --- |
| Wisp | Oversized ghost hood and ribbon tail | Tail flick |
| Moth | Wide moon-moth wings | Wing flutter |
| Kettle | Little teapot, lid and handle | Steam curls and lid taps |
| Mimic | Hinged prompt box with a shy face | Lid chomp |
| Orbit | One-eyed satellite and small moon | Moon orbit |
| Moss | Speckled mushroom with short feet | Cap wobble |
| Bytebat | Tall ears and scalloped wings | Cape flap |
| Cinder | Asymmetric flame and little boots | Flame dance |
| Jelly | Bell-shaped head and four tentacles | Tentacle ripple |
| Origami | Angular fox ears and a large tail | Brush swish |
| Imp | Horns and a crooked grin | Ear twitch |
| Rover | Binocular eyes and caterpillar tracks | Track crawl |

Wisp is the strongest brand direction for Specter. Bytebat is the most expressive alternative; Rover is the most clearly mechanical. This is a design judgment, not user-testing evidence.

## Review and terminal preview

The conversation gallery offers selection, all three states, and pause/play. It honors the browser's Reduce Motion preference, freezes when hidden, and uses the exact frames in the terminal catalog. `gallery.html` is the generated inline fragment; `gallery.template.html` is its editable source.

Run these commands from this worktree:

```sh
python3 scripts/preview-mascots.py --all --state working
python3 scripts/preview-mascots.py --mascot wisp --state idle --seconds 30
python3 scripts/preview-mascots.py --mascot bytebat --state celebrate
python3 scripts/preview-mascots.py --all --still
python3 scripts/preview-mascots.py --all --plain
```

The standalone terminal preview uses foreground/background true color and Unicode half blocks: 24 columns by 12 rows per character. It runs for 20 seconds by default, at most 300 seconds. Ctrl-C exits. The grid adapts to terminal size and pages every four seconds when necessary. Below 27 × 18 cells it asks for a larger window. Redirected output, `TERM=dumb`, and `--plain` produce static ASCII without cursor controls. Use `--still` for reduced motion; the CLI does not inspect system preferences.

This is an explicitly launched terminal program. It does not install startup banners, hooks, dependencies, or configuration. It does not read terminal contents, inspect processes, or run commands from its catalog. Working and celebrate are manual animation studies, not detection of a running or successful shell command.

## Source and regeneration

```sh
python3 design/mascots/generate.py
python3 design/mascots/build-gallery.py
python3 design/mascots/validate.py
```

`catalog.json` is versioned passive data. IDs are stable within this study. Tokens are `B` for body, `A` for detail, `o` for eyes, and `.` for transparency. All frames have equal dimensions, so changing poses cannot move neighboring terminal text. The gallery and ANSI renderer share this catalog; there is no separate browser-only animation.

## Native integration boundary

The selected design renders in the existing companion strip with pause, Off, per-profile persistence, inactive-window behavior, and macOS Reduce Motion support. The native gallery keeps the profile captured at opening. Animation stays outside the terminal grid and PTY data path. Busy and Celebrate are explicitly selected decorative motions, not inferred command status. Legacy Specter, Comet, Sprout, and Pixel values migrate to Wisp, Cinder, Moss, and Rover. See `docs/pixel-companion-validation.md` for native integration evidence.

The generator also writes `Sources/TerminalUI/Resources/Mascots.json`, packaged in `Specter_TerminalUI.bundle`. Native code validates its version, dimensions, frame counts, colors, and pixel alphabet before compiling paths.

## Original study evidence (before native integration)

Base revision: `8994993`; branch: `codex/mascot-lab`. Apple silicon, macOS 26.3.1 (a), build 25D771280a; Apple Swift 6.2.4. macOS 14 remains a target, not a tested hardware claim.

- `scripts/check.sh`: passed formatting, 33 tests in six suites, C static analysis, release app/helper build and local ad-hoc signing. The app was built, not runtime-tested for these studies.
- `swift run SpecterBench`: 20,000 synthetic lines in 1.5336 seconds, 0.7711 MiB/s in this debug run. This is a parser workload, not a mascot or GPU performance measurement.
- `swift run SpecterBench --fuzz 600`: completed 600 seconds and 82,754 mutation iterations, seed `0x53504543544552`, zero crashes.
- `python3 scripts/check-website.py`: passed static resources, links, shared palette schema, and contrast checks; the product website was not changed.
- `python3 design/mascots/validate.py`: 12 unique IDs, 432 frames, 24 × 24 bounds, allowed pixel tokens, and distinct animation frames in every character/state pair.
- A synthetic PTY exercised the ANSI preview for normal completion, SIGTERM, and SIGINT. Each emitted multiple frames, returned exit 0, and restored color, cursor visibility, and the alternate screen. These byte captures are not screenshots of the native app.
- Redirected output contains no ANSI controls; non-finite duration is rejected.
- PTY layout checks covered 27 × 18 and 108 × 48 cells. The status line and rendered frames stay within those bounds.
- Browser review: character selection, working/celebration states, pause preserving its frame, desktop layout, a 390-pixel viewport, and light/forced-dark previews. Reduce Motion is implemented but was not exercised by changing the user's macOS preference. No native app integration or automatic activity detection is claimed.

Raw logs and synthetic ANSI captures stay in `.artifacts/mascot-lab/`. Terminal appearance can vary with font, line spacing, true-color support, and the user's background. SIGKILL cannot run cleanup; normal completion and catchable termination are the tested restoration boundary.
