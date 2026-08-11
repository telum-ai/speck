#!/usr/bin/env bash
# validate-project-analysis.test.sh — tests for the decorrelated-analysis gate (issue #106).
#
# NOTE ON PIPEFAIL, repeated because it has silently inverted assertions in this repo before:
# never write `if bash "$VAL" … | grep -q X; then`. Under `set -o pipefail` the pipeline reports
# the VALIDATOR's status, not the match, so the assertion becomes one that cannot fail. Every
# assertion below captures into $OUT first, then greps the variable.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
# SPECK_VALIDATOR_UNDER_TEST is the mutation-harness hook: point it at a SCRATCH COPY of the
# validator to confirm a given assertion actually goes red when its fix is reverted. Unset in every
# normal run (npm test, CI, a developer's shell), where it resolves to the shipped validator.
VAL="${SPECK_VALIDATOR_UNDER_TEST:-$ROOT/.speck/scripts/validation/validators/validate-project-analysis.sh}"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

run() { RC=0; OUT=$(bash "$VAL" "$@" 2>&1) || RC=$?; }
run_with() { local v="$1"; shift; RC=0; OUT=$(bash "$v" "$@" 2>&1) || RC=$?; }

# --- the conformance fixture -------------------------------------------------------------------
# Written by hand rather than substituted from the template, so a template edit that breaks the
# validator — and a validator edit the template cannot satisfy — both surface as a failure here
# instead of the two silently agreeing with each other.
write_report() { # <path> [artifact_type] [gate_verdict]
  local at="${2:-project-analysis-report}" gv="${3:-NEEDS_FIXES}"
  cat > "$1" <<EOF
---
speck_version: 10.3.0
artifact_type: ${at}
analyzed_sha: 0123456789abcdef0123456789abcdef01234567
play_level: build
epic_count: 6
lenses:
  - id: L3
    name: promise-coverage
    reviewer: reviewer-a
    authored_corpus: false
  - id: L6
    name: cross-artifact-drift
    reviewer: reviewer-b
    authored_corpus: false
  - id: L7
    name: completeness-critic
    reviewer: reviewer-c
    authored_corpus: false
---

# Project Analysis Report: Fixture

**Gate verdict**: ${gv}

## Lens Roster

| Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings |
|------|------------------|----------|-------------------------------|----------|
| L3 promise-coverage | Which MM-N does no epic carry? | reviewer-a | no | 1 |
| L6 cross-artifact-drift | Which two artifacts cannot both hold? | reviewer-b | no | 1 |
| L7 completeness-critic | What is missing entirely? | reviewer-c | no | 0 |

## Analysis Results

### ⚠️ Issues Found

| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |
|----|----------|----------|-------------|----------------|----------|---------|--------|
| L6-1 | cross-artifact-drift | HIGH | PRD says X, epics say Y | Reconcile | L7 | confirmed | open |
| L3-1 | promise-coverage | MEDIUM | thin coverage | Widen | L6 | confirmed | resolved |

### Promise Coverage (Unaddressed-Promise Gap)

| Promise dimension | Source | Epic / story coverage | Status |
|-------------------|--------|----------------------|--------|
| MM-1 fast plan | product-contract 5 | E001 / S002 | resolved |
| MM-2 second moment | product-contract 5 | E002 / S004 | resolved |
| JOB-1 get moving | product-contract 4 | E001 / S003 | resolved |
EOF
}

# A project tree the witness graph can actually read: product-contract.md carries MM-1, MM-2, JOB-1.
mkproj() { # <repo-root> [n-epics] [play_level]
  local d="$1" n="${2:-6}" play="${3:-build}" i p
  mkdir -p "$d/.speck"
  printf '{"project_id":"001-x","play_level":"%s"}\n' "$play" > "$d/.speck/project.json"
  p="$d/specs/projects/001-x"
  mkdir -p "$p/epics"
  i=1
  while [ "$i" -le "$n" ]; do
    mkdir -p "$p/epics/$(printf 'E%03d' "$i")-thing"
    i=$((i + 1))
  done
  cat > "$p/product-contract.md" <<'EOF'
# Product Contract

## 5. Magic Moments

### MM-1 — Fast plan
The first moment.

### MM-2 — Second moment
The second moment.

## 4. Jobs

JOB-1 get moving
EOF
  printf '# PRD\n' > "$p/PRD.md"
  printf '# Epics\n' > "$p/epics.md"
  printf '%s' "$p"
}

gitify() { # <repo-root>
  git -C "$1" init -q
  git -C "$1" config user.email t@t.co
  git -C "$1" config user.name t
  git -C "$1" add -A >/dev/null 2>&1
  git -C "$1" -c commit.gpgsign=false commit -qm init >/dev/null 2>&1
}

echo "── structural mode ──────────────────────────────────────────────────────────"

# 1. VINTAGE EXEMPTION — a report with no artifact_type is pre-v10.3 and is not held to any v10.3
# rule. This is what makes the change need no data migration: every analysis report already on disk
# has exactly this shape.
d="$T/s1"; mkdir -p "$d"
cat > "$d/project-analysis-report.md" <<'EOF'
# Project Analysis Report: Legacy

### ⚠️ Issues Found

| ID | Category | Severity | Description | Recommendation |
|----|----------|----------|-------------|----------------|
| P1 | Epic Overlap | HIGH | x | y |
EOF
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "pre-v10.3 analysis report"; } \
  && pass "pre-v10.3 report (no artifact_type) is exempt — no migration needed" \
  || fail "a report with no artifact_type must be exempt, and say so"

# 2. the conformance fixture passes under --strict
d="$T/s2"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "v10.3-vintage analysis report"; } \
  && pass "a conforming v10.3 report passes --strict" \
  || fail "the conformance fixture must pass"

# 3. the epic artifact type is handled by the same entry point
d="$T/s3"; mkdir -p "$d"; write_report "$d/epic-analysis-report.md" epic-analysis-report
run --strict "$d/epic-analysis-report.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "artifact_type: epic-analysis-report"; } \
  && pass "epic-analysis-report.md validates through the same entry point" \
  || fail "both altitudes must route to one implementation"

# 3b. story analysis uses the same structural contract without reviving a standalone skill.
d="$T/s3b"; mkdir -p "$d"; write_report "$d/story-analysis-report.md" story-analysis-report
run --strict "$d/story-analysis-report.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "artifact_type: story-analysis-report"; } \
  && pass "story-analysis-report.md validates through the shared analysis entry point" \
  || fail "story analysis must reuse the shared structural contract"

# 4. required frontmatter keys
d="$T/s4"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak '/^speck_version:/d' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "missing 'speck_version'"; } \
  && pass "missing speck_version is a structural violation" \
  || fail "speck_version is required of a bound report"

# 5. analyzed_sha must be a FULL sha (or the honest literal 'unknown')
d="$T/s5"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/^analyzed_sha: .*/analyzed_sha: 0123456/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "neither a full 40-character SHA"; } \
  && pass "a short analyzed_sha is rejected" \
  || fail "analyzed_sha must be a full SHA or 'unknown'"

d="$T/s5b"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/^analyzed_sha: .*/analyzed_sha: unknown/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
[[ "$RC" == 0 ]] \
  && pass "'analyzed_sha: unknown' is accepted — an honest unknown is not a violation" \
  || fail "outside git the honest answer must be spellable"

# 6. an empty lens roster declaration
d="$T/s6"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
python3 - "$d/project-analysis-report.md" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r"lenses:\n(  - .*\n|    .*\n)+", "lenses: []\n", s, count=1)
open(p, "w").write(s)
PY
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "declares no 'lenses:'"; } \
  && pass "an empty lenses: list is a structural violation" \
  || fail "the roster is the decorrelation claim; empty must not pass"

# 7. required sections
d="$T/s7"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/^## Lens Roster/## Who Looked/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "Missing required section: Lens Roster"; } \
  && pass "a renamed Lens Roster section is caught" \
  || fail "the required sections must be asserted"

# 8. COLUMNS ARE RESOLVED BY HEADER NAME — a missing column is a finding, never a silent
# fall-through to a position.
d="$T/s8"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |/| ID | Category | Severity | Description | Recommendation | Verdict | Status |/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "declares no 'verifier' column"; } \
  && pass "a dropped Verifier column is caught by NAME" \
  || fail "columns must be resolved by header name"

# 9. MECHANISM PROOF for the header-keyed read (#103): insert a NEW column in the MIDDLE of the
# Issues table. Under a positional read every field after it shifts by one and Status would be read
# out of the Verdict cell — the row below would then look 'confirmed', not 'open'. Header-keyed, the
# CRITICAL row is still seen as open and the CLEAN verdict is still convicted.
d="$T/s9"; mkdir -p "$d"; write_report "$d/project-analysis-report.md" project-analysis-report CLEAN
python3 - "$d/project-analysis-report.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |",
              "| ID | Category | Owner | Severity | Description | Recommendation | Verifier | Verdict | Status |")
s = s.replace("|----|----------|----------|-------------|----------------|----------|---------|--------|",
              "|----|----------|-------|----------|-------------|----------------|----------|---------|--------|")
s = s.replace("| L6-1 | cross-artifact-drift | HIGH | PRD says X, epics say Y | Reconcile | L7 | confirmed | open |",
              "| L6-1 | boundary | team-a | CRITICAL | PRD says X, epics say Y | Reconcile | L7 | confirmed | open |")
s = s.replace("| L3-1 | promise-coverage | MEDIUM | thin coverage | Widen | L6 | confirmed | resolved |",
              "| L3-1 | promise-coverage | team-b | MEDIUM | thin coverage | Widen | L6 | confirmed | resolved |")
open(p, "w").write(s)
PY
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "CLEAN' while carrying 1 CRITICAL"; } \
  && pass "9-col mechanism proof: Severity/Status still resolve from their REAL (shifted) columns" \
  || fail "an inserted middle column must not re-map the columns this gate reads"

# 10. THE SEVERITY MAPPING RULE. A cross-artifact contradiction is CRITICAL by construction; an
# author grading it HIGH has mis-graded it. 13 of the 14 motivating defects were authored below
# CRITICAL, so a discretion-graded gate would have passed all of them.
d="$T/s10"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | cross-artifact contradiction | HIGH |/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "CRITICAL BY RULE"; } \
  && pass "a contradiction authored as HIGH is convicted by the mapping rule" \
  || fail "severity by rule must outrank the author's cell"

# 11. the fixed vocabularies
d="$T/s11"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/| confirmed | open |/| looks fine to me | open |/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "not in the fixed vocabulary"; } \
  && pass "an off-vocabulary per-finding Verdict is caught" \
  || fail "Verdict vocabulary is confirmed | refuted"

d="$T/s11b"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/| confirmed | open |/| confirmed | pending |/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "Status 'pending'"; } \
  && pass "an off-vocabulary Status is caught" \
  || fail "Status vocabulary is open | resolved | waived DEC-####"

# 12. the gate verdict must parse to EXACTLY one token — a line carrying the template's whole
# legend has declared nothing.
d="$T/s12"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak 's/^\*\*Gate verdict\*\*: NEEDS_FIXES/**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "does not parse to exactly one verdict"; } \
  && pass "a verdict line listing all three declares nothing" \
  || fail "the verdict must parse to exactly one token"

d="$T/s12b"; mkdir -p "$d"; write_report "$d/project-analysis-report.md"
sed -i.bak '/^\*\*Gate verdict\*\*/d' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "no '\*\*Gate verdict\*\*:' line"; } \
  && pass "a missing gate-verdict line is caught" \
  || fail "every report declares one verdict"

# 13. A REPORT CANNOT SELF-CERTIFY PAST ITS OWN OPEN CRITICAL. This is #106 in miniature: the party
# assigning the severity is the party signing the verdict.
d="$T/s13"; mkdir -p "$d"; write_report "$d/project-analysis-report.md" project-analysis-report CLEAN
sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | cross-artifact-drift | CRITICAL |/' "$d/project-analysis-report.md"
run --strict "$d/project-analysis-report.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "CLEAN' while carrying 1 CRITICAL"; } \
  && pass "verdict CLEAN over an open CRITICAL is itself a violation" \
  || fail "the verdict does not get to overrule the table above it"

# 14. structural mode softens WITHOUT --strict, exactly like every sibling structural validator
run "$d/project-analysis-report.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "ignored without --strict"; } \
  && pass "structural mode is advisory without --strict" \
  || fail "structural mode must match its siblings' exit contract"

# 15. invocation errors are exit 2, never a silent pass
run --strict "$T/does-not-exist.md"
[[ "$RC" == 2 ]] && pass "a missing file is exit 2 (invocation error)" || fail "missing file must be exit 2"
run --gate "$T/s13/project-analysis-report.md"
[[ "$RC" == 2 ]] && pass "--gate pointed at a file is exit 2" || fail "--gate needs a directory"

echo "── gate mode ────────────────────────────────────────────────────────────────"

# 16. THE GATE ITSELF — no report, and the tier requires one. Exits 1 WITHOUT --strict: a gate that
# only fires when asked politely is not a gate.
d="$T/g16"; P="$(mkproj "$d")"; gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "UNANALYZED_CORPUS.P1"; } \
  && pass "no analysis report at Build/6-epics → UNANALYZED_CORPUS.P1, exit 1 without --strict" \
  || fail "a P1 must exit 1 by default"

# 17. THE GRANDFATHER PATH — settled by the repo owner: loud, repeated, never a block. It does not
# escalate under --strict either, because --strict is where CI runs and "never a block" would stop
# being true there. The one place the exit contract bends, and it is stated in the validator.
touch "$P/.analysis-gate-grandfathered"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "ANALYSIS_GRANDFATHERED.P2"; } \
  && pass "marker present + no report → GRANDFATHERED.P2, non-blocking" \
  || fail "the grandfather marker must exempt, loudly"
run --strict --gate "$P"
[[ "$RC" == 0 ]] \
  && pass "the grandfather exemption does not escalate under --strict either" \
  || fail "'never a block' must hold in CI, which is where --strict runs"

# 18. THE EXEMPTION EXPIRES BY ITSELF. Nobody has to remember to delete the marker: the moment a
# v10.3 report lands, the marker is inert.
write_report "$P/project-analysis-report.md"
run --gate "$P"
{ echo "$OUT" | grep -q "the exemption has expired and the marker is inert"; } \
  && pass "a v10.3 report expires the marker without anyone deleting it" \
  || fail "the marker must go inert once the report exists"
rm -f "$P/.analysis-gate-grandfathered"

# 19. TIER — the mandate is deliberately tiered (AGENTS.md:37 forbids charging a 3-epic Build the
# Platform price). Below Build-with-4-epics the gate does not apply at all.
d="$T/g19"; P="$(mkproj "$d" 2)"; gitify "$d"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "does not reach this tier"; } \
  && pass "Build with 2 epics is below the mandate → gate not applicable" \
  || fail "the tiered mandate must not charge a small Build the Platform price"

# 20. Platform requires all seven lenses; a 3-lens roster is UNVERIFIED, non-blocking by default.
d="$T/g20"; P="$(mkproj "$d" 6 platform)"; write_report "$P/project-analysis-report.md"
python3 - "$P/project-analysis-report.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("play_level: build", "play_level: platform")
open(p, "w").write(s)
PY
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "requires 7 lens/lenses and the report declares 3"; } \
  && pass "Platform demands 7 lenses → DECORRELATION_UNVERIFIED.P2 at 3" \
  || fail "the Platform tier must require the full roster"
run --strict --gate "$P"
[[ "$RC" == 1 ]] \
  && pass "a P2 escalates to exit 1 under --strict" \
  || fail "--strict must escalate an ordinary P2"

# 21. FRESHNESS IS THE CONTENT PREDICATE. The report is stamped at a SHA and committed; then PRD.md
# moves. `analyzed_sha == HEAD` would still be false-fresh at the moment of stamping — the question
# is whether the corpus changed AFTER the proof.
d="$T/g21"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"; gitify "$d"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "freshness: fresh"; } \
  && pass "nothing moved after the report → fresh" \
  || fail "an untouched corpus must read fresh"
printf '# PRD\n\nnew requirement\n' > "$P/PRD.md"
git -C "$d" add -A >/dev/null 2>&1
git -C "$d" -c commit.gpgsign=false commit -qm "PRD moves after the analysis" >/dev/null 2>&1
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_STALE.P1"; } \
  && pass "PRD.md committed after the report → ANALYSIS_STALE.P1" \
  || fail "content freshness must catch a corpus that moved after the proof"

# 22. NO GIT HISTORY ⇒ unknown, never fresh.
d="$T/g22"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "freshness: UNKNOWN"; } \
  && pass "outside git, freshness is UNKNOWN and says so" \
  || fail "with no history the answer is unknown, never fresh"

# 23. AN OPEN CRITICAL BLOCKS. Deliberately NOT check-story-prereqs.sh:85's grep pipeline — that one
# requires a `[ ]` checkbox or `todo` on the same line and therefore cannot see a table row, which
# is the exact shape this template mandates.
d="$T/g23"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | boundary | CRITICAL |/' "$P/project-analysis-report.md"
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_CRITICAL_OPEN.P1"; } \
  && pass "a CRITICAL row with Status open → ANALYSIS_CRITICAL_OPEN.P1" \
  || fail "the open-CRITICAL predicate must read the TABLE"

# 24. resolved closes it
sed -i.bak 's/| L7 | confirmed | open |/| L7 | confirmed | resolved |/' "$P/project-analysis-report.md"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "no CRITICAL finding is open"; } \
  && pass "Status resolved closes the CRITICAL" \
  || fail "a resolved CRITICAL must not block"

# 25. A BLANK STATUS IS OPEN. `open | resolved | waived DEC-####` is the whole vocabulary, so
# anything else is not an escape — otherwise a status field closes findings by being vague.
sed -i.bak 's/| L7 | confirmed | resolved |/| L7 | confirmed |  |/' "$P/project-analysis-report.md"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_CRITICAL_OPEN.P1"; } \
  && pass "a blank Status on a CRITICAL row counts as open" \
  || fail "an unrecognised status must not close a CRITICAL"

# 26. A WAIVER IS AN ESCAPE ONLY IF THE DECISION IT CITES EXISTS.
sed -i.bak 's/| L7 | confirmed |  |/| L7 | confirmed | waived DEC-0042 |/' "$P/project-analysis-report.md"
printf '# Decisions\n\n## DEC-0042 — accepted for now\n' > "$P/project-decisions-log.md"
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "no CRITICAL finding is open"; } \
  && pass "waived DEC-0042, backed by the decisions log → closed" \
  || fail "a backed waiver must close the finding"
printf '# Decisions\n\n## DEC-0001 — something else\n' > "$P/project-decisions-log.md"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_CRITICAL_OPEN.P1"; } \
  && pass "a waiver citing a DEC the log does not carry is a claim, not a waiver" \
  || fail "an unbacked waiver must not close a CRITICAL"

# 27. THE MAPPING RULE APPLIES IN THE GATE TOO — an author cannot lower a contradiction to HIGH to
# walk past the block.
d="$T/g27"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | cross-artifact contradiction | HIGH |/' "$P/project-analysis-report.md"
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_CRITICAL_OPEN.P1"; } \
  && pass "a contradiction authored HIGH still blocks — severity is by rule" \
  || fail "the gate must apply the mapping rule, not the author's cell"

# 28. PROMISE COVERAGE IS READ FROM THE GRAPH, never re-grepped out of product-contract.md.
d="$T/g28"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak '/^| MM-2 second moment |/d' "$P/project-analysis-report.md"
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROMISE_UNCOVERED.P1" && echo "$OUT" | grep -q "MM-2"; } \
  && pass "an MM-N the graph knows and the matrix omits → PROMISE_UNCOVERED.P1" \
  || fail "the graph is the reader for MM-N/JOB-N completeness"

# 29. present-but-unresolved is the same finding — a row that names a gap is not coverage
d="$T/g29"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak 's/| MM-2 second moment | product-contract 5 | E002 \/ S004 | resolved |/| MM-2 second moment | product-contract 5 | none | open |/' "$P/project-analysis-report.md"
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "unresolved status"; } \
  && pass "an MM-N present with an open status → PROMISE_UNCOVERED.P1" \
  || fail "a gap row is a finding, not coverage"

# 29b. #108 — DIF-N PILLARS ARE GATED EXACTLY LIKE MM-N, once a contract declares one.
# v10.3 shipped this as a disclosed limit: §3 was free prose with no id, so the gate emitted
# "pillars: not evaluated" rather than claim a verdict it could not compute. The gradient is the
# safety property — a contract with no pillar is untouched, and declaring one opts in.
d="$T/g29b"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
printf '\n### DIF-1 — The wedge pillar\n' >> "$P/product-contract.md"
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROMISE_UNCOVERED.P1" && echo "$OUT" | grep -q "DIF-1"; } \
  && pass "a declared DIF-1 the matrix omits → PROMISE_UNCOVERED.P1, naming the pillar" \
  || fail "#108: declared pillars must reach the coverage gate"

# …and the contrapositive, which is the half that keeps the gradient honest: a contract that
# declares NO pillar must behave exactly as it did before #108. Otherwise the feature is a silent
# tax on every project that never asked for it.
d="$T/g29c"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"; gitify "$d"
run --gate "$P"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "PROMISE_UNCOVERED"; } \
  && pass "a contract declaring no pillar is untouched by #108 (no new finding, exit 0)" \
  || fail "#108 must not convict a project that declared no pillar"

# The mapping rule has to reach the new class too, or a pillar gap is whatever severity the author
# types — the exact discretion #106 removed for MM-N.
d="$T/g29d"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | unaddressed differentiator pillar | HIGH |/' "$P/project-analysis-report.md"
gitify "$d"
run --strict "$P/project-analysis-report.md"
{ echo "$OUT" | grep -qi "critical"; } \
  && pass "an 'unaddressed differentiator pillar' row is CRITICAL by rule, not by the author's cell" \
  || fail "#108: the severity mapping rule must cover pillars"

# 30. THE GRAPH DEGRADE IS HONEST, never a silent pass. A python3 that cannot build the graph
# yields ANALYSIS_COVERAGE_UNCOMPUTED.P2 — completeness was NOT computed.
d="$T/g30"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak '/^| MM-2 second moment |/d' "$P/project-analysis-report.md"
gitify "$d"
mkdir -p "$T/stub"
printf '#!/bin/sh\nexit 3\n' > "$T/stub/python3"; chmod +x "$T/stub/python3"
RC=0; OUT=$(PATH="$T/stub:$PATH" bash "$VAL" --gate "$P" 2>&1) || RC=$?
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "ANALYSIS_COVERAGE_UNCOMPUTED.P2" && ! echo "$OUT" | grep -q "PROMISE_UNCOVERED.P1"; } \
  && pass "an unreadable graph → COVERAGE_UNCOMPUTED.P2, and NO false PROMISE_UNCOVERED.P1" \
  || fail "when the graph cannot be read, completeness is unknown — never a pass and never a conviction"

# 31. A PRE-v10.3 REPORT IN A GATED PROJECT. It is NOT unanalyzed — saying so would be false — and
# its structure is exempt by the vintage rule, so what the gate reports is that decorrelation is
# unknown. Advisory by default.
d="$T/g31"; P="$(mkproj "$d")"; gitify "$d"
cat > "$P/project-analysis-report.md" <<'EOF'
# Project Analysis Report: Legacy

### ⚠️ Issues Found

| ID | Category | Severity | Description | Recommendation |
|----|----------|----------|-------------|----------------|
| P1 | Epic Overlap | HIGH | x | y |
EOF
run --gate "$P"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "ANALYSIS_DECORRELATION_UNVERIFIED.P2" && ! echo "$OUT" | grep -q "UNANALYZED_CORPUS.P1"; } \
  && pass "a pre-v10.3 report is unverified, not unanalyzed — and not blocking by default" \
  || fail "the gate must not claim a report that exists does not exist"

# 32. SELF-VERIFICATION IS THE SHAPE #106 EXISTS TO CATCH: a CRITICAL/HIGH row whose Verifier is the
# lens that raised it.
d="$T/g32"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
sed -i.bak 's/| Reconcile | L7 | confirmed | open |/| Reconcile | L6 | confirmed | open |/' "$P/project-analysis-report.md"
gitify "$d"
run --gate "$P"
{ echo "$OUT" | grep -q "ANALYSIS_DECORRELATION_UNVERIFIED.P2" && echo "$OUT" | grep -q "is the lens that raised it"; } \
  && pass "Verifier == the raising lens (read off the finding ID) → DECORRELATION_UNVERIFIED.P2" \
  || fail "a finding checked only by the party that found it is not decorrelated"

# 33. A BOUND REPORT WHOSE MANDATED TABLE IS UNREADABLE cannot report a pass. Validator-local code,
# outside the shared P-code set, and it escalates — a green here would report this gate's exposure
# rather than its verdict.
d="$T/g33"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
python3 - "$P/project-analysis-report.md" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r"### ⚠️ Issues Found\n(.|\n)*?\n### Promise Coverage", "### ⚠️ Issues Found\n\nNone found.\n\n### Promise Coverage", s, count=1)
open(p, "w").write(s)
PY
gitify "$d"
run --gate "$P"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_REPORT_MALFORMED.P1"; } \
  && pass "a v10.3 report with no readable findings table blocks rather than passing" \
  || fail "an un-evaluable predicate must never read as a pass"

# 34. EPIC ALTITUDE — the same implementation, the epic's own corpus for freshness, and promise
# coverage correctly scoped OUT (MM-N/JOB-N are project-global nodes).
d="$T/g34"; P="$(mkproj "$d")"
E="$P/epics/E001-thing"
printf '# Epic E001\n' > "$E/epic.md"
printf '# Tech spec\n' > "$E/epic-tech-spec.md"
printf '# Breakdown\n' > "$E/epic-breakdown.md"
write_report "$E/epic-analysis-report.md" epic-analysis-report
gitify "$d"
run --gate "$E"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "promise coverage is a project-level predicate"; } \
  && pass "an epic dir gates against the epic corpus, with promise coverage scoped out" \
  || fail "the epic altitude must reuse one implementation without manufacturing findings"

printf '# Epic E001\n\nrewritten\n' > "$E/epic.md"
git -C "$d" add -A >/dev/null 2>&1
git -C "$d" -c commit.gpgsign=false commit -qm "epic.md moves after its analysis" >/dev/null 2>&1
run --gate "$E"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_STALE.P1"; } \
  && pass "epic.md committed after the epic analysis → ANALYSIS_STALE.P1" \
  || fail "freshness must bind at the epic altitude too"

# 35. STORY ALTITUDE — Build requires one independent lens and Platform requires all three
# story lenses. This is the pre-implementation adversary that the old self-check did not provide.
d="$T/g35"; P="$(mkproj "$d" 2 build)"
S="$P/epics/E001-thing/stories/S001-ready"; mkdir -p "$S"
printf '# Spec\n\n**Status**: Specified\n' > "$S/spec.md"
printf '# Plan\n' > "$S/plan.md"
printf '%s\n' '---' 'status: pending' 'analysis_required: true' '---' '# Tasks' > "$S/tasks.md"
write_report "$S/story-analysis-report.md" story-analysis-report
gitify "$d"
run --gate "$S"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "Analysis gate (#106) — story"; } \
  && pass "Build story with a bound independent analysis clears" \
  || fail "story directories must route to story analysis rather than epic analysis"

d="$T/g35b"; P="$(mkproj "$d" 2 build)"
S="$P/epics/E001-thing/stories/S001-missing"; mkdir -p "$S"
printf '# Spec\n' > "$S/spec.md"; printf '# Plan\n' > "$S/plan.md"; printf '# Tasks\n' > "$S/tasks.md"
gitify "$d"
run --gate "$S"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "UNANALYZED_CORPUS.P1"; } \
  && pass "Build story without story-analysis-report.md is blocked" \
  || fail "the restored story analysis capability must be structural"

d="$T/g35c"; P="$(mkproj "$d" 2 platform)"
S="$P/epics/E001-thing/stories/S001-platform"; mkdir -p "$S"
printf '# Spec\n' > "$S/spec.md"; printf '# Plan\n' > "$S/plan.md"; printf '# Tasks\n' > "$S/tasks.md"
write_report "$S/story-analysis-report.md" story-analysis-report
python3 - "$S/story-analysis-report.md" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("play_level: build", "play_level: platform")
s = re.sub(r"  - id: L6\n(?:    .*\n){3}", "", s, count=1)
s = re.sub(r"  - id: L7\n(?:    .*\n){3}", "", s, count=1)
open(p, "w").write(s)
PY
gitify "$d"
run --gate "$S"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "ANALYSIS_DECORRELATION_MISSING.P1"; } \
  && pass "Platform story with fewer than three lenses is blocked" \
  || fail "Platform story analysis must require three independent lenses"

echo "── mutation proofs (each assertion, proven red against a reverted copy) ──────"

# The mutation harness: a SCRATCH COPY of the validator with one fix reverted, run through
# SPECK_VALIDATOR_UNDER_TEST. An assertion that stays green against the mutant is an assertion that
# was never testing its fix — this repo's own Mutation Record discipline, applied to a validator.
MUT="$T/mut/.speck/scripts/validation/validators"
mkdir -p "$MUT" "$T/mut/.speck/scripts/lib" "$T/mut/.speck/scripts/graph"
cp "$ROOT/.speck/scripts/lib/text.sh" "$T/mut/.speck/scripts/lib/text.sh"
cp "$ROOT/.speck/scripts/graph/speck_graph.py" "$T/mut/.speck/scripts/graph/speck_graph.py"

# A mutation that cannot be APPLIED fails LOUDLY, never skips. A skipped mutation proof is the exact
# shape this repo names a green that reports its exposure rather than its verdict: the four proofs
# below would print nothing at all and the suite would still end on "all tests passed".
MUTANT=""
mutate() { # <name> <old-literal> <new-literal>
  local name out rc
  name="$1"
  out="$MUT/$name.sh"
  MUTANT=""
  cp "$VAL" "$out"
  OLD="$2" NEW="$3" python3 "$MUT_APPLY" "$out"
  rc=$?
  if [[ "$rc" != 0 ]]; then
    echo "  ✗ mutation '$name' could not be applied — the code it targets has moved, so its proof is vacuous"
    FAILED=1
    return 1
  fi
  if cmp -s "$VAL" "$out"; then
    echo "  ✗ mutation '$name' produced an IDENTICAL file — nothing was reverted"
    FAILED=1
    return 1
  fi
  MUTANT="$out"
  return 0
}

MUT_APPLY="$T/apply-mutation.py"
cat > "$MUT_APPLY" <<'MUTPY'
import os, sys
path = sys.argv[1]
old, new = os.environ["OLD"], os.environ["NEW"]
s = open(path).read()
if old not in s:
    sys.stderr.write("MUTATION TARGET NOT FOUND: %r\n" % old[:80])
    sys.exit(9)
open(path, "w").write(s.replace(old, new, 1))
MUTPY

# M1 — revert the severity MAPPING RULE to plain author discretion. Test 27 must go red: the
# contradiction graded HIGH walks straight through, which is 13 of the 14 motivating defects.
if mutate m1 \
  "    *contradict*) printf 'critical'; return 0 ;;" \
  "    *zzz-never-matches*) printf 'critical'; return 0 ;;"; then
  d="$T/m1"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
  sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | cross-artifact contradiction | HIGH |/' "$P/project-analysis-report.md"
  gitify "$d"
  run_with "$MUTANT" --gate "$P"
  { [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "ANALYSIS_CRITICAL_OPEN.P1"; } \
    && pass "M1: reverting the mapping rule turns test 27 red (the HIGH-graded contradiction walks)" \
    || fail "M1: test 27 stayed green against a validator with the mapping rule removed — it was not testing it"
fi

# M2 — revert "an unrecognised status is open" to "an unrecognised status is closed". Test 25 must
# go red: a blank cell would close a CRITICAL.
if mutate m2 \
  "    *)                        printf 'unknown' ;;" \
  "    *)                        printf 'resolved' ;;"; then
  d="$T/m2"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
  sed -i.bak 's/| L6-1 | cross-artifact-drift | HIGH |/| L6-1 | boundary | CRITICAL |/' "$P/project-analysis-report.md"
  sed -i.bak 's/| L7 | confirmed | open |/| L7 | confirmed |  |/' "$P/project-analysis-report.md"
  gitify "$d"
  run_with "$MUTANT" --gate "$P"
  { [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "ANALYSIS_CRITICAL_OPEN.P1"; } \
    && pass "M2: treating an unrecognised status as closed turns test 25 red" \
    || fail "M2: test 25 stayed green against a validator that closes findings by vagueness"
fi

# M3 — revert the exit contract to "a P1 blocks only under --strict". Test 16 must go red: that is
# precisely the difference between a gate and a report.
if mutate m3 \
  '  if [[ "$p1" -gt 0 ]]; then' \
  '  if [[ "$p1" -gt 0 && "$strict" == true ]]; then'; then
  d="$T/m3"; P="$(mkproj "$d")"; gitify "$d"
  run_with "$MUTANT" --gate "$P"
  [[ "$RC" == 0 ]] \
    && pass "M3: making P1 depend on --strict turns test 16 red (a gate that only fires when asked)" \
    || fail "M3: test 16 stayed green against a validator whose P1 does not block by default"
fi

# M4 — revert the graph degrade from an honest unknown to a silent pass. Test 30 must go red.
if mutate m4 \
  '    emit_p2 "ANALYSIS_COVERAGE_UNCOMPUTED.P2" "'"'"'speck_graph.py build' \
  '    emit_note "coverage computed fine ('"'"'speck_graph.py build'; then
  d="$T/m4"; P="$(mkproj "$d")"; write_report "$P/project-analysis-report.md"
  sed -i.bak '/^| MM-2 second moment |/d' "$P/project-analysis-report.md"
  gitify "$d"
  RC=0; OUT=$(PATH="$T/stub:$PATH" bash "$MUTANT" --gate "$P" 2>&1) || RC=$?
  { ! echo "$OUT" | grep -q "ANALYSIS_COVERAGE_UNCOMPUTED.P2"; } \
    && pass "M4: a graph reader that degrades to a note turns test 30 red" \
    || fail "M4: test 30 stayed green against a validator that reports an unknown as fine"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ validate-project-analysis: all tests passed"
else
  echo "❌ validate-project-analysis: FAILURES"
  exit 1
fi
