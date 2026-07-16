#!/bin/bash

# TASTE Axis Validator (issue #84)
# Validates validation-report.md / epic- / project-validation-report.md for FOUR-axis
# compliance — specifically the TASTE (aesthetic connoisseur) axis.
#
# TASTE is the 4th non-collapsible readiness axis (CORRECT / ON-CONTRACT / FELT-GOOD / TASTE).
# FELT-GOOD = "not broken / not confusing" (legibility). TASTE = "crafted / premium / it sings"
# (connoisseur craft). The AI evaluates TASTE directly via the connoisseur-hostile pass (Job C),
# DUAL-ANCHORED against (a) the product's declared aesthetic intent (product-contract §6b +
# design-system.md) and (b) universal craft (visual-quality skill).
#
# This validator enforces STRUCTURE + COVERAGE, not pixels (pixels are the SKILL's job, same
# division of labor as felt): TASTE must be COVERED for consumer UX-RC+, a forks-open claim must
# actually list forks, and a universal-only anchor cannot back a premium/crafted claim at ship.

set -euo pipefail

strict=false
if [[ "${1:-}" == "--strict" ]]; then
  strict=true
  shift
fi

file_path="${1:-}"

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  echo "Error: File path not specified or file does not exist." >&2
  exit 1
fi

content=$(cat "$file_path")

errors=0
warnings=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_error() {
  echo -e "${RED}ERROR:${NC} $1" >&2
  if [[ -n "${2:-}" ]]; then echo -e "${BLUE}Fix:${NC} $2" >&2; fi
  echo "" >&2
  ((errors++))
}
log_warning() {
  echo -e "${YELLOW}WARNING:${NC} $1" >&2
  if [[ -n "${2:-}" ]]; then echo -e "${BLUE}Suggestion:${NC} $2" >&2; fi
  echo "" >&2
  ((warnings++))
}
log_success() { echo -e "${GREEN}✓${NC} $1"; }

is_ux_rc_or_higher() {
  case "$1" in
    UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;
    *) return 1 ;;
  esac
}

# === VALIDATION RULES ===

# 1. Four-Axis block header exists (loose match — the exact axis list may evolve).
if echo "$content" | grep -qE "^## 🧭 .*Readiness \("; then
  log_success "Readiness axes header found"
else
  log_error "Missing the Readiness axes header (e.g. '## 🧭 Four-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD / TASTE)')" \
    "Add the Four-Axis Readiness section to your validation report."
fi

# 2. taste_axis frontmatter exists and is valid.
taste_axis=""
if echo "$content" | grep -q "^taste_axis:[[:space:]]*"; then
  taste_axis=$(echo "$content" | grep "^taste_axis:[[:space:]]*" | sed -E 's/taste_axis:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
  log_success "taste_axis frontmatter found: '$taste_axis'"
  case "$taste_axis" in
    uncovered|ai-critiqued|forks-open|human-verified) ;;
    *) log_error "Invalid taste_axis value: '$taste_axis'" \
        "taste_axis must be one of: 'uncovered', 'ai-critiqued', 'forks-open', or 'human-verified'." ;;
  esac
else
  log_error "Missing 'taste_axis' frontmatter field" \
    "Add 'taste_axis: [uncovered | ai-critiqued | forks-open | human-verified]' to the YAML frontmatter."
fi

# 3. taste_anchor frontmatter (anti-masquerade: a universal-only pass cannot pose as product-relative).
taste_anchor=""
if echo "$content" | grep -q "^taste_anchor:[[:space:]]*"; then
  taste_anchor=$(echo "$content" | grep "^taste_anchor:[[:space:]]*" | sed -E 's/taste_anchor:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
  case "$taste_anchor" in
    product+universal|universal-only) log_success "taste_anchor: '$taste_anchor'" ;;
    *) log_error "Invalid taste_anchor value: '$taste_anchor'" \
        "taste_anchor must be 'product+universal' or 'universal-only'." ;;
  esac
elif [[ "$taste_axis" != "uncovered" && -n "$taste_axis" ]]; then
  log_error "Missing 'taste_anchor' frontmatter field" \
    "A covered TASTE pass must declare 'taste_anchor: [product+universal | universal-only]'. universal-only means §6b/design-system was absent — run /project-design-system to earn the product-relative anchor."
fi

# 4. Detect archetype (walk up for project.json).
TARGET_DIR=$(dirname "$file_path")
project_archetype="consumer_product"
project_json=""
dir="$TARGET_DIR"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -f "${dir}/project.json" ]]; then project_json="${dir}/project.json"; break
  elif [[ -f "${dir}/.speck/project.json" ]]; then project_json="${dir}/.speck/project.json"; break; fi
  dir=$(dirname "$dir")
done
if [[ -f "$project_json" ]]; then
  archetype=$(grep -o '"project_archetype"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)
  [[ -n "$archetype" ]] && project_archetype="$archetype"
fi

# 5. Parse claimed readiness state.
claimed_state=""
if echo "$content" | grep -q "^readiness_state_claimed:[[:space:]]*"; then
  claimed_state=$(echo "$content" | grep "^readiness_state_claimed:[[:space:]]*" | sed -E 's/readiness_state_claimed:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
fi
if [[ -z "$claimed_state" ]]; then
  claimed_state_line=$(echo "$content" | grep -i "Claiming:" | head -n 1 || true)
  if [[ -n "$claimed_state_line" ]]; then
    claimed_state=$(echo "$claimed_state_line" | grep -oE '(NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN|UX-RC|API-RC|COMMERCIAL-RC|SHIP-RC|SHIP)' | head -n 1 || true)
  fi
fi

# 6. Consumer UX-RC+ enforcement.
if [[ "$project_archetype" == "consumer_product" && -n "$claimed_state" ]] && is_ux_rc_or_higher "$claimed_state"; then
  if [[ "$taste_axis" == "uncovered" ]]; then
    log_error "Consumer product claiming $claimed_state has an uncovered TASTE axis" \
      "Run the connoisseur-hostile pass (Job C) and record a verdict (taste_axis: ai-critiqued). TASTE is AI-evaluated and dual-anchored — do not leave it uncovered."
  elif [[ -n "$taste_axis" ]]; then
    log_success "TASTE axis is covered ($taste_axis) for $claimed_state"
  fi

  # forks-open must actually enumerate forks for the owner.
  if [[ "$taste_axis" == "forks-open" ]]; then
    if echo "$content" | grep -qE "^### .*Aesthetic Forks"; then
      forks_body=$(echo "$content" | awk '/^### .*Aesthetic Forks/{flag=1;next}/^#{1,3} /{flag=0}flag' || true)
      if echo "$forks_body" | grep -qE '\S'; then
        log_success "forks-open with a populated Aesthetic Forks section"
      else
        log_error "taste_axis is 'forks-open' but the Aesthetic Forks section is empty" \
          "List each open aesthetic fork (decision, Option A vs B, pixel reasoning, AI recommendation) — or set taste_axis to ai-critiqued if there are no open forks."
      fi
    else
      log_error "taste_axis is 'forks-open' but there is no 'Aesthetic Forks — Owner Decision' section" \
        "Add the '### 🎨 Aesthetic Forks — Owner Decision' subsection and list the forks."
    fi
  fi

  # A universal-only anchor cannot back a premium/crafted claim at the ship gates.
  if [[ "$taste_anchor" == "universal-only" ]] && { [[ "$claimed_state" == "SHIP-RC" ]] || [[ "$claimed_state" == "SHIP" ]] || [[ "$claimed_state" == "COMMERCIAL-RC" ]]; }; then
    log_error "Claiming $claimed_state with taste_anchor: universal-only" \
      "A universal-only TASTE pass judged craft without the product's declared aesthetic intent (§6b Aesthetic Contract / design-system.md missing). Author §6b and re-run so TASTE is product-relative before a premium ship claim."
  fi
fi

# 7. Flag an unqualified premium/beautiful/crafted claim not backed by a covered TASTE pass.
claim_section=$(echo "$content" | awk '/^## 🎯 Readiness State Claim/{flag=1;next}/^## /{flag=0}flag' || true)
if [[ -n "$claim_section" ]] && echo "$claim_section" | grep -qiE "premium|beautiful|crafted|polished|it sings|delightful"; then
  if [[ "$taste_axis" == "uncovered" || -z "$taste_axis" ]]; then
    log_error "Aesthetic claim ('premium/beautiful/crafted/...') in the Readiness State Claim with an uncovered TASTE axis" \
      "Back the claim with a covered connoisseur pass (taste_axis: ai-critiqued) or drop the aesthetic language."
  fi
fi

if [[ "$errors" -gt 0 ]]; then
  if [[ "$strict" == "true" ]]; then
    echo -e "${RED}Validation FAILED with $errors error(s).${NC}" >&2
    exit 1
  else
    echo -e "${YELLOW}Validation completed with $errors error(s) (ignored without --strict).${NC}"
  fi
fi

echo -e "${GREEN}Validation PASSED.${NC}"
exit 0
