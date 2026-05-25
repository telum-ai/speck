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

echo "All validate-template smoke tests passed"
