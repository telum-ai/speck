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

cat > "$TMP/.speck/project.json" <<'EOF'
{"project_id":"001-pulseboard","play_level":"build"}
EOF

if bash "$SCRIPT" --json "Another product" >/dev/null 2>&1; then
  echo "FAIL: omitted --project-id created beside the declared project"
  exit 1
fi
test ! -d "$TMP/specs/projects/002-another-product"

if bash "$SCRIPT" --dry-run --project-id 002-another "Another product" >/dev/null 2>&1; then
  echo "FAIL: explicit project id overrode the declared canonical project"
  exit 1
fi

rm "$TMP/.speck/project.json"
bash "$SCRIPT" --json "Another product" > "$TMP/generated.json"
python3 - "$TMP/generated.json" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert data["project_id"].startswith("002-another-product"), data
PY

echo "create-new-project canonical-id tests passed"
