# Theme, workspace and website validation

Date: 2026-09-10. Base: `f786150` (native terminal foundation); repository setup `4bd7321`. The feature revision is the commit that adds this record. Host: Apple silicon / arm64, macOS 26.3.1 (25D771280a), Apple Swift 6.2.4. Only this local machine was exercised.

## Automated checks

| Command / tool | Expected | Actual |
| --- | --- | --- |
| `SPECTER_APP_OUTPUT=/private/tmp/Specter-DesignRelease.app scripts/check.sh` | Format, Swift tests, C static analysis, release build and ad-hoc package pass | Passed; **30 tests in 6 suites**, including 12 concurrent PTYs |
| `python3 scripts/check-website.py` | App/web/download catalog parity, valid static links and resources, safe schema, readable default colors, self-contained offline handbook | Passed: **130** unique palettes; three website pages and thirteen chapters; minimum default text/background contrast **10.56:1** |
| `node --check website/site.js`, `website/docs.js`, `website/guides.js` | Valid JavaScript | Passed |
| `node scripts/export-handbook.mjs` | Produce the Markdown handbook and self-contained app handbook | Produced both editions |
| `swift run SpecterBench` | Run the synthetic parser benchmark | Completed: 1,240,000 bytes / 20,000 lines in 3.5016 s; 0.3377 MiB/s in a debug build on this busy host. This is not a release performance or comparative claim. |
| `codesign --verify --strict /private/tmp/Specter-DesignRelease.app` | Verify local ad-hoc signature | Passed |
| `xcodegen generate` | Include offline handbook in the Xcode project | Generated successfully; an additional Xcode build was not run for this feature revision |

The new PTY test opens twelve `/bin/sh` sessions before sending any commands, verifies all twelve helper processes are live, applies different sizes, checks execution-only markers and `stty size` in each session, verifies no cross-session output, and closes/reaps them. It is distinct from a sequential lifecycle test.

The unchanged terminal core already passed a 600-second parser mutation run at `f786150` (635,749 iterations, zero crashes), recorded in `docs/validation.md`. This feature work does not change the parser, PTY bridge, session implementation, glyph layout, or renderer. The extended fuzz run was not repeated for UI/theme/documentation changes.

## Native runtime

The release bundle was copied into a separate locally signed `app.specter.designpreview` bundle with an isolated preferences domain. Its profile launches a synthetic shell; no existing user terminal session or personal shell configuration was used for capture. A temporary test script used `/bin/zsh -f` with a minimal environment. The harness was moved outside the synced Documents directory for subsequent work.

Observed in the actual app:

- Theme Gallery loaded all 130 embedded themes.
- Searching Alpine and selecting Light produced three results.
- Applying Alpine Dawn selected the card; favoriting it and enabling Favorites produced one result.
- The selected theme and favorite survived a test-app relaunch.
- The final gallery’s Done action returned focus to the terminal. Auxiliary windows are excluded from automatic tab grouping.
- The Session Overview listed twelve live sessions across windows/tabs. Searching `12.1` isolated the twelfth session; selecting it focused the shell, which executed `printf 'SESSION_TWELVE_OK\n'` and produced the marker.
- A separate synthetic shell executed `SPECTER_RUNTIME_OK`.
- The native import panel opened and a generated JSON file was navigated to. File-picker automation did not reliably complete the final import action, so **end-to-end native import is not claimed as verified**. Data validation, catalog parity, and the browser download were verified separately.

The first synthetic shell script in the synced Documents directory did not reliably reach its prompt during the harness run; later synthetic windows and the twelfth session executed commands. This is recorded as a harness limitation, not a claim that every first-launch environment has been validated.

Public-safe, reviewed app captures:

- `docs/images/theme-gallery.png`: native SwiftUI gallery with synthetic preview cards.
- `docs/images/session-overview.png`: native session navigation listing twelve synthetic sessions.

## Browser runtime

Served with `scripts/serve-website.sh` on loopback port 4173, then exercised in the Codex browser using computer-use tools.

- Homepage loaded its original local landscape and terminal illustration.
- Selecting Alpine Dawn changed the hero’s selected theme and palette.
- Theme search plus Light filter produced three Alpine palettes; selecting a card updated the preview and URL.
- Pagination advanced from page 1 to page 2; an unmatched query showed zero results and disabled pagination.
- The final static JSON link emitted a browser download event. Its HTTP response matched the source palette byte-for-byte. An earlier blob-download approach timed out in the browser and was replaced by static downloadable files.
- Handbook navigation and full-text chapter search worked. Searching clipboard found two relevant chapters.
- Homepage, theme browser, and handbook were checked at a 390 × 844 viewport without horizontal overflow. The temporary viewport override was reset.
- No JavaScript errors were returned by the browser log check. Reduced-motion handling and visible focus styles were checked in the stylesheet; a full screen-reader or OS reduced-motion runtime audit was not performed.

The offline handbook has no scripts or external assets, includes all thirteen chapter anchors, and is embedded in the app. The Help action is compiled and points to that file; automatic opening in the system’s default browser was not separately exercised.

Raw evidence stays local under `.artifacts/expansion/`: check logs, benchmark output, browser screenshots, gallery/session captures, downloaded JSON, and the synthetic runtime harness.

## Build recovery and limits

The first combined SwiftPM build reported missing AppKit members in unchanged source after the shared bootstrap checkout build. `swift package clean` resolved it; subsequent compilation and all thirty tests passed without core source changes.

The synced Documents folder intermittently reattached Finder metadata between cleanup and signing. Packaging with the documented `SPECTER_APP_OUTPUT` override outside that folder succeeded and passed strict signature verification. The default output remains `.build/Specter.app` for ordinary checkouts.

The website terminal is an illustration, not a runtime capture. The app has 130 coordinated original palette variations, not 130 unrelated community imports. Native eight-pane same-axis split limits and twelve-record restoration limits remain documented. Full Ghostty protocol/configuration parity, Linux/Windows support, signed distribution, broad OS/application compatibility, and a full accessibility audit remain outside this preview’s verified scope.
