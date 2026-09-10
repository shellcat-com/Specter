# Website navigation and palette validation

Date: 2026-09-10. Base revision: `5e9a475`. Branch: `codex/website-download-guide`.

This change adds direct GitHub navigation, routes app Download actions to `docs/install.md` on GitHub, and replaces green website chrome and illustrations with neutral stone, charcoal, and blue. Theme files retain their original colors. No terminal engine or session code changed.

## Checks and actual results

| Command or tool | Expected | Actual |
| --- | --- | --- |
| `node scripts/export-handbook.mjs` | Both offline editions match the authored web handbook | Exported 13 chapters, including the new GitHub installation link and revised credits. |
| `python3 scripts/check-website.py` | Existing static routes, chapter links, resources, and palettes remain valid | Passed all three pages, 13 chapters, 130 unique matching app/web/download palettes; minimum default text contrast 10.56:1. |
| `scripts/check.sh` | Formatting, Swift tests, C analysis, release app build | Passed; 30 tests in six suites in 4.369 seconds. Release build completed in 44.21 seconds. These are local check durations, not performance benchmarks. |
| `codesign --verify --strict .build/Specter.app` | Valid local ad-hoc package | Passed. |
| `cmp Resources/Handbook.html .build/Specter.app/Contents/Resources/Handbook.html` | Latest neutral offline handbook bundled | Identical. |
| In-app browser, default desktop viewport and 390 × 844 | Header links remain visible, neutral styles render, mobile content fits | Inspected home and documentation screenshots. All three pages had no horizontal overflow on mobile. GitHub and Download remained visible. Documentation code blocks rendered charcoal. |
| Browser click on header GitHub | Open the intended public repository | Opened `https://github.com/shellcat-com/Specter` with the expected repository title. |
| Header/link inspection | Every app Download leads to the guide; theme downloads still lead to JSON | Verified the three page headers, hero and closing actions, and a theme download destination. Installation guide’s relative documentation targets exist. |
| Browser console | No new errors or warnings during the exercised routes | None observed. |

Environment: Apple silicon Mac, macOS 26.3.1, Apple Swift 6.2.4, Xcode toolchain. Work ran in an isolated local worktree outside synced Documents. Raw check output and desktop/mobile browser screenshots are under `.artifacts/website-refinement/` in that worktree and are not published.

This is a website and documentation change. Native terminal runtime workflows were not re-exercised; previous native evidence remains in `docs/design-validation.md`. The installation instructions were checked against the actual build script and a successful local build, but a clean-machine Xcode installation and every troubleshooting scenario were not exercised. The guide explicitly describes source distribution; no DMG, notarized release, or public website hosting was created.
