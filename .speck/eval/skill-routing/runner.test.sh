#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RUNNER="$ROOT/.speck/eval/skill-routing/runner.py"

python3 "$RUNNER" self-test

TMP="$(mktemp -d)"
trap 'rm -r "$TMP"' EXIT

python3 - "$ROOT/.speck/reference/skill-routing-cases.json" "$TMP/perfect.json" <<'PY'
import json, pathlib, sys
suite_path, output_path = map(pathlib.Path, sys.argv[1:])
suite = json.loads(suite_path.read_text())
output_path.write_text(json.dumps({
    "predictions": [{"id": case["id"], "skill": case["expect"]} for case in suite["cases"]]
}))
PY

python3 "$RUNNER" score --predictions "$TMP/perfect.json"
python3 "$RUNNER" verify-reports
python3 "$RUNNER" score \
  --predictions "$ROOT/.speck/eval/skill-routing/reports/2026-08-10-codex-terra.json"

python3 - "$ROOT/.speck/reference/skill-routing-cases.json" "$TMP/perfect.json" "$TMP/mutant.json" <<'PY'
import json, pathlib, sys
suite_path, perfect_path, mutant_path = map(pathlib.Path, sys.argv[1:])
suite = json.loads(suite_path.read_text())
data = json.loads(perfect_path.read_text())
data["predictions"][0]["skill"] = suite["cases"][0]["forbid"][0]
mutant_path.write_text(json.dumps(data))
PY

if python3 "$RUNNER" score --predictions "$TMP/mutant.json" >/dev/null; then
  echo "FAIL: forbidden-selection mutant passed"
  exit 1
fi

cp -R "$ROOT/.speck/eval/skill-routing/reports" "$TMP/reports"
python3 - "$TMP/reports/2026-08-10-codex-terra.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
report = json.loads(path.read_text())
report["catalog_sha256"] = "0" * 64
path.write_text(json.dumps(report))
PY
if python3 "$RUNNER" verify-reports --reports-dir "$TMP/reports" >/dev/null; then
  echo "FAIL: stale-report mutant passed"
  exit 1
fi

echo "Skill-routing evaluator tests passed"
