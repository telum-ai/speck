#!/usr/bin/env bash
# gate-liveness-probe.sh — gate LIVENESS (mutation/canary) probe (issue #88, Phase 2).
#
# Phase 1 (validate-gate-liveness.sh) proves a gate is WIRED (reachable at its declared stage).
# Phase 2 proves it is LOAD-BEARING: for each §6a gate that carries a canary token, inject a
# deliberate defect in the domain the gate owns, run the gate, and assert it goes RED for the RIGHT
# reason. "A guardrail you haven't watched fail is a guardrail you're assuming." (#88)
#
# The whole probe runs inside a throwaway git worktree — the real tree ($ROOT) is NEVER the write
# surface, so a mid-run kill leaks a worktree, never a defect in real source (INVARIANT-ZERO).
#
# Three outcomes per gate (the fail-closed tension, resolved):
#   • GATE_LIVE                     — baseline green, defect injected, gate went red naming the defect.
#   • GATE_DISARMED.P1              — defect injected IN the gate's required scope, gate STILL green
#                                     (or red for an unrelated reason). The one positive block.
#   • GATE_LIVENESS_UNVERIFIED.P2  — couldn't apply/attribute the canary (unknown key, no green
#                                     baseline, unsafe-to-probe, no local invocation, infra-bound,
#                                     red-unattributable). Degrade-to-honest — never P1, never green.
# Fail-closed on SAFETY (refuse to run a destructive gate) and on CLAIMS (UNVERIFIED caps the ship
# claim); degrade-to-honest on APPLICABILITY. Only an attributed disarmed-green is a positive block.
#
# Usage:  gate-liveness-probe.sh [--strict] [--require-liveness] <evidence-contract.md | project-dir>
# Exit:   0 = no DISARMED gate (or none probeable), 1 = DISARMED under --strict, 2 = invocation error,
#         3 = probe-integrity failure ($ROOT was mutated — should be impossible; loud, never green).
#
# Opt-in + lazy (v8 SHRINK ethos): mutation runs are too slow for a push. Runs at /epic-validate,
# /project-validate, on-demand at /audit — NEVER in the always-on /recheck shell or on pre-commit.
#
# Portable bash 3.2 / macOS. No associative arrays, no mapfile.

set -uo pipefail   # NOT -e: gate runs are expected to exit non-zero; we manage rc explicitly.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

LIB="$(cd "$(dirname "$0")/.." && pwd)/canary-lib.sh"
[[ -f "$LIB" ]] || { echo "ERROR: canary-lib.sh not found at $LIB" >&2; exit 2; }
# shellcheck disable=SC1090
. "$LIB"

strict=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=true; shift ;;
    --require-liveness) shift ;;   # recognized alias; invoking the probe IS the opt-in
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) TARGET="${TARGET:-}"; [[ -z "$TARGET" ]] && TARGET="$1"; shift ;;
  esac
done
TARGET="${TARGET:-}"
[[ -n "$TARGET" ]] || { echo "ERROR: pass an evidence-contract.md or a project dir" >&2; exit 2; }

if [[ -d "$TARGET" ]]; then CONTRACT="$TARGET/evidence-contract.md"; else CONTRACT="$TARGET"; fi
[[ -f "$CONTRACT" ]] || { echo "ERROR: evidence-contract.md not found at $CONTRACT" >&2; exit 2; }
PROJECT_DIR="$(cd "$(dirname "$CONTRACT")" && pwd)"

# Repo root: walk up for .git.
ROOT="$PROJECT_DIR"
while [[ "$ROOT" != "/" && ! -d "$ROOT/.git" ]]; do ROOT="$(dirname "$ROOT")"; done
[[ -d "$ROOT/.git" ]] || { echo "ERROR: not inside a git repo (needed for worktree isolation)" >&2; exit 2; }

CANARY_DIR="$(cd "$(dirname "$0")/.." && pwd)/canaries"
PCC="$ROOT/.pre-commit-config.yaml"

# --- §6a row extraction + gate_sig (verbatim from Phase 1 for coherence) --------------------------
rows="$(awk '
  /^### 6a\./ { ins=1; next }
  ins && /^#{2,3} / { ins=0 }
  ins && /^\|/ { print }
' "$CONTRACT" 2>/dev/null | grep -vE '^\|[- :]+\||Gate ID|REPLACE_BEFORE_SHIP' || true)"

if [[ -z "$rows" ]]; then
  echo -e "${YELLOW}GATE_LIVENESS.P3${NC}  no §6a CI-Enforced Gate Registry found — nothing to probe."
  exit 0
fi

gate_sig() {
  local c="$1"; c="${c//\`/}"; c="$(printf '%s' "$c" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  case "$c" in
    */*.sh|*/*.py|*/*.js|*/*.ts) basename "$c" ;;
    *) printf '%s' "$c" ;;
  esac
}

# Resolve the exact committed invocation for a gate (graft: probe the gate that SHIPS, not bare cmd).
# 1) a .pre-commit-config.yaml hook whose id/entry matches the sig → its `entry:` (full argv, --staged…)
# 2) else the §6a command if it names a script that exists in the worktree → run as-is
# 3) else empty (→ no-local-invocation)
resolve_invocation() {
  local sig="$1" cmd="$2" wt="$3" ent=""
  if [[ -f "$PCC" ]]; then
    ent="$(awk -v sig="$sig" '
      /^[[:space:]]*-[[:space:]]*id:/ { blk=""; e=""; hit=0 }
      { blk=blk"\n"$0; if (index($0,sig)>0) hit=1
        if ($0 ~ /entry:/) { e=$0; sub(/.*entry:[[:space:]]*/,"",e) } }
      /^[[:space:]]*-[[:space:]]*id:/ { }
      { if (hit && e!="") { print e; exit } }
    ' "$PCC" 2>/dev/null | head -n1 | sed -E "s/^[\"']//; s/[\"']$//")"
  fi
  if [[ -n "$ent" ]]; then printf '%s' "$ent"; return 0; fi
  local bare; bare="${cmd//\`/}"; bare="$(printf '%s' "$bare" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  # runnable if it names a script present in the worktree, or a bare tool on PATH
  local first; first="$(printf '%s' "$bare" | awk '{print $1}')"
  if [[ -n "$first" && ( -f "$wt/$first" || -f "$wt/${first#./}" ) ]]; then printf '%s' "$bare"; return 0; fi
  case "$first" in */*) : ;; *) command -v "$first" >/dev/null 2>&1 && { printf '%s' "$bare"; return 0; } ;; esac
  printf ''
  return 0
}

emit_p1() { echo -e "${RED}$1${NC}  $2"; disarmed=$((disarmed + 1)); }
emit_p2() { echo -e "${YELLOW}$1${NC}  $2"; unverified=$((unverified + 1)); }
emit_live() { echo -e "${GREEN}$1${NC}  $2"; live=$((live + 1)); }
emit_note() { echo -e "${BLUE}$1${NC}  $2"; }

live=0; disarmed=0; unverified=0

echo -e "${BLUE}🐤 Gate-liveness (canary probe) — contract: $CONTRACT${NC}"
SNAP0="$(cl_root_snapshot "$ROOT")"
cl_selfheal "$ROOT"
RUNID="$$"
WT="$(cl_worktree_add "$ROOT" "$RUNID")"
[[ -n "$WT" && -d "$WT" ]] || { echo -e "${RED}ERROR: could not create isolation worktree${NC}" >&2; exit 2; }
# node_modules symlinks (root + common frontend subdir) — never npm install
cl_link_node_modules "$ROOT" "$WT" ""
cl_link_node_modules "$ROOT" "$WT" "frontend"
# worktree-relative project dir (for providers that read product-contract.md)
WT_PROJECT="$WT/${PROJECT_DIR#$ROOT/}"

cleanup() { cl_worktree_remove "$ROOT" "$WT"; }
trap cleanup EXIT

while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  gid=$(printf '%s' "$row"    | awk -F'|' '{print $2}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  cmd=$(printf '%s' "$row"    | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  domain=$(printf '%s' "$row" | awk -F'|' '{print $5}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  canary=$(printf '%s' "$row" | awk -F'|' '{print $6}' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
  [[ -z "$gid" ]] && continue

  # No canary declared → un-probed-honest (never a finding). `exempt:` → deliberately un-probeable.
  case "$canary" in
    ""|"—"|"-"|"–"|"N/A") continue ;;
    exempt:*) emit_note "GATE_EXEMPT" "$gid — canary '$canary' (deliberately un-probeable: destructive/infra)"; continue ;;
  esac

  cfile="$CANARY_DIR/$canary.canary"
  if [[ ! -f "$cfile" ]]; then
    emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — unknown canary key '$canary' (no $canary.canary in the library)"; continue
  fi
  # source the canary record → DOMAIN/MECHANISM/REQUIRED_SCOPE/EXT_CLASSES/PROVIDER
  DOMAIN=""; MECHANISM=""; REQUIRED_SCOPE=""; EXT_CLASSES=""; PROVIDER=""; TIER=""
  # shellcheck disable=SC1090
  . "$cfile"
  CANARY_REQUIRED_SCOPE="$REQUIRED_SCOPE"; CANARY_EXT_CLASSES="$EXT_CLASSES"; CANARY_TERM=""

  # Family match on WHOLE TOKENS (split on -/_/space): the canary DOMAIN must equal the §6a domain or
  # one of its components — so `tests` covers `frontend-tests`/`backend-tests` but `copy` ≠ `copyright`.
  if [[ -n "$DOMAIN" && -n "$domain" ]]; then
    dmatch=false
    if [[ "$domain" == "$DOMAIN" ]]; then dmatch=true; else
      for _tok in $(printf '%s' "$domain" | tr '-_ ' '   '); do [[ "$_tok" == "$DOMAIN" ]] && { dmatch=true; break; }; done
    fi
    [[ "$dmatch" == true ]] || { emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — canary '$canary' domain '$DOMAIN' not a token of §6a domain '$domain' (domain-mismatch)"; continue; }
  fi

  sig="$(gate_sig "$cmd")"
  inv="$(resolve_invocation "$sig" "$cmd" "$WT")"
  if [[ -z "$inv" ]]; then
    emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — no locally-runnable invocation resolved for '$cmd' (CI-only / no entry) — no-local-invocation"; continue
  fi
  safety="$(cl_probe_safety "$inv" "$WT")"
  case "$safety" in
    unsafe)  emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — invocation looks destructive ('$inv') — unsafe-to-probe, gate NOT executed (mark it 'exempt:<reason>' in §6a)"; continue ;;
    unknown) emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — command family not recognized as probe-safe ('$inv') — not executed (fail-closed; add the tool to cl_is_safe_tool or 'exempt:' the gate)"; continue ;;
  esac

  # Baseline: watch it pass on the clean worktree.
  OUT="$WT/.speck-canary-out"
  base_rc="$(cl_run_gate "$WT" "" "$inv" "$OUT")"
  if [[ "$base_rc" != "0" ]]; then
    emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — baseline not green (exit $base_rc for '$inv') — cannot establish a green→red measurement (deps/cwd/infra)"; continue
  fi

  # Plan the surfaces (provider decides what to inject; multi-surface for banned-language).
  plan="$("${PROVIDER}_plan" "$WT" "$WT_PROJECT" "$inv" 2>/dev/null || true)"
  if [[ -z "$plan" ]] || printf '%s' "$plan" | head -n1 | grep -q '^DEGRADE|'; then
    reason="$(printf '%s' "$plan" | sed -E 's/^DEGRADE\|//' | head -n1)"
    emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — canary '$canary' cannot apply: ${reason:-no injectable surface}"; continue
  fi

  gate_disarmed=0; gate_live_surfaces=0; gate_unattr=0; dark_list=""
  while IFS= read -r sline; do
    [[ -z "$sline" ]] && continue
    ext="$(printf '%s' "$sline" | awk -F'|' '{print $1}')"
    rel="$(printf '%s' "$sline" | awk -F'|' '{print $2}')"
    fp="$(printf '%s' "$sline"  | cut -d'|' -f3-)"     # fingerprint may contain '|' (ERE alternation)
    # For banned-language the fingerprint IS the injected term; _write uses it. Other providers
    # ignore the term arg and key off $ext. (Note: _plan ran in a subshell, so we pass fp directly
    # rather than relying on a CANARY_TERM export propagating back.)
    "${PROVIDER}_write" "$WT" "$rel" "$ext" "$WT_PROJECT" "$fp"
    [[ "${STAGE_IT:-true}" == "true" ]] && git -C "$WT" add -f "$rel" >/dev/null 2>&1

    m_rc="$(cl_run_gate "$WT" "" "$inv" "$OUT")"
    # banned-language fingerprints are LITERAL §7 terms (may contain regex metachars like C++) → -F;
    # lint/unit fingerprints are crafted EREs (alternations) → -E.
    gmode="-qiE"; [[ "$PROVIDER" == "provide_banned_language" ]] && gmode="-qiF"
    if [[ "$m_rc" != "0" ]]; then
      if grep $gmode -- "$fp" "$OUT" 2>/dev/null; then
        gate_live_surfaces=$((gate_live_surfaces + 1))
      else
        gate_unattr=$((gate_unattr + 1))
      fi
    else
      # green after an in-scope mutation = a dark surface the gate is contracted to cover
      gate_disarmed=$((gate_disarmed + 1)); dark_list="$dark_list $ext"
    fi

    # revert this surface (ADD-only cleanup; worktree index is disposable)
    git -C "$WT" reset -q -- "$rel" >/dev/null 2>&1 || true
    rm -f "$WT/$rel" 2>/dev/null || true
  done <<< "$plan"

  if [[ "$gate_disarmed" -gt 0 ]]; then
    emit_p1 "GATE_DISARMED.P1" "$gid — baseline green but a defect in required scope did NOT go red on surface(s):$dark_list (canary '$canary'). The guardrail slept on a defect it owns."
  elif [[ "$gate_live_surfaces" -gt 0 && "$gate_unattr" -eq 0 ]]; then
    emit_live "GATE_LIVE" "$gid — watched it fail on every injected surface (canary '$canary', ${gate_live_surfaces} surface(s)) ✓"
  elif [[ "$gate_live_surfaces" -gt 0 ]]; then
    emit_live "GATE_LIVE" "$gid — live on ${gate_live_surfaces} surface(s); ${gate_unattr} surface red for an unattributable reason (canary '$canary')"
  else
    emit_p2 "GATE_LIVENESS_UNVERIFIED.P2" "$gid — gate went red but never named the injected defect (red-unattributable) — cannot certify LIVE or DISARMED"
  fi
done <<< "$rows"

# --- INVARIANT-ZERO: the real tree must be byte-identical --------------------------------------
cl_worktree_remove "$ROOT" "$WT"; trap - EXIT
SNAP1="$(cl_root_snapshot "$ROOT")"
if [[ "$SNAP0" != "$SNAP1" ]]; then
  echo -e "${RED}❌ PROBE-INTEGRITY FAILURE — the real working tree changed during the probe.${NC}" >&2
  echo -e "${RED}   before: $SNAP0${NC}" >&2
  echo -e "${RED}   after : $SNAP1${NC}" >&2
  exit 3
fi

echo ""
echo "Gate-liveness (canary): ${live} live · ${disarmed} disarmed(P1) · ${unverified} unverified(P2)"
if [[ "$disarmed" -gt 0 && "$strict" == true ]]; then
  echo -e "${RED}Gate-liveness FAILED: $disarmed gate(s) proven DISARMED — green over a real defect they own.${NC}" >&2
  exit 1
fi
if [[ "$unverified" -gt 0 ]]; then
  echo -e "${YELLOW}Note: $unverified gate(s) UNVERIFIED (degrade-to-honest) — caps the ship claim, does not block dev.${NC}"
fi
echo -e "${GREEN}Gate-liveness (canary) probe complete.${NC}"
exit 0
