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

# L11.6a — the SAME pin must fire when .speck/project.json uses the "_active_project" /
# "active_project" convention every OTHER Speck resolver in this repo reads
# (profile-lib.sh, profile-surface-check.py, banned-language-lint.sh) instead of
# "project_id". Before the fix, only "project_id" was recognised, so a repo declaring
# itself the other way had NO pin at all and a second, unrelated create-new-project.sh
# call silently created a stray sibling directory.
cat > "$TMP/.speck/project.json" <<'EOF'
{"active_project":"001-pulseboard","play_level":"build"}
EOF
if bash "$SCRIPT" --json "Yet another product" >/dev/null 2>&1; then
  echo "FAIL: active_project (not project_id) failed to pin the canonical project"
  exit 1
fi
test ! -d "$TMP/specs/projects/003-yet-another-product"

# L11.6b — the error hint must not tell the caller to "choose a different project
# description" when a description change literally cannot help: canonical_project_id
# overrides slug derivation entirely once a pin is declared. It must instead name the
# pinning key so the caller understands why every description lands on the same directory.
cat > "$TMP/.speck/project.json" <<'EOF'
{"project_id":"001-pulseboard","play_level":"build"}
EOF
ERR_OUT="$(bash "$SCRIPT" --json "Some unrelated product" 2>&1 >/dev/null || true)"
if grep -q "choose a different project description" <<<"$ERR_OUT"; then
  echo "FAIL: the pinned-project conflict still prints the misleading generic hint"
  echo "$ERR_OUT"
  exit 1
fi
if ! grep -q "project_id" <<<"$ERR_OUT"; then
  echo "FAIL: the pinned-project conflict error does not name the pinning key"
  echo "$ERR_OUT"
  exit 1
fi

# L11.6c — --force must not silently scaffold a different description atop the pinned
# project's directory; it may still proceed (that is what --force means) but must say so.
FORCE_OUT="$(bash "$SCRIPT" --json --force "Some unrelated product" 2>&1 >/dev/null || true)"
if ! grep -q "project_id" <<<"$FORCE_OUT"; then
  echo "FAIL: --force scaffolded into the pinned project directory without saying why"
  echo "$FORCE_OUT"
  exit 1
fi

echo "create-new-project canonical-id tests passed"
