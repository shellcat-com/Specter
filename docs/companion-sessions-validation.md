# Independent terminal companions

Validated September 11, 2026 UTC (September 10 locally), on Apple silicon, macOS 26.3.1 (a), build 25D771280a, Apple Swift 6.2.4. Base revision `95f915f`; branch `codex/companion-sessions`. The commit containing this record is the final source revision. macOS 14 is the deployment target, not a hardware-tested claim.

## Behavior

Every terminal owns an independent character, motion and animation setting, initialized from its profile. A direct Companions… button and Specter → Companions… (⇧⌘M) open the same visual gallery. The shortcut works when Off removes the strip. Split focus changes the strip’s target; an open gallery retains its original terminal. Settings edits defaults for future terminals. Optional window restoration saves each pane’s selection alongside layout metadata and starts fresh shells.

The website presents three independent character previews using the identical generated catalog. The README displays a generated static SVG catalog, explicitly labeled as an illustration. Neither is a screenshot of the native app.

## Automated checks

| Command | Actual result |
| --- | --- |
| `SPECTER_APP_OUTPUT=/private/tmp/specter-companion-sessions-final/Specter.app scripts/check.sh` | Passed strict formatting, 40 Swift tests in eight suites, C static analysis, release app/helper build, and local ad-hoc signing. |
| `swift run SpecterBench` | 20,000 synthetic lines, 1,240,000 bytes, 5.3293 seconds, 0.2219 MiB/s, 5,765 retained rows. Debug parser workload run concurrently with other validation; not a mascot or GPU benchmark. |
| `swift run SpecterBench --fuzz 600` | 76,268 iterations over 600 seconds, zero crashes, seed `0x53504543544552`. |
| `python3 design/mascots/validate.py` | Twelve unique characters, 432 bounded frames, static-output fallback, rejected invalid durations, and real PTY normal/SIGTERM/SIGINT cleanup passed. |
| `python3 scripts/check-website.py` | Static routes, resources, handbook links, twelve matching native/web/study characters, and all 130 matching app/web/download palettes passed. |
| `node scripts/export-handbook.mjs` | Regenerated the Markdown and self-contained app handbooks. |

The new tests exercise same-profile terminal independence, default changes, gallery ownership after focus/Off changes, persistence round trips, unknown-value migration and change notifications. Existing coverage includes twelve concurrent real PTYs and their lifecycle cleanup.

The ANSI signal check originally sent a signal after a fixed 0.3 seconds and failed its multiple-frame assertion under load. It now waits for two observed frames before signaling, retaining bounded execution and all cleanup assertions. The final default-path packaging attempt encountered iCloud-added Finder metadata during signing; rerunning the full check with the existing supported output override outside the synced directory passed.

Raw command logs remain local under `.artifacts/companion-sessions/`; ANSI validation artifacts are under `.artifacts/mascot-lab/`. No evidence is uploaded automatically.

## Native runtime observations

The release app was copied to an isolated preview bundle, `app.specter.companionsessions20260911`, and locally ad-hoc signed. Synthetic profiles launched an explicit `/bin/zsh -f` wrapper with an empty inherited environment and disposable HOME and ZDOTDIR. Existing personal terminal sessions and preferences were not used.

Computer Use observations verified:

- A direct gallery button and ⇧⌘M open all twelve native choices.
- Two real panes sharing one profile independently retained Moth and Jelly. Control–Tab restored each correct companion.
- Off disabled the gallery motion controls and removed the strip. After dismissing the gallery, ⇧⌘M reopened it and restored Jelly.
- Jelly’s animation could be paused without changing Moth.
- Another window retained Moss, and a new native tab initially used Wisp.
- Changing the profile default to Cinder left the four existing selections intact. A new window used Cinder.
- Session Overview listed five real sessions: Moth, Jelly, Moss, Wisp and Cinder, all sharing the same profile.
- Native-menu Quit ended the app process. Saved layout metadata contained the five corresponding selections, including Jelly’s disabled animation. Relaunch started fresh shells; the overview retained all five names.
- Explicitly launched ANSI previews ran Moth/Busy and Jelly/Celebrate simultaneously in the two real split PTYs. Accessibility output showed changing frames in both panes; a subsequent working-app screenshot visibly showed both colored characters side by side.

Native screenshot captures sometimes showed the preceding Metal frame immediately after a command. A later capture with the window raised displayed both running animations. The final Settings restoration-description wording was built after these functional observations; it does not alter session behavior.

## Browser observations and limits

The local website was exercised at its normal desktop width and a 390 × 844 viewport. All three selectors exposed twelve characters plus Off. Changing the first to Kettle and then Off left Moss and Rover unchanged. Busy/Celebrate and Pause/Resume controls worked. The compact layout stacked the cards without horizontal overflow; no browser console errors were reported. Native selects and buttons retain keyboard access. Reduced-motion and hidden/offscreen pause guards were inspected in code; no new system-wide Reduce Motion toggle was performed.

Native decoration still uses one strip per window/tab, following the focused split pane; it does not display every pane’s companion simultaneously above the split. The explicit ANSI demo can animate separate characters inside multiple panes. Busy and Celebrate are user-selected decoration, not process-status detection. Website previews do not configure the app, and no website deployment or signed public release is included.
