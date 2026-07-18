#!/usr/bin/env bash
# Validates Speck recipe.yaml files including extends: chain integrity.
#
# Usage: bash validate-recipes.sh [recipes_root]
# Exit 0 on success, 1 on failure.

set -euo pipefail

# Reuse the runtime probe's destructive classifier as the SINGLE SOURCE OF TRUTH so the recipe-time
# lint flags a canary-on-destructive exactly when gate-liveness-probe.sh would refuse to run it (#88).
CANARY_LIB="$(cd "$(dirname "$0")/.." && pwd)/canary-lib.sh"
# shellcheck disable=SC1090
[[ -f "$CANARY_LIB" ]] && . "$CANARY_LIB"

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

# Known canary vocabulary (#88 Phase 2) = the Speck-owned .canary library. A recipe may only
# reference a canary Speck ships (or `exempt:<reason>` / none).
CANARY_LIB_DIR="$(dirname "$RECIPES_ROOT")/scripts/validation/canaries"
KNOWN_CANARIES=""
if [[ -d "$CANARY_LIB_DIR" ]]; then
  for cf in "$CANARY_LIB_DIR"/*.canary; do
    [[ -f "$cf" ]] || continue
    KNOWN_CANARIES="$KNOWN_CANARIES $(basename "$cf" .canary)"
  done
fi

# Emit "command<TAB>canary" for each ci_gate in a recipe (awk over the ci_gates: block).
ci_gate_pairs() {
  awk '
    function val(line,   v){ v=line; sub(/^[^:]*:[[:space:]]*/,"",v); gsub(/^["'"'"' ]+|["'"'"' ]+$/,"",v); return v }
    function lead(s){ return match(s,/[^ ]/) ? match(s,/[^ ]/)-1 : 0 }
    function flush(){ if(id!=""){ printf "%s\t%s\n", command, canary } id="";command="";canary="" }
    /^[[:space:]]*ci_gates:[[:space:]]*$/ { ins=1; base=lead($0); next }
    ins && /^[[:space:]]*[a-zA-Z_]+:/ && $0 !~ /^[[:space:]]*-/ { if (lead($0) <= base) { flush(); ins=0 } }
    ins && /^[[:space:]]*-[[:space:]]*id:/ { flush(); id=val($0) }
    ins && /^[[:space:]]*command:/ { command=val($0) }
    ins && /^[[:space:]]*canary:/  { canary=val($0) }
    END { if (ins) flush() }
  ' "$1"
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

  # Canary vocabulary lint (#88 Phase 2): each ci_gate canary must be a known library key or
  # `exempt:<reason>`; a canary on a destructive-verb command is a recipe error (never probe a deploy).
  if grep -qE "^[[:space:]]*ci_gates:" "$recipe"; then
    while IFS="$(printf '\t')" read -r gcmd gcanary; do
      [[ -z "${gcanary:-}" || "$gcanary" == "—" || "$gcanary" == "-" ]] && continue
      case "$gcanary" in exempt:*) continue ;; esac
      if ! printf '%s' " $KNOWN_CANARIES " | grep -qF " $gcanary "; then
        echo "❌ Unknown canary '$gcanary' in $recipe (not in the .canary library:$KNOWN_CANARIES)"
        failed=1
      fi
      if command -v cl_looks_destructive >/dev/null 2>&1 && cl_looks_destructive "$gcmd"; then
        echo "❌ Canary '$gcanary' declared on a destructive command ('$gcmd') in $recipe — never probe a deploy/migrate gate; use 'exempt:<reason>'"
        failed=1
      fi
    done < <(ci_gate_pairs "$recipe")
  fi
done

if [[ $failed -eq 1 ]]; then
  echo "❌ Recipe validation failed"
  exit 1
fi

echo "✅ Recipes look structurally valid (extends: chains verified)"
exit 0
