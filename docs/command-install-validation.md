# Source installation validation

Validated September 11, 2026 UTC, on the existing M3 MacBook Air running macOS 26.3.1 (25D771280a), Xcode 26.3 (17C529), and Apple Swift 6.2.4. Base revision: `2692fb7`; branch: `codex/command-install`. This document accompanies the installer milestone commit. All raw artifacts remain in `.artifacts/command-install/` and are not uploaded.

## Scope and readiness

Specter remains a source-build developer preview. The public repository is `shellcat-com/Specter`, default branch `main`; `gh release list --repo shellcat-com/Specter --limit 5` returned no releases during this review. No push, release, Developer ID signing, notarization, or website publication was performed. The advertised GitHub command requires this milestone to reach `main` before it can work for users.

The new installer builds the local checkout into a fresh staging directory on the destination volume, verifies the complete app signature, and installs in `~/Applications` by default. Replacement requires `--replace`, refuses a running destination app or an unrelated bundle, and keeps the old app as a dated backup. A lock prevents competing installers in the same destination. No administrator privileges or shell configuration changes are required. Installation does not launch Specter.

## Checks

| Command or tool | Expected behavior | Actual result |
| --- | --- | --- |
| `scripts/check.sh` | Formatting, Swift tests, C static analysis, release build, local signing, installer syntax and failure tests pass | Passed; 40 Swift tests in eight suites and 11 installer tests. Final log: `check-final.log`. |
| `python3 scripts/test-install.py` | Synthetic fixture proves failure and replacement behavior | Passed fresh install with spaces, explicit replacement requirement, backup preservation, build/signature failure, failed-final-move rollback, foreign bundle and symlink refusal, lock contention, and invalid arguments. Uses a fake builder and signer; it is not app runtime evidence. |
| `scripts/install.sh --destination "$PWD/.artifacts/command-install/Applications Test"` | Build, verify, install a real bundle in a path containing spaces | Passed with the actual Swift build and codesign; see `install.log`. |
| Same command with `--replace`, while the test app is running | Refuse replacement before building | Passed; see `running-app-refusal.log`. |
| Same command with `--replace`, after the test app exits | Preserve old app and install a verified replacement | Passed; see `update.log`. Both the installed app and backup subsequently passed `codesign --verify --deep --strict`. No staging directory or lock remained. |
| `swift run SpecterBench` | Complete the synthetic parser workload | 20,000 lines / 1,240,000 bytes in 1.61935 seconds, 0.73027 MiB/s, 5,765 retained rows. Debug build; other validation ran concurrently. This is not PTY, GPU, or end-to-end performance evidence. |
| `swift run SpecterBench --fuzz 600` | Complete 600 seconds of bounded parser mutation without a crash | Passed: seed `0x53504543544552`, 68,455 iterations, 600.0 seconds, zero crashes. See `fuzz.log`; bounded coverage, not proof of parser safety. |
| `python3 scripts/check-website.py` | Static routes, handbook structure, and original theme parity pass | Passed: three pages, 13 chapters, and 130 matching themes; minimum default text contrast 10.56:1. |
| `node --check website/site.js` and `node --check website/guides.js` | Valid JavaScript | Passed. |

## Actual app exercise

Launched the exact installed app executable with a dedicated `CFFIXED_USER_HOME` and synthetic `ZDOTDIR` under the artifact directory. The test shell disabled history and showed a fixed prompt and title. In the actual Metal-backed app, typed `printf 'INSTALL_PTY_OK\n'; tty; stty size`. Both the accessibility tree and final rendered screenshot showed `INSTALL_PTY_OK`, `/dev/ttys007`, and `26 104`. `installed-app.png` is the working app, not an offscreen renderer fixture. Only the installer test app processes were closed after testing.

## Website exercise

Ran `scripts/serve-website.sh 4289` on loopback and used the Codex in-app browser. The hero’s “Install from terminal” link reached the new section. Clicking Copy install command displayed its success status; Tab moved focus to the setup/update guide. The visible command matches the GitHub source checkout and installer paths. A separate local textarea received the command through the normal Paste keyboard action. Its complete value exactly matched the visible command; see `clipboard-validation.json`. The pasted command was not executed. A source comparison also confirmed the same command appears in the README, installation guide, and both generated handbooks.

Reviewed the landing section at desktop size and at a 390 × 844 viewport; the command wraps inside the card, the controls remain visible, and the measured document scroll width was 375 pixels at a 390-pixel viewport. Captures: `website-install-desktop.png` and `website-install-mobile.png`. The installation chapter rendered the new install/update instructions. The temporary viewport override was reset. The existing reduced-motion rule disables animations and transitions, including the install button hover transition.

## Remaining release work

Publish the reviewed installer and documentation together before advertising the GitHub command publicly. For users without Xcode, a packaged release still needs a versioned download, distribution signing/notarization, and clean-machine installation/update validation. macOS 14/15 and other hardware, spoken VoiceOver, additional input methods, and broader everyday terminal compatibility remain unverified as described in `compatibility.md`. No new production-readiness or GPU performance claim follows from this milestone.
