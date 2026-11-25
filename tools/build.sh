#!/bin/zsh
# Build the web/PWA version into build/web.
# Steps: validate content (bad entry fails the build) -> engine tests ->
# Godot web export -> secret scan of the output.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}

echo "== import"
$GODOT --headless --path . --import >/dev/null 2>&1 || true

echo "== validate content"
$GODOT --headless --path . -s res://tools/validate_content.gd

echo "== tests"
$GODOT --headless --path . -s res://tests/run_tests.gd 2>&1 | tee /dev/stderr | grep -q " 0 failures"

echo "== export"
rm -rf build/web && mkdir -p build/web
$GODOT --headless --path . --export-release "Web" build/web/index.html
test -f build/web/index.wasm || { echo "export failed"; exit 1; }

echo "== secret scan"
./tools/secret_scan.sh build/web

ls -la build/web
echo "build OK"
