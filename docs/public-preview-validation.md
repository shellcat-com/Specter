# Public preview validation — September 11, 2026

Base `2692fb7`; source installer milestone `95a1b11` carried into isolated branch `codex/public-preview`. The original checkout and unrelated background tasks were preserved. This milestone changes website, distribution packaging, and documentation; the native application source is unchanged.

## Local checks

- `scripts/check.sh`: passed Swift formatting, 40 Swift tests in eight suites, C static analysis, release build, and 11 source-installer tests. Raw log: `.artifacts/public-preview/check.log`.
- `scripts/package-preview.sh`: rebuilt the release app with the updated offline handbook; packaged a prebuilt Apple silicon ZIP, installation note, MIT and Unicode licenses, and SHA-256 manifest.
- `codesign --verify --deep --strict .build/Specter.app`: passed. `codesign -dv` confirms ad-hoc signing and no TeamIdentifier. `spctl --assess --type execute` rejected the app, as expected for the unnotarized preview. No signing or system security setting was changed.
- `python3 scripts/check-website.py`: passed three pages, thirteen chapters, media paths and deliberate-playback requirement, 130 matching themes, and minimum default text contrast 10.56:1. JavaScript and packaging shell syntax checks passed.
- The final MP4 matches the reviewed fast edit byte-for-byte. Its metadata reports 74.7 seconds at 1600×900. See `website/assets/DEMO.md` for provenance and sound audition limits.
- Browser exercise on loopback: reviewed the desktop video poster/player and the download section at 390×844; scroll width was 375 pixels, without horizontal overflow. Copy install command displayed success. The browser clipboard API did not reflect the native clipboard, so this milestone does not claim a fresh end-to-end paste check; the unchanged copy handler has earlier paste evidence in `command-install-validation.md`.

## Limits

Native runtime evidence remains the actual source-installer and companion-session exercises documented in their validation reports (M3, macOS 26.3.1). This milestone does not establish clean-machine Gatekeeper installation, macOS 14/15 compatibility, notarization, or stable release readiness. Video generation is accelerated; external AI CLIs are not built into Specter.
