#!/bin/zsh
# Fails if anything that looks like a secret is in the given path(s) or in
# the staged git changes. Run before every commit and deploy.
set -uo pipefail
cd "$(dirname "$0")/.."
PATTERN='(sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[abp]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{35}|(api[_-]?key|secret|password|token)["'"'"' ]*[:=] *["'"'"'][^"'"'"' ]{8,})'
fail=0
# .env values (if any) must never appear anywhere.
if [[ -f .env ]]; then
  for v in $(grep -E '^[A-Za-z_]+=.{6,}' .env | cut -d= -f2-); do
    for p in "$@"; do
      if grep -rqF -- "$v" "$p" 2>/dev/null; then echo "SECRET from .env found in $p"; fail=1; fi
    done
    if git diff --cached | grep -qF -- "$v"; then echo "SECRET from .env in staged changes"; fail=1; fi
  done
fi
for p in "$@"; do
  # Binary files are scanned as text too (-a); the wasm is engine code.
  if grep -rEaIl -- "$PATTERN" "$p" 2>/dev/null | grep -v '\.wasm$'; then echo "possible secret in files above"; fail=1; fi
  if find "$p" -name ".env*" | grep -q .; then echo ".env file inside $p"; fail=1; fi
done
if git diff --cached --name-only | grep -E '(^|/)\.env($|\.)' | grep -v '.env.example'; then echo ".env staged"; fail=1; fi
if git diff --cached | grep -E -- "$PATTERN" | grep -q '^+'; then echo "possible secret in staged changes"; fail=1; fi
[[ $fail -eq 0 ]] && echo "secret scan: clean"
exit $fail
