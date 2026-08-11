#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/.speck/scripts/bash"
cp "$ROOT/.speck/scripts/bash/create-new-project.sh" "$TMP/.speck/scripts/bash/create-new-project.sh"
SCRIPT="$TMP/.speck/scripts/bash/create-new-project.sh"

bash "$SCRIPT" --json --project-id 001-pulseboard "A small product" > "$TMP/declared.json"
python3 - "$TMP/declared.json" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert data["project_id"] == "001-pulseboard", data
assert data["project_dir"] == "specs/projects/001-pulseboard", data
PY
test -f "$TMP/specs/projects/001-pulseboard/project.md"

if bash "$SCRIPT" --dry-run --project-id '../escape' "bad" >/dev/null 2>&1; then
  echo "FAIL: invalid canonical project id was accepted"
  exit 1
fi

bash "$SCRIPT" --json "Another product" > "$TMP/generated.json"
python3 - "$TMP/generated.json" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert data["project_id"].startswith("002-another-product"), data
PY

echo "create-new-project canonical-id tests passed"
