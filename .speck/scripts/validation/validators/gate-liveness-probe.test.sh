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
PROBE="$ROOT_REPO/.speck/scripts/validation/validators/gate-liveness-probe.sh"
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

echo ""
echo "All gate-liveness-probe tests passed ($PASS assertions)."
exit 0
