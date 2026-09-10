#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcrun swift-format lint --strict --recursive Sources Tests Package.swift
swift test -j 4
xcrun clang --analyze -Wall -Wextra -I Sources/PTYBridge/include Sources/PTYBridge/PTYBridge.c -o /dev/null
xcrun clang --analyze -Wall -Wextra Sources/PTYLauncher/main.c -o /dev/null
scripts/build-app.sh
