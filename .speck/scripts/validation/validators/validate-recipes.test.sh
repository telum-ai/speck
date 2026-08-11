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
if bash "$VAL" "$TMP/.speck/recipes" >/tmp/speck-recipes-mutant.out 2>&1; then
  echo "FAIL: a recipe without visual_testing.platform passed"
  exit 1
fi
grep -q "Missing top-level visual_testing.platform" /tmp/speck-recipes-mutant.out

sed -i.bak 's/platform: web/platform: hologram/' \
  "$TMP/.speck/recipes/static-site/recipe.yaml"
if bash "$VAL" "$TMP/.speck/recipes" >/tmp/speck-recipes-host-mutant.out 2>&1; then
  echo "FAIL: a recipe with an unsupported visual host passed"
  exit 1
fi
grep -q "Unsupported visual_testing.platform 'hologram'" /tmp/speck-recipes-host-mutant.out

echo "validate-recipes tests passed"
