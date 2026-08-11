#!/usr/bin/env bash
# seed-gate-registry.sh — generate the evidence-contract §6a gate registry from a recipe (issue #88).
#
# §6a is SCAFFOLDED, not hand-authored: the recipe declares each CI-enforced gate under
# `evidence_contract.ci_gates:` (id / command / stage / domain / [canary]); this script
# emits the §6a markdown table rows so a project's contract ships with an accurate registry
# and validate-gate-liveness.sh has something to diff the committed config against. Kills the
# migration hole — an un-seeded project isn't dark, it's seeded on first contract generation.
#
# Usage:
#   seed-gate-registry.sh <recipe.yaml>                 # print §6a rows to stdout
#   seed-gate-registry.sh <recipe.yaml> --contract <evidence-contract.md>   # splice into the contract in place
#
# Exit: 0 ok, 2 invocation error.

set -euo pipefail

RECIPE="${1:-}"
[[ -n "$RECIPE" && -f "$RECIPE" ]] || { echo "ERROR: pass a recipe.yaml" >&2; exit 2; }
CONTRACT=""
[[ "${2:-}" == "--contract" ]] && CONTRACT="${3:-}"

# --- ONE shared column list (Speck v9.6, header-keyed §6a — this cluster) ------------------------
# Verified: the header text (below, printed literally) and the row printf (gen_rows' `flush`) used
# to be TWO independently hardcoded strings — nothing forced their field counts to agree, and the
# three readers (this script + the two validators) had ALREADY drifted from each other on top of
# that. GATE_REGISTRY_COLUMNS is now the one place the table's shape is declared; both the header
# and the row FORMAT string below are derived from it, so a column insert here changes both in
# lockstep instead of only one of them.
#
# v9.6/v10 (#98) INSERTS `Scope` + `Subject` MID-TABLE, between Domain and Canary. That insert is
# only safe because both consumers are header-keyed: `Scope`/`Subject` sit exactly where the old
# positional readers expected `Canary`/`Waiver`, so a positional consumer would read the scope glob
# as a canary key and the subject assertion as a waiver. The mid-table-insert round-trip test in
# seed-gate-registry.test.sh is the proof, not this comment.
GATE_REGISTRY_COLUMNS=("Gate ID" "Command / Script" "Stage" "Domain" "Scope" "Subject" "Canary" "Waiver")

# "| Gate ID | Command / Script | Stage | Domain | Scope | Subject | Canary | Waiver |"
gate_registry_header() {
  local out="|" c
  for c in "${GATE_REGISTRY_COLUMNS[@]}"; do out="$out $c |"; done
  printf '%s' "$out"
}

# "|---------|------------------|-------|--------|--------|--------|" (width = label length, min 3)
gate_registry_separator() {
  local out="|" c n
  for c in "${GATE_REGISTRY_COLUMNS[@]}"; do
    n=${#c}; (( n < 3 )) && n=3
    out="$out$(printf -- '-%.0s' $(seq 1 "$n"))|"
  done
  printf '%s' "$out"
}

# One "| %s " per column (Command / Script backtick-quoted) — the row printf's arg COUNT is tied
# to GATE_REGISTRY_COLUMNS' length, so a column insert that isn't matched by a new value in flush()
# below fails loudly (awk arg-count mismatch) instead of silently misaligning cells.
# NOTE: no trailing \n here — command substitution strips trailing newlines, so the newline is
# added separately by the awk caller (gen_rows) after this format string is filled in.
gate_registry_row_fmt() {
  local out="" c
  for c in "${GATE_REGISTRY_COLUMNS[@]}"; do
    if [[ "$c" == "Command / Script" ]]; then out="${out}| \`%s\` "; else out="${out}| %s "; fi
  done
  printf '%s|' "$out"
}

# Parse the ci_gates: list-of-maps under evidence_contract: (awk, bash-3.2 safe).
# Each item: `- id: X` then indented `command:/stage:/domain:/scope:/subject:/canary:`.
gen_rows() {
  local fmt; fmt="$(gate_registry_row_fmt)"
  awk -v fmt="$fmt" '
    function lead(s){ return match(s,/[^ ]/) ? match(s,/[^ ]/)-1 : 0 }
    function val(line,   v){ v=line; sub(/^[^:]*:[[:space:]]*/,"",v); gsub(/^["'"'"' ]+|["'"'"' ]+$/,"",v); return v }
    function flush(){ if(id!=""){ c=(canary==""?"—":canary); printf fmt, id, command, stage, (domain==""?"—":domain), (scope==""?"—":scope), (subject==""?"—":subject), c, "—"; printf "\n" } id="";command="";stage="";domain="";canary="";scope="";subject="" }
    /^[[:space:]]*ci_gates:[[:space:]]*$/ { ins=1; base=lead($0); next }
    ins && /^[[:space:]]*[a-zA-Z_]+:/ && $0 !~ /^[[:space:]]*-/ { if (lead($0) <= base) { flush(); ins=0; next } }
    ins && /^[[:space:]]*-[[:space:]]*id:/ { flush(); id=val($0) }
    ins && /^[[:space:]]*command:/ { command=val($0) }
    ins && /^[[:space:]]*stage:/   { stage=val($0) }
    ins && /^[[:space:]]*domain:/  { domain=val($0) }
    ins && /^[[:space:]]*scope:/   { scope=val($0) }
    ins && /^[[:space:]]*subject:/ { subject=val($0) }
    ins && /^[[:space:]]*canary:/  { canary=val($0) }
    END { if (ins) flush() }
  ' "$RECIPE"
}

ROWS="$(gen_rows)"

# --- SPECK-OWNED STANDING GATES (issue #101 (c), v10.2) -------------------------------------
# The recipe declares the PROJECT's gates. These two are SPECK's, and they are emitted on every
# seed for one reason: `validate-evidence-citations.sh` shipped in v10.1 with no hook, no CI step
# and no §6a row, so the rule it implements could not fail a build — which is the exact shape this
# whole backlog was filed about. A gate that is not declared anywhere is not a gate.
#
# WHY `manual`, HONESTLY. Nothing on the commit path invokes them yet, and §6a's own law is that
# declaring a stage a gate does not fire at is the divergence `validate-gate-liveness.sh` exists to
# catch. `manual` is the true value; the invocation that does exist is at the bottom of this file
# (every seed/amend of a contract runs both), plus /speck-audit, /epic-validate and /project-validate on
# demand. Both are NUDGES — they exit 0 without --strict, so declaring them cannot turn a
# downstream repo red on the day they land.
#
# WHY THEY GO THROUGH gen_rows RATHER THAN A printf OF THEIR OWN. A second row producer is a second
# place the §6a column list can drift from — the precise defect GATE_REGISTRY_COLUMNS was
# introduced to kill (three readers, three independently hardcoded field orders). Feeding a
# synthetic recipe back through the SAME parser means a column insert shifts these rows exactly as
# it shifts the project's.
STANDING_YAML="$(mktemp)"
cat > "$STANDING_YAML" <<'STANDING'
evidence_contract:
  ci_gates:
    - id: speck:evidence-citations
      command: .speck/scripts/validation/validators/validate-evidence-citations.sh specs/
      stage: manual
      domain: evidence
      scope: specs/**
      subject: citations>0
    - id: speck:probe-library
      command: .speck/scripts/validation/validators/validate-evidence-citations.sh --check-probe-library
      stage: manual
      domain: evidence
      scope: specs/projects/**
      subject: probe_classes>0
STANDING
SAVED_RECIPE="$RECIPE"
RECIPE="$STANDING_YAML"
STANDING_ROWS="$(gen_rows)"
RECIPE="$SAVED_RECIPE"
rm -f "$STANDING_YAML"

if [[ -z "$ROWS" ]]; then
  echo "⚠️  No evidence_contract.ci_gates found in $RECIPE — seeding Speck's standing gates only." >&2
  ROWS="$STANDING_ROWS"
else
  ROWS="$ROWS
$STANDING_ROWS"
fi

TABLE="$(
  printf '%s\n' "$(gate_registry_header)"
  printf '%s\n' "$(gate_registry_separator)"
  printf '%s\n' "$ROWS"
)"

if [[ -z "$CONTRACT" ]]; then
  printf '%s\n' "$TABLE"
  exit 0
fi

[[ -f "$CONTRACT" ]] || { echo "ERROR: contract not found: $CONTRACT" >&2; exit 2; }
# Replace only the §6a TABLE (header→last row) in place; prose around it is preserved.
TBLFILE="$(mktemp)"; printf '%s\n' "$TABLE" > "$TBLFILE"
TMP="$(mktemp)"
awk -v tblfile="$TBLFILE" '
  /^\|[[:space:]]*Gate ID[[:space:]]*\|/ && !done {
    while ((getline l < tblfile) > 0) print l
    close(tblfile); skip=1; done=1; next
  }
  skip && /^\|/ { next }
  skip && !/^\|/ { skip=0 }
  { print }
' "$CONTRACT" > "$TMP" && mv "$TMP" "$CONTRACT"
rm -f "$TBLFILE"
echo "✅ Seeded §6a gate registry in $CONTRACT from $(basename "$(dirname "$RECIPE")")"

# --- RUN the standing gates on the contract we just wrote (issue #101 (c)) -------------------
# A §6a row declares a gate; it does not execute one. This block is the execution: every seed or
# amend of an evidence contract now judges that contract's typed citations (§2b parity) and its
# §11a probe library, right here, on a real path an agent already walks.
#
# STRICTLY NON-BLOCKING, and the `|| true` is load-bearing under `set -e`: a project that has not
# adopted typed citations or §11a must be ENUMERATED, not blocked, on the day this lands. The
# findings are printed; this script's exit code is untouched. Set SPECK_SEED_SKIP_NUDGE=1 to
# silence (the gate is declared in §6a either way, so silencing is visible, not a hole).
CITATIONS_VALIDATOR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validation/validators/validate-evidence-citations.sh"
if [[ "${SPECK_SEED_SKIP_NUDGE:-0}" != "1" && -f "$CITATIONS_VALIDATOR" ]]; then
  echo ""
  echo "── Speck standing evidence gates (nudge — findings only, never a block) ──"
  bash "$CITATIONS_VALIDATOR" --check-contract "$CONTRACT" || true
  bash "$CITATIONS_VALIDATOR" --check-probe-library "$CONTRACT" || true
fi
exit 0
