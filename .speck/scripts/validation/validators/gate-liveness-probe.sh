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
# Outcomes per gate (the fail-closed tension, resolved):
#   • GATE_LIVE                     — baseline green, defect injected, gate went red naming the defect.
#   • GATE_DISARMED.P1              — defect injected IN the gate's required scope, gate STILL green
#                                     (or red for an unrelated reason). The one positive block.
#   • GATE_VACUOUS.P1               — (#98) the THIRD verdict. The gate exited 0 having inspected
#                                     NOTHING: SUBJECT=0 with a scope that resolves to tracked files
#                                     it should have read, SUBJECT=0 with a scope that resolves to no
#                                     tracked file at all (it can never reach a subject), or
#                                     PREDICATES=0 (it read files and compared them against nothing) —
#                                     UNLESS the gate self-reports SPECK_GATE_MODE=notice, in which
#                                     case PREDICATES=0 is a legitimate, by-design zero (see
#                                     GATE_PREDICATES_LEGITIMATE below) rather than a dead rule set.
#                                     Wiring and liveness both pass on such a gate — #88's two halves
#                                     answer "does it run" and "does it bite", never "did it look".
#   • GATE_PREDICATES_LEGITIMATE    — NOTE, never a finding. PREDICATES=0 on a gate that self-declared
#                                     SPECK_GATE_MODE=notice (a run mode with genuinely nothing to
#                                     compare, e.g. a non-live schema-drift pass). Bounded + opt-in:
#                                     only the gate's OWN reported mode excuses ITS OWN zero.
#   • GATE_EMPTY_LEGITIMATE         — NOTE, never a finding. SUBJECT=0 on a DIFF-scoped run whose
#                                     scope does resolve. A staged run touching no product file is
#                                     honest; conflating it with vacuity is what makes the verdict
#                                     unshippable.
#   • GATE_SCOPE_UNREPORTED.P3      — the gate publishes no SPECK_GATE_SCOPE, so its vacuity cannot
#                                     be measured and the canary must guess. Residual, enumerable.
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
# /project-validate, on-demand at /speck-audit — NEVER in the always-on /speck-recheck shell or on pre-commit.
#
# Portable bash 3.2 / macOS. No associative arrays, no mapfile.

set -uo pipefail   # NOT -e: gate runs are expected to exit non-zero; we manage rc explicitly.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

LIB="$(cd "$(dirname "$0")/.." && pwd)/canary-lib.sh"
[[ -f "$LIB" ]] || { echo "ERROR: canary-lib.sh not found at $LIB" >&2; exit 2; }
# shellcheck disable=SC1090
. "$LIB"
# shellcheck source=../../lib/text.sh
. "$(dirname "$0")/../../lib/text.sh"

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

# --- Header-keyed column resolution (verbatim from validate-gate-liveness.sh for coherence — #88 /
# Speck v9.6 #header-keyed-6a). See that file's copy of this block for the full rationale: three
# independently hardcoded positional reads had already drifted from each other and from the
# producer; resolving by header NAME instead makes a future column insert safe, with a positional
# fallback for a legacy table whose header row is missing/unrecognized. -------------------------
ROW_CELLS=()
split_row() {
  local line="$1" i cell
  local -a raw=()
  IFS='|' read -r -a raw <<< "$line" || true
  ROW_CELLS=()
  for (( i=1; i<${#raw[@]}; i++ )); do
    cell="$(sp_trim "${raw[$i]}")"
    ROW_CELLS+=("$cell")
  done
}

COL_ID=-1; COL_CMD=-1; COL_STAGE=-1; COL_DOMAIN=-1; COL_SCOPE=-1; COL_SUBJECT=-1; COL_CANARY=-1; COL_WAIVER=-1

resolve_columns_from_header() {
  split_row "$1"
  COL_ID=-1; COL_CMD=-1; COL_STAGE=-1; COL_DOMAIN=-1; COL_SCOPE=-1; COL_SUBJECT=-1; COL_CANARY=-1; COL_WAIVER=-1
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(printf '%s' "${ROW_CELLS[$i]}" | tr '[:upper:]' '[:lower:]')"
    case "$lc" in
      "gate id"*) COL_ID=$i ;;
      command*)   COL_CMD=$i ;;
      stage*)     COL_STAGE=$i ;;
      domain*)    COL_DOMAIN=$i ;;
      scope*)     COL_SCOPE=$i ;;
      subject*)   COL_SUBJECT=$i ;;
      canary*)    COL_CANARY=$i ;;
      waiver*)    COL_WAIVER=$i ;;
    esac
  done
  [[ $COL_ID -ge 0 && $COL_CMD -ge 0 && $COL_DOMAIN -ge 0 && $COL_CANARY -ge 0 ]]
}

# Historical fixed layout: Gate ID | Command / Script | Stage | Domain | Canary | Waiver.
resolve_columns_positional() {
  COL_ID=0; COL_CMD=1; COL_STAGE=2; COL_DOMAIN=3; COL_CANARY=4; COL_WAIVER=5
  COL_SCOPE=-1; COL_SUBJECT=-1
}

# --- THE GATE OUTPUT CONTRACT — the consumer half (#98 §4) ---------------------------------------
# v9.6 taught the canonical gates to PUBLISH what they inspected: three lines, on every exit path,
#   SPECK_GATE_SCOPE=<comma-separated globs>   SPECK_GATE_SUBJECT=<n>   SPECK_GATE_PREDICATES=<n>
# This is where they are read. The point is not telemetry for its own sake: #98 §1 measured a gate
# and its OWN liveness canary sharing a correlated blind spot because each re-derived "the product
# surface" from its own hardcoded list, and the two lists had already drifted (`content`/`lib`
# canaried and never scanned; `i18n` scanned and never canaried). One list, published by the gate,
# read by everyone else — the drift is impossible by construction rather than caught by review.
#
# A FOURTH, OPTIONAL line — SPECK_GATE_MODE=notice|live (v9.6/v10 follow-up) — resolves an inversion
# #98's own PREDICATES=0 teeth introduced: validate-schema-drift.sh legitimately reports
# PREDICATES=0 on EVERY non-live invocation (nothing was compared against a live catalog — that is
# the honest, by-design notice-mode output), and this probe's own PREDICATES=0 rule (below) cannot
# tell that apart from a gate that scanned files and compared them against nothing. Measured: 7 real
# repos, 188 migration files, PREDICATES=0 with exit 0 on all 7 — every one would have convicted as
# GATE_VACUOUS.P1 and blocked /epic-validate for a gate behaving exactly as designed. THE CHOSEN
# OWNER OF THIS SEMANTIC: the PROBE bounds the PREDICATES=0 trigger (not the gate suppressing its
# own PREDICATES line) — a missing/zero PREDICATES value stays a single, uniform signal for every
# gate family, and only a gate that explicitly self-declares "I am in a mode with legitimately zero
# predicates" gets the exemption. A gate that says nothing about its mode is judged exactly as
# before (GATE_VACUOUS.P1 on PREDICATES=0) — MODE is opt-in, never a way to go quiet and dodge.

# telemetry_value <KEY> <file> — the LAST SPECK_GATE_<KEY>= value the run printed; empty if none.
telemetry_value() {
  local key="$1" f="$2"
  [[ -f "$f" ]] || { printf ''; return 0; }
  sed -n "s/^SPECK_GATE_${key}=//p" "$f" 2>/dev/null | tail -n1
}

# probe_scope_dirs <wt> <scope-csv> — the reported scope, resolved to worktree-relative DIRECTORIES.
# Handles all four forms banned-language-lint.sh publishes: `src/**` (legacy-root), `**/src/**`
# (any-depth — the monorepo form the old root-anchored canary list could not see), an absolute
# workspace fallback, and explicit targets.
probe_scope_dirs() {
  local wt="$1" scope="$2" tok base out="" d name
  while IFS= read -r tok; do
    tok="$(sp_trim "$tok")"
    [[ -z "$tok" ]] && continue
    base="${tok%/\*\*}"; base="${base%/\*}"; base="${base%/}"
    case "$base" in
      "$wt")   out="$out ." ;;
      "$wt"/*) d="${base#"$wt"/}"; [[ -d "$wt/$d" ]] && out="$out $d" ;;
      '**/'*)
        name="${base:3}"
        while IFS= read -r d; do
          [[ -n "$d" ]] && out="$out ${d#"$wt"/}"
        done <<< "$(find "$wt" \( -name .git -o -name node_modules -o -name .speck \) -prune -o \
                      -type d -name "$name" -print 2>/dev/null)"
        ;;
      /*)      : ;;    # an absolute path outside the worktree — not resolvable here
      *)       [[ -d "$wt/$base" ]] && out="$out $base" ;;
    esac
  done <<< "$(printf '%s' "$scope" | tr ',' '\n')"
  printf '%s' "$(printf '%s' "$out" | sed -E 's/^ +//')"
}

# scope_tracked_files <wt> <dirs> — how many TRACKED files those dirs hold. This is the mechanical
# discriminator #98 §1 asks for: it resolves the scope against the repo, independently of any diff,
# so "no subject because this commit has none" and "no subject because the scope cannot reach one"
# stop being the same observation.
scope_tracked_files() {
  local wt="$1" dirs="$2" d total=0 n
  for d in $dirs; do
    n="$(git -C "$wt" ls-files -- "$d" 2>/dev/null | wc -l | tr -d ' ')"
    total=$(( total + ${n:-0} ))
  done
  printf '%s' "$total"
}

# reported_zero <value> — true only for a literally-reported 0. An empty (never printed) or
# non-numeric value is NOT zero: we did not measure it, and "unmeasured" must never read as "empty".
reported_zero() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) [[ "$1" -eq 0 ]] ;;
  esac
}

# is_diff_scoped <invocation> — does this invocation only ever look at the current change set?
# A diff-scoped run with an empty intersection is EMPTY-LEGITIMATE, never vacuous.
is_diff_scoped() {
  case " $1 " in
    *" --staged "*|*" --cached "*|*" --changed "*|*" --diff "*|*" --since "*) return 0 ;;
  esac
  return 1
}

cell_at() {
  local idx="$1"
  [[ "$idx" -ge 0 && "$idx" -lt ${#ROW_CELLS[@]} ]] && printf '%s' "${ROW_CELLS[$idx]}" || printf ''
}

# --- §6a row extraction (verbatim from Phase 1 for coherence) --------------------------------------
block="$(awk '
  /^### 6a\./ { ins=1; next }
  ins && /^#{2,3} / { ins=0 }
  ins && /^\|/ { print }
' "$CONTRACT" 2>/dev/null || true)"

header_lines="$(printf '%s\n' "$block" | grep -iE '\|[[:space:]]*Gate ID[[:space:]]*\|' || true)"
header_row="$(sp_head 1 "$header_lines")"
if [[ -n "$header_row" ]] && resolve_columns_from_header "$header_row"; then
  :
else
  resolve_columns_positional
fi

rows="$(printf '%s\n' "$block" | grep -vE '^\|[- :]+\||Gate ID|REPLACE_BEFORE_SHIP' || true)"

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
# The THIRD verdict class. Distinct from DISARMED (the gate slept on a defect it owns) and from
# UNVERIFIED (we could not measure): we DID measure, and the gate inspected nothing.
emit_vacuous() { echo -e "${RED}GATE_VACUOUS.P1${NC}  $1"; vacuous=$((vacuous + 1)); }
emit_p3() { echo -e "${YELLOW}$1${NC}  $2"; unreported=$((unreported + 1)); }

live=0; disarmed=0; unverified=0; vacuous=0; unreported=0

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
  split_row "$row"
  gid="$(cell_at "$COL_ID")"
  cmd="$(cell_at "$COL_CMD")"
  domain="$(cell_at "$COL_DOMAIN")"
  canary="$(cell_at "$COL_CANARY")"
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
      # Dash LAST in the SET1 argument. BSD/macOS tr parses a leading '-' as an option and dies
      # (`tr: illegal option -- _`), so this whole-token split silently produced nothing: a §6a row
      # with Domain `backend-tests` never matched the `tests`-domain canary, was rejected as a
      # domain mismatch, and THE CANARY NEVER RAN. It failed closed — GATE_LIVENESS_UNVERIFIED.P2
      # caps rather than false-greens — which is why it survived: the symptom was a cap nobody
      # traced back to a quoting bug in the splitter.
      for _tok in $(printf '%s' "$domain" | tr '_ -' '   '); do [[ "$_tok" == "$DOMAIN" ]] && { dmatch=true; break; }; done
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

  # ── DID IT LOOK AT ANYTHING? (#98 (b)+(c)) ────────────────────────────────────────────────────
  # Parse the telemetry out of the BASELINE run just made — never a second execution of the gate.
  # A gate re-run to answer this question is a different run with a different subject, and on a
  # diff-scoped gate it is a different answer.
  rep_scope="$(telemetry_value SCOPE "$OUT")"
  rep_subject="$(telemetry_value SUBJECT "$OUT")"
  rep_predicates="$(telemetry_value PREDICATES "$OUT")"
  rep_mode="$(telemetry_value MODE "$OUT")"
  has_scope_line=false
  grep -q '^SPECK_GATE_SCOPE=' "$OUT" 2>/dev/null && has_scope_line=true

  if [[ "$has_scope_line" != true ]]; then
    # Residual fallback use is ENUMERABLE, not invisible. Every P3 here is one gate still forcing a
    # consumer to guess its scope from a second hardcoded list — the exact duplication #98 §1 is
    # about. The canary's REQUIRED_SCOPE stays as the fallback so a not-yet-migrated gate is still
    # probed, but you can count how many are left.
    emit_p3 "GATE_SCOPE_UNREPORTED.P3" "$gid — the gate printed no SPECK_GATE_SCOPE= line, so the canary falls back to its own residual scope list ('$REQUIRED_SCOPE'). Teach the gate the output contract (SPECK_GATE_SCOPE/SUBJECT/PREDICATES on every exit path) and this guess disappears."
  else
    scope_dirs="$(probe_scope_dirs "$WT" "$rep_scope")"
    tracked="$(scope_tracked_files "$WT" "$scope_dirs")"

    # `[[ "$x" -eq 0 ]]` on a NON-numeric x resolves x as a variable name and answers TRUE — an
    # unparsable telemetry value would manufacture a P1. Match the digits explicitly instead.
    if reported_zero "$rep_predicates" && [[ "$rep_mode" == "notice" ]]; then
      # The gate self-declared a mode with legitimately zero predicates (e.g. a non-live schema-drift
      # notice run — nothing was compared against a live catalog, by design). Bounded, opt-in
      # exemption: only THIS gate's own reported MODE excuses ITS OWN PREDICATES=0, never a blanket
      # pass — a gate that says nothing about its mode still gets the vacuous rule below unchanged.
      emit_note "GATE_PREDICATES_LEGITIMATE" "$gid — PREDICATES=0 but the gate reports SPECK_GATE_MODE=notice (a non-live run with nothing to compare against a live target — honest, not vacuous)."
    elif reported_zero "$rep_predicates"; then
      # The dimension that makes this gate family's vacuity visible at all: banned-language can scan
      # 180 files with 12 unmatchable terms and look perfectly healthy. Zero predicates means every
      # one of those files was compared against nothing.
      emit_vacuous "$gid — exited 0 with PREDICATES=0: the gate evaluated ZERO assertions over SUBJECT=${rep_subject:-?} file(s). A dead predicate set and a satisfied one produce identical output."
    elif reported_zero "$rep_subject"; then
      if [[ "$tracked" -eq 0 ]]; then
        emit_vacuous "$gid — exited 0 with SUBJECT=0 and a scope ('$rep_scope') that resolves to ZERO tracked files. The declared scope cannot reach a subject in this repo, so no commit will ever make this gate look at anything."
      elif is_diff_scoped "$inv"; then
        emit_note "GATE_EMPTY_LEGITIMATE" "$gid — SUBJECT=0 on a diff-scoped run, but the scope ('$rep_scope') resolves to $tracked tracked file(s). This change set genuinely has none — honest, not vacuous."
      else
        emit_vacuous "$gid — exited 0 with SUBJECT=0 while its scope ('$rep_scope') resolves to $tracked tracked file(s). It had something to inspect on a full scan and inspected none of it."
      fi
    fi

    # (#98 (d)) The canary now takes the gate's WORD for its scope instead of restating it. The two
    # lists cannot drift apart when there is only one list.
    [[ -n "$scope_dirs" ]] && CANARY_REQUIRED_SCOPE="$scope_dirs"
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
echo "Gate-liveness (canary): ${live} live · ${disarmed} disarmed(P1) · ${vacuous} vacuous(P1) · ${unverified} unverified(P2) · ${unreported} scope-unreported(P3)"
if [[ $(( disarmed + vacuous )) -gt 0 && "$strict" == true ]]; then
  if [[ "$disarmed" -gt 0 ]]; then
    echo -e "${RED}Gate-liveness FAILED: $disarmed gate(s) proven DISARMED — green over a real defect they own.${NC}" >&2
  fi
  if [[ "$vacuous" -gt 0 ]]; then
    echo -e "${RED}Gate-liveness FAILED: $vacuous gate(s) proven VACUOUS — exited 0 having inspected nothing. Zero violations is only meaningful if something was there to violate them.${NC}" >&2
  fi
  exit 1
fi
if [[ "$unreported" -gt 0 ]]; then
  echo -e "${YELLOW}Note: $unreported gate(s) publish no SPECK_GATE_SCOPE — their vacuity cannot be measured and the canary is guessing their scope.${NC}"
fi
if [[ "$unverified" -gt 0 ]]; then
  echo -e "${YELLOW}Note: $unverified gate(s) UNVERIFIED (degrade-to-honest) — caps the ship claim, does not block dev.${NC}"
fi
echo -e "${GREEN}Gate-liveness (canary) probe complete.${NC}"
exit 0
