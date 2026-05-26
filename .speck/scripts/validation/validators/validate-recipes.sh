#!/usr/bin/env bash
# Validates Speck recipe.yaml files including extends: chain integrity.
#
# Usage: bash validate-recipes.sh [recipes_root]
# Exit 0 on success, 1 on failure.

set -euo pipefail

RECIPES_ROOT="${1:-.speck/recipes}"

if [[ ! -d "$RECIPES_ROOT" ]]; then
  echo "❌ Missing recipes directory: $RECIPES_ROOT"
  exit 1
fi

shopt -s nullglob
recipes=("$RECIPES_ROOT"/*/recipe.yaml)

if [[ ${#recipes[@]} -eq 0 ]]; then
  echo "⚠️  No recipes found under $RECIPES_ROOT/*/recipe.yaml"
  exit 0
fi

failed=0
required_keys=(name display_name description version keywords stack)

get_yaml_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed -E "s/^${key}:[[:space:]]*//" | tr -d \"\'\" || true
}

recipe_exists() {
  local name="$1"
  [[ -f "$RECIPES_ROOT/$name/recipe.yaml" ]]
}

# Walk extends: chain; detect cycles and missing parents
validate_extends_chain() {
  local file="$1"
  local seen=""
  local current="$file"

  while true; do
    local parent_name
    parent_name=$(get_yaml_value "$current" "extends")
    [[ -z "$parent_name" ]] && return 0

    if echo "$seen" | grep -qF "|${parent_name}|"; then
      echo "❌ extends: cycle detected at $file (revisits '$parent_name')"
      return 1
    fi
    seen="${seen}|${parent_name}|"

    if ! recipe_exists "$parent_name"; then
      echo "❌ extends: parent recipe '$parent_name' not found (referenced from $file)"
      return 1
    fi

    current="$RECIPES_ROOT/$parent_name/recipe.yaml"
  done
}

echo "🍳 Validating Speck recipes (including extends: chains)..."

for recipe in "${recipes[@]}"; do
  echo "  Checking: $recipe"
  dir_name=$(basename "$(dirname "$recipe")")

  for key in "${required_keys[@]}"; do
    if [[ "$key" == "stack" ]] && grep -qE "^extends:" "$recipe"; then
      continue
    fi
    if ! grep -qE "^${key}:" "$recipe"; then
      echo "❌ Missing '${key}:' in $recipe"
      failed=1
    fi
  done

  recipe_name=$(get_yaml_value "$recipe" "name")
  if [[ -n "$recipe_name" && "$recipe_name" != "$dir_name" ]]; then
    echo "❌ Recipe name mismatch: directory='$dir_name' but name='$recipe_name'"
    failed=1
  fi

  if grep -qE "^extends:" "$recipe"; then
    if ! validate_extends_chain "$recipe"; then
      failed=1
    else
      parent=$(get_yaml_value "$recipe" "extends")
      echo "    ✓ extends: $parent (chain valid)"
    fi
  fi

  if grep -qE "^keywords:" "$recipe"; then
    if ! awk '
      BEGIN{in_keywords=0; ok=0}
      /^keywords:[[:space:]]*$/ {in_keywords=1; next}
      in_keywords==1 && /^[^[:space:]]/ {in_keywords=0}
      in_keywords==1 && /^[[:space:]]*-[[:space:]]+/ {ok=1}
      END{exit ok?0:1}
    ' "$recipe"; then
      echo "❌ keywords list is empty in $recipe"
      failed=1
    fi
  else
    echo "❌ Missing 'keywords:' top-level key in $recipe"
    failed=1
  fi
done

if [[ $failed -eq 1 ]]; then
  echo "❌ Recipe validation failed"
  exit 1
fi

echo "✅ Recipes look structurally valid (extends: chains verified)"
exit 0
