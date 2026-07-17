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

# Parse the ci_gates: list-of-maps under evidence_contract: (awk, bash-3.2 safe).
# Each item: `- id: X` then indented `command:/stage:/domain:/canary:`.
gen_rows() {
  awk '
    function lead(s){ return match(s,/[^ ]/) ? match(s,/[^ ]/)-1 : 0 }
    function val(line,   v){ v=line; sub(/^[^:]*:[[:space:]]*/,"",v); gsub(/^["'"'"' ]+|["'"'"' ]+$/,"",v); return v }
    function flush(){ if(id!=""){ c=(canary==""?"—":canary); printf "| %s | `%s` | %s | %s | %s | — |\n", id, command, stage, (domain==""?"—":domain), c } id="";command="";stage="";domain="";canary="" }
    /^[[:space:]]*ci_gates:[[:space:]]*$/ { ins=1; base=lead($0); next }
    ins && /^[[:space:]]*[a-zA-Z_]+:/ && $0 !~ /^[[:space:]]*-/ { if (lead($0) <= base) { flush(); ins=0; next } }
    ins && /^[[:space:]]*-[[:space:]]*id:/ { flush(); id=val($0) }
    ins && /^[[:space:]]*command:/ { command=val($0) }
    ins && /^[[:space:]]*stage:/   { stage=val($0) }
    ins && /^[[:space:]]*domain:/  { domain=val($0) }
    ins && /^[[:space:]]*canary:/  { canary=val($0) }
    END { if (ins) flush() }
  ' "$RECIPE"
}

ROWS="$(gen_rows)"
if [[ -z "$ROWS" ]]; then
  echo "⚠️  No evidence_contract.ci_gates found in $RECIPE — nothing to seed." >&2
  exit 0
fi

TABLE="$(
  echo "| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |"
  echo "|---------|------------------|-------|--------|--------|--------|"
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
