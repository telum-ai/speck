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

echo "All validate-template smoke tests passed"
