#!/usr/bin/env bash
# validate-readme.test.sh — smoke tests for PROFILE validators

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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

echo "All validate-readme smoke tests passed"
