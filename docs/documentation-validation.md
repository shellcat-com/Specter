# Documentation review evidence

Date: September 10, 2026 (America/Chicago; September 11 UTC). Base revision: `2692fb7`. The results below apply to the accompanying documentation review on `codex/documentation-review`; application source was unchanged.

Environment: Apple M3, arm64, macOS 26.3.1 (25D771280a), Xcode 26.3 (17C529), Swift 6.2.4, Node.js 25.8.1, Python 3.14.6. This is one local machine, not a macOS support matrix.

## What was reviewed

The README, installation guide, handbook, compatibility notes, architecture, security policy, contributor instructions, and issue forms were checked against the build scripts, native menus, preferences, session creation, restoration, theme imports, notifications, and PTY code. Historical validation and media records retain their revision-specific context.

The handbook now explains custom-theme selection after import, profile selection for new splits, independent companions, restoration limits, shell exit/restart, input troubleshooting, and reporting. A documentation index directs readers to the relevant guide. Generated Markdown has a consistent heading hierarchy, and offline HTML includes a skip link. The repository now includes a usage-question issue form; it has not been published to GitHub.

## Commands and results

Commands run from the isolated worktree root. Raw output is retained under `.artifacts/documentation-review/`.

| Command or check | Expected behavior | Actual result |
| --- | --- | --- |
| `scripts/check.sh` | Documentation validation, strict Swift formatting, Swift tests, C static analysis, and release app build succeed | Passed. Swift Testing reported 40 tests in 8 suites. The separate XCTest harness reported zero tests; the Swift Testing result is the relevant count. |
| `node scripts/export-handbook.mjs` followed by `node scripts/export-handbook.mjs --check` | Both generated editions exactly match the shared source | Passed for all 13 chapters. Rerun after the final prose and heading edits. |
| `python3 scripts/check-docs.py` | Local Markdown links resolve to existing files and anchors | Passed: 105 links in 19 documents. External URLs are deliberately not fetched. |
| `python3 scripts/check-website.py` | Website routes, chapter links, offline resources, and shared palettes validate | Passed: 3 pages, 13 chapters, 130 matching app/web/download palettes; minimum default text contrast 10.56:1. |
| Issue-template YAML parse | New question form and existing forms remain valid YAML | Passed using Ruby’s YAML parser; live GitHub rendering was not exercised. |
| Temporary stale-output and missing-anchor probes | Checks reject a stale generated handbook and a nonexistent Markdown fragment | Both rejected as expected. Temporary edits were restored and the probe file removed. |
| `scripts/build-app.sh` after final handbook export | The release app embeds the latest offline handbook | Passed; bundled HTML was byte-for-byte equal to `Resources/Handbook.html`. Local ad-hoc signing only. |
| `swift run SpecterBench` | Synthetic workload completes with bounded history | Passed: 1,240,000 bytes, 20,000 lines, 5,765 retained rows, 5.0633 seconds, 0.2336 MiB/s. Debug build on a shared busy host; not a GPU or comparative performance measurement. |
| `swift run SpecterBench --fuzz 600` | Run parser mutation checks for 600 seconds without a crash | Passed: `seed=0x53504543544552 iterations=91244 duration_seconds=600.0 crashes=0`. The time limit is checked between mutation cases, so wall time can exceed 600 seconds. |
| `git diff --check` and staged-diff review | No whitespace errors or unintended files | Reviewed before the milestone commit. Raw artifacts remain untracked. |

The combined check log predates the final Markdown heading cleanup and tool-version wording. Generated-content, link, website, and packaging checks were rerun after those edits; application code did not change.

## Browser exercise

Served the revised website with `scripts/serve-website.sh 4174`, bound to localhost. In the Codex in-app browser:

- Searching `Restart shell` returned the sessions and troubleshooting chapters. Selecting Troubleshooting opened the revised guide. An unmatched query reported zero matching chapters.
- All 13 chapter routes rendered their expected title and one main heading at a 390 × 844 viewport. None had horizontal document overflow.
- Inspected the troubleshooting page at 390 × 844 and 1440 × 1000. Captures are `docs-390.png` and `docs-1440.png` in the local artifacts directory.
- Keyboard traversal exposed a visible solid focus outline. The viewport override was reset after testing.

The native Help action opened the packaged handbook in the default Firefox browser. Its file URL pointed inside the isolated test bundle; the updated chapters and internal links appeared in the accessibility tree. A later attempt to open the same file directly in the in-app browser was blocked by its URL policy. No workaround was used. Offline responsiveness in that browser and a full spoken VoiceOver review were not established.

## Actual app exercise

Copied the release app into a temporary bundle with the isolated preferences domain `app.specter.documentationreview20260910`, then signed it ad hoc. A synthetic profile launched an explicit `/bin/zsh -f` wrapper with a minimal environment, disposable working directory and `ZDOTDIR`, and no history file. Existing Specter sessions and preferences were not used for the exercise.

1. Ran `printf 'DOCUMENTATION_RUNTIME_OK\n'; stty size` in a real terminal pane. The marker printed and the PTY reported `26 104`.
2. Used ⌘D to split; the second pane printed `SECOND_PANE_OK` independently.
3. Used ⇧⌘P; Session Overview listed two sessions under the synthetic profile, both with Wisp.
4. Used ⇧⌘M; the native gallery showed twelve characters and stated that its choice applies to this terminal only.
5. Chose Help → Specter Handbook; the default browser opened the bundled offline HTML.
6. Entered `exit` in the second pane; it showed “Shell exited with status 0” and Restart shell. Restart created a fresh shell, removed that pane’s old output, and printed `RESTART_OK`.
7. Closed the isolated app with ⌘Q after capturing synthetic runtime evidence.

`native-runtime.png`, `native-runtime.txt`, the wrapper, and the temporary runtime location are retained locally. These are live app observations, distinct from the suite’s offscreen Metal tests.

## Limits

This review does not certify every shell, editor, SSH host, input method, accessibility workflow, macOS version, or display configuration. It did not install a fresh Xcode, replace the user's installed app, change system settings, test remote terminfo installation, or measure GPU timings. External link availability and GitHub issue-form rendering were not network-verified. See [compatibility](compatibility.md) for unsupported sequences and restoration boundaries. No push, publication, notarization, distribution signing, or evidence upload was performed.
