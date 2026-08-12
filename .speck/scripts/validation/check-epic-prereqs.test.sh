#!/usr/bin/env bash
# check-epic-prereqs.test.sh — tests for the epic-altitude analysis gate (issue #106)

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
# SPECK_VALIDATOR_UNDER_TEST is the mutation-harness hook: point it at a SCRATCH COPY of the gate to
# confirm a given assertion actually goes red when its fix is reverted. Unset in every normal run
# (npm test, CI, a developer's shell), where it resolves to the shipped gate.
VAL="${SPECK_VALIDATOR_UNDER_TEST:-$ROOT/.speck/scripts/validation/check-epic-prereqs.sh}"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "${OUT:-}"; echo "------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# ── fixtures ─────────────────────────────────────────────────────────────────────────────────────
#
# Every case runs the REAL gate inside a throwaway workspace. The copy is not decoration: the gate
# resolves its delegate from its OWN directory (never from an environment variable — an
# env-overridable validator path is a gate with an off switch), so a stub is only reachable if the
# gate is standing next to it. Copying $VAL also means the mutation hook is genuinely exercised.

# mkws <name> [play_level] — a workspace wired the way `speck upgrade` leaves .speck/scripts/.
# Omitting play_level omits .speck/project.json entirely, which is the Speck repo's own shape.
mkws() {
  local name="$1" level="${2-}"
  local ws="$T/$name"
  mkdir -p "$ws/.speck/scripts/validation/validators" "$ws/.speck/scripts/lib"
  cp "$VAL" "$ws/.speck/scripts/validation/check-epic-prereqs.sh"
  cp "$ROOT/.speck/scripts/lib/text.sh" "$ws/.speck/scripts/lib/text.sh"
  printf '10.3.0\n' > "$ws/.speck/VERSION"
  if [[ -n "$level" ]]; then
    printf '{\n  "play_level": "%s",\n  "speck_version": "10.3.0"\n}\n' "$level" > "$ws/.speck/project.json"
  fi
  printf '%s' "$ws"
}

# mkproj <ws> <id> — a project that has evidently been through /project-plan.
mkproj() {
  local p="$1/specs/projects/$2"
  mkdir -p "$p"
  printf '# PRD\n' > "$p/PRD.md"
  printf '%s' "$p"
}

# add_epics_md <proj> <n> — n epic headings in the canonical `### E###:` shape.
add_epics_md() {
  local p="$1" n="$2" i
  {
    echo "# Epics"
    echo ""
    echo "### MVP Epics (Must Have)"
    for (( i=1; i<=n; i++ )); do printf '### E%03d: Epic %d\n' "$i" "$i"; done
  } > "$p/epics.md"
}

# add_epic_dirs <proj> <n> [prefix] — n scaffolded epic dirs. Default prefix is the ORDINAL naming
# ("001-name"), the form AGENTS.md records as "many repos use" and the form a naive `E*` glob misses.
add_epic_dirs() {
  local p="$1" n="$2" prefix="${3-}" i
  for (( i=1; i<=n; i++ )); do
    mkdir -p "$(printf '%s/epics/%s%03d-epic%d' "$p" "$prefix" "$i" "$i")"
  done
}

# install_stub <ws> <mode> — stand a fake validate-project-analysis.sh next to the gate. Every stub
# records its argv so forwarding can be asserted on what the delegate actually RECEIVED.
# Modes: clear (exit 0) · block (prints a green line, then a P1, exit 1) · crash (exit 2).
install_stub() {
  local ws="$1" mode="$2"
  local f="$ws/.speck/scripts/validation/validators/validate-project-analysis.sh"
  {
    echo '#!/usr/bin/env bash'
    echo "printf '%s\\n' \"\$*\" > \"$ws/stub-argv.txt\""
    case "$mode" in
      clear)
        echo 'echo "project-analysis: no findings"'
        echo 'exit 0' ;;
      block)
        # The green line is the point: it reproduces the validate-template.sh:504-515 scar, where a
        # sub-check's own "✅ Validation PASSED" sat directly above a blocking finding and the last
        # words on the log said the opposite of the exit code.
        echo 'echo "✅ Validation PASSED"'
        echo 'echo "UNANALYZED_CORPUS.P1  no project-analysis-report.md"'
        echo 'exit 1' ;;
      crash)
        echo 'echo "ERROR: bad invocation" >&2'
        echo 'exit 2' ;;
    esac
  } > "$f"
  chmod +x "$f"
}

run() { RC=0; OUT=$(bash "$WS/.speck/scripts/validation/check-epic-prereqs.sh" "$@" 2>&1) || RC=$?; }

# First line number matching a pattern, 0 when absent. No pipe: `grep -n | head -1` SIGPIPEs its
# producer under pipefail, which is the sp_head scar text.sh exists for.
line_of() { awk -v pat="$1" '$0 ~ pat { if (!n) n = NR } END { print n + 0 }' <<<"$2"; }

# ── 1. applicability is COMPUTED, and a below-threshold Build SAYS SO ────────────────────────────
# The blocking stub is installed deliberately: if applicability were decided anywhere but before the
# delegation, this case would be rejected. "Not applicable" must also never be silent — a gate that
# quietly decides it does not apply is indistinguishable from one that ran and found nothing.
WS="$(mkws build3 build)"; P="$(mkproj "$WS" 001-small)"
add_epics_md "$P" 3
install_stub "$WS" block
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "NOT APPLICABLE" <<<"$OUT" \
  && grep -q "epic count: 3" <<<"$OUT" \
  && ! grep -q "GATE REJECTED" <<<"$OUT"; } \
  && pass "Build with 3 epics → not applicable, printed explicitly, delegate never consulted" \
  || fail "a 3-epic Build must exit 0 and SAY it is not applicable"

# ── 2. the 4+-epic threshold, read out of epics.md ───────────────────────────────────────────────
WS="$(mkws build4 build)"; P="$(mkproj "$WS" 001-four)"
add_epics_md "$P" 4
install_stub "$WS" clear
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "APPLICABLE (build with 4 epics" <<<"$OUT" \
  && [[ -f "$WS/stub-argv.txt" ]]; } \
  && pass "Build with 4 epics → applicable, and the analysis gate is actually invoked" \
  || fail "4 epics must cross the threshold and reach the delegate"

# ── 3. the count survives a project whose epics.md has not been written yet ──────────────────────
# The MAX exists for the window between /project-plan and scaffolding, and for the ORDINAL dir
# naming: a glob of `E*` alone counts an `001-epic` repo as zero, which switches the gate off with
# no trace anywhere.
WS="$(mkws dirs4 build)"; P="$(mkproj "$WS" 001-scaffolded)"
add_epic_dirs "$P" 4
install_stub "$WS" clear
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "epics.md headings: 0, epics/ dirs: 4" <<<"$OUT" \
  && grep -q "APPLICABLE (build with 4 epics" <<<"$OUT"; } \
  && pass "no epics.md + 4 ordinal epic dirs → applicable (dirs counted, ordinal naming included)" \
  || fail "an unwritten epics.md must not under-count a scaffolded project to zero"

# ── 4. MAX, not first-non-zero ───────────────────────────────────────────────────────────────────
WS="$(mkws max build)"; P="$(mkproj "$WS" 001-mixed)"
add_epics_md "$P" 1
add_epic_dirs "$P" 4 E
install_stub "$WS" clear
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "epics.md headings: 1, epics/ dirs: 4 — MAX taken" <<<"$OUT" \
  && grep -q "APPLICABLE (build with 4 epics" <<<"$OUT"; } \
  && pass "a stale 1-epic epics.md beside 4 epic dirs resolves to 4 (MAX, not the first reading)" \
  || fail "the epic count must be the MAX of both measurements"

# ── 5. Platform applies at any size ──────────────────────────────────────────────────────────────
WS="$(mkws plat platform)"; P="$(mkproj "$WS" 001-plat)"
add_epics_md "$P" 1
install_stub "$WS" clear
run "$P"
{ [[ "$RC" == 0 ]] && grep -q "APPLICABLE (play_level is Platform" <<<"$OUT"; } \
  && pass "Platform with 1 epic → applicable (the level decides, not the count)" \
  || fail "Platform must be applicable regardless of epic count"

# ── 6. a workspace with NO .speck/project.json ───────────────────────────────────────────────────
# Speck's documented back-compat (.speck/README.md:187) is "no project.json = treated as Platform",
# and it is also the safe direction: an unknown play level makes the gate RUN rather than vanish.
# This is the Speck repo's own shape, so it is the normal path and not an edge case.
WS="$(mkws nopj)"; P="$(mkproj "$WS" 001-nopj)"
add_epics_md "$P" 1
install_stub "$WS" clear
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "play_level: platform" <<<"$OUT" \
  && grep -q "no .speck/project.json found" <<<"$OUT" \
  && grep -q "APPLICABLE (play_level is Platform" <<<"$OUT"; } \
  && pass "missing project.json → Platform back-compat, applicable, and the default is NAMED" \
  || fail "an absent project.json must default to Platform and say where the level came from"

# ── 7. the grandfather marker is a loud NOTICE, never a block ────────────────────────────────────
WS="$(mkws gf build)"; P="$(mkproj "$WS" 001-legacy)"
add_epics_md "$P" 5
install_stub "$WS" clear
cat > "$P/.analysis-gate-grandfathered" <<'EOF'
speck_version: 10.3.0
reason: planned before the v10.3 project-analysis gate existed
clears_with: /analyze --level project specs/projects/001-legacy
EOF
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "GRANDFATHERED" <<<"$OUT" \
  && grep -q "clears_with: /analyze --level project" <<<"$OUT" \
  && grep -q "repeats on every run" <<<"$OUT"; } \
  && pass "grandfathered project → loud repeated notice with the marker's own contents, exit 0" \
  || fail "the grandfather marker must print a repeated notice and never block"

# ── 8. NON-SHORT-CIRCUIT: a blocking delegate must not swallow the earlier steps or the verdict ──
# The scar (validate-template.sh:466-517): under `set -e` a sequential pair makes the second check
# unreachable whenever the first aborts, and a sub-check's own green line becomes the last word on
# the log. Reverting the `|| gate_rc=$?` capture kills the run at the delegate — RC is still 1, so
# an exit-code-only assertion would stay green. What goes red is the OUTPUT: no final verdict, and
# the stub's "✅ Validation PASSED" left as the tail.
WS="$(mkws nosc build)"; P="$(mkproj "$WS" 001-block)"
add_epics_md "$P" 6
install_stub "$WS" block
cat > "$P/.analysis-gate-grandfathered" <<'EOF'
speck_version: 10.3.0
reason: planned before the v10.3 project-analysis gate existed
EOF
run "$P"
step0_ln="$(line_of "Step 0 — applicability" "$OUT")"
marker_ln="$(line_of "GRANDFATHERED" "$OUT")"
green_ln="$(line_of "Validation PASSED" "$OUT")"
verdict_ln="$(line_of "GATE REJECTED" "$OUT")"
{ [[ "$RC" == 1 ]] \
  && [[ "$step0_ln" -gt 0 && "$marker_ln" -gt 0 && "$green_ln" -gt 0 && "$verdict_ln" -gt 0 ]] \
  && [[ "$verdict_ln" -gt "$green_ln" ]] \
  && ! grep -q "PREREQUISITE GATES PASSED" <<<"$OUT"; } \
  && pass "a blocking delegate still leaves Step 0 + the marker notice printed, and the verdict LAST" \
  || fail "the steps must not short-circuit, and no green may sit below the block"

# ── 9. a MISSING delegate is an unevaluated gate, never a pass ───────────────────────────────────
# The two scripts ship together in .speck/scripts/, so absence means an incomplete sync or a deleted
# gate. Reporting "could not run" as "found nothing" is the reporting defect #106 is about.
WS="$(mkws nodelegate platform)"; P="$(mkproj "$WS" 001-nodel)"
add_epics_md "$P" 1
run "$P"
{ [[ "$RC" == 1 ]] \
  && grep -q "could NOT be evaluated" <<<"$OUT" \
  && grep -q "GATE REJECTED" <<<"$OUT"; } \
  && pass "validate-project-analysis.sh missing → exit 1, explicitly unevaluated" \
  || fail "a missing delegate must not read as a clean corpus"

# ── 10. a delegate that never reached a verdict is not clean either ──────────────────────────────
WS="$(mkws crash platform)"; P="$(mkproj "$WS" 001-crash)"
add_epics_md "$P" 1
install_stub "$WS" crash
run "$P"
{ [[ "$RC" == 1 ]] && grep -q "NOT counted as clean" <<<"$OUT"; } \
  && pass "delegate exit 2 (invocation error) → exit 1, NOT counted as clean" \
  || fail "an exit-2 delegate must fail closed"

# ── 11. --strict is forwarded, and absent when not asked for ─────────────────────────────────────
WS="$(mkws strictfw platform)"; P="$(mkproj "$WS" 001-strict)"
add_epics_md "$P" 1
install_stub "$WS" clear
run --strict "$P"
argv_strict="$(cat "$WS/stub-argv.txt" 2>/dev/null || true)"
rm -f "$WS/stub-argv.txt"
run "$P"
argv_plain="$(cat "$WS/stub-argv.txt" 2>/dev/null || true)"
{ [[ "$argv_strict" == *"--strict"* ]] \
  && [[ "$argv_strict" == *"--gate"* && "$argv_strict" == *"$P"* ]] \
  && [[ "$argv_plain" != *"--strict"* ]] \
  && [[ "$argv_plain" == *"--gate"* && "$argv_plain" == *"$P"* ]]; } \
  && pass "--gate <PROJECT_DIR> always forwarded; --strict forwarded only when asked for" \
  || fail "delegate argv wrong: strict=[$argv_strict] plain=[$argv_plain]"

# ── 12. a spent marker is named rather than left as a silent re-exemption ────────────────────────
# Marker + report on disk together: delete the report later and the marker quietly exempts the
# project again. Still not a block — the grandfather lane never blocks, by decision.
WS="$(mkws spent build)"; P="$(mkproj "$WS" 001-spent)"
add_epics_md "$P" 4
install_stub "$WS" clear
printf 'speck_version: 10.3.0\n' > "$P/.analysis-gate-grandfathered"
printf '# Analysis\n' > "$P/project-analysis-report.md"
run "$P"
{ [[ "$RC" == 0 ]] \
  && grep -q "exemption is spent" <<<"$OUT" \
  && grep -q "rm $P/.analysis-gate-grandfathered" <<<"$OUT"; } \
  && pass "marker + report both present → the spent marker is called out with its rm command" \
  || fail "a spent grandfather marker must be surfaced, not left to re-exempt silently"

# ── 13. --epic scopes the report ─────────────────────────────────────────────────────────────────
WS="$(mkws epicarg platform)"; P="$(mkproj "$WS" 001-epicarg)"
add_epics_md "$P" 1
install_stub "$WS" clear
run "$P" --epic E003
{ [[ "$RC" == 0 ]] && grep -q "specifying epic E003" <<<"$OUT" && grep -q "clear to specify epic E003" <<<"$OUT"; } \
  && pass "--epic is reported in the header and the verdict" \
  || fail "--epic must scope the report"

# ── 14. the invocation contract: exit 2, never 0 and never 1 ─────────────────────────────────────
# Exit 2 is what keeps an operator error distinguishable from a rejected gate; collapsing it into 1
# would make a typo look like a finding, and into 0 would make it look like a pass.
WS="$(mkws args platform)"; P="$(mkproj "$WS" 001-args)"
add_epics_md "$P" 1
install_stub "$WS" clear
bad=0
run;                        [[ "$RC" == 2 ]] || bad=1   # no PROJECT_DIR
run "$WS/specs/projects/nope"; [[ "$RC" == 2 ]] || bad=1   # dir does not exist
run "$P" --epic;            [[ "$RC" == 2 ]] || bad=1   # --epic with no value
run "$P" --epic --strict;   [[ "$RC" == 2 ]] || bad=1   # --epic swallowing the next flag
run "$P" --bogus;           [[ "$RC" == 2 ]] || bad=1   # unknown option
run "$P" "$P";              [[ "$RC" == 2 ]] || bad=1   # two positionals
[[ "$bad" == 0 ]] \
  && pass "every invocation error exits 2 (distinct from 1 = gate rejected, 0 = clear)" \
  || fail "an invocation error must exit 2"

# ── 15. THE DRIFT GUARD: both epic counters must agree ───────────────────────────────────────────
# This gate and validate-project-analysis.sh EACH compute the epic count, and for one release they
# disagreed. This script took the MAX of epics.md headings and epics/ dirs; the validator returned
# the directory count whenever it was non-zero and consulted epics.md only as a fallback. A project
# with 4 planned epics and its first epic dir scaffolded — the single most common state a project is
# ever in — therefore read 4 here (APPLICABLE) and 1 there (not applicable), and the validator's
# answer is the one that decides. The whole #106 gate was inert, and an inert gate and a satisfied
# gate print the same exit code.
#
# The duplication is the real defect; this assertion is what holds it closed until one of them is
# deleted. It runs the two scripts against ONE fixture and compares the numbers they print, so a
# future edit to either counter fails here rather than in a project six months from now.
WS="$(mkws drift build)"; P="$(mkproj "$WS" 001-drift)"
add_epics_md "$P" 4                 # 4 headings in epics.md…
mkdir -p "$P/epics/E001"            # …and exactly one scaffolded dir. MAX must win: 4.
install_stub "$WS" clear
run "$P"
gate_n="$(printf '%s' "$OUT" | grep -oE 'epic count: [0-9]+' | grep -oE '[0-9]+' | head -1)"
val_n="$(bash "$ROOT/.speck/scripts/validation/validators/validate-project-analysis.sh" --gate "$P" 2>&1 \
  | grep -oE 'epics: [0-9]+' | grep -oE '[0-9]+' | head -1)"
{ [[ "$gate_n" == 4 && "$val_n" == 4 ]]; } \
  && pass "both epic counters take the MAX and agree (4 headings + 1 dir → 4, 4)" \
  || fail "epic-count drift: check-epic-prereqs says '${gate_n:-?}', validate-project-analysis says '${val_n:-?}' (both must be 4)"

if [[ "$FAILED" == 0 ]]; then echo "✅ check-epic-prereqs: all tests passed"; else echo "❌ check-epic-prereqs: FAILURES"; exit 1; fi
