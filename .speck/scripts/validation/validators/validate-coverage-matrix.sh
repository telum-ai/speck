#!/usr/bin/env bash
# validate-coverage-matrix.sh — breadth-coverage gate (issue #84).
#
# The runtime analog of validate-traceability-matrix.sh: every enumerated cell must resolve
# (RUN with real evidence / DEFERRED-BY-BUDGET / N-A) — a GAP (un-run, un-waived, in-universe)
# is a visible finding, and a RUN with no evidence is surrogate proof.
#
# Usage:  validate-coverage-matrix.sh [--strict] <coverage-matrix.md | dir>
# Exit:   0 = pass, 1 = unresolved coverage, 2 = invocation error.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
strict=false
[[ "${1:-}" == "--strict" ]] && { strict=true; shift; }
target="${1:-}"
[[ -n "$target" ]] || { echo "ERROR: pass a coverage-matrix.md or a dir containing one" >&2; exit 2; }
[[ -d "$target" ]] && target="$target/coverage-matrix.md"
[[ -f "$target" ]] || { echo "ERROR: coverage-matrix.md not found at $target" >&2; exit 2; }

content=$(cat "$target")
errors=0; warnings=0

if ! echo "$content" | grep -q "^artifact_type:[[:space:]]*coverage-matrix"; then
  echo -e "${RED}ERROR:${NC} not a coverage-matrix (missing 'artifact_type: coverage-matrix')" >&2
  exit 2
fi

# generator completeness
completeness=$(echo "$content" | grep -m1 '^generator_completeness:' | sed -E 's/.*:[[:space:]]*//' | tr -d '[] ' || true)
if [[ "$completeness" == "chain-partial" ]]; then
  if $strict; then
    echo -e "${RED}ERROR:${NC} generator_completeness is 'chain-partial' — the coverage universe is under-enumerated and cannot back a breadth claim. Fill the experience-chain screen table and regenerate." >&2
    ((errors++))
  else
    echo -e "${YELLOW}WARNING:${NC} generator_completeness: chain-partial (universe under-enumerated)"
    ((warnings++))
  fi
fi

# Parse the cell status grid: rows between "## Cell status grid" and "## Cross-cell".
#
# Columns resolve BY HEADER NAME, not by position. This file used to read `$10` and `$11`
# with the comment "Status = 9th data column (field 10)" — the identical shape that made the
# §6a Gate Registry unsafe to extend, where inserting one column silently re-mapped Canary to
# Waiver and the registry reported green having read the wrong cell. Adding a persona column
# here (v10.1 adds `second-actor` and `impatient`) shifts every field, so a positional read
# would have taken a persona verdict as the Status and reported a grid that parsed cleanly and
# meant nothing. The positional values survive only as a fallback for a grid whose header row
# cannot be recognised.
COL_STATUS=10; COL_EVIDENCE=11
_hdr="$(echo "$content" | awk '/^## Cell status grid/{ins=1;next} ins && /^## /{ins=0} ins && /^\|/{print; exit}')"
if [[ -n "$_hdr" ]]; then
  _i=0
  while IFS= read -r _cell; do
    _i=$((_i + 1))
    case "$(printf '%s' "$_cell" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')" in
      status*)   COL_STATUS=$_i ;;
      evidence*) COL_EVIDENCE=$_i ;;
    esac
  done < <(printf '%s' "$_hdr" | tr '|' '\n')
fi

gap_count=0; run_count=0; noevidence=0; badstatus=0; total=0
while IFS= read -r row; do
  status=$(printf '%s' "$row" | awk -F'|' -v c="$COL_STATUS" '{s=$c; gsub(/^[ \t]+|[ \t]+$/,"",s); print s}')
  evidence=$(printf '%s' "$row" | awk -F'|' -v c="$COL_EVIDENCE" '{e=$c; gsub(/^[ \t]+|[ \t]+$/,"",e); print e}')
  [[ -z "$status" ]] && continue
  ((total++))
  case "$status" in
    RUN)
      ((run_count++))
      if [[ -z "$evidence" || "$evidence" == "—" || "$evidence" == "-" ]]; then
        ((noevidence++))
      fi ;;
    GAP) ((gap_count++)) ;;
    DEFERRED-BY-BUDGET*|N-A*) ;;   # waived with a reason
    *) ((badstatus++)) ;;
  esac
done < <(echo "$content" | awk '/^## Cell status grid/{ins=1;next} ins && /^## /{ins=0} ins && /^\|/{print}' | grep -vE '^\|[- ]*Persona|^\|[-: ]+\|')

if [[ "$total" -eq 0 ]]; then
  echo -e "${YELLOW}WARNING:${NC} coverage grid has no cell rows"; ((warnings++))
fi
if [[ "$badstatus" -gt 0 ]]; then
  echo -e "${RED}ERROR:${NC} $badstatus cell(s) have an unrecognized Status (must be RUN | DEFERRED-BY-BUDGET | N-A | GAP)" >&2; ((errors++))
fi
if [[ "$noevidence" -gt 0 ]]; then
  echo -e "${RED}ERROR:${NC} $noevidence RUN cell(s) cite no evidence path (surrogate proof — a RUN must cite a real larp-recordings/… path)" >&2; ((errors++))
fi
if [[ "$gap_count" -gt 0 ]]; then
  if $strict; then
    echo -e "${RED}ERROR:${NC} $gap_count in-universe cell(s) are GAP (un-run, un-waived). Fill via /project-validate --exhaustive, or waive as DEFERRED-BY-BUDGET(reason)/N-A(reason)." >&2; ((errors++))
  else
    echo -e "${YELLOW}WARNING:${NC} $gap_count GAP cell(s) (visible breadth gaps — each a P3 finding)"; ((warnings++))
  fi
fi

echo "Coverage: ${run_count} RUN / ${total} cells · GAPs: ${gap_count} · completeness: ${completeness:-unknown}"

if [[ "$errors" -gt 0 && "$strict" == true ]]; then
  echo -e "${RED}Coverage-matrix validation FAILED ($errors error(s)).${NC}" >&2
  exit 1
fi
echo -e "${GREEN}Coverage-matrix validation passed${NC}${warnings:+ ($warnings warning(s))}."
exit 0
