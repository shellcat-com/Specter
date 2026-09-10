#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../website"
exec python3 -m http.server "${1:-4173}" --bind 127.0.0.1
