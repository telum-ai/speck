#!/usr/bin/env bash
# market-reconcile-check.sh — §2a (Value Defensibility) ↔ §3 (Differentiator) reconciliation (issue #80)
#
# The deepest, most defensible differentiation can live in §2a's defensible-wedge
# verdict while §3 still leads with a weaker / copyable one-liner. This trip-wire
# ensures the canonical §3 differentiator is never weaker than the project's own
# defensibility analysis. Observed live in Brightstance (§2a flagged §3 as
# thin/copyable; §3 was never updated).
#
# Cheap shell detector — the semantic "is §3 at least as defensible as the §2a
# wedge?" judgment is done by the auditor at the product-contract lock and in
# /recheck; this script surfaces the structural + self-flag + low-overlap cases.
#
# Usage:  .speck/scripts/market-reconcile-check.sh [PROJECT_DIR]
#
# Output: zero or more TYPE.Pn lines (consumed by /recheck):
#   WEDGE_DRIFT.P1  <detail>   (structural or self-flagged — blocks the contract stamp)
#   WEDGE_DRIFT.P2  <detail>   (low §3↔§2a overlap — hand to the auditor)
#
# Exit: 0 = reconciled (or n/a), 1 = at least one WEDGE_DRIFT, 3 = invocation error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
[[ -f "$SCRIPT_DIR/profile-lib.sh" ]] && source "$SCRIPT_DIR/profile-lib.sh"

PROJECT_DIR="${1:-}"
if [[ -z "$PROJECT_DIR" ]]; then
  cur="$(pwd)"
  while [[ "$cur" != "/" ]]; do
    if compgen -G "$cur/specs/projects/*/project.md" >/dev/null 2>&1; then
      PROJECT_DIR="$(echo "$cur"/specs/projects/*/ | head -n1)"
      break
    fi
    cur="$(dirname "$cur")"
  done
fi
if [[ -z "$PROJECT_DIR" ]] || [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Could not locate project directory. Pass it as \$1 or run from inside a Speck project." >&2
  exit 3
fi
PROJECT_DIR="${PROJECT_DIR%/}"
[[ "$PROJECT_DIR" = /* ]] || PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

CONTRACT="$PROJECT_DIR/product-contract.md"
[[ -f "$CONTRACT" ]] || exit 0

# --- FILLED-values-only extraction (skip guidance/example/scaffold) ---
extract_field() { # file "Bold Label"
  local file="$1" label="$2" line val
  line=$(grep -m1 -E "^\*\*$label\*\*:" "$file" 2>/dev/null || true)
  [[ -z "$line" ]] && { echo ""; return; }
  val="${line#*:}"
  val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  case "$val" in
    *REPLACE_BEFORE_SHIP*|"") echo "" ;;
    *)                        echo "$val" ;;
  esac
}

# §2a section body, filled lines only (drop italic guidance, comments, placeholders, scaffolds).
section2a_filled() {
  awk '
    /^### 2a\./ { ins=1; next }
    ins && (/^---[[:space:]]*$/ || /^## / || /^### 3/) { exit }
    ins { print }
  ' "$CONTRACT" 2>/dev/null \
    | grep -vE '^\*|^<!--|REPLACE_BEFORE_SHIP' \
    | grep -vE '\[[^]]*\]' || true
}

DIFF3=$(extract_field "$CONTRACT" "Core differentiator")

# Wedge value: §2a verdict, else legacy standalone value-defensibility.md.
WEDGE=$(extract_field "$CONTRACT" "Defensible-wedge verdict")
WEDGE_SOURCE="product-contract §2a"
if [[ -z "$WEDGE" && -f "$PROJECT_DIR/value-defensibility.md" ]]; then
  WEDGE=$(extract_field "$PROJECT_DIR/value-defensibility.md" "Defensible-wedge verdict")
  [[ -z "$WEDGE" ]] && WEDGE=$(grep -m1 -iE 'verdict' "$PROJECT_DIR/value-defensibility.md" 2>/dev/null | grep -viE 'REPLACE_BEFORE_SHIP' || true)
  WEDGE_SOURCE="value-defensibility.md"
fi

# Self-flag: the project's own defensibility text calling the differentiator weak.
# Scan the wedge verdict VALUE (its line starts with **, filtered from the body) plus
# the filled §2a body (table rows / prose).
SELF_FLAG_RE='thin|copyable|easily replicat|not (yet )?defensible|commoditi|undifferentiated|weaker than'
SELF_FLAG=$(printf '%s\n%s\n' "$WEDGE" "$(section2a_filled)" | grep -iE "$SELF_FLAG_RE" | head -1 || true)

DRIFT=0
emit() { echo "$1  $2"; DRIFT=1; }

# Nothing filled → scaffold; REPLACE_BEFORE_SHIP gate owns it.
if [[ -z "$DIFF3" && -z "$WEDGE" && -z "$SELF_FLAG" ]]; then
  exit 0
fi

if [[ -n "$WEDGE" && -z "$DIFF3" ]]; then
  emit "WEDGE_DRIFT.P1" "a defensible wedge is stated in $WEDGE_SOURCE but §3 Core differentiator is empty/placeholder — promote the wedge into §3"
elif [[ -n "$SELF_FLAG" ]]; then
  emit "WEDGE_DRIFT.P1" "the project's own defensibility analysis flags §3 as weak: \"$(printf '%s' "$SELF_FLAG" | sed -E 's/^[[:space:]]+//' | cut -c1-100)\" — reconcile §3 with $WEDGE_SOURCE"
elif [[ -n "$DIFF3" && -n "$WEDGE" ]]; then
  if declare -f profile_token_overlap_pct >/dev/null 2>&1; then
    OVERLAP=$(profile_token_overlap_pct "$DIFF3" "$WEDGE")
    if [[ "$OVERLAP" -lt 25 ]]; then
      emit "WEDGE_DRIFT.P2" "§3 differentiator and $WEDGE_SOURCE wedge share only ${OVERLAP}% tokens — they may name different wedges; auditor should confirm §3 ≥ the wedge"
    fi
  fi
fi

if [[ "$DRIFT" -eq 0 ]]; then
  echo "✅ WEDGE_RECONCILED  §3 differentiator is consistent with the defensible wedge"
  exit 0
fi
exit 1
