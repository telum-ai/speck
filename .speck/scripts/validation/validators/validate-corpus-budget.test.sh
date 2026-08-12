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

mkdir -p "$TMP/.speck/scripts"
printf '#!/usr/bin/env bash\n/speck-reprove\n' > "$TMP/.speck/scripts/retired-route.sh"
echo "Test: retired migration command in active runtime fails"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected retired-route failure"
  exit 1
}
grep -q "retired migration command /speck-reprove" <<<"$OUT" || {
  echo "FAIL: expected precise retired migration route failure"
  echo "$OUT"
  exit 1
}
rm "$TMP/.speck/scripts/retired-route.sh"

printf '# Guide\nRun `/larp` now.\n' > "$TMP/.speck/scripts/short-route.md"
echo "Test: nonexistent short audit/LARP command in active runtime fails"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected short-route failure"
  exit 1
}
grep -q "nonexistent short command /larp" <<<"$OUT" || {
  echo "FAIL: expected precise short-route failure"
  echo "$OUT"
  exit 1
}
rm "$TMP/.speck/scripts/short-route.md"

printf '# Guide\nRun `/recheck` now.\n' > "$TMP/.speck/scripts/short-route.md"
echo "Test: nonexistent short recheck command in active runtime fails"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected short-route failure"
  exit 1
}
grep -q "nonexistent short command /recheck" <<<"$OUT" || {
  echo "FAIL: expected precise short-route failure"
  echo "$OUT"
  exit 1
}
rm "$TMP/.speck/scripts/short-route.md"

# AGENTS.md emoji-section-header rule must not depend on ripgrep being on
# PATH (it used to be wrapped in `if command -v rg`, so a host without rg
# silently skipped the check and still printed PASS), and must not be a
# second, independently-maintained regex that can drift from the Python
# EMOJI_HEADER set used for every other agent-prose surface.
cp "$TMP/AGENTS.md" "$TMP/AGENTS.md.bak"
{
  echo '<!-- SPECK:START -->'
  echo '## 🎯 Goals'
  for i in $(seq 1 8); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"

echo "Test: AGENTS.md emoji section header fails with rg on PATH"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected AGENTS.md emoji-header failure with rg present"
  exit 1
fi

echo "Test: AGENTS.md emoji section header fails WITHOUT rg on PATH"
OUT=$(env -i PATH=/usr/bin:/bin bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected AGENTS.md emoji-header failure without rg (was silently skipped and PASSed)"
  echo "$OUT"
  exit 1
}
grep -q "emoji section headers" <<<"$OUT" || {
  echo "FAIL: expected the emoji-header check to actually run without rg on PATH"
  echo "$OUT"
  exit 1
}
mv "$TMP/AGENTS.md.bak" "$TMP/AGENTS.md"

# The bash rg block that was deleted covered a DIFFERENT 18-glyph set than
# the Python EMOJI_HEADER set it was replaced by (only 9 of them overlapped:
# 🎯🚨📋🧠🧪📊🧭🧱🏁). Routing AGENTS.md through EMOJI_HEADER unchanged would
# have silently dropped coverage for the other 9 (🚦🎚📁🗺⚖🔌🎛🦾📚) — every
# glyph the deleted rg pattern caught must still fail today, not just the
# one the first test above happens to use (U+1F3AF / 🎯).
cp "$TMP/AGENTS.md" "$TMP/AGENTS.md.bak"
echo "Test: every previously-rg-covered AGENTS.md emoji still fails (no silent narrowing)"
for e in 🚦 🎚 📁 🗺 ⚖ 🔌 🎛 🦾 📚; do
  {
    echo '<!-- SPECK:START -->'
    echo "## ${e} Goals"
    for i in $(seq 1 8); do echo "line $i"; done
    echo '<!-- SPECK:END -->'
  } > "$TMP/AGENTS.md"
  if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
    echo "FAIL: expected AGENTS.md emoji-header failure for '$e' (rg-only glyph dropped by the Python migration)"
    exit 1
  fi
done
mv "$TMP/AGENTS.md.bak" "$TMP/AGENTS.md"

# Router grandfather waivers: the forward mint at gf_key = f"{name}#router"
# (n_refs >= 2) had no matching branch in the reverse-staleness audit — the
# "#" fails the "/" skill-ref check, and the bare-name fallback re-checked
# the skill against max_body (200) instead of MAX_ROUTER_BODY (80), so
# either spelling failed even while the waiver was still legitimately in
# force. Build a real >=2-ref router whose body exceeds the 80-line cap.
mkdir -p "$TMP/.cursor/skills/waived-router/references"
python3 - "$TMP/.cursor/skills/waived-router" <<'PY'
from pathlib import Path
import sys
base = Path(sys.argv[1])
lines = [
    "If mode a: MUST Read `references/a.md`.",
    "If mode b: MUST Read `references/b.md`.",
]
lines += [f"padding line {i}" for i in range(90)]
(base / "SKILL.md").write_text(
    "---\n"
    "name: waived-router\n"
    "description: Routes to per-mode references. Use when testing router grandfather waivers.\n"
    "---\n\n"
    "# waived-router\n" + "\n".join(lines) + "\n"
)
(base / "references" / "a.md").write_text("# a\ncontent\n")
(base / "references" / "b.md").write_text("# b\ncontent\n")
PY

echo "Test: router body over 80 lines fails without a grandfather waiver"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected router body-cap failure"
  exit 1
fi

echo '# grandfather' > "$TMP/.speck/corpus-budget-grandfather.txt"
echo 'waived-router#router' >> "$TMP/.speck/corpus-budget-grandfather.txt"
echo "Test: '#router'-suffixed grandfather waiver passes (was: skill missing)"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) || {
  echo "FAIL: expected the #router waiver to pass"
  echo "$OUT"
  exit 1
}
grep -q "WARN grandfather body waived-router" <<<"$OUT" || {
  echo "FAIL: expected a grandfather WARN, got:"
  echo "$OUT"
  exit 1
}

echo '# grandfather' > "$TMP/.speck/corpus-budget-grandfather.txt"
echo 'waived-router' >> "$TMP/.speck/corpus-budget-grandfather.txt"
echo "Test: bare-name grandfather waiver passes for a router (was: re-checked against 200, not 80)"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"

python3 - "$TMP/.cursor/skills/waived-router/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
lines = text.splitlines()
head = lines[:8]  # frontmatter + the two "If mode" routing lines
path.write_text("\n".join(head) + "\n")
PY
echo "Test: stale router grandfather entry (now under cap) is flagged for removal"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected a stale-grandfather-entry failure"
  exit 1
}
grep -q "grandfather entry 'waived-router' is now <= 80" <<<"$OUT" || {
  echo "FAIL: expected the stale entry to report the router cap (80), not the general body cap (200)"
  echo "$OUT"
  exit 1
}
rm -rf "$TMP/.cursor/skills/waived-router"
printf '# grandfather\n' > "$TMP/.speck/corpus-budget-grandfather.txt"

# The AGENTS.md byte/line ceiling is declared once in skill-load-budgets.json
# (`ceilings`), not restated as a bash literal — prove the script actually
# reads it rather than only tolerating its presence.
cp "$TMP/.speck/reference/skill-load-budgets.json" "$TMP/.speck/reference/skill-load-budgets.json.bak"
python3 - "$TMP/.speck/reference/skill-load-budgets.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["ceilings"] = {"agents_bytes": 10, "agents_lines": 200}
path.write_text(json.dumps(data))
PY
echo "Test: AGENTS.md byte ceiling is read from skill-load-budgets.json, not hardcoded"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected the registry ceiling of 10 bytes to fail slim AGENTS.md"
  echo "$OUT"
  exit 1
}
grep -q "max 10)" <<<"$OUT" || {
  echo "FAIL: expected the reported ceiling to reflect the registry value (10), not a hardcoded default"
  echo "$OUT"
  exit 1
}
mv "$TMP/.speck/reference/skill-load-budgets.json.bak" "$TMP/.speck/reference/skill-load-budgets.json"

# A `ceilings` block that IS declared but malformed (wrong type, a missing
# key, non-positive) must fail loudly, never silently fall back to the
# historical 16384/200 default with no warning — that would reopen the same
# "gate reports a verdict it did not compute from the declared source" class
# this registry exists to close, one layer up. Only a fully-absent ceilings
# key may fall back silently (minimal fixtures without a full registry).
cp "$TMP/.speck/reference/skill-load-budgets.json" "$TMP/.speck/reference/skill-load-budgets.json.bak"

python3 - "$TMP/.speck/reference/skill-load-budgets.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["ceilings"] = {"agents_bytes": "20480", "agents_lines": 200}
path.write_text(json.dumps(data))
PY
echo "Test: string-typed ceilings.agents_bytes fails loudly (was: silently enforced 16384)"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected a malformed-ceilings failure, not a silent fall-back"
  echo "$OUT"
  exit 1
}
grep -q "ceilings.agents_bytes and ceilings.agents_lines must both be present positive integers" <<<"$OUT" || {
  echo "FAIL: expected a precise malformed-ceilings message"
  echo "$OUT"
  exit 1
}

python3 - "$TMP/.speck/reference/skill-load-budgets.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["ceilings"] = {"agents_bytes": 9000}  # agents_lines omitted
path.write_text(json.dumps(data))
PY
echo "Test: ceilings missing agents_lines fails loudly (was: silently enforced 16384, declared 9000 unheard)"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected a malformed-ceilings failure for a partial ceilings block"
  echo "$OUT"
  exit 1
}
grep -q "ceilings.agents_bytes and ceilings.agents_lines must both be present positive integers" <<<"$OUT" || {
  echo "FAIL: expected a precise malformed-ceilings message"
  echo "$OUT"
  exit 1
}

python3 - "$TMP/.speck/reference/skill-load-budgets.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data["ceilings"] = 0  # not even an object
path.write_text(json.dumps(data))
PY
echo "Test: non-object ceilings value fails loudly"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected a malformed-ceilings failure for a non-object ceilings value"
  echo "$OUT"
  exit 1
}
grep -q "ceilings must be an object" <<<"$OUT" || {
  echo "FAIL: expected a precise non-object-ceilings message"
  echo "$OUT"
  exit 1
}

mv "$TMP/.speck/reference/skill-load-budgets.json.bak" "$TMP/.speck/reference/skill-load-budgets.json"
echo "Test: registry with no ceilings key at all still falls back to the historical default"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"

# .speck/reference/*.md essay-pattern lint used to be a hand-copied subset
# (REF_ROOT_ESSAY) missing "Until v9.", "feel free to" and "anti-bloat
# trade" — identical prose was a hard FAIL in a SKILL.md and clean in
# .speck/reference, an accident of two copy-pastes rather than policy. The
# version-history pattern is also generalized so a fresh "Until v<N>."
# cannot ship unflagged every release without a manual regex edit.
printf '# ref\nUntil v9. this gate was advisory.\n' > "$TMP/.speck/reference/essay-probe.md"
echo "Test: .speck/reference essay pattern 'Until v9.' now fails (was ref-root-only gap)"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected .speck/reference essay failure for 'Until v9.'"
  exit 1
fi

printf '# ref\nFeel free to skip this step.\n' > "$TMP/.speck/reference/essay-probe.md"
echo "Test: .speck/reference essay pattern 'feel free to' now fails (was ref-root-only gap)"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected .speck/reference essay failure for 'feel free to'"
  exit 1
fi

printf '# ref\nUntil v11. this gate was advisory.\n' > "$TMP/.speck/reference/essay-probe.md"
echo "Test: .speck/reference essay pattern 'Until v11.' fails (generalized Until v<N>.)"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected .speck/reference essay failure for 'Until v11.'"
  exit 1
fi
rm "$TMP/.speck/reference/essay-probe.md"

# Retired/typo route detection used to be a closed three(+three)-name
# dictionary (audit/larp/recheck, catch-up/reprove/graph-up), so any other
# retired or mistyped route — /project-analyze, /story-spec,
# /retrospective — shipped green. It is now catalog-driven: every
# backtick-quoted /route must resolve to a live skill directory or a
# declared host command.
printf '# probe\nRun `/project-analyze` after planning.\n' > "$TMP/.speck/reference/route-catalog-probe.md"
echo "Test: route not in the old fixed dictionary still fails (catalog-driven)"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected route \`/project-analyze\` to fail catalog resolution"
  echo "$OUT"
  exit 1
}
grep -q 'route `/project-analyze`' <<<"$OUT" || {
  echo "FAIL: expected a precise unresolved-route failure"
  echo "$OUT"
  exit 1
}

printf '# probe\nRun `/good` first.\n' > "$TMP/.speck/reference/route-catalog-probe.md"
echo "Test: route resolving to a live skill directory passes"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"

printf '# probe\nRun `/goal` when the host offers it.\n' > "$TMP/.speck/reference/route-catalog-probe.md"
echo "Test: declared host-level route (not a skill) passes"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"
rm "$TMP/.speck/reference/route-catalog-probe.md"

# The catalog-driven route check must cover .speck/templates like the
# sibling retired/short-route checks in the same function already do —
# packages/cli/lib/sync.js ships .speck/templates into every downstream
# repo (ALWAYS_OVERWRITE), so a dead route there is a load edge readers
# follow literally, not exempt worked-example prose.
mkdir -p "$TMP/.speck/templates/story"
printf '# tmpl\nRun `/project-analyze` after planning.\n' > "$TMP/.speck/templates/story/route-probe-template.md"
echo "Test: dead route inside .speck/templates fails (was excluded from the catalog scan)"
OUT=$(bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP" 2>&1) && {
  echo "FAIL: expected route \`/project-analyze\` inside .speck/templates to fail catalog resolution"
  echo "$OUT"
  exit 1
}
grep -q 'route `/project-analyze`.*templates' <<<"$OUT" || {
  echo "FAIL: expected a precise unresolved-route failure naming the templates path"
  echo "$OUT"
  exit 1
}

printf '# tmpl\nRun `/good` first.\n' > "$TMP/.speck/templates/story/route-probe-template.md"
echo "Test: route inside .speck/templates resolving to a live skill directory passes"
bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"
rm -rf "$TMP/.speck/templates/story"

echo "All corpus-budget tests passed"
