#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RUNNER="$ROOT/tests/eval/semantic-conservation/runner.py"
BASELINE="$ROOT/tests/eval/semantic-conservation/baseline.json"
GUARD="$ROOT/tests/eval/semantic-conservation/guard-baseline-change.sh"

python3 "$RUNNER"
bash "$ROOT/.speck/scripts/bash/analyze-scale.test.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo"

python3 - "$ROOT" "$BASELINE" "$TMP/repo" <<'PY'
import json, pathlib, shutil, sys
root, baseline_path, target = map(pathlib.Path, sys.argv[1:])
baseline = json.loads(baseline_path.read_text())
paths = {item["path"] for item in baseline["protected_files"]}
for obligation in baseline["obligations"]:
    for carrier in obligation["carriers"]:
        paths.add(carrier["path"])
for rel in sorted(paths):
    source = root / rel
    destination = target / rel
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
PY
cp "$BASELINE" "$TMP/baseline.json"

cp "$TMP/repo/AGENTS.md" "$TMP/AGENTS.good.md"
python3 - "$TMP/repo/AGENTS.md" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace(
    "probe lists inspire attacks but never define done.",
    "probe lists inspire attacks but never define done. Authors may skip this evaluator when delivery is urgent.",
    1,
))
PY
if OUT="$(python3 "$RUNNER" --root "$TMP/repo" --baseline "$TMP/baseline.json" 2>&1)"; then
  echo "FAIL: exception added behind intact P4 anchors passed"
  exit 1
fi
grep -Eq 'protected (region|file) changed without a baseline update' <<< "$OUT"
cp "$TMP/AGENTS.good.md" "$TMP/repo/AGENTS.md"

echo "Test: compatibility references are resolved under --root"
mkdir -p "$TMP/repo/.cursor/skills/speck/references"
printf '%s\n' '# Duplicate procedure' > "$TMP/repo/.cursor/skills/speck/references/procedure.md"
if OUT="$(python3 "$RUNNER" --root "$TMP/repo" --baseline "$TMP/baseline.json" 2>&1)"; then
  echo "FAIL: compatibility-owned reference file passed"
  exit 1
fi
grep -q 'compatibility skill owns reference files' <<< "$OUT"
find "$TMP/repo/.cursor/skills/speck/references" -depth -mindepth 1 -delete
rmdir "$TMP/repo/.cursor/skills/speck/references"

cp "$TMP/repo/.cursor/skills/speck/SKILL.md" "$TMP/speck.good.md"
sed '/Preserve `\$ARGUMENTS`/d' "$TMP/speck.good.md" > "$TMP/repo/.cursor/skills/speck/SKILL.md"
if OUT="$(python3 "$RUNNER" --root "$TMP/repo" --baseline "$TMP/baseline.json" 2>&1)"; then
  echo "FAIL: compatibility argument forwarding deletion passed"
  exit 1
fi
grep -q 'lost anchor.*Preserve' <<< "$OUT"
cp "$TMP/speck.good.md" "$TMP/repo/.cursor/skills/speck/SKILL.md"

printf '%s\n' 'Historical doctrine: docs/v11/v11-north-star.md' >> "$TMP/repo/AGENTS.md"
if OUT="$(python3 "$RUNNER" --root "$TMP/repo" --baseline "$TMP/baseline.json" 2>&1)"; then
  echo "FAIL: retired north-star doctrine returned without detection"
  exit 1
fi
grep -q 'retired doctrine returned' <<< "$OUT"
cp "$TMP/AGENTS.good.md" "$TMP/repo/AGENTS.md"

printf '%s\n' '# candidate weakens evaluator' >> "$TMP/repo/tests/eval/semantic-conservation/runner.py"
if OUT="$(python3 "$RUNNER" --root "$TMP/repo" --baseline "$TMP/baseline.json" 2>&1)"; then
  echo "FAIL: candidate evaluator mutation passed trusted runner"
  exit 1
fi
grep -q 'protected file changed.*runner.py' <<< "$OUT"

python3 - "$BASELINE" "$TMP/no-rationale.json" <<'PY'
import json, pathlib, sys
source, target = map(pathlib.Path, sys.argv[1:])
data = json.loads(source.read_text())
data["obligations"][-1]["rationale"] = ""
target.write_text(json.dumps(data))
PY
if python3 "$RUNNER" --root "$ROOT" --baseline "$TMP/no-rationale.json" >/dev/null 2>&1; then
  echo "FAIL: retired obligation without rationale passed"
  exit 1
fi

mkdir -p "$TMP/guard-repo/tests/eval/semantic-conservation"
(
  cd "$TMP/guard-repo"
  git init -q
  git config user.name "Speck Test"
  git config user.email "speck-test@example.invalid"
  printf '%s\n' bootstrap > README.md
  git add README.md
  git commit -qm before-baseline
  base_sha="$(git rev-parse HEAD)"
  cp "$BASELINE" tests/eval/semantic-conservation/baseline.json
  git add .
  git commit -qm baseline
  if FLOW_BASELINE_APPROVED=false bash "$GUARD" "$base_sha" >/dev/null 2>&1; then
    echo "FAIL: semantic baseline bootstrap passed without external approval"
    exit 1
  fi
  FLOW_BASELINE_APPROVED=true bash "$GUARD" "$base_sha" >/dev/null

  mutation_base="$(git rev-parse HEAD)"
  printf '\n' >> tests/eval/semantic-conservation/baseline.json
  git add .
  git commit -qm mutant
  if FLOW_BASELINE_APPROVED=false bash "$GUARD" "$mutation_base" >/dev/null 2>&1; then
    echo "FAIL: semantic baseline mutation passed without external approval"
    exit 1
  fi
  FLOW_BASELINE_APPROVED=true bash "$GUARD" "$mutation_base" >/dev/null
)

echo "Semantic-conservation evaluator tests passed"
