#!/bin/bash
# Build a local ad-hoc tester ZIP; never signs with Developer ID or publishes.
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:-0.1.0-preview.1}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+-preview\.[0-9]+$ ]] || { echo 'Expected a version such as 0.1.0-preview.1' >&2; exit 1; }
OUTPUT="$PWD/.artifacts/releases/$VERSION"
[[ ! -e "$OUTPUT" ]] || { echo "Output already exists: $OUTPUT" >&2; exit 1; }
scripts/build-app.sh
codesign --verify --deep --strict .build/Specter.app
mkdir -p "$OUTPUT"
STAGE="$(mktemp -d "$OUTPUT/stage.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
ditto .build/Specter.app "$STAGE/Specter.app"
cp LICENSE docs/Unicode-LICENSE.txt "$STAGE/"
cat > "$STAGE/READ-ME.txt" <<'NOTE'
Specter developer preview — Apple silicon, macOS 14+ target.

Move the complete Specter.app into Applications and open it.
This app is ad-hoc signed, NOT Developer ID signed or Apple notarized.
macOS may block it. Only use this tester preview if you trust the source.
Installation and Apple security guidance:
https://github.com/shellcat-com/Specter/blob/main/docs/install.md

No Xcode, Specter account, or Specter server is required to run this app.
External network tools need their own connections. Updates are manual.
Runtime testing covers M3 / macOS 26.3.1; this is not a stable release.
Source and limitations: https://github.com/shellcat-com/Specter
NOTE
ZIP="Specter-$VERSION-arm64.zip"
ditto -c -k --sequesterRsrc "$STAGE" "$OUTPUT/$ZIP"
(cd "$OUTPUT" && shasum -a 256 "$ZIP" > SHA256SUMS.txt)
printf 'Packaged %s/%s\n' "$OUTPUT" "$ZIP"
