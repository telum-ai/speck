#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-evidence-contract.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROJECT="$TMP/specs/projects/probe"
mkdir -p "$PROJECT"

cat > "$PROJECT/product-contract.md" <<'EOF'
# Product contract
PRM-001 Explicit confirmation precedes scheduling.
PRM-002 Workspace data is isolated.
EOF

write_valid() {
  cat > "$PROJECT/evidence-contract.md" <<'EOF'
---
artifact_type: evidence-contract
---
# Evidence Contract: Probe

## 1. Target Launch Platforms
| Platform | Build | Distribution |
|---|---|---|
| Web | Production-like build | Hosted target |

### 1a. Promise Proof Map
| Promise | Claim | Observable mechanism | Admissible evidence | Failure probe |
|---|---|---|---|---|
| PRM-001 | Confirmation precedes scheduling | Schedule transition | live-probe:path | Bypass confirmation |
| PRM-002 | Workspace data is isolated | Request-role denial | live-probe:path | Cross-workspace read |

## 2. Valid Proof Sources
Live reads and writes against the real target as named principals.

## 3. Invalid Proof Sources
Development-server screenshots, mock or bypass clients, and unadjudicated captures or source inspection do not establish these claims.

## 4. Required Runtime LARP / Integration Stress Tests
| Test | Persona / principal | Pass condition | Evidence home |
|---|---|---|---|
| Confirmation bypass | Facilitator | No schedule is created | live-probe:path |

## 5. Quality Judgment & Scoring Protocol
Judge CORRECT, ON-CONTRACT, FELT-GOOD, and TASTE separately. Record DOES-IT-WORK and IS-IT-GOOD separately.

## 6. Required Static Evidence
Current-SHA test and build output.

## 7. Required Live-Service Evidence
Real-boundary confirmation and request-role probes.

## 8. Readiness State Gate Criteria
NO-SHIP → IMPL-GREEN → INTEGRATION-GREEN → SHIP-RC → SHIP.

### 8a. PROFILE Gate Criteria
PROFILE_REGISTRY=project.md#PROFILE surfaces
PROFILE_GATE_COMMAND=bash .speck/scripts/profile-drift-check.sh --claim <state>
PROFILE_COVERAGE=every-row
PROFILE_P1_BLOCKS=true
PROFILE_MISSING_POLICY=finding
PROFILE_UNREACHABLE_POLICY=finding
PROFILE_PLACEHOLDER_POLICY=finding
EOF
}

expect_red() {
  local label="$1" expected="$2"
  if out="$(bash "$VALIDATOR" --strict "$PROJECT/evidence-contract.md" 2>&1)"; then
    echo "FAIL: $label passed strict validation"
    exit 1
  fi
  if ! grep -Fq "$expected" <<<"$out"; then
    echo "FAIL: $label failed for the wrong reason"
    echo "$out"
    exit 1
  fi
  echo "  ✓ $label"
}

echo "validate-evidence-contract semantic controls"
write_valid
bash "$VALIDATOR" --strict "$PROJECT/evidence-contract.md" >/dev/null
echo "  ✓ substantive contract passes"

write_valid
python3 - "$PROJECT/evidence-contract.md" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
text = p.read_text()
text = re.sub(r'(?ms)^## 1\..*?(?=^## 2\.)', '## 1. Target Launch Platforms\n\n', text)
p.write_text(text)
PY
expect_red "headers-only promise map" "Promise Proof Map has no concrete PRM-NNN row"

write_valid
sed -i.bak 's/## 5\. Quality Judgment & Scoring Protocol/## 5. Required Static Evidence/' "$PROJECT/evidence-contract.md"
expect_red "wrong section identity" "Section 5 has the wrong or missing semantic title"

write_valid
sed -i.bak '/PRM-002 |/d' "$PROJECT/evidence-contract.md"
expect_red "omitted product promise" "Promise Proof Map omits product-contract promises: PRM-002"

write_valid
python3 - "$PROJECT/evidence-contract.md" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
text = p.read_text()
text = re.sub(r'(?ms)(^## 3\.[^\n]*\n).*?(?=^## 4\.)', r'\1Generic proof cautions apply.\n\n', text)
p.write_text(text)
PY
expect_red "generic anti-proof pointer" "Invalid Proof Sources is a pointer or generic warning"

write_valid
sed -i.bak '/| Confirmation bypass |/d' "$PROJECT/evidence-contract.md"
expect_red "empty LARP table" "Runtime LARP / stress section has no executable row"

echo "All evidence-contract semantic tests passed"
