#!/usr/bin/env bash
# validate-template.test.sh — smoke tests for placeholder scanner + story-spec lifecycle

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIXTURES="$ROOT/.speck/scripts/validation/test-fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test"

# Use non-routed filenames so tests exercise the Python placeholder scanner only
# (validate-template.sh exits 0 after scan for unknown artifact names).

echo "Test: multi-line bracket inside fenced code block passes"
cp "$FIXTURES/multiline-bracket-codeblock.md" "$TMP/specs/projects/test-proj/epics/E000-test/fixture-multiline-bracket.md"
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/fixture-multiline-bracket.md"

echo "Test: single-line JSON bracket inside fenced code block passes"
cp "$FIXTURES/fenced-json-bracket.md" "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-fenced-json.md"
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-fenced-json.md"

echo "Test: descriptive FR-XXX reference passes"
cp "$FIXTURES/descriptive-fr-xxx.md" "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-descriptive-fr.md"
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-descriptive-fr.md"

echo "Test: placeholder spec passes loose validation"
cp "$FIXTURES/placeholder-spec-good.md" "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/spec.md"
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/spec.md"

echo "Test: pre-commit hook empty-array expansion is set -u safe"
bash -c 'set -euo pipefail; staged_specs=(); staged_readme=false; if [[ ${#staged_specs[@]} -eq 0 && "$staged_readme" == false ]]; then exit 0; fi; for spec in "${staged_specs[@]}"; do echo "$spec"; done'

echo "Test: no bash 4+ builtins (mapfile/readarray) in .speck/scripts (macOS bash 3.2 portability)"
portability_hits=""
while IFS= read -r candidate; do
  [[ -z "$candidate" ]] && continue
  # This test file legitimately names the builtins (in patterns/messages) — skip it.
  [[ "$candidate" == *"validate-template.test.sh" ]] && continue
  # Strip comments before matching so backticked mentions in comments don't false-positive;
  # only flag mapfile/readarray used as an actual command token.
  if sed 's/#.*//' "$candidate" | grep -qE '(^|[^[:alnum:]_])(mapfile|readarray)[[:space:]]'; then
    portability_hits="$portability_hits$candidate"$'\n'
  fi
done < <(grep -rlE '(mapfile|readarray)' "$ROOT/.speck/scripts" --include='*.sh' 2>/dev/null || true)
if [[ -n "$portability_hits" ]]; then
  echo "ERROR: mapfile/readarray used in .speck/scripts — not portable to macOS default bash 3.2:"
  printf '%s' "$portability_hits"
  echo "Use a portable read-loop: arr=(); while IFS= read -r l; do arr+=(\"\$l\"); done < <(cmd)"
  exit 1
fi
echo "  ✓ No bash 4+ array builtins found"

echo "Test: bracketed code tokens in prose pass (not template placeholders)"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-bracketed-code.md" <<'EOF'
# Fixture

Run lint against [BULK_MODEL, ESCALATION_MODEL] and ["scripts/banned-language-lint.mjs", target].
EOF
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-bracketed-code.md"

echo "Test: user story 'As an' / 'As the' passes validate-story-spec"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/spec.md" <<'EOF'
---
depends_on: []
blocks: []
---

**Current State**: Specified

## User Story

As an owner-operator, I want automated classification so that I save review time.

## 1. Experience (What the user lives)

Content here.

## 2. Acceptance LARP (How we prove the experience works)

#### Scenario: Happy path
- **GIVEN** articles exist
- **WHEN** classifier runs
- **THEN** labels are assigned

## 3. Evidence Required

Screenshots.

## 4. Adversarial Cases (What must NOT happen)

None.
EOF
bash "$ROOT/.speck/scripts/validation/validators/validate-story-spec.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/spec.md"

# --- #92: sanctioned markers + citation-vs-residue over-match ---------------
# validate-template.sh's placeholder scanner used to convict [NEEDS USER
# REVIEW] — a marker Speck's OWN project-state-template.md instructs agents
# to emit and then greps for — plus prose that CITES the placeholder
# convention rather than containing residue of it. Regression-guard each
# case, and pair every "must now pass" case with a "must still fail" trap so
# the fix can't have overcorrected into a false negative.

echo "Test: [NEEDS USER REVIEW] (Speck-sanctioned marker) passes strict validation"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-needs-review.md" <<'EOF'
# Fixture

Auth flow: [NEEDS USER REVIEW] — token expiry policy unclear.
EOF
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-needs-review.md"

echo "Test: provenance legend defining an ALL-CAPS tag (e.g. [FROM RESEARCH]) passes"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-legend.md" <<'EOF'
# Fixture

Provenance legend:

**[FROM RESEARCH]** — content sourced from due-diligence research.
EOF
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-legend.md"

echo "Test: prose CITING the [PLACEHOLDER] convention (not residue of it) passes"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-citation.md" <<'EOF'
# Fixture

If you are seeing this, the producing skill likely did not run to completion —
invoke it and try again, replacing every [PLACEHOLDER] with real content.
EOF
bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-citation.md"

echo "Test: TRAP — a genuine mixed-case unfilled placeholder must still be caught"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-mixed.md" <<'EOF'
- **[Option A name]** — a one-sentence description.
EOF
if bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-mixed.md" >/dev/null 2>&1; then
  echo "FAIL: a genuine unfilled [Option A name] was wrongly allowed through"
  exit 1
fi

echo "Test: TRAP — a genuine ALL-CAPS placeholder mid-sentence must still be caught"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-allcaps.md" <<'EOF'
**Project Archetype**: [CONSUMER PRODUCT OR B2B SAAS]
EOF
if bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-allcaps.md" >/dev/null 2>&1; then
  echo "FAIL: a genuine unfilled all-caps placeholder was wrongly allowed through"
  exit 1
fi

echo "Test: TRAP — a colon-separated '[LABEL]: [value]' field (feedback/template.md shape) must still be caught"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-signal-id.md" <<'EOF'
- **[SIGNAL_ID]**: [description]
EOF
if bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-signal-id.md" >/dev/null 2>&1; then
  echo "FAIL: a genuine unfilled [SIGNAL_ID]: [description] field was wrongly allowed through"
  exit 1
fi

echo "Test: TRAP — a numbered-list ALL-CAPS bracket with an em-dash must still be caught"
cat > "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-numbered.md" <<'EOF'
1. **[OPTION A NAME]** — one sentence description.
EOF
if bash "$ROOT/.speck/scripts/validation/validate-template.sh" --strict "$TMP/specs/projects/test-proj/epics/E000-test/stories/S001-test/fixture-trap-numbered.md" >/dev/null 2>&1; then
  echo "FAIL: a genuine unfilled numbered-list [OPTION A NAME] was wrongly allowed through"
  exit 1
fi
echo "  ✓ all #92 sanctioned-marker / citation-context cases pass, all traps still fail"

echo "All validate-template smoke tests passed"
