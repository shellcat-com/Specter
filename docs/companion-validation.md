# Companion and appearance validation

Validated September 10, 2026 (local Chicago time), from base revision `7e10410` on `codex/mascot-personalization`. The final source is the commit containing this record. Hardware: Apple silicon MacBook Air; macOS 26.3.1 (a), build 25D771280a; Apple Swift 6.2.4, Xcode toolchain. macOS 14 remains the deployment target, not a hardware-tested result for this milestone.

## Checks and results

| Command or exercise | Expected | Actual |
| --- | --- | --- |
| `scripts/check.sh` | Formatting, Swift tests, C static analysis, release app build and local ad-hoc signing pass | Passed; 33 tests in six suites. Includes legacy profile migration, all mascot settings round trips, unknown-design fallback, contrast validation, and stable dynamic menu entries. |
| `python3 scripts/generate-themes.py` | Shared catalog remains reproducible | Regenerated 130 palettes with no catalog changes. |
| `node scripts/export-handbook.mjs` and `python3 scripts/check-website.py` | Web/offline documentation and theme schema agree | Passed; 13 handbook chapters, 130 matching app/web/download palettes, minimum default text contrast 10.56:1. |
| `swift run SpecterBench` | Synthetic workload completes with bounded history | 1,240,000 bytes / 20,000 lines; 1.4845 seconds, 0.7966 MiB/s, 5,765 retained rows. Debug synthetic parser measurement, not GPU throughput or a terminal comparison. |
| `swift run SpecterBench --fuzz 600` | Ten minutes of parser mutations without invariant failure | 111,690 iterations, 600 seconds, zero crashes, seed `0x53504543544552`. |
| `scripts/serve-website.sh 4175` | Appearance handbook works locally | Browser checked at desktop and 390-pixel width; new companion, launch-menu, and editor instructions render. No website deployment. |

## Native runtime

Used a separate locally ad-hoc signed `app.specter.mascotvalidation` bundle and isolated preferences. Controlled profiles launched `/bin/zsh -f` with a minimal environment and a temporary home. Only synthetic text was captured. The original user screenshots were used as design references and are not redistributed.

Verified through native controls:

- Working shell input and colored output with the companion strip present.
- All four designs: Specter, Comet, Sprout, and Pixel. Settings and the strip menu update the chosen profile.
- Off removes the strip without shrinking the window. Re-enabling restores it. Off and a saved custom theme persisted through relaunch.
- Focus changes between split panes update the strip to the focused profile, including a profile with Off selected.
- New Window with Theme → Dusk opens a separate native window. New Tab with Theme → Porcelain joins the existing window. Saved-profile menu selection also opens the correct profile.
- Theme Gallery opens from the terminal strip and names its target profile. Search, favorite, appearance filter, and no-results feedback work with a saved custom palette.
- Customize current opens a private draft. Invalid hex input disables Save & Apply; valid background/name edits update the preview and contrast. Saving creates and applies a new uniquely identified custom theme, which remains available after relaunch. The final editor names and retains its target profile. Cancel was exercised on the final signed build and left the theme count unchanged.

Two runtime issues were found and fixed before committing: SwiftUI hosting size propagation could collapse the whole window when Off was selected; automatic native tabbing could turn New Window into a tab. Hosting now publishes only its intrinsic size, and new windows initially disable automatic grouping before explicit tab attachment when requested.

The automation moves app windows into the background when inspecting them, correctly pausing decorative animation. A temporary diagnostic build traced 295 timeline updates while active, with a median interval of 0.0416666 seconds (about 24 Hz), and activity transitions when hidden/inactive. All diagnostic logging was removed from the final source and the complete checks passed again. This is a scheduling observation, not a GPU presentation-rate measurement. Reduce Motion is handled by the SwiftUI accessibility environment; the global macOS setting was not changed during this test.

An Instruments Activity Monitor trace (`xcrun xctrace record --template 'Activity Monitor' --attach <test-pid> --time-limit 10s`) completed. The isolated app's sampled memory footprint was 180.78–180.81 MiB while mostly inactive, with multiple synthetic sessions open. This short sample does not establish a leak-free result or active-animation CPU/GPU performance.

Reviewed public-safe captures:

- [Pixel and a real light-theme terminal](images/companion-light.png).
- [Native color editor with a synthetic preview](images/theme-editor.png).

Raw traces, diagnostic observations, screenshots, test logs, and benchmark output stay ignored in `.artifacts/mascot/`. Raw Instruments metadata is not suitable for publication. No raw evidence was uploaded.

## Boundaries

The catalog already contained 130 original palettes; this milestone exposes them through launch menus and adds visual custom editing. It does not import TerminalColors palettes or Apple Terminal profiles. Native macOS chrome remains; Windows platform support, arbitrary window skins, wallpaper/transparency, a process inspector, and Apple Terminal configuration compatibility are not added. The companion lives above each window/tab's shell and follows focused split panes; it is not an escape-sequence banner or shell startup command.

Custom palette validation checks structure and hexadecimal colors; it does not enforce contrast. The editor displays default-text contrast and invalid-input feedback. Existing import/export boundaries, terminal sequence limitations, and fresh-shell-only restoration remain documented in the handbook and compatibility guide. A complete VoiceOver audit, live Reduce Motion toggle exercise, extended memory soak, and GPU profiling are not claimed.
