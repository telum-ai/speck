#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT="$ROOT/.speck/scripts/bash/analyze-scale.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

assert_route() {
  local expected_level="$1" expected_complexity="$2" request="$3"
  bash "$SCRIPT" --json "$request" > "$TMP/out.json"
  python3 - "$TMP/out.json" "$expected_level" "$expected_complexity" <<'PY'
import json, pathlib, sys
path, level, complexity = pathlib.Path(sys.argv[1]), sys.argv[2], int(sys.argv[3])
data = json.loads(path.read_text())
assert data["routing"]["suggested_level"] == level, data
assert data["routing"]["complexity"] == complexity, data
assert "play_level" not in data and "play_level" not in data["routing"], data
PY
}

assert_route project 3 "Build a new multi-team subscription product from this clear business idea; the whole product needs specification."
assert_route epic 2 "Add a complete authentication capability spanning login, recovery, and session handling."
assert_route story 1 "Change one validated settings form so a single field is required."
assert_route project 3 "project: modernize the existing billing capability"
assert_route epic 2 "epic: modernize the billing capability"
assert_route story 1 "story: modernize the billing button"

echo "analyze-scale routing tests passed"
