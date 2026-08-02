#!/usr/bin/env bash
# gate-liveness-probe.test.sh — hostile harness for the gate-liveness canary probe (#88 Phase 2).
#
# Each case builds a throwaway git repo (the probe checks out HEAD into a worktree, so fixtures MUST
# be committed) with a §6a registry, a §7 banned term, product surfaces, and a STUB gate whose
# behavior we control precisely. Proves: LIVE, DISARMED, DISARMED scope-hole (#85 shape),
# UNVERIFIED (unknown-key / baseline-red / red-unattributable / unsafe-to-probe), staged-mutation LIVE,
# real-PATH preserved, and INVARIANT-ZERO ($ROOT untouched + no .git/config write).

set -uo pipefail

ROOT_REPO="$(cd "$(dirname "$0")/../../../../" && pwd)"
# SPECK_PROBE_UNDER_TEST is the mutation-harness hook: point it at a SCRATCH COPY of the probe to
# confirm a given assertion actually goes red when its fix is reverted. Unset in every normal run
# (npm test, CI, a developer's shell), where it resolves to the shipped probe. The copy must live in
# a validators/ dir whose siblings resolve — the probe sources canary-lib.sh and text.sh by relative
# path — which is what makes this a hook rather than a free-floating path argument.
PROBE="${SPECK_PROBE_UNDER_TEST:-$ROOT_REPO/.speck/scripts/validation/validators/gate-liveness-probe.sh}"
PASS=0

fail() { echo "  ✗ $1"; echo "----- probe output -----"; echo "${2:-}"; echo "------------------------"; exit 1; }
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }

# scaffold a fixture repo: $1=dir. Writes contract(§6a+§7), a src/.tsx surface, commits. Caller adds gate.
scaffold() {
  local d="$1"
  mkdir -p "$d/specs/projects/001-x" "$d/src"
  git -C "$d" init -q
  git -C "$d" config user.email t@t.co; git -C "$d" config user.name t
  cat > "$d/specs/projects/001-x/product-contract.md" <<'EOF'
# Product Contract

## 7. Banned Language / System Anti-Patterns

- Never say `frobnicate` in a user-visible surface.
EOF
  printf 'export const App = () => <div>hello</div>\n' > "$d/src/App.tsx"
}

commit() { git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m init >/dev/null 2>&1; }

# write a §6a registry with a single gate row. $1=dir $2=command $3=domain $4=canary
registry() {
  cat > "$1/specs/projects/001-x/evidence-contract.md" <<EOF
# Evidence Contract

### 6a. CI-Enforced Gate Registry

| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |
|---------|------------------|-------|--------|--------|--------|
| test-gate | $2 | pre-commit | $3 | $4 | — |
EOF
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" 2>/dev/null || true' EXIT

# ---------------------------------------------------------------------------------------------------
echo "Test 1: LIVE — a healthy banned-language gate goes red naming the injected term"
D="$TMP/t1"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# healthy: scan the product surface for the banned term
if grep -rIn "frobnicate" src 2>/dev/null | grep -q .; then exit 1; fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "GATE_LIVE.*test-gate" || fail "expected GATE_LIVE" "$OUT"
ok "LIVE detected"

# ---------------------------------------------------------------------------------------------------
echo "Test 2: DISARMED.P1 — a dark gate stays green over the injected defect"
D="$TMP/t2"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
exit 0   # dark: never scans anything
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
if OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"; then
  fail "expected --strict to exit 1 on DISARMED" "$OUT"
fi
echo "$OUT" | grep -q "GATE_DISARMED.P1.*test-gate" || fail "expected GATE_DISARMED.P1" "$OUT"
ok "DISARMED detected + --strict blocks"

# ---------------------------------------------------------------------------------------------------
echo "Test 3: DISARMED scope-hole (#85 shape) — gate scans .tsx but not .astro"
D="$TMP/t3"; scaffold "$D"
printf '<div>hello</div>\n' > "$D/src/Page.astro"   # a second surface class
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# scans ONLY .tsx (the #85 allowlist bug) — .astro is dark
if grep -rIn --include='*.tsx' "frobnicate" src 2>/dev/null; then exit 1; fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "GATE_DISARMED.P1" || fail "expected DISARMED for the dark .astro surface" "$OUT"
echo "$OUT" | grep -q "astro" || fail "expected the dark surface to be named (astro)" "$OUT"
ok "scope-hole caught + dark surface named"

# ---------------------------------------------------------------------------------------------------
echo "Test 4: UNVERIFIED — unknown canary key"
D="$TMP/t4"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "no-such-canary"; commit "$D"
OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"   # must NOT exit 1 (unverified, not disarmed)
echo "$OUT" | grep -q "GATE_LIVENESS_UNVERIFIED.P2.*unknown canary key" || fail "expected unknown-key UNVERIFIED" "$OUT"
ok "unknown key → UNVERIFIED (not a P1)"

# ---------------------------------------------------------------------------------------------------
echo "Test 5: UNVERIFIED — baseline not green (cannot establish green→red)"
D="$TMP/t5"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "always broken"; exit 1
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "GATE_LIVENESS_UNVERIFIED.P2.*baseline not green" || fail "expected baseline-not-green UNVERIFIED" "$OUT"
ok "baseline-red → UNVERIFIED"

# ---------------------------------------------------------------------------------------------------
echo "Test 6: UNVERIFIED — red for an unattributable reason (not the injected term)"
D="$TMP/t6"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# green at baseline; goes red on ANY new canary file but never names the term (unattributable)
if ls src/__speck_canary__* >/dev/null 2>&1; then echo "some unrelated compile error"; exit 1; fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "GATE_LIVENESS_UNVERIFIED.P2.*red-unattributable" || fail "expected red-unattributable UNVERIFIED" "$OUT"
ok "red-without-fingerprint → UNVERIFIED (never DISARMED)"

# ---------------------------------------------------------------------------------------------------
echo "Test 7: UNVERIFIED — destructive invocation is never executed"
D="$TMP/t7"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "DESTRUCTIVE_GATE_RAN" > "$PWD/.destructive-ran"   # if this ever runs, the sentinel appears
exit 0
EOF
registry "$D" "bash gate.sh deploy --prod" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "unsafe-to-probe" || fail "expected unsafe-to-probe UNVERIFIED" "$OUT"
[[ -z "$(find "$TMP" -name .destructive-ran 2>/dev/null)" ]] || fail "destructive gate WAS executed (sentinel found)" "$OUT"
ok "destructive gate refused + never executed"

# ---------------------------------------------------------------------------------------------------
echo "Test 8: staged-mutation LIVE — a gate that scans only git-staged files still catches the canary"
D="$TMP/t8"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# only inspects staged files (like a --staged pre-commit gate)
files="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)"
[[ -z "$files" ]] && exit 0
if echo "$files" | xargs grep -In "frobnicate" 2>/dev/null | grep -q .; then exit 1; fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "GATE_LIVE.*test-gate" || fail "expected staged-scanning gate to be LIVE (STAGE_IT)" "$OUT"
ok "staged mutation observed → LIVE"

# ---------------------------------------------------------------------------------------------------
echo "Test 9: INVARIANT-ZERO — the real tree + .git/config are byte-identical after a run"
D="$TMP/t9"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
if grep -rIn "frobnicate" src 2>/dev/null; then exit 1; fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
CFG_BEFORE="$(openssl md5 < "$D/.git/config" 2>/dev/null | awk '{print $NF}')"
bash "$PROBE" "$D/specs/projects/001-x" >/dev/null 2>&1
PORCELAIN="$(git -C "$D" status --porcelain)"
CFG_AFTER="$(openssl md5 < "$D/.git/config" 2>/dev/null | awk '{print $NF}')"
WORKTREES="$(git -C "$D" worktree list 2>/dev/null | wc -l | tr -d ' ')"
[[ -z "$PORCELAIN" ]] || fail "real tree dirty after probe: $PORCELAIN" ""
[[ "$CFG_BEFORE" == "$CFG_AFTER" ]] || fail "the probe wrote .git/config (hooksPath leak)" ""
[[ "$WORKTREES" == "1" ]] || fail "probe leaked a worktree ($WORKTREES listed)" ""
ok "INVARIANT-ZERO held (clean tree, config untouched, no leaked worktree)"

# ---------------------------------------------------------------------------------------------------
echo "Test 10: real PATH preserved — a gate whose subprocess needs a PATH tool isn't false-DISARMED"
if command -v python3 >/dev/null 2>&1; then
  D="$TMP/t10"; scaffold "$D"
  cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# detects the term via a python3 subprocess — fails to find it (green) if PATH were blanked
hit="$(python3 - <<'PY'
import os,glob
found=False
for f in glob.glob('src/**/*', recursive=True):
    try:
        if 'frobnicate' in open(f, encoding='utf-8', errors='ignore').read(): print(f); found=True
    except Exception: pass
PY
)"
[[ -n "$hit" ]] && { echo "frobnicate in $hit"; exit 1; }
exit 0
EOF
  registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
  OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
  echo "$OUT" | grep -q "GATE_LIVE.*test-gate" || fail "expected LIVE (python3-subprocess gate) — PATH must be preserved" "$OUT"
  ok "real PATH preserved (python3-subprocess gate LIVE)"
else
  echo "  ⊘ Skipped Test 10 (python3 not available)"
fi

# ---------------------------------------------------------------------------------------------------
echo "Test 11: destructive SEE-THROUGH — a wrapper script whose BODY deploys is refused + never run"
D="$TMP/t11"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo RAN > "$PWD/.wrapper-ran"   # sentinel: if this body ever executes, it appears
vercel deploy --prod
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "unsafe-to-probe" || fail "expected see-through unsafe-to-probe" "$OUT"
[[ -z "$(find "$TMP" -name .wrapper-ran 2>/dev/null)" ]] || fail "wrapper body with a deploy WAS executed" "$OUT"
ok "destructive wrapper body seen through + never executed"

# ---------------------------------------------------------------------------------------------------
echo "Test 12: opaque/unknown command family is refused (fail-closed), not executed"
D="$TMP/t12"; scaffold "$D"
registry "$D" "sed -n 1p src/App.tsx" "copy" "banned-language"; commit "$D"   # sed: resolvable but not a probe-safe tool
OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"   # must NOT exit 1 (unverified, not disarmed)
echo "$OUT" | grep -q "not recognized as probe-safe" || fail "expected unknown-command fail-closed UNVERIFIED" "$OUT"
ok "unrecognized command → UNVERIFIED (fail-closed)"

# ---------------------------------------------------------------------------------------------------
echo "Test 13: cl_digest never collapses to a constant (INVARIANT-ZERO can't fail open)"
. "$ROOT_REPO/.speck/scripts/validation/canary-lib.sh"
[[ "$(cl_digest abc)" != "$(cl_digest xyz)" ]] || fail "cl_digest gave same output for different input (with hashers present)" ""
# force ALL hashers off (empty PATH): must fall back to the raw-embed branch, still distinct
A="$(PATH= cl_digest abc 2>/dev/null)"; B="$(PATH= cl_digest xyz 2>/dev/null)"
[[ "$A" != "$B" ]] || fail "cl_digest collapsed to a constant with no hashers on PATH (fail-open!)" "A=$A B=$B"
ok "digest is content-sensitive even with no hasher available (fail-closed)"

# ---------------------------------------------------------------------------------------------------
echo "Test 14: MECHANISM PROOF (header-keyed conversion) — a 7th column (\"Scope\") inserted between"
echo "Domain and Canary must not desync the Canary/Waiver reads. Under the old \$6/\$5 positional"
echo "reads, this insertion makes the probe read the Scope cell ('widget') as the canary key — an"
echo "unknown key, degrading to UNVERIFIED instead of actually probing the gate."
D="$TMP/t14"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
if grep -rIn "frobnicate" src 2>/dev/null | grep -q .; then exit 1; fi
exit 0
EOF
cat > "$D/specs/projects/001-x/evidence-contract.md" <<'EOF'
# Evidence Contract

### 6a. CI-Enforced Gate Registry

| Gate ID | Command / Script | Stage | Domain | Scope | Canary | Waiver |
|---------|------------------|-------|--------|-------|--------|--------|
| test-gate | bash gate.sh | pre-commit | copy | widget | banned-language | — |
EOF
commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "unknown canary key" && fail "canary must resolve from its REAL (shifted) column, not the old fixed position" "$OUT"
echo "$OUT" | grep -q "GATE_LIVE.*test-gate" || fail "expected GATE_LIVE once Canary/Domain resolve correctly despite the inserted column" "$OUT"
ok "7-col mechanism proof: Canary resolved from its real column, gate probed LIVE"

# ---------------------------------------------------------------------------------------------------
echo "Test 15: LEGACY FALLBACK — a §6a table with NO header row at all still probes correctly via"
echo "the historical fixed-position fallback (do not strand a pre-header-keyed project)."
D="$TMP/t15"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
if grep -rIn "frobnicate" src 2>/dev/null | grep -q .; then exit 1; fi
exit 0
EOF
cat > "$D/specs/projects/001-x/evidence-contract.md" <<'EOF'
# Evidence Contract

### 6a. CI-Enforced Gate Registry

| test-gate | bash gate.sh | pre-commit | copy | banned-language | — |
EOF
commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "GATE_LIVE.*test-gate" || fail "headerless legacy table should still probe correctly via positional fallback" "$OUT"
ok "headerless legacy table → positional fallback still probes correctly"

# ===================================================================================================
# #98 — THE THIRD VERDICT. #88's two halves answer "does the gate run" (wiring) and "does it bite"
# (canary). Neither answers "did it look at anything". Every fixture below is a gate that would pass
# BOTH of #88's halves and is still worthless.
# ===================================================================================================

# scaffold_mono <dir> — a MONOREPO: the product lives under frontend/src, there is NO root src/.
# This is the layout that made banned-language-lint report ✅ over 0 of 1194 files in one repo and
# 0 of 590 in another (#98 §1), while the canary that was supposed to catch it degraded to P2 for
# the very same reason — both re-derived "the product surface" from their own root-anchored list.
scaffold_mono() {
  local d="$1"
  mkdir -p "$d/specs/projects/001-x" "$d/frontend/src"
  git -C "$d" init -q
  git -C "$d" config user.email t@t.co; git -C "$d" config user.name t
  cat > "$d/specs/projects/001-x/product-contract.md" <<'EOF'
# Product Contract

## 7. Banned Language / System Anti-Patterns

- Never say `frobnicate` in a user-visible surface.
EOF
  printf 'export const App = () => <div>hello</div>\n' > "$d/frontend/src/App.tsx"
}

# ---------------------------------------------------------------------------------------------------
echo "Test 16: GATE_VACUOUS.P1 — full scan, SUBJECT=0, scope resolves to tracked files it should"
echo "have read. Wired ✓, implemented ✓, exit 0, ✅ on stdout — and it inspected nothing."
D="$TMP/t16"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# The #98 shape: a scope that never resolved to a target, so TARGETS is empty and the loop
# body never runs. Publishes the truth and still exits 0 with a green tick.
echo "SPECK_GATE_SCOPE=src/**"
echo "SPECK_GATE_SUBJECT=0"
echo "SPECK_GATE_PREDICATES=7"
echo "✅ No banned-language violations found."
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
if OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"; then
  fail "expected --strict to exit 1 on GATE_VACUOUS" "$OUT"
fi
echo "$OUT" | grep -q "GATE_VACUOUS.P1.*test-gate" || fail "expected GATE_VACUOUS.P1" "$OUT"
echo "$OUT" | grep -q "resolves to 1 tracked file" || fail "expected the resolved tracked-file count to be named" "$OUT"
ok "SUBJECT=0 over a scope that DOES resolve → GATE_VACUOUS.P1 + --strict blocks"

# ---------------------------------------------------------------------------------------------------
echo "Test 17: GATE_EMPTY_LEGITIMATE — the bounding exception. Same SUBJECT=0, same resolving scope,"
echo "but a DIFF-scoped run: a staged commit touching no product file is honest, not vacuous."
D="$TMP/t17"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "SPECK_GATE_SCOPE=src/**"
echo "SPECK_GATE_SUBJECT=0"
echo "SPECK_GATE_PREDICATES=7"
echo "✅ No staged product-surface files to scan (--staged)."
exit 0
EOF
registry "$D" "bash gate.sh --staged" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"   # must NOT exit 1
echo "$OUT" | grep -q "GATE_VACUOUS" && fail "a diff-scoped empty run must never be VACUOUS" "$OUT"
echo "$OUT" | grep -q "GATE_EMPTY_LEGITIMATE.*test-gate" || fail "expected GATE_EMPTY_LEGITIMATE note" "$OUT"
ok "diff-scoped SUBJECT=0 → EMPTY_LEGITIMATE note, never a finding"

# ---------------------------------------------------------------------------------------------------
echo "Test 18: GATE_VACUOUS.P1 — PREDICATES=0. The dimension without which this gate family's"
echo "vacuity is invisible: 180 files scanned against 0 usable terms looks perfectly healthy."
D="$TMP/t18"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "SPECK_GATE_SCOPE=src/**"
echo "SPECK_GATE_SUBJECT=180"
echo "SPECK_GATE_PREDICATES=0"
echo "✅ No banned-language violations found."
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
if OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"; then
  fail "expected --strict to exit 1 on a dead predicate set" "$OUT"
fi
{ echo "$OUT" | grep -q "GATE_VACUOUS.P1.*test-gate" && echo "$OUT" | grep -q "PREDICATES=0"; } \
  || fail "expected GATE_VACUOUS.P1 naming PREDICATES=0 despite a healthy SUBJECT" "$OUT"
ok "a non-empty subject with ZERO predicates → GATE_VACUOUS.P1"

# ---------------------------------------------------------------------------------------------------
echo "Test 19: GATE_VACUOUS.P1 — the live #98 §1 repro. Monorepo, gate reports the root-anchored"
echo "scope 'src/**,app/**' which matches ZERO tracked files: no commit can ever give it a subject."
D="$TMP/t19"; scaffold_mono "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "SPECK_GATE_SCOPE=src/**,app/**"
echo "SPECK_GATE_SUBJECT=0"
echo "SPECK_GATE_PREDICATES=7"
echo "✅ No staged product-surface files to scan (--staged)."
exit 0
EOF
registry "$D" "bash gate.sh --staged" "copy" "banned-language"; commit "$D"
if OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"; then
  fail "expected --strict to exit 1 on an unreachable scope" "$OUT"
fi
{ echo "$OUT" | grep -q "GATE_VACUOUS.P1.*test-gate" && echo "$OUT" | grep -q "ZERO tracked files"; } \
  || fail "expected GATE_VACUOUS.P1 for a scope that resolves to nothing" "$OUT"
echo "$OUT" | grep -q "GATE_EMPTY_LEGITIMATE" \
  && fail "an unreachable scope must NOT be excused as EMPTY_LEGITIMATE just because the run is diff-scoped" "$OUT"
ok "unreachable scope beats the diff-scoped excuse → GATE_VACUOUS.P1"

# ---------------------------------------------------------------------------------------------------
echo "Test 20: GATE_SCOPE_UNREPORTED.P3 — a gate that publishes no scope still gets probed via the"
echo "canary's residual list, but the guess is ENUMERABLE instead of invisible."
D="$TMP/t20"; scaffold "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
if grep -rIn "frobnicate" src 2>/dev/null | grep -q .; then exit 1; fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" --strict "$D/specs/projects/001-x" 2>&1)"   # P3 must not block
{ echo "$OUT" | grep -q "GATE_SCOPE_UNREPORTED.P3.*test-gate" && echo "$OUT" | grep -q "GATE_LIVE.*test-gate"; } \
  || fail "expected a P3 for the missing output contract AND a still-successful probe" "$OUT"
ok "no telemetry → P3 (countable residue), probe still runs on the fallback"

# ---------------------------------------------------------------------------------------------------
echo "Test 21: THE #98 §1 REPAIR — the canary READS the gate's reported scope instead of restating"
echo "it. Monorepo: the gate really does scan frontend/src and reports '**/src/**'. The canary's own"
echo "root-anchored list resolves to nothing here, so before this fix the probe DEGRADED to"
echo "'no required-scope surface dirs present' — the gate and its own liveness probe sharing one"
echo "blind spot. Reading the gate's report finds frontend/src and actually probes it."
D="$TMP/t21"; scaffold_mono "$D"
cat > "$D/gate.sh" <<'EOF'
#!/usr/bin/env bash
# A genuinely healthy any-depth gate: scans every src/ at any depth, publishes what it inspected.
n=0
for d in $(find . -type d -name src -not -path './.git/*' 2>/dev/null); do
  n=$(( n + $(find "$d" -type f | wc -l | tr -d ' ') ))
done
echo "SPECK_GATE_SCOPE=**/src/**"
echo "SPECK_GATE_SUBJECT=$n"
echo "SPECK_GATE_PREDICATES=1"
if grep -rIn "frobnicate" $(find . -type d -name src -not -path './.git/*') 2>/dev/null | grep -q .; then
  echo '❌ "frobnicate"'; exit 1
fi
exit 0
EOF
registry "$D" "bash gate.sh" "copy" "banned-language"; commit "$D"
OUT="$(bash "$PROBE" "$D/specs/projects/001-x" 2>&1)"
echo "$OUT" | grep -q "no required-scope surface dirs present" \
  && fail "the canary is still guessing scope from its own list — the correlated blind spot survives" "$OUT"
echo "$OUT" | grep -q "GATE_LIVE.*test-gate" \
  || fail "expected GATE_LIVE: the canary must inject under the scope the GATE reported (frontend/src)" "$OUT"
ok "canary injected under the gate's REPORTED scope (frontend/src) → LIVE where it used to degrade"

# ---------------------------------------------------------------------------------------------------
echo "Test 22: DRIFT PIN — the canary's residual REQUIRED_SCOPE must stay byte-equal to the lint's"
echo "own SCOPE_SEGMENTS. Two hardcoded lists is the defect; while a fallback list still exists at"
echo "all, nothing but an assertion keeps it from drifting again (it already had: content+lib"
echo "canaried and never scanned, i18n scanned and never canaried)."
CANARY_SCOPE="$(. "$ROOT_REPO/.speck/scripts/validation/canaries/banned-language.canary"; printf '%s' "$REQUIRED_SCOPE")"
LINT_SEGMENTS="$(sed -n 's/^SCOPE_SEGMENTS=(\(.*\))$/\1/p' "$ROOT_REPO/.speck/scripts/banned-language-lint.sh" | head -n1)"
[[ -n "$LINT_SEGMENTS" ]] || fail "could not read SCOPE_SEGMENTS from banned-language-lint.sh — did it move?" ""
[[ "$CANARY_SCOPE" == "$LINT_SEGMENTS" ]] \
  || fail "canary REQUIRED_SCOPE drifted from the gate's SCOPE_SEGMENTS" "canary: [$CANARY_SCOPE]
lint:   [$LINT_SEGMENTS]"
ok "residual fallback scope is byte-equal to the gate's own SCOPE_SEGMENTS"

# ===================================================================================================
# P2 (v9.6/v10 cross-cluster) — the SHIPPED validate-schema-drift.sh, run notice-mode (no --live), is
# the gate this defect was found against: 7 real repos / 188 migration files, PREDICATES=0 with
# exit 0 on all 7, every one convicted as GATE_VACUOUS.P1 by this probe pre-fix.
#
# The real script is run DIRECTLY (bash, no probe) against a real migration dir to capture its
# genuine stdout — the fixture text below is that captured output, byte for byte, never hand-typed —
# and REPLAYED through a stub gate.sh so the probe's own destructive-verb safety heuristic (which
# fires on the mere word "supabase" appearing anywhere in a `bash <script>` body it reads, canary-lib
# .sh — not a file this cluster owns) doesn't block the run. What is under test is the PROBE's
# interpretation of genuinely-shipped telemetry, not a hand-typed imitation of it.
# ===================================================================================================
REAL_SCHEMA_DRIFT="$ROOT_REPO/.speck/scripts/validation/validators/validate-schema-drift.sh"

# capture_real_schema_drift_notice <schema-drift-script-path> — runs the given script for real
# against a fresh migration dir (no --live: the common, shipped, notice-mode invocation) and prints
# its exact stdout.
capture_real_schema_drift_notice() {
  local script="$1" d
  d="$(mktemp -d)"
  # A plain "migrations/" dir (generic-sql), NOT "supabase/migrations/": the probe's own
  # destructive-verb safety heuristic (canary-lib.sh, not a file this cluster owns) fires on the
  # bare WORD "supabase" appearing anywhere in a `bash <script>` invocation it reads — including in
  # the gate's own "Framework: supabase" banner line. Using generic-sql keeps the captured output
  # genuinely real while not tripping a safety check this fix has nothing to do with.
  mkdir -p "$d/migrations" "$d/.speck/scripts/lib"
  cp "$ROOT_REPO/.speck/scripts/lib/text.sh" "$d/.speck/scripts/lib/text.sh"
  cat > "$d/migrations/0001_init.sql" <<'SQL'
CREATE TABLE public.widgets (
  id uuid PRIMARY KEY
);
SQL
  mkdir -p "$d/.speck/scripts/validation/validators"
  cp "$script" "$d/.speck/scripts/validation/validators/probed.sh"
  (cd "$d" && bash .speck/scripts/validation/validators/probed.sh . 2>&1)
  rm -rf "$d" 2>/dev/null || true
}

REAL_NOTICE_OUT="$(capture_real_schema_drift_notice "$REAL_SCHEMA_DRIFT")"
echo "$REAL_NOTICE_OUT" | grep -q "^SPECK_GATE_PREDICATES=0$" \
  || fail "PRECONDITION: the real, unmutated validate-schema-drift.sh no longer reports PREDICATES=0 in notice mode — has its behavior changed?" "$REAL_NOTICE_OUT"
echo "$REAL_NOTICE_OUT" | grep -q "^SPECK_GATE_MODE=notice$" \
  || fail "PRECONDITION: the real, unmutated validate-schema-drift.sh no longer reports SPECK_GATE_MODE=notice" "$REAL_NOTICE_OUT"
echo "  (precondition confirmed: the shipped gate's real notice-mode run genuinely emits PREDICATES=0 + MODE=notice)"

# make_replay_gate <dir> <captured-output> — a probe-safe stub that reproduces genuinely-captured
# gate stdout verbatim (echo/cat are on the probe's known-safe-tool allowlist).
make_replay_gate() {
  local d="$1" body="$2"
  printf '#!/usr/bin/env bash\ncat <<'"'"'REPLAY_EOF'"'"'\n%s\nREPLAY_EOF\nexit 0\n' "$body" > "$d/gate.sh"
}

echo "Test 23: GATE_PREDICATES_LEGITIMATE — replaying the REAL gate's captured notice-mode output"
echo "(PREDICATES=0, SPECK_GATE_MODE=notice) must NOT be convicted as GATE_VACUOUS.P1 (the verified"
echo "P2: 7 real repos, 188 migration files, all false-convicted pre-fix for a gate behaving exactly"
echo "as designed)."
D23="$TMP/t23"; scaffold "$D23"
make_replay_gate "$D23" "$REAL_NOTICE_OUT"
registry "$D23" "bash gate.sh" "copy" "banned-language"; commit "$D23"
OUT23="$(bash "$PROBE" "$D23/specs/projects/001-x" 2>&1)"
echo "$OUT23" | grep -q "GATE_VACUOUS.P1.*test-gate" \
  && fail "the real gate's captured honest notice-mode PREDICATES=0 was wrongly convicted as GATE_VACUOUS.P1" "$OUT23"
echo "$OUT23" | grep -q "GATE_PREDICATES_LEGITIMATE.*test-gate" \
  || fail "expected GATE_PREDICATES_LEGITIMATE for the real gate's self-declared notice mode" "$OUT23"
ok "replayed real validate-schema-drift.sh notice-mode output → GATE_PREDICATES_LEGITIMATE, never GATE_VACUOUS.P1"

echo "Test 24: MUTATION PROOF (probe side) — reverting the MODE-exemption condition in a SCRATCH COPY"
echo "of the probe turns Test 23's exact fixture back into a false GATE_VACUOUS.P1. Confirms the"
echo "exemption branch itself is the real control point, not an unreached default."
# The scratch copy must live in a validators/ dir whose siblings resolve — the probe sources
# canary-lib.sh (../canary-lib.sh) and text.sh (../../lib/text.sh) by relative path.
SCRATCHROOT24="$TMP/scratch-probe-tree-24"
mkdir -p "$SCRATCHROOT24/.speck/scripts/validation/validators" "$SCRATCHROOT24/.speck/scripts/lib"
cp "$ROOT_REPO/.speck/scripts/validation/canary-lib.sh" "$SCRATCHROOT24/.speck/scripts/validation/canary-lib.sh"
cp -R "$ROOT_REPO/.speck/scripts/validation/canaries" "$SCRATCHROOT24/.speck/scripts/validation/canaries"
cp "$ROOT_REPO/.speck/scripts/lib/text.sh" "$SCRATCHROOT24/.speck/scripts/lib/text.sh"
SCRATCH_PROBE24="$SCRATCHROOT24/.speck/scripts/validation/validators/gate-liveness-probe.sh"
cp "$ROOT_REPO/.speck/scripts/validation/validators/gate-liveness-probe.sh" "$SCRATCH_PROBE24"
sed -i.bak 's/\[\[ "\$rep_mode" == "notice" \]\]/[[ "$rep_mode" == "__mutated_off__" ]]/' "$SCRATCH_PROBE24"
grep -q '"\$rep_mode" == "notice"' "$SCRATCH_PROBE24" && fail "mutation did not actually disable the MODE exemption (control point not found)" ""
OUT24="$(bash "$SCRATCH_PROBE24" "$D23/specs/projects/001-x" 2>&1)"
echo "$OUT24" | grep -q "GATE_VACUOUS.P1.*test-gate" \
  || fail "MUTATION PROOF FAILED — reverting the probe's MODE exemption should re-convict the same fixture as GATE_VACUOUS.P1, but it stayed clean" "$OUT24"
ok "revert-and-confirm-RED: the probe's MODE-exemption condition is the real control point"

echo "Test 25: MUTATION PROOF (gate side) — capturing the REAL validate-schema-drift.sh with its"
echo "SPECK_GATE_MODE emission removed (a SCRATCH COPY, run for real to produce genuinely-mutated"
echo "output) and replaying THAT through the real, unmutated probe also re-convicts. Confirms the"
echo "gate's own MODE line is load-bearing — the probe truly reads it, not some other signal."
SCRATCH_SCHEMA25="$TMP/scratch-schema-drift-25.sh"
cp "$REAL_SCHEMA_DRIFT" "$SCRATCH_SCHEMA25"
sed -i.bak '/echo "SPECK_GATE_MODE=\$GATE_MODE"/d' "$SCRATCH_SCHEMA25"
grep -q 'SPECK_GATE_MODE=\$GATE_MODE' "$SCRATCH_SCHEMA25" && fail "mutation did not actually remove the MODE emission line (control point not found)" ""
MUTATED_NOTICE_OUT="$(capture_real_schema_drift_notice "$SCRATCH_SCHEMA25")"
echo "$MUTATED_NOTICE_OUT" | grep -q "^SPECK_GATE_MODE=" \
  && fail "MUTATION SETUP FAILED — the scratch copy still emits a MODE line" "$MUTATED_NOTICE_OUT"
D25="$TMP/t25"; scaffold "$D25"
make_replay_gate "$D25" "$MUTATED_NOTICE_OUT"
registry "$D25" "bash gate.sh" "copy" "banned-language"; commit "$D25"
OUT25="$(bash "$PROBE" "$D25/specs/projects/001-x" 2>&1)"
echo "$OUT25" | grep -q "GATE_VACUOUS.P1.*test-gate" \
  || fail "MUTATION PROOF FAILED — a schema-drift copy that never emits SPECK_GATE_MODE should be convicted (no exemption possible), but it stayed clean" "$OUT25"
ok "revert-and-confirm-RED: the gate's own SPECK_GATE_MODE=notice line is the real control point"

echo "Test 26: BOUNDED, NOT BLANKET — a stub gate with PREDICATES=0 and NO MODE line (the pre-existing"
echo "Test 18 shape) must still convict as GATE_VACUOUS.P1. The exemption is opt-in per-gate, never a"
echo "global softening of the PREDICATES=0 rule."
D26="$TMP/t26"; scaffold "$D26"
cat > "$D26/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "SPECK_GATE_SCOPE=src/**"
echo "SPECK_GATE_SUBJECT=180"
echo "SPECK_GATE_PREDICATES=0"
echo "✅ No banned-language violations found."
exit 0
EOF
registry "$D26" "bash gate.sh" "copy" "banned-language"; commit "$D26"
if OUT26="$(bash "$PROBE" --strict "$D26/specs/projects/001-x" 2>&1)"; then
  fail "expected --strict to exit 1 — a gate with no MODE line gets no exemption" "$OUT26"
fi
echo "$OUT26" | grep -q "GATE_VACUOUS.P1.*test-gate" || fail "expected GATE_VACUOUS.P1 (no MODE line → no exemption)" "$OUT26"
echo "$OUT26" | grep -q "GATE_PREDICATES_LEGITIMATE" && fail "a gate that never claimed notice mode must not get the exemption note" "$OUT26"
ok "no SPECK_GATE_MODE line → still GATE_VACUOUS.P1 (exemption is opt-in, not blanket)"

echo "Test 27: BOUNDED, NOT BLANKET — a stub gate that claims SPECK_GATE_MODE=notice but ALSO reports"
echo "SUBJECT=0 over a resolving scope must still be judged on the SUBJECT dimension (GATE_VACUOUS.P1"
echo "from the elif branch below), never laundered clean just because it name-drops notice mode."
D27="$TMP/t27"; scaffold "$D27"
cat > "$D27/gate.sh" <<'EOF'
#!/usr/bin/env bash
echo "SPECK_GATE_SCOPE=src/**"
echo "SPECK_GATE_SUBJECT=0"
echo "SPECK_GATE_PREDICATES=7"
echo "SPECK_GATE_MODE=notice"
echo "✅ No banned-language violations found."
exit 0
EOF
registry "$D27" "bash gate.sh" "copy" "banned-language"; commit "$D27"
if OUT27="$(bash "$PROBE" --strict "$D27/specs/projects/001-x" 2>&1)"; then
  fail "expected --strict to exit 1 — SUBJECT=0 over a resolving scope is vacuous regardless of MODE" "$OUT27"
fi
echo "$OUT27" | grep -q "GATE_VACUOUS.P1.*test-gate" || fail "expected GATE_VACUOUS.P1 on the SUBJECT dimension despite MODE=notice" "$OUT27"
ok "MODE=notice exempts only the PREDICATES dimension, never SUBJECT"

echo ""
echo "All gate-liveness-probe tests passed ($PASS assertions)."
exit 0
