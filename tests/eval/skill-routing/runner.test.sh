#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RUNNER="$ROOT/tests/eval/skill-routing/runner.py"
BASELINE_GUARD="$ROOT/tests/eval/skill-routing/guard-baseline-change.sh"

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
mkdir -p "$TMP/reports"
python3 - "$RUNNER" "$TMP/perfect.json" "$TMP/reports/synthetic.json" <<'PY'
import importlib.util, json, pathlib, sys
runner_path, predictions_path, output_path = map(pathlib.Path, sys.argv[1:])
spec = importlib.util.spec_from_file_location("routing_runner", runner_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
catalog = mod.load_catalog()
suite = mod.load_cases()
contract = mod.load_flow_contract()
agents = mod.load_agents()
flow = mod.load_flow(agents_text=agents)
predictions = json.loads(predictions_path.read_text())
report = mod.score_predictions(catalog, suite, predictions)
report.update({
    "schema_version": 3,
    "provider": "test-double",
    "model": "deterministic",
    "effort": "none",
    "started_at": "2026-08-11T00:00:00+00:00",
    "catalog_sha256": mod.digest(catalog),
    "cases_sha256": mod.digest(suite),
    "flow_sha256": mod.digest(flow),
    "flow_contract_sha256": mod.digest(contract),
    "agents_sha256": mod.digest(agents),
    "user_only_aliases_available": False,
    "execution": {"exit_code": 0},
})
output_path.write_text(json.dumps(report))
PY
python3 "$RUNNER" verify-reports --reports-dir "$TMP/reports"
python3 "$RUNNER" score --predictions "$TMP/reports/synthetic.json"

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

cp -R "$TMP/reports" "$TMP/reports-mutant"
python3 - "$TMP/reports-mutant/synthetic.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
report = json.loads(path.read_text())
report["flow_sha256"] = "0" * 64
path.write_text(json.dumps(report))
PY
if python3 "$RUNNER" verify-reports --reports-dir "$TMP/reports-mutant" >/dev/null; then
  echo "FAIL: stale-flow report mutant passed"
  exit 1
fi

rm -r "$TMP/reports-mutant"
cp -R "$TMP/reports" "$TMP/reports-mutant"
python3 - "$TMP/reports-mutant/synthetic.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
report = json.loads(path.read_text())
report["agents_sha256"] = "0" * 64
path.write_text(json.dumps(report))
PY
if python3 "$RUNNER" verify-reports --reports-dir "$TMP/reports-mutant" >/dev/null; then
  echo "FAIL: stale-AGENTS report mutant passed"
  exit 1
fi

rm -r "$TMP/reports-mutant"
cp -R "$TMP/reports" "$TMP/reports-mutant"
python3 - "$TMP/reports-mutant/synthetic.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
report = json.loads(path.read_text())
report["flow_contract_sha256"] = "0" * 64
path.write_text(json.dumps(report))
PY
if python3 "$RUNNER" verify-reports --reports-dir "$TMP/reports-mutant" >/dev/null; then
  echo "FAIL: stale-flow-baseline report mutant passed"
  exit 1
fi

mkdir -p "$TMP/guard-repo/tests/eval/skill-routing"
cp "$ROOT/tests/eval/skill-routing/baseline.json" "$TMP/guard-repo/tests/eval/skill-routing/baseline.json"
(
  cd "$TMP/guard-repo"
  git init -q
  git config user.name "Speck Test"
  git config user.email "speck-test@example.invalid"
  git add .
  git commit -qm baseline
  base_sha="$(git rev-parse HEAD)"
  FLOW_BASELINE_APPROVED=false bash "$BASELINE_GUARD" "$base_sha" >/dev/null
  printf '\n' >> tests/eval/skill-routing/baseline.json
  git add .
  git commit -qm mutant
  if FLOW_BASELINE_APPROVED=false bash "$BASELINE_GUARD" "$base_sha" >/dev/null 2>&1; then
    echo "FAIL: same-PR baseline mutation passed without external approval"
    exit 1
  fi
  FLOW_BASELINE_APPROVED=true bash "$BASELINE_GUARD" "$base_sha" >/dev/null
)

echo "Skill-routing evaluator tests passed"
