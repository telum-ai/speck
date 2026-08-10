#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Test: live candidate clears immutable baseline"
bash "$ROOT/.speck/eval/score.sh" --check >/dev/null

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.speck" "$TMP/.cursor"
cp -R "$ROOT/.speck/eval" "$TMP/.speck/eval"
mkdir -p "$TMP/.speck/reference" "$TMP/.speck/templates"
cp "$ROOT/.speck/reference/skill-load-contracts.json" "$TMP/.speck/reference/skill-load-contracts.json"
cp -R "$ROOT/.speck/templates/." "$TMP/.speck/templates/"
cp -R "$ROOT/.cursor/skills" "$TMP/.cursor/skills"

before="$(shasum -a 256 "$TMP/.speck/eval/reports/baseline.json" | awk '{print $1}')"
bash "$TMP/.speck/eval/score.sh" --root "$TMP" >/dev/null
after="$(shasum -a 256 "$TMP/.speck/eval/reports/baseline.json" | awk '{print $1}')"
[[ "$before" == "$after" ]] || { echo "FAIL: score run mutated immutable baseline"; exit 1; }

echo "Test: moving a capability to an unreachable node turns the score red"
python3 - "$TMP" <<'PY'
from pathlib import Path
import json, re, sys
root = Path(sys.argv[1])
skill = root / ".cursor/skills/story-validate"
paths = set(skill.rglob("*.md"))
contracts = json.loads((root / ".speck/reference/skill-load-contracts.json").read_text())
for profile in contracts["profiles"].values():
    if profile.get("entrypoint") != ".cursor/skills/story-validate/SKILL.md":
        continue
    paths.update(root / rel for rel in profile.get("required_files", []))
    for selector in profile.get("selectors", {}).values():
        for value in selector.get("values", {}).values():
            paths.update(root / rel for rel in value.get("required_files", []))
for path in paths:
    text = path.read_text()
    text = re.sub(r"IS-IT-GOOD|adjudicat(?:e|ed|ion)?", "quality-check-removed", text, flags=re.I)
    path.write_text(text)
(skill / "references" / "unreachable-anchor.md").write_text("# unreachable\nadjudicate\n")
PY
if bash "$TMP/.speck/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score counted a capability outside the router-reachable corpus"
  exit 1
fi

echo "Test: an incorrect fixture verdict is blocking"
rm -rf "$TMP"
TMP="$(mktemp -d)"
mkdir -p "$TMP/.speck" "$TMP/.cursor"
cp -R "$ROOT/.speck/eval" "$TMP/.speck/eval"
mkdir -p "$TMP/.speck/reference" "$TMP/.speck/templates"
cp "$ROOT/.speck/reference/skill-load-contracts.json" "$TMP/.speck/reference/skill-load-contracts.json"
cp -R "$ROOT/.speck/templates/." "$TMP/.speck/templates/"
cp -R "$ROOT/.cursor/skills" "$TMP/.cursor/skills"
python3 - "$TMP/.speck/eval/fixtures/bl-leak/manifest.json" <<'PY'
from pathlib import Path
import json, sys
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data["expect"] = "clean-pass"
path.write_text(json.dumps(data, indent=2) + "\n")
PY
if bash "$TMP/.speck/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score exited green with an incorrect fixture verdict"
  exit 1
fi

echo "A1-lite score tests passed"
