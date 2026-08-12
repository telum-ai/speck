#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-proof-flow.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

copy_fixture() {
  rm -rf "$TMP/AGENTS.md" "$TMP/.cursor"
  cp "$ROOT/AGENTS.md" "$TMP/AGENTS.md"
  mkdir -p "$TMP/.cursor/skills"
  cp -R "$ROOT/.cursor/skills/epic-validate" "$TMP/.cursor/skills/"
  cp -R "$ROOT/.cursor/skills/project-validate" "$TMP/.cursor/skills/"
  cp -R "$ROOT/.cursor/skills/story-validate" "$TMP/.cursor/skills/"
}

echo "Test: live proof flow passes"
bash "$VALIDATOR" "$ROOT"

copy_fixture
printf '\n## 12. Write outputs\n' >> "$TMP/.cursor/skills/epic-validate/references/spine.md"
echo "Test: duplicate epic spine procedure fails"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: duplicated epic output procedure passed"
  exit 1
fi

copy_fixture
printf '\nRun validate-gate-liveness here too.\n' >> "$TMP/.cursor/skills/project-validate/references/commercial.md"
echo "Test: duplicate commercial gate-liveness procedure fails"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: duplicated commercial gate-liveness procedure passed"
  exit 1
fi

copy_fixture
python3 - "$TMP/AGENTS.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("Project close: completed epics `→ speck-larp(+ visual-testing if UI) → project-validate", "Project close: completed epics `→ [speck-larp(+ visual-testing) if UI] → project-validate"))
PY
echo "Test: UI-only project evidence route fails"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: UI-only project LARP route passed"
  exit 1
fi

copy_fixture
printf '\nSkip Premise-Challenge.\n' >> "$TMP/.cursor/skills/story-validate/references/backend-skip.md"
echo "Test: backend premise waiver fails"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: backend premise waiver passed"
  exit 1
fi

copy_fixture
python3 - "$TMP/.cursor/skills/project-validate/references/spine.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("nonvisual/API projects require `API-RC`", "nonvisual/API projects require `UX-RC`"))
PY
echo "Test: project API-RC branch removal fails"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: missing project API-RC branch passed"
  exit 1
fi

copy_fixture
rm "$TMP/.cursor/skills/epic-validate/references/mutation.md"
echo "Test: forbid() node missing entirely fails (L11.1)"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: a JIT node whose file was deleted outright passed forbid()"
  exit 1
fi

copy_fixture
rm "$TMP/.cursor/skills/project-validate/references/gate-liveness.md"
echo "Test: forbid()-only gate-liveness node missing entirely fails (L11.1)"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: a deleted gate-liveness node passed forbid()"
  exit 1
fi

copy_fixture
rm "$TMP/.cursor/skills/project-validate/references/commercial.md"
echo "Test: forbid()-only commercial node missing entirely fails (L11.1)"
if bash "$VALIDATOR" "$TMP" >/dev/null 2>&1; then
  echo "FAIL: a deleted commercial node passed forbid()"
  exit 1
fi

echo "validate-proof-flow tests passed"
