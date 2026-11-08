#!/usr/bin/env bash
# Runs every repository check. CI and scripts/check.ps1 both call this file, so
# local results match CI. Run from the repository root; needs lua5.1, luacheck,
# and python3.
set -euo pipefail

addon=PallySealCooldowns

echo "== luacheck"
luacheck "$addon"

echo "== Lua tests"
for test in tests/*_test.lua; do
  echo "Running $test"
  lua5.1 "$test"
done

echo "== Python tests"
python3 -m unittest tests.test_export_diagnostics

echo "== TOC files"
grep -vE '^[[:space:]]*(#|$)' "$addon/$addon.toc" | tr -d '\r' |
  while read -r file; do
    if [ ! -f "$addon/$file" ]; then
      echo "::error::TOC lists a missing file: $file"
      exit 1
    fi
  done

echo "All checks passed."
