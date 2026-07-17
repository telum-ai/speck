#!/usr/bin/env bash
# validate-gate-liveness.sh — gate WIRING check (issue #88, Phase 1).
#
# v8's thesis: verification-shaped evidence lies. One link the thesis didn't reach:
# nothing checks that the gates evidence-contract §6/§6a declares actually RUN. A gate
# that never runs is indistinguishable from a passing one — both leave every validator
# green, and the dark one manufactures a clean-looking evidence trail.
#
# This validator parses the §6a CI-Enforced Gate Registry and, for each gate, builds the
# set of stages it ACTUALLY fires on from the project's COMMITTED config (.pre-commit-
# config.yaml, .husky/, package.json, Speck's pre-commit-hook.sh, .github/workflows/*) —
# never from the ephemeral, untracked .git/hooks/*. Then it DIFFS the declared stage
# against that firing-set. All three real-world dark-gate bugs are one case: declared ∉ firing.
#   • declared pre-push, wired stages:[manual]      → GATE_WIRING_DRIFT.P1
#   • declared ci:push, workflow branches-ignore:main → CI_TRUNK_EXCLUDED.P1
#   • declared script, never referenced on commit path → SCRIPT_UNREFERENCED.P1
# Unrecognized hook/CI system → GATE_WIRING_UNVERIFIED (degrade-to-honest, never false-green/false-P1).
#
# Usage:  validate-gate-liveness.sh [--strict] <evidence-contract.md | project-dir>
# Exit:   0 = no P1 divergence (or none found), 1 = P1 divergence under --strict, 2 = invocation error.
#
# NOTE: this is the WIRING half (always-on, cheap). The LIVENESS/canary half (mutation
# probes) is Phase 2 (gate-liveness-probe.sh, opt-in).

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
strict=false
[[ "${1:-}" == "--strict" ]] && { strict=true; shift; }
target="${1:-}"
[[ -n "$target" ]] || { echo "ERROR: pass an evidence-contract.md or a project dir" >&2; exit 2; }
if [[ -d "$target" ]]; then
  CONTRACT="$(ls "$target"/evidence-contract.md 2>/dev/null || true)"
  [[ -z "$CONTRACT" ]] && CONTRACT="$target/evidence-contract.md"
else
  CONTRACT="$target"
fi
[[ -f "$CONTRACT" ]] || { echo "ERROR: evidence-contract.md not found at $CONTRACT" >&2; exit 2; }

# Project/repo root: walk up for .git or .speck.
ROOT="$(cd "$(dirname "$CONTRACT")" && pwd)"
while [[ "$ROOT" != "/" && ! -d "$ROOT/.git" && ! -d "$ROOT/.speck" ]]; do ROOT="$(dirname "$ROOT")"; done
DECISIONS="$(ls "$(dirname "$CONTRACT")"/project-decisions-log.md 2>/dev/null || true)"

PCC="$ROOT/.pre-commit-config.yaml"
HUSKY="$ROOT/.husky"
PKG="$ROOT/package.json"
SPECK_HOOK="$ROOT/.speck/scripts/validation/pre-commit-hook.sh"
WF_DIR="$ROOT/.github/workflows"

errors=0; warnings=0; agree=0
emit_p1() { echo -e "${RED}$1${NC}  $2" >&2; errors=$((errors + 1)); }
emit_p2() { echo -e "${YELLOW}$1${NC}  $2"; warnings=$((warnings + 1)); }
emit_note() { echo -e "${BLUE}$1${NC}  $2"; }

# --- §6a table extraction ---
rows="$(awk '
  /^### 6a\./ { ins=1; next }
  ins && /^#{2,3} / { ins=0 }
  ins && /^\|/ { print }
' "$CONTRACT" 2>/dev/null | grep -vE '^\|[- :]+\||Gate ID|REPLACE_BEFORE_SHIP' || true)"

if [[ -z "$rows" ]]; then
  echo -e "${YELLOW}GATE_WIRING.P3${NC}  no §6a CI-Enforced Gate Registry found — run seed-gate-registry.sh to generate it from the recipe. (A missing registry hard-blocks only at COMMERCIAL-RC/SHIP-RC.)"
  echo -e "${GREEN}Gate-liveness (wiring): no registry to check.${NC}"
  exit 0
fi

# gate command → a match signature (script basename, else the command string)
gate_sig() {
  local c="$1"; c="${c//\`/}"; c="$(printf '%s' "$c" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  case "$c" in
    */*.sh|*/*.py|*/*.js|*/*.ts) basename "$c" ;;
    *) printf '%s' "$c" ;;
  esac
}

# stages a .pre-commit-config.yaml hook matching sig fires at (space-separated); empty if unmatched.
precommit_stages() {
  local sig="$1"; [[ -f "$PCC" ]] || return 0
  awk -v sig="$sig" '
    function flush() {
      if (has) {
        st=stages; if (st=="") st="pre-commit"
        gsub(/[][,]/," ",st); print st
      }
      block=""; has=0; stages=""
    }
    /^[[:space:]]*-[[:space:]]*id:/ { flush() }
    { if (index($0,sig)>0) has=1
      if ($0 ~ /stages:/) { s=$0; sub(/.*stages:[[:space:]]*/,"",s); stages=s } }
    END { flush() }
  ' "$PCC" 2>/dev/null | tr '\n' ' '
}

# does husky / package.json / Speck hook reference sig on the commit path? echoes stage tokens.
other_commit_path_stages() {
  local sig="$1" out=""
  [[ -f "$HUSKY/pre-commit" ]] && grep -qF "$sig" "$HUSKY/pre-commit" 2>/dev/null && out="$out pre-commit"
  [[ -f "$HUSKY/pre-push" ]] && grep -qF "$sig" "$HUSKY/pre-push" 2>/dev/null && out="$out pre-push"
  [[ -f "$SPECK_HOOK" ]] && grep -qF "$sig" "$SPECK_HOOK" 2>/dev/null && out="$out pre-commit"
  [[ -f "$PKG" ]] && grep -qF "$sig" "$PKG" 2>/dev/null && out="$out pkg"
  printf '%s' "$out"
}

# trunk branch name
trunk() {
  local t; t="$(git -C "$ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
  [[ -z "$t" && -f "$ROOT/.speck/project.json" ]] && t="$(grep -oE '"default_branch"[[:space:]]*:[[:space:]]*"[^"]*"' "$ROOT/.speck/project.json" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)"
  [[ -z "$t" ]] && t="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
  [[ -z "$t" ]] && t="main"
  printf '%s' "$t"
}

# does a workflow run sig, and does it fire automatically on trunk? echoes: ok | trunk-excluded | manual-only | none
ci_status_for() {
  local sig="$1" tk; tk="$(trunk)"
  [[ -d "$WF_DIR" ]] || { echo none; return; }
  local found_any=none
  for wf in "$WF_DIR"/*.yml "$WF_DIR"/*.yaml; do
    [[ -f "$wf" ]] || continue
    grep -qF "$sig" "$wf" 2>/dev/null || continue
    # this workflow runs the gate; inspect its on: triggers (line-scan; degrade if unsure)
    local on_block; on_block="$(awk '/^on:/{ins=1;next} ins && /^[^[:space:]]/{ins=0} ins{print} /^on:.*\[/{print}' "$wf" 2>/dev/null || true)"
    local whole; whole="$(cat "$wf")"
    if printf '%s' "$whole" | grep -qE 'branches-ignore:'; then
      if printf '%s' "$whole" | grep -A3 'branches-ignore:' | grep -qE "(^|[^a-zA-Z0-9-])${tk}([^a-zA-Z0-9-]|$)"; then
        echo "trunk-excluded"; return
      fi
    fi
    if printf '%s' "$whole" | grep -qE '^on:\s*$|^on:\s*\[' && printf '%s' "$whole" | grep -qE '\bpush\b'; then
      # has push trigger; if push.branches restricts and trunk not listed → excluded
      if printf '%s' "$whole" | grep -qE 'branches:' && ! printf '%s' "$whole" | grep -A3 -E '^\s*branches:' | grep -qE "(^|[^a-zA-Z0-9-])${tk}([^a-zA-Z0-9-]|$)"; then
        found_any="trunk-excluded"; continue
      fi
      echo "ok"; return
    fi
    # only workflow_dispatch / schedule?
    if printf '%s' "$whole" | grep -qE 'workflow_dispatch|schedule' && ! printf '%s' "$whole" | grep -qE '\bpush\b|\bpull_request\b'; then
      found_any="manual-only"; continue
    fi
    # pull_request present → automatic on PRs (counts for ci:pull_request; for ci:push it's weaker)
    printf '%s' "$whole" | grep -qE '\bpull_request\b' && { echo "ok"; return; }
    echo "ok"; return
  done
  echo "$found_any"
}

echo -e "${BLUE}🔌 Gate-liveness (wiring) — contract: $CONTRACT${NC}"
echo "   trunk: $(trunk)"
echo ""

while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  gid=$(printf '%s' "$row"    | awk -F'|' '{print $2}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  cmd=$(printf '%s' "$row"    | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  stage=$(printf '%s' "$row"  | awk -F'|' '{print $4}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  waiver=$(printf '%s' "$row" | awk -F'|' '{print $7}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  [[ -z "$gid" || -z "$stage" ]] && continue
  sig="$(gate_sig "$cmd")"

  # Waiver: skip wiring, but the cited DEC must resolve.
  if printf '%s' "$waiver" | grep -qE 'waived[[:space:]]+DEC-[0-9]+'; then
    dec="$(printf '%s' "$waiver" | grep -oE 'DEC-[0-9]+')"
    if [[ -n "$DECISIONS" && -f "$DECISIONS" ]] && grep -qF "$dec" "$DECISIONS" 2>/dev/null; then
      emit_note "GATE_WAIVED" "$gid — $dec (wiring check skipped, DEC resolves)"
    else
      emit_p2 "GATE_WAIVER_UNBACKED.P2" "$gid — waiver cites $dec but it is not found in project-decisions-log.md"
    fi
    continue
  fi

  case "$stage" in
    manual)
      emit_note "GATE_MANUAL" "$gid — declared off the automatic path (no divergence to detect)" ;;
    pre-commit|pre-push|commit-msg)
      pcstages="$(precommit_stages "$sig")"
      others="$(other_commit_path_stages "$sig")"
      firing="$pcstages $others"
      if [[ -z "$(printf '%s' "$firing" | tr -d ' ')" ]]; then
        # not referenced anywhere on the commit path
        if [[ ! -f "$PCC" && ! -d "$HUSKY" && ! -f "$SPECK_HOOK" ]]; then
          emit_p2 "GATE_WIRING_UNVERIFIED.P2" "$gid — no recognized hook system (.pre-commit-config.yaml / .husky / Speck hook) to verify against"
        else
          emit_p1 "SCRIPT_UNREFERENCED.P1" "$gid — '$cmd' declared at $stage but is referenced by NO committed hook config (present-on-disk ≠ wired)"
        fi
      elif printf '%s' "$firing" | grep -qw "$stage"; then
        emit_note "GATE_OK" "$gid — $stage ✓ (firing: $(printf '%s' "$firing" | xargs))"; agree=$((agree + 1))
      elif printf '%s' "$firing" | grep -qw "manual" && ! printf '%s' "$firing" | grep -qw "$stage"; then
        emit_p1 "GATE_WIRING_DRIFT.P1" "$gid — §6a declares $stage but the matching hook runs stages:[manual] (declared ∉ firing-set)"
      else
        emit_p1 "GATE_WIRING_DRIFT.P1" "$gid — §6a declares $stage but firing-set is [$(printf '%s' "$firing" | xargs)]"
      fi ;;
    ci:push|ci:pull_request)
      st="$(ci_status_for "$sig")"
      case "$st" in
        ok) emit_note "GATE_OK" "$gid — $stage ✓"; agree=$((agree + 1)) ;;
        trunk-excluded) emit_p1 "CI_TRUNK_EXCLUDED.P1" "$gid — §6a declares $stage but the workflow running it excludes trunk '$(trunk)' (branches-ignore / branches) → fires on no trunk push" ;;
        manual-only) emit_p1 "GATE_WIRING_DRIFT.P1" "$gid — §6a declares $stage but the only workflow running it is workflow_dispatch/schedule (a manual escape hatch is not automatic enforcement)" ;;
        none)
          if [[ ! -d "$WF_DIR" ]]; then
            emit_p2 "GATE_WIRING_UNVERIFIED.P2" "$gid — no .github/workflows to verify a CI gate against (non-GitHub CI degrades to unverified, not failed)"
          else
            emit_p1 "SCRIPT_UNREFERENCED.P1" "$gid — §6a declares $stage but no workflow runs '$cmd'"
          fi ;;
      esac ;;
    *)
      emit_p2 "GATE_WIRING_DRIFT.P2" "$gid — unparseable stage '$stage' (must be pre-commit|pre-push|commit-msg|ci:push|ci:pull_request|manual)" ;;
  esac
done <<< "$rows"

echo ""
echo "Gate-liveness (wiring): ${agree} agree · ${errors} divergence(P1) · ${warnings} warning(s)"
if [[ "$errors" -gt 0 && "$strict" == true ]]; then
  echo -e "${RED}Gate-liveness FAILED: $errors gate(s) declared but not wired as claimed.${NC}" >&2
  exit 1
fi
echo -e "${GREEN}Gate-liveness (wiring) check complete.${NC}"
exit 0
