#!/usr/bin/env bash
# validate-readme.test.sh — smoke tests for PROFILE validators

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# shellcheck source=../../profile-lib.sh
source "$ROOT/.speck/scripts/profile-lib.sh"

mkdir -p "$TMP/.speck" "$TMP/specs/projects/test-proj"
echo "v7.7.0" > "$TMP/.speck/VERSION"
echo '{"_active_project":"test-proj"}' > "$TMP/.speck/project.json"
echo "## 1. Paid Promise

We help teams ship faster with evidence-driven specs." > "$TMP/specs/projects/test-proj/product-contract.md"

cat > "$TMP/README.md" << 'EOF'
# Test Product

> We help teams ship faster with evidence-driven specs.

**Status**: Spec phase

<!-- SPECK:START -->
Built with Speck (speck v7.7.0).
<!-- SPECK:END -->
EOF

echo "Test: valid README passes"
bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$TMP"

cat > "$TMP/README.md" << 'EOF'
# Speck 🥓
Spec-driven development methodology
<!-- SPECK:START -->
old
<!-- SPECK:END -->
EOF

echo "Test: legacy marketing fails"
if bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$TMP" 2>/dev/null; then
  echo "FAIL: expected error for legacy README"
  exit 1
fi

echo "Test: profile-drift-check on aligned README"
cat > "$TMP/README.md" << 'EOF'
# Test Product
> We help teams ship faster with evidence-driven specs.
<!-- SPECK:START -->
speck v7.7.0
<!-- SPECK:END -->
EOF
bash "$ROOT/.speck/scripts/profile-drift-check.sh" "$TMP" test-proj

echo "Test: specification-phase README links only to truth that exists"
EARLY="$TMP/early"
mkdir -p "$EARLY/.speck/templates/project" "$EARLY/specs/projects/early-proj"
cp "$ROOT/.speck/templates/project/readme-template.md" "$EARLY/.speck/templates/project/readme-template.md"
echo "11.0.0" > "$EARLY/.speck/VERSION"
echo '{"project_id":"early-proj"}' > "$EARLY/.speck/project.json"
cat > "$EARLY/specs/projects/early-proj/project.md" << 'EOF'
# Early Product

## Project overview

Early Product turns meeting transcripts into reviewed, owned actions.

## Vision

Facilitators leave every meeting confident that commitments will not disappear.
EOF
bash "$ROOT/.speck/scripts/regenerate-project-readme.sh" early-proj "$EARLY"
grep -q '^\*\*Status\*\*: Specified · no readiness claim$' "$EARLY/README.md"
grep -q 'Early Product turns meeting transcripts into reviewed, owned actions.' "$EARLY/README.md"
if grep -q 'Facilitators leave every meeting confident' "$EARLY/README.md"; then
  echo "FAIL: README skipped the project overview and duplicated the later vision"
  exit 1
fi
grep -q 'specs/projects/early-proj/project.md' "$EARLY/README.md"
if grep -Eq 'REPLACE_BEFORE_SHIP|\[[^]]*placeholder[^]]*\]|architecture.md|product-contract.md|project-state.md|project-decisions-log.md' "$EARLY/README.md"; then
  echo "FAIL: early README contains a placeholder or phantom artifact link"
  exit 1
fi
bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$EARLY" >/dev/null

cat > "$TMP/specs/projects/test-proj/project.md" << 'EOF'
# Test Product

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|-----------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | UX-RC / API-RC |
| Package description | `package` | `package.json#description` | `README.md#one-liner` | COMMERCIAL-RC |
| GitHub repo description | `github` | `remote:description` | `README.md#one-liner` | SHIP-RC |
| Landing page hero | `file` | `src/landing.txt` | `product-contract.md#1` | COMMERCIAL-RC |
| Public changelog intro | `file` | `docs/public-intro.md` | `README.md#one-liner` | SHIP-RC |

## Target users
EOF

cat > "$TMP/package.json" << 'EOF'
{"description":"We help teams ship faster with evidence-driven specs."}
EOF
mkdir -p "$TMP/src" "$TMP/docs"
echo "We help teams ship faster with evidence-driven specs." > "$TMP/src/landing.txt"
echo "We help teams ship faster with evidence-driven specs." > "$TMP/docs/public-intro.md"

cp "$TMP/specs/projects/test-proj/project.md" "$TMP/specs/projects/test-proj/project.valid.md"

echo "Test: malformed PROFILE rows fail closed instead of disappearing"
awk '/^## Target users/ { print "| Broken public surface | file | missing.txt |" } { print }' \
  "$TMP/specs/projects/test-proj/project.valid.md" > "$TMP/specs/projects/test-proj/project.md"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim ship-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: malformed PROFILE row disappeared from SHIP-RC evaluation"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[registry\].*requires 5 columns.*found 3' <<< "$OUT"

echo "Test: targeted PROFILE checks cannot return before registry errors"
awk '
  /Package description/ { print "| Broken package | `package` | `package.json#description` | `README.md#one-liner` |"; next }
  { print }
' "$TMP/specs/projects/test-proj/project.valid.md" > "$TMP/specs/projects/test-proj/project.md"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim ship-rc --surface package "$TMP" test-proj 2>&1)"; then
  echo "FAIL: targeted PROFILE check returned before its malformed registry row"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[registry\].*requires 5 columns.*found 4' <<< "$OUT"
grep -q 'PROFILE_DRIFT_SUMMARY P1=1 P2=1' <<< "$OUT"

echo "Test: unknown Required by states fail closed at every claim"
sed 's/COMMERCIAL-RC/COMMERCIAL RC/' \
  "$TMP/specs/projects/test-proj/project.valid.md" > "$TMP/specs/projects/test-proj/project.md"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim commercial-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: malformed Required by state was delayed past COMMERCIAL-RC"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[registry\].*unknown Required by readiness state: COMMERCIAL RC' <<< "$OUT"
mv "$TMP/specs/projects/test-proj/project.valid.md" "$TMP/specs/projects/test-proj/project.md"

echo "Test: remote fixture override is refused outside explicit test mode"
if OUT="$(SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim ship-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: expected production-mode GitHub fixture override to be refused"
  exit 1
fi
grep -q 'fixture override refused' <<< "$OUT"

echo "Test: production callers do not skip a non-executable wrapper"
HARNESS="$TMP/nonexec/.speck/scripts"
mkdir -p "$HARNESS/validation/validators"
cp "$ROOT/.speck/scripts/profile-drift-check.sh" "$HARNESS/profile-drift-check.sh"
cp "$ROOT/.speck/scripts/profile-surface-check.py" "$HARNESS/profile-surface-check.py"
cp "$ROOT/.speck/scripts/profile-lib.sh" "$HARNESS/profile-lib.sh"
cp "$ROOT/.speck/scripts/regenerate-project-readme.sh" "$HARNESS/regenerate-project-readme.sh"
cp "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" "$HARNESS/validation/validators/validate-readme.sh"
chmod -x "$HARNESS/profile-drift-check.sh"
cp "$TMP/specs/projects/test-proj/project.md" "$TMP/specs/projects/test-proj/project.saved.md"
awk '/^## Target users/ { print "| Duplicate package | `package` | `package.json#description` | `README.md#one-liner` | COMMERCIAL-RC |" } { print }' \
  "$TMP/specs/projects/test-proj/project.saved.md" > "$TMP/specs/projects/test-proj/project.md"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$HARNESS/regenerate-project-readme.sh" --check test-proj "$TMP" 2>&1)"; then
  echo "FAIL: expected production --check path to reject duplicate registry targets"
  exit 1
fi
if grep -q 'Permission denied' <<< "$OUT"; then
  echo "FAIL: production --check path depended on wrapper execute permission"
  exit 1
fi
if SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$HARNESS/validation/validators/validate-readme.sh" --strict "$TMP" >/dev/null 2>&1; then
  echo "FAIL: strict README validation skipped registry drift behind wrapper permissions"
  exit 1
fi
mv "$TMP/specs/projects/test-proj/project.saved.md" "$TMP/specs/projects/test-proj/project.md"

echo "Test: every declared PROFILE surface passes at SHIP-RC"
SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim ship-rc "$TMP" test-proj

echo "Test: package drift blocks its required readiness"
echo '{"description":"A completely unrelated accounting utility."}' > "$TMP/package.json"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim commercial-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: expected package drift to block COMMERCIAL-RC"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[Package description\]' <<< "$OUT"
echo '{"description":"We help teams ship faster with evidence-driven specs."}' > "$TMP/package.json"

echo "Test: generic file drift blocks its required readiness"
echo "A completely unrelated accounting utility." > "$TMP/src/landing.txt"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim commercial-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: expected landing drift to block COMMERCIAL-RC"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[Landing page hero\]' <<< "$OUT"
echo "We help teams ship faster with evidence-driven specs." > "$TMP/src/landing.txt"

echo "Test: remote provider empty blocks SHIP-RC"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="" \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim ship-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: expected empty GitHub description to block SHIP-RC"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[GitHub repo description\]' <<< "$OUT"

echo "Test: arbitrary declared file target is enforced"
rm "$TMP/docs/public-intro.md"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim ship-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: expected missing generic file target to block SHIP-RC"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[Public changelog intro\]' <<< "$OUT"
echo "We help teams ship faster with evidence-driven specs." > "$TMP/docs/public-intro.md"

echo "Test: a not-yet-required missing surface is visible but non-blocking"
rm "$TMP/src/landing.txt"
OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim integration-green "$TMP" test-proj)"
grep -q 'PROFILE_DRIFT.P2: \[Landing page hero\]' <<< "$OUT"
echo "We help teams ship faster with evidence-driven specs." > "$TMP/src/landing.txt"

echo "Test: registry placeholders fail closed when due"
sed 's|`src/landing.txt`|REPLACE_BEFORE_SHIP: landing path|' \
  "$TMP/specs/projects/test-proj/project.md" > "$TMP/specs/projects/test-proj/project-placeholder.md"
mv "$TMP/specs/projects/test-proj/project-placeholder.md" "$TMP/specs/projects/test-proj/project.md"
if OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="We help teams ship faster with evidence-driven specs." \
  bash "$ROOT/.speck/scripts/profile-drift-check.sh" --claim commercial-rc "$TMP" test-proj 2>&1)"; then
  echo "FAIL: expected required registry placeholder to block COMMERCIAL-RC"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[Landing page hero\]' <<< "$OUT"

echo "Test: malformed PROFILE header reports a finding instead of crashing"
HDR="$TMP/hdr"
mkdir -p "$HDR/.speck" "$HDR/specs/projects/demo"
echo "11.0.0" > "$HDR/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$HDR/.speck/project.json"
cat > "$HDR/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Target | Required by |
| --- | --- | --- |
| Root README | README.md | UX-RC |

## Target users
EOF
if OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$HDR" demo 2>&1)"; then
  echo "FAIL: expected a malformed PROFILE header to report a finding, not pass clean"
  exit 1
fi
if grep -qi 'UnboundLocalError\|Traceback (most recent call last)' <<< "$OUT"; then
  echo "FAIL: malformed PROFILE header crashed the checker instead of reporting a finding"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[registry\] line 5: PROFILE header requires 4 or 5 columns, found 3' <<< "$OUT"
grep -q 'PROFILE_DRIFT_SUMMARY' <<< "$OUT"

echo "Test: a valid header followed by a second malformed header does not leak row identity"
cat > "$HDR/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | UX-RC |

| Surface | Target | Required by |
| Bogus | x.txt | UX-RC |

## Target users
EOF
if OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$HDR" demo 2>&1)"; then
  : # exit status is not the point of this test — absence of a crash and no leaked row is
fi
if grep -qi 'UnboundLocalError\|Traceback (most recent call last)' <<< "$OUT"; then
  echo "FAIL: a second malformed header crashed the checker"
  exit 1
fi
if grep -q '\[Bogus\]' <<< "$OUT"; then
  echo "FAIL: a row under an invalid header leaked into the evaluated surfaces"
  exit 1
fi
# The actual leak defect is not a row named [Bogus] appearing — header_width resetting to 0
# already keeps that row out. It is loop state from the FIRST (valid) row surviving the
# second, invalid header and re-emitting as a phantom duplicate of that first row's own
# identity. Assert its absence directly instead of only checking for a name that was never
# going to appear.
if grep -qE 'PROFILE_DRIFT\.P[123]: \[Root README\].*duplicates another registry target' <<< "$OUT"; then
  echo "FAIL: a row under an invalid header leaked the PREVIOUS row's identity, synthesizing a phantom duplicate"
  exit 1
fi

echo "Test: bare invocation (no --claim) fails closed on real drift, matching the deleted bash gate"
BARE="$TMP/bare"
mkdir -p "$BARE/.speck" "$BARE/specs/projects/demo"
echo "11.0.0" > "$BARE/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$BARE/.speck/project.json"
cat > "$BARE/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | UX-RC |

## Target users
EOF
cat > "$BARE/specs/projects/demo/product-contract.md" << 'EOF'
## 1. Paid Promise

Invoicing automation that pays freelancers on time.
EOF
cat > "$BARE/README.md" << 'EOF'
# Demo

> Totally unrelated bicycle repair manual.

<!-- SPECK:START -->
speck v11.0.0
<!-- SPECK:END -->
EOF
if OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$BARE" demo 2>&1)"; then
  echo "FAIL: expected bare invocation to fail closed on a 0% overlap README"
  exit 1
fi
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*severely diverged' <<< "$OUT"
if bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$BARE" 2>/dev/null; then
  echo "FAIL: validate-readme.sh --strict passed clean despite a bare-invocation P1"
  exit 1
fi

echo "Test: an explicitly declared registry row never gets the legacy-fallback source carve-out"
# BARE declares an explicit '## PROFILE surfaces' registry row (not the synthetic legacy
# fallback) — a missing declared source of truth on a row someone actually wrote is a real
# defect its author must fix, and must fail closed at every claim, bare included, exactly
# like the deleted bash gate did.
rm "$BARE/specs/projects/demo/product-contract.md"
RC=0
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$BARE" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*source missing' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: a declared registry row with a missing source must fail closed bare"; echo "$OUT"; exit 1; }
RC=0
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" --claim ship-rc "$BARE" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*source missing' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: a declared registry row with a missing source must fail closed at --claim ship-rc"; echo "$OUT"; exit 1; }
if bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$BARE" 2>/dev/null; then
  echo "FAIL: validate-readme.sh --strict passed clean despite a declared row's missing source"
  exit 1
fi

echo "Test: a declared registry row with an EMPTY (not missing) source also fails closed bare"
# Neighbouring shape: the source file exists but its extracted promise is empty, rather than
# the file being absent — must land on the same P1 path, not just the missing-file path.
EMPTYSRC="$TMP/emptysrc"
mkdir -p "$EMPTYSRC/.speck" "$EMPTYSRC/specs/projects/demo"
echo "11.0.0" > "$EMPTYSRC/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$EMPTYSRC/.speck/project.json"
cat > "$EMPTYSRC/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | SHIP-RC |

## Target users
EOF
cat > "$EMPTYSRC/specs/projects/demo/product-contract.md" << 'EOF'
## 1. Paid Promise

<!--
EOF
cat > "$EMPTYSRC/README.md" << 'EOF'
# Demo

> Totally unrelated bicycle repair manual for vintage frames.

<!-- SPECK:START -->
speck v11.0.0
<!-- SPECK:END -->
EOF
RC=0
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" --claim ship-rc "$EMPTYSRC" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*source empty' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: a declared row with an empty source must fail closed at --claim ship-rc"; echo "$OUT"; exit 1; }

echo "Test: a declared file-adapter row with a missing source also fails closed (adapter neighbour)"
# Second neighbouring shape: a non-readme adapter (file), so the carve-out cannot have been
# narrowed to only the readme adapter's shape instead of to legacy_registry.
FILEMISS="$TMP/filemiss"
mkdir -p "$FILEMISS/.speck" "$FILEMISS/specs/projects/demo" "$FILEMISS/web"
echo "11.0.0" > "$FILEMISS/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$FILEMISS/.speck/project.json"
cat > "$FILEMISS/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Landing hero | `file` | `web/hero.txt` | `docs/marketing-truth.md` | SHIP-RC |

## Target users
EOF
echo "Totally unrelated bicycle repair manual." > "$FILEMISS/web/hero.txt"
RC=0
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$FILEMISS" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[Landing hero\].*source missing' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: a declared file-adapter row with a missing source must fail closed bare"; echo "$OUT"; exit 1; }

echo "Test: the legacy README-only fallback stays non-blocking bare but fails closed at a claim"
# The carve-out's actual, intended shape: no '## PROFILE surfaces' section declared at all,
# so profile-surface-check.py invents the synthetic single-surface fallback. An unwritten
# product-contract.md here is not drift on the always-on bare path (nobody has written a
# promise yet to diverge from) — but the moment a real readiness claim is being evaluated,
# project-validate's ship-rc gate must still see it.
LEGACY="$TMP/legacy"
mkdir -p "$LEGACY/.speck" "$LEGACY/specs/projects/demo"
echo "11.0.0" > "$LEGACY/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$LEGACY/.speck/project.json"
cat > "$LEGACY/specs/projects/demo/project.md" << 'EOF'
# Demo

## Target users
EOF
cat > "$LEGACY/README.md" << 'EOF'
# Demo

> A real one-liner describing the actual product.

<!-- SPECK:START -->
speck v11.0.0
<!-- SPECK:END -->
EOF
RC=0
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$LEGACY" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P2: \[Root README\].*source missing' <<< "$OUT"
[[ "$RC" -eq 0 ]] || { echo "FAIL: the legacy README-only fallback should not fail closed bare"; echo "$OUT"; exit 1; }
RC=0
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" --claim ship-rc "$LEGACY" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*source missing' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: the legacy README-only fallback must still fail closed once a readiness claim is evaluated"; echo "$OUT"; exit 1; }

echo "Test: an unreachable target (missing gh) stays non-blocking bare but blocks at its required claim"
# A target adapter failing for an environment/tooling reason (no gh binary — nothing a
# README edit can fix) must not block the always-on bare/pre-commit path, but must still
# surface as a real finding once the caller claims the readiness state that surface gates.
GHSURF="$TMP/ghsurf"
mkdir -p "$GHSURF/.speck" "$GHSURF/specs/projects/demo"
echo "11.0.0" > "$GHSURF/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$GHSURF/.speck/project.json"
cat > "$GHSURF/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | UX-RC |
| GitHub repo description | `github` | `remote:description` | `README.md#one-liner` | SHIP-RC |

## Target users
EOF
cat > "$GHSURF/specs/projects/demo/product-contract.md" << 'EOF'
## 1. Paid Promise

Invoicing automation that pays freelancers on time.
EOF
cat > "$GHSURF/README.md" << 'EOF'
# Demo

> Invoicing automation that pays freelancers on time.

<!-- SPECK:START -->
speck v11.0.0
<!-- SPECK:END -->
EOF
PY3DIR="$(dirname "$(command -v python3)")"
RC=0
OUT="$(PATH="$PY3DIR" python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$GHSURF" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P2: \[GitHub repo description\].*unreachable' <<< "$OUT"
[[ "$RC" -eq 0 ]] || { echo "FAIL: an unreachable gh target must not fail closed bare"; echo "$OUT"; exit 1; }
RC=0
OUT="$(PATH="$PY3DIR" python3 "$ROOT/.speck/scripts/profile-surface-check.py" --claim ship-rc "$GHSURF" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[GitHub repo description\].*unreachable' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: an unreachable gh target must fail closed once its required claim is evaluated"; echo "$OUT"; exit 1; }

echo "Test: a real (non-environmental) github content defect still fails closed bare"
# Neighbouring shape for the unreachable-target carve-out: an actual content problem (an
# empty GitHub description) must NOT be swept into the same non-blocking treatment as a
# missing `gh` binary — only messages naming the target as unreachable get the pass.
RC=0
OUT="$(SPECK_PROFILE_TEST_MODE=1 SPECK_PROFILE_GITHUB_DESCRIPTION="" python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$GHSURF" demo 2>&1)" || RC=$?
grep -q 'PROFILE_DRIFT.P1: \[GitHub repo description\].*GitHub description is empty' <<< "$OUT"
[[ "$RC" -eq 1 ]] || { echo "FAIL: an empty (not unreachable) github description must still fail closed bare"; echo "$OUT"; exit 1; }

echo "Test: a missing README one-liner does not mask marker or legacy-title P1s"
MASK="$TMP/mask"
mkdir -p "$MASK/.speck" "$MASK/specs/projects/demo"
echo "11.0.0" > "$MASK/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$MASK/.speck/project.json"
cat > "$MASK/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | UX-RC / API-RC |

## Target users
EOF
cat > "$MASK/specs/projects/demo/product-contract.md" << 'EOF'
## 1. Paid Promise

Invoicing automation that pays freelancers on time.
EOF
cat > "$MASK/README.md" << 'EOF'
# Speck 🥓
Spec-driven development methodology
EOF
OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" "$MASK" demo 2>&1)" || true
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*lacks SPECK:START..END markers' <<< "$OUT"
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*still has the legacy Speck marketing title' <<< "$OUT"
grep -q 'PROFILE_DRIFT.P1: \[Root README\].*README one-liner missing' <<< "$OUT"

echo "Test: paid-promise extraction matches profile-lib.sh's length-10 gate"
PROMISE_WS="$TMP/promise"
mkdir -p "$PROMISE_WS/.speck" "$PROMISE_WS/specs/projects/demo"
echo "11.0.0" > "$PROMISE_WS/.speck/VERSION"
echo '{"_active_project":"demo"}' > "$PROMISE_WS/.speck/project.json"
cat > "$PROMISE_WS/specs/projects/demo/project.md" << 'EOF'
# Demo

## PROFILE surfaces

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|------------------|-------------|
| Root README | `readme` | `README.md` | `product-contract.md#1` | UX-RC |

## Target users
EOF
cat > "$PROMISE_WS/specs/projects/demo/product-contract.md" << 'EOF'
## 1. Paid Promise

<!--
We help teams ship faster with evidence-driven specs.
-->
**Promise**: We help teams ship faster with evidence-driven specs.
EOF
cat > "$PROMISE_WS/README.md" << 'EOF'
# Demo

> We help teams ship faster with evidence-driven specs.

<!-- SPECK:START -->
speck v11.0.0
<!-- SPECK:END -->
EOF
BASH_PROMISE="$(profile_extract_paid_promise "$PROMISE_WS/specs/projects/demo/product-contract.md")"
PY_OUT="$(python3 "$ROOT/.speck/scripts/profile-surface-check.py" --claim ux-rc "$PROMISE_WS" demo 2>&1)"
if ! grep -q 'PROFILE_SURFACE PASS: \[Root README\]' <<< "$PY_OUT"; then
  echo "FAIL: python paid_promise() diverged from profile_extract_paid_promise (bash saw: $BASH_PROMISE)"
  echo "$PY_OUT"
  exit 1
fi

echo "Test: profile-drift-check.sh guards a missing python3 instead of a raw 127"
NOPY="$TMP/nopy-bin"
mkdir -p "$NOPY"
for tool in bash sh cat grep sed awk head tr mktemp dirname basename mv cp rm chmod xargs realpath env; do
  real="$(command -v "$tool" 2>/dev/null || true)"
  [[ -n "$real" ]] && ln -sf "$real" "$NOPY/$tool"
done
ln -sf /usr/bin/grep "$NOPY/grep"
ln -sf /usr/bin/find "$NOPY/find"
GUARD_RC=0
OUT="$(PATH="$NOPY" bash "$ROOT/.speck/scripts/profile-drift-check.sh" "$BARE" demo 2>&1)" || GUARD_RC=$?
# The raw, unguarded `exec python3 ...` failure also exits non-zero and also mentions
# "python3" (bash's own "exec: python3: not found"), so checking only those two things
# passes against the UNGUARDED wrapper too and proves nothing about the guard. Pin the
# guard's own exit code (1, not the raw exec failure's 127) and its own message text.
if [[ "$GUARD_RC" -eq 127 ]]; then
  echo "FAIL: raw unguarded exec failure (rc=127) leaked through instead of the python3 guard"
  exit 1
fi
[[ "$GUARD_RC" -eq 1 ]] || { echo "FAIL: expected the python3 guard to exit 1, got rc=$GUARD_RC"; echo "$OUT"; exit 1; }
grep -q '^ERROR: python3 is required for profile-drift-check.sh$' <<< "$OUT"
if grep -qi 'exec: python3: not found' <<< "$OUT"; then
  echo "FAIL: raw unguarded exec failure text leaked through instead of the guard's own message"
  exit 1
fi

echo "Test: validate-readme.sh does not read a silent drift-checker failure as clean"
if OUT="$(PATH="$NOPY" bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$BARE" 2>&1)"; then
  echo "FAIL: validate-readme.sh --strict passed clean while the PROFILE drift checker could not run"
  echo "$OUT"
  exit 1
fi
grep -q 'PROFILE drift checker did not complete' <<< "$OUT"

echo "All validate-readme smoke tests passed"
