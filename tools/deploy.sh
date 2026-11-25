#!/bin/zsh
# Build and publish build/web to the gh-pages branch (GitHub Pages).
# Runs the full build (content validation, tests, secret scan) first.
set -euo pipefail
cd "$(dirname "$0")/.."
./tools/build.sh
STAGE=$(mktemp -d)
cp -R build/web/. "$STAGE/"
touch "$STAGE/.nojekyll"
./tools/secret_scan.sh "$STAGE"
REMOTE=$(git remote get-url origin)
cd "$STAGE"
git init -q -b gh-pages
git add -A
git commit -q -m "Deploy web build $(date +%Y-%m-%d\ %H:%M)"
git push -q -f "$REMOTE" gh-pages
rm -rf "$STAGE"
echo "deployed"
