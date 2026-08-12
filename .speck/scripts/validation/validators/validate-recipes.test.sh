#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
VAL="$ROOT/.speck/scripts/validation/validators/validate-recipes.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash "$VAL" "$ROOT/.speck/recipes" >/dev/null

mkdir -p "$TMP/.speck/scripts/validation"
cp -R "$ROOT/.speck/recipes" "$TMP/.speck/recipes"
cp -R "$ROOT/.speck/scripts/validation/canaries" "$TMP/.speck/scripts/validation/canaries"

sed -i.bak '/^visual_testing:/,/^# Suggested epics:/ { /^# Suggested epics:/!d; }' \
  "$TMP/.speck/recipes/capacitor-wrapped-web/recipe.yaml"
# L11.8 — captures live under $TMP (mktemp -d, cleaned by the EXIT trap above), never at
# a fixed /tmp path. A fixed path leaks across runs (nothing ever removed it) and, on a
# shared/multi-user box, a foreign-owned leftover there makes THIS redirect fail with
# EACCES; `set -e` is suspended inside the `if` condition, so the mutant validator never
# runs, the `if` reads as "did not fail", and the grep below silently reads the STALE
# capture from a previous run instead — a false green with nothing to do with recipes.
MUTANT_OUT="$TMP/speck-recipes-mutant.out"
if bash "$VAL" "$TMP/.speck/recipes" >"$MUTANT_OUT" 2>&1; then
  echo "FAIL: a recipe without visual_testing.platform passed"
  exit 1
fi
grep -q "Missing top-level visual_testing.platform" "$MUTANT_OUT"

sed -i.bak 's/platform: web/platform: hologram/' \
  "$TMP/.speck/recipes/static-site/recipe.yaml"
HOST_MUTANT_OUT="$TMP/speck-recipes-host-mutant.out"
if bash "$VAL" "$TMP/.speck/recipes" >"$HOST_MUTANT_OUT" 2>&1; then
  echo "FAIL: a recipe with an unsupported visual host passed"
  exit 1
fi
grep -q "Unsupported visual_testing.platform 'hologram'" "$HOST_MUTANT_OUT"

echo "validate-recipes tests passed"
