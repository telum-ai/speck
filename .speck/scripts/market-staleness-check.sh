#!/usr/bin/env bash
# market-staleness-check.sh — competitive-claim / differentiator staleness detector (issue #80)
#
# Cheap, NO-web, age/stamp-based. Reads product-contract.md §3 (Differentiator),
# §3a (Anti-Differentiators) and §2a (Value Defensibility) FILLED values and the
# inline market-verified stamp, then flags claims that have gone stale — using a
# SPLIT CLOCK: absolute "no competitor does X" claims get a tight clock (they rot
# fast, e.g. Streb's went false in ~8 weeks); generic differentiators get a slower
# archetype cadence.
#
# It is the engagement-gap companion to speck-frontier-scan --product (the web scan
# that re-validates the claim and re-stamps). This script never touches the network.
#
# Usage:
#   .speck/scripts/market-staleness-check.sh [PROJECT_DIR]
#
# Output: emits zero or more TYPE.Pn lines (consumed by /recheck), e.g.
#   MARKET_DRIFT.P1  <detail>
#   MARKET_DRIFT.P2  <detail>
#
# Exit code:
#   0 = no market drift (or not applicable: no contract / market_scan disabled)
#   1 = at least one MARKET_DRIFT finding
#   3 = invocation error

set -euo pipefail

PROJECT_DIR="${1:-}"

# --- Locate the project dir (walk up from cwd; same idiom as staleness-check.sh) ---
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
if [[ ! "$PROJECT_DIR" = /* ]]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

CONTRACT="$PROJECT_DIR/product-contract.md"
# No contract (e.g. sprint level) → nothing to market-check.
if [[ ! -f "$CONTRACT" ]]; then
  exit 0
fi

# --- Find .speck/project.json (walk up) and read optional config ---
PROJECT_JSON=""
cur="$PROJECT_DIR"
while [[ "$cur" != "/" ]]; do
  if [[ -f "$cur/.speck/project.json" ]]; then
    PROJECT_JSON="$cur/.speck/project.json"
    break
  fi
  cur="$(dirname "$cur")"
done

read_json_int() { # key default
  local key="$1" default="$2" val=""
  if [[ -n "$PROJECT_JSON" ]]; then
    val=$(grep -oE "\"$key\"[[:space:]]*:[[:space:]]*[0-9]+" "$PROJECT_JSON" 2>/dev/null | grep -oE '[0-9]+' | tail -1 || true)
  fi
  echo "${val:-$default}"
}
read_json_str() { # key
  [[ -n "$PROJECT_JSON" ]] || { echo ""; return; }
  grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$PROJECT_JSON" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' | head -1 || true
}

# Opt-out: market_scan:false disables the class for claim-free internal tools.
if [[ -n "$PROJECT_JSON" ]] && grep -qE '"market_scan"[[:space:]]*:[[:space:]]*false' "$PROJECT_JSON" 2>/dev/null; then
  exit 0
fi

# Split clock. Absolute claims use a tight clock (below the observed rot half-life);
# generic differentiators use an archetype-tuned cadence.
ABS_DAYS=$(read_json_int market_absolute_claim_days 30)
ARCH=$(read_json_str project_archetype)
[[ -z "$ARCH" ]] && ARCH=$(read_json_str archetype)
case "$ARCH" in
  infra_service|backend_api) CADENCE_DEFAULT=90 ;;
  *)                          CADENCE_DEFAULT=45 ;;
esac
CADENCE_DAYS=$(read_json_int market_scan_cadence_days "$CADENCE_DEFAULT")
SOURCES_FLOOR=$(read_json_int market_sources_floor 3)

today_epoch=$(date +%s)
to_epoch() { # YYYY-MM-DD -> epoch (BSD/GNU compatible)
  local d="$1"
  if date -j -f "%Y-%m-%d" "$d" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$d" "+%s"
  else
    date -d "$d" "+%s"
  fi
}
age_days() { echo $(( (today_epoch - $(to_epoch "$1")) / 86400 )); }

# --- Extract FILLED claim values only (skip guidance/example/placeholder/scaffold) ---
extract_field() { # file "Bold Label"
  local file="$1" label="$2" line val
  line=$(grep -m1 -E "^\*\*$label\*\*:" "$file" 2>/dev/null || true)
  [[ -z "$line" ]] && { echo ""; return; }
  val="${line#*:}"
  val="$(printf '%s' "$val" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  # Unfilled scaffold → not yet a claim.
  case "$val" in
    *REPLACE_BEFORE_SHIP*|"") echo "" ;;
    *)                        echo "$val" ;;
  esac
}
extract_antidiff() { # filled "We are NOT ..." bullets (drop [thing N] template rows)
  grep -E "^- We are NOT " "$1" 2>/dev/null | grep -vE '\[thing [0-9]\]' || true
}
# §2a wedge: prefer product-contract §2a; fall back to legacy standalone value-defensibility.md.
extract_wedge() {
  local w
  w=$(extract_field "$CONTRACT" "Defensible-wedge verdict")
  if [[ -z "$w" && -f "$PROJECT_DIR/value-defensibility.md" ]]; then
    w=$(extract_field "$PROJECT_DIR/value-defensibility.md" "Defensible-wedge verdict")
    [[ -z "$w" ]] && w=$(grep -m1 -iE 'verdict' "$PROJECT_DIR/value-defensibility.md" 2>/dev/null | grep -viE 'REPLACE_BEFORE_SHIP' || true)
  fi
  echo "$w"
}

DIFF3=$(extract_field "$CONTRACT" "Core differentiator")
ANTIDIFF=$(extract_antidiff "$CONTRACT")
WEDGE=$(extract_wedge)

# Nothing filled in yet → a scaffold; other gates (REPLACE_BEFORE_SHIP) own it.
if [[ -z "$DIFF3" && -z "$ANTIDIFF" && -z "$WEDGE" ]]; then
  exit 0
fi

# Absolute / exclusivity claim = catastrophically falsifiable (the Streb class).
# Competitor-RELATIVE frames only — bare only/first/unique are excluded (they flood).
ABS_RE='no competitor|no[ -]one else|nobody else|unlike any(one| other)?|the only [a-z]+ that|first to [a-z]|no other [a-z]+ (offer|do|ship|have|provide)s?|only [a-z]+ that (offer|do|ship)s?'
HAS_ABSOLUTE=0
if printf '%s\n%s\n%s\n' "$DIFF3" "$ANTIDIFF" "$WEDGE" | grep -iqE "$ABS_RE"; then
  HAS_ABSOLUTE=1
fi

# --- Parse the inline market-verified stamp (may be absent / baseline / verified) ---
STAMP=$(grep -E '^\*\[market-verified' "$CONTRACT" | tail -n1 || true)

emit() { echo "$1  $2"; DRIFT=1; }
DRIFT=0

if [[ -z "$STAMP" ]]; then
  # Legacy / never-verified contract.
  if [[ "$HAS_ABSOLUTE" -eq 1 ]]; then
    emit "MARKET_DRIFT.P1" "absolute competitive claim in §3/§3a has never been market-verified — run /speck-frontier-scan --product"
  else
    emit "MARKET_DRIFT.P2" "differentiator has no market-verification stamp (unverified baseline) — schedule /speck-frontier-scan --product"
  fi
elif printf '%s' "$STAMP" | grep -qE 'market-verified:[[:space:]]*unverified'; then
  # Baseline stamp written at lock. P2 (scheduled), unless an absolute claim has
  # sat unverified past its tight clock — then it must not ship unproven.
  STAGED=$(printf '%s' "$STAMP" | sed -nE 's/.*staged ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p')
  if [[ "$HAS_ABSOLUTE" -eq 1 && -n "$STAGED" ]] && [[ $(age_days "$STAGED") -gt "$ABS_DAYS" ]]; then
    emit "MARKET_DRIFT.P1" "absolute claim staged unverified $(age_days "$STAGED")d ago (> ${ABS_DAYS}d) — verify before COMMERCIAL-RC / marketing copy"
  else
    emit "MARKET_DRIFT.P2" "differentiator market-verification is a provisional baseline (unverified) — run /speck-frontier-scan --product"
  fi
else
  # A real verified stamp: check verdict, phantom evidence, sources floor, and age.
  VDATE=$(printf '%s' "$STAMP" | sed -nE 's/.*market-verified ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p')
  VERDICT=$(printf '%s' "$STAMP" | sed -nE 's/.*verdict:[[:space:]]*([a-z]+).*/\1/p')
  SOURCES=$(printf '%s' "$STAMP" | sed -nE 's/.*sources:[[:space:]]*([0-9]+).*/\1/p')
  SCAN=$(printf '%s' "$STAMP" | sed -nE 's/.*scan:[[:space:]]*([A-Za-z0-9._-]+).*/\1/p')

  # Honest bad verdict forces the fix (evaluation over verification).
  if [[ "$VERDICT" == "eroded" || "$VERDICT" == "false" ]]; then
    emit "MARKET_DRIFT.P1" "last scan recorded verdict:${VERDICT} on the differentiator — reconcile §3 / run /project-adjust"
  fi
  # Phantom evidence: the cited scan report must actually exist.
  if [[ -n "$SCAN" && ! -f "$PROJECT_DIR/$SCAN" ]]; then
    emit "MARKET_DRIFT.P1" "market stamp cites scan '$SCAN' but that report is missing from the project (phantom evidence)"
  fi
  # Under-sourced fresh stamp → provisional.
  if [[ -n "$SOURCES" ]] && [[ "$SOURCES" -lt "$SOURCES_FLOOR" ]]; then
    emit "MARKET_DRIFT.P2" "market stamp cites only ${SOURCES} source(s) (floor ${SOURCES_FLOOR}) — treat as provisional"
  fi
  # Age against the split clock.
  if [[ -n "$VDATE" ]]; then
    A=$(age_days "$VDATE")
    if [[ "$HAS_ABSOLUTE" -eq 1 ]] && [[ "$A" -gt "$ABS_DAYS" ]]; then
      emit "MARKET_DRIFT.P1" "absolute competitive claim market-verified ${A}d ago (> ${ABS_DAYS}d tight clock) — re-scan before relying on it"
    elif [[ "$A" -gt "$CADENCE_DAYS" ]]; then
      emit "MARKET_DRIFT.P2" "differentiator market-verified ${A}d ago (> ${CADENCE_DAYS}d cadence) — re-scan on cadence"
    fi
  fi
fi

if [[ "$DRIFT" -eq 0 ]]; then
  echo "✅ MARKET_FRESH  differentiator/competitive claims within clock"
  exit 0
fi
exit 1
