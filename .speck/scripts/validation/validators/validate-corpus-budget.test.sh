#!/usr/bin/env bash
# validate-corpus-budget.test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
SCRIPT="$ROOT/.speck/scripts/validation/validators/validate-corpus-budget.sh"

echo "Test: live repo passes"
bash "$SCRIPT" "$ROOT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Build a fake tree with validator + lib copied so ROOT=TMP works
mkdir -p "$TMP/.speck/scripts/validation/validators" "$TMP/.cursor/skills/good" "$TMP/.speck/reference"
cp "$ROOT/.speck/scripts/validation/validators/validate-corpus-budget.sh" \
   "$TMP/.speck/scripts/validation/validators/"
cp "$ROOT/.speck/scripts/validation/validators/_corpus_budget_lib.py" \
   "$TMP/.speck/scripts/validation/validators/"
printf '# grandfather\n' > "$TMP/.speck/corpus-budget-grandfather.txt"
cat > "$TMP/.speck/reference/skill-catalog-policy.json" <<'EOF'
{
  "schema_version": 1,
  "explicit_user_only": [],
  "compatibility_shims": [],
  "families": {
    "test": {
      "auto_entrypoints": ["good"],
      "user_only_routers": [],
      "compatibility_shims": []
    }
  }
}
EOF

# 250-line AGENTS should fail line ceiling
{
  echo '<!-- SPECK:START -->'
  for i in $(seq 1 250); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"

cat > "$TMP/.cursor/skills/good/SKILL.md" <<'EOF'
---
name: good
description: Checks deterministic budget behavior. Use when testing catalog and corpus enforcement.
---

# good
1. Do thing.
EOF

echo "Test: oversized AGENTS fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected failure"
  exit 1
fi

# Reset AGENTS to slim; inject essay into a skill reference
{
  echo '<!-- SPECK:START -->'
  for i in $(seq 1 10); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"

python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace(
    "Checks deterministic budget behavior. Use when testing catalog and corpus enforcement.",
    "Checks deterministic budget behavior without a trigger clause.",
))
PY
echo "Test: automatic description missing WHAT/WHEN separator fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected description-contract failure"
  exit 1
fi

python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace(
    "Checks deterministic budget behavior without a trigger clause.",
    "I check deterministic budget behavior. Use when testing catalog and corpus enforcement.",
))
PY
echo "Test: automatic description using first person fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected third-person failure"
  exit 1
fi

python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace(
    "I check deterministic budget behavior. Use when testing catalog and corpus enforcement.",
    "Checks deterministic budget behavior. Use when needed.",
))
PY
echo "Test: automatic description with vague trigger fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected trigger-specificity failure"
  exit 1
fi

python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace(
    "Checks deterministic budget behavior. Use when needed.",
    "Checks deterministic budget behavior. Use when testing catalog and corpus enforcement.",
))
PY

python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text() + "\nRead `references/missing.md` before acting.\n")
PY
echo "Test: router edge to missing reference fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected missing-reference failure"
  exit 1
fi
python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("\nRead `references/missing.md` before acting.\n", "\n"))
PY

mkdir -p "$TMP/.cursor/skills/essay/references"
cat > "$TMP/.cursor/skills/essay/SKILL.md" <<'EOF'
---
name: essay
description: Checks prose for forbidden essays. Use when testing agent-context lint enforcement.
---

# essay
1. Read references/procedure.md
EOF
cat > "$TMP/.cursor/skills/essay/references/procedure.md" <<'EOF'
# essay procedure
Field evidence from 001-odd says this gate matters.
1. Do the work.
EOF

echo "Test: essay pattern in skill references fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected essay failure"
  exit 1
fi

# Anti-theater: single procedure.md pointer
rm -rf "$TMP/.cursor/skills/essay"
mkdir -p "$TMP/.cursor/skills/theater/references"
cat > "$TMP/.cursor/skills/theater/SKILL.md" <<'EOF'
---
name: theater
description: Checks single-pointer reference structure. Use when testing anti-theater enforcement behavior.
---

# theater
1. Read and fully execute `references/procedure.md`.
EOF
echo '# procedure' > "$TMP/.cursor/skills/theater/references/procedure.md"
# slim AGENTS again (essay test may have left FAIL state only)
{
  echo '<!-- SPECK:START -->'
  for i in $(seq 1 10); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"

echo "Test: single procedure.md pointer fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected anti-theater failure"
  exit 1
fi

rm -r "$TMP/.cursor/skills/theater"
mkdir -p "$TMP/.cursor/skills/nested/references"
cat > "$TMP/.cursor/skills/nested/SKILL.md" <<'EOF'
---
name: nested
description: Checks nested reference edges. Use when testing direct router ownership and load-DAG enforcement.
---

# nested
If mode A: MUST Read `references/a.md`. Else MUST Read `references/b.md`.
EOF
cat > "$TMP/.cursor/skills/nested/references/a.md" <<'EOF'
# a
MUST Read `references/b.md` to continue.
EOF
echo '# b' > "$TMP/.cursor/skills/nested/references/b.md"

echo "Test: reference-to-reference load edge fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected nested-edge failure"
  exit 1
fi

echo '# orphan' > "$TMP/.cursor/skills/nested/references/orphan.md"
sed -i.bak '/MUST Read `references\/b.md` to continue/d' "$TMP/.cursor/skills/nested/references/a.md"
rm "$TMP/.cursor/skills/nested/references/a.md.bak"

echo "Test: router-orphaned reference fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected orphan failure"
  exit 1
fi

rm "$TMP/.cursor/skills/nested/references/orphan.md"
printf '' > "$TMP/.cursor/skills/nested/references/a.md"

echo "Test: empty reference node fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected empty-node failure"
  exit 1
fi

echo '# a' > "$TMP/.cursor/skills/nested/references/a.md"
mkdir -p "$TMP/.speck/reference"
cat > "$TMP/.speck/reference/skill-load-budgets.json" <<'EOF'
{
  "cases": [
    {
      "id": "deliberate-overflow",
      "files": [".cursor/skills/good/SKILL.md"],
      "max_bytes": 1
    }
  ]
}
EOF

echo "Test: declared execution-path byte overflow fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected load-path budget failure"
  exit 1
fi

cat > "$TMP/.cursor/skills/good/SKILL.md" <<'EOF'
---
name: good
description: Checks deterministic budget behavior. Use when testing catalog and corpus enforcement.
---

# good
Run `python3 .speck/scripts/context/speck_context.py good-static` before writes.
EOF
cat > "$TMP/.speck/reference/skill-load-budgets.json" <<'EOF'
{
  "cases": [
    {
      "id": "good-static",
      "files": [".cursor/skills/good/SKILL.md", "AGENTS.md"],
      "max_bytes": 10000
    }
  ]
}
EOF
cat > "$TMP/.speck/reference/skill-load-contracts.json" <<'EOF'
{
  "schema_version": 1,
  "profiles": {
    "good-static": {
      "entrypoint": ".cursor/skills/good/SKILL.md",
      "required_files": ["AGENTS.md"],
      "forbidden_files": [],
      "post_write_gates": ["test"]
    }
  }
}
EOF

echo "Test: executable load contract aligned with budget passes"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"

cat >> "$TMP/.cursor/skills/good/SKILL.md" <<'EOF'

## Response Format

Always print a uniform completion summary.
EOF
echo "Test: chat-only output schemas fail"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected chat-output-schema failure"
  exit 1
fi
python3 - "$TMP/.cursor/skills/good/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace(
    "\n## Response Format\n\nAlways print a uniform completion summary.\n",
    "\n",
))
PY

mkdir -p "$TMP/.cursor/skills/good/references"
printf '# spine\nRead `AGENTS.md` again.\n' > "$TMP/.cursor/skills/good/references/spine.md"
python3 - "$TMP/.speck/reference/skill-load-budgets.json" "$TMP/.speck/reference/skill-load-contracts.json" <<'PY'
import json, pathlib, sys
budget_path, contract_path = map(pathlib.Path, sys.argv[1:])
budget = json.loads(budget_path.read_text())
contract = json.loads(contract_path.read_text())
rel = ".cursor/skills/good/references/spine.md"
budget["cases"][0]["files"].append(rel)
contract["profiles"]["good-static"]["required_files"].append(rel)
budget_path.write_text(json.dumps(budget))
contract_path.write_text(json.dumps(contract))
PY

echo "Test: receipted instruction cannot create a second direct load edge"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected duplicate load-edge failure"
  exit 1
fi
rm "$TMP/.cursor/skills/good/references/spine.md"
python3 - "$TMP/.speck/reference/skill-load-budgets.json" "$TMP/.speck/reference/skill-load-contracts.json" <<'PY'
import json, pathlib, sys
budget_path, contract_path = map(pathlib.Path, sys.argv[1:])
budget = json.loads(budget_path.read_text())
contract = json.loads(contract_path.read_text())
rel = ".cursor/skills/good/references/spine.md"
budget["cases"][0]["files"].remove(rel)
contract["profiles"]["good-static"]["required_files"].remove(rel)
budget_path.write_text(json.dumps(budget))
contract_path.write_text(json.dumps(contract))
PY

python3 - "$TMP/.speck/reference/skill-load-budgets.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["cases"][0]["files"] = [".cursor/skills/good/SKILL.md"]
path.write_text(json.dumps(data))
PY

echo "Test: contract-to-budget drift fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected contract drift failure"
  exit 1
fi

cat > "$TMP/.speck/reference/skill-load-budgets.json" <<'EOF'
{"cases": []}
EOF
cat > "$TMP/.speck/reference/skill-load-contracts.json" <<'EOF'
{
  "schema_version": 1,
  "profiles": {
    "good-dynamic": {
      "entrypoint": ".cursor/skills/good/SKILL.md",
      "required_files": ["AGENTS.md"],
      "forbidden_files": [],
      "post_write_gates": ["test"],
      "max_bytes": 1,
      "selectors": {
        "mode": {
          "required": true,
          "exclusive": true,
          "values": {"x": {"required_files": []}}
        }
      }
    }
  }
}
EOF

echo "Test: dynamic contract byte overflow fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected dynamic contract budget failure"
  exit 1
fi

python3 - "$TMP/.speck/reference/skill-load-contracts.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["profiles"]["good-dynamic"]["max_bytes"] = 10000
path.write_text(json.dumps(data))
PY
mkdir -p "$TMP/.cursor/skills/old-good"
cat > "$TMP/.cursor/skills/old-good/SKILL.md" <<'EOF'
---
name: old-good
description: Compatibility alias for good. Invoke only when the user names old-good.
---

# old-good compatibility shim
Read and fully execute `.cursor/skills/good/SKILL.md`.
EOF
python3 - "$TMP/.speck/reference/skill-catalog-policy.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["families"]["test"]["compatibility_shims"] = ["old-good"]
path.write_text(json.dumps(data))
PY

echo "Test: compatibility shim left auto-invocable fails"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected catalog-policy failure"
  exit 1
}
grep -q "old-good disable-model-invocation must be true" <<<"$OUT" || {
  echo "FAIL: expected precise shim invocation failure"
  echo "$OUT"
  exit 1
}

python3 - "$TMP/.cursor/skills/old-good/SKILL.md" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("description: Compatibility alias for good. Invoke only when the user names old-good.\n", "description: Compatibility alias for good. Invoke only when the user names old-good.\ndisable-model-invocation: true\n"))
PY

echo "Test: declared user-only compatibility shim passes"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"

echo "All corpus-budget tests passed"
