#!/usr/bin/env bash
# validate-wave-safety.test.sh — smoke tests for wave safety and concurrency collision validator

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-wave-safety.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Test 1: Valid parallel waves with no collisions passes"
cat > "$TMP/epics.md" <<'EOF'
# Epic Breakdown: Test Project

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when | Daily rebase cadence |
|------|-------|----------------------|-------------|----------------------|
| 1 | E001, E002 | Yes | E000 merged | rebase |

### E001: Epic One

**Touch-points (creates/modifies)**:
- Migrations: create table auto_reply_config
- Models/Services: models/availability.py, match_service.py
- Files/Components: src/components/AvailabilityCard.tsx

### E002: Epic Two

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/crew.py, crew_service.py
- Files/Components: src/components/CrewCard.tsx
EOF

bash "$VALIDATOR" "$TMP/epics.md"
echo "  ✓ Passed Test 1"


echo "Test 2: Two concurrent epics both authoring migrations fails"
cat > "$TMP/epics-fail-migrations.md" <<'EOF'
# Epic Breakdown: Test Project

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when | Daily rebase cadence |
|------|-------|----------------------|-------------|----------------------|
| 1 | E001, E002 | Yes | E000 merged | rebase |

### E001: Epic One

**Touch-points (creates/modifies)**:
- Migrations: create table auto_reply_config
- Models/Services: models/availability.py
- Files/Components: —

### E002: Epic Two

**Touch-points (creates/modifies)**:
- Migrations: create table crew_members
- Models/Services: models/crew.py
- Files/Components: —
EOF

if bash "$VALIDATOR" "$TMP/epics-fail-migrations.md" >/dev/null 2>&1; then
  echo "ERROR: Expected migration collision to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi


echo "Test 3: Two concurrent epics touching the same model/service file fails"
cat > "$TMP/epics-fail-models.md" <<'EOF'
# Epic Breakdown: Test Project

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when | Daily rebase cadence |
|------|-------|----------------------|-------------|----------------------|
| 1 | E001, E002 | Yes | E000 merged | rebase |

### E001: Epic One

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/availability.py, match_service.py
- Files/Components: —

### E002: Epic Two

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/availability.py, crew_service.py
- Files/Components: —
EOF

if bash "$VALIDATOR" "$TMP/epics-fail-models.md" >/dev/null 2>&1; then
  echo "ERROR: Expected shared models collision to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 3 (failed correctly)"
fi


echo "Test 4: Two concurrent epics touching the same component file fails"
cat > "$TMP/epics-fail-files.md" <<'EOF'
# Epic Breakdown: Test Project

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when | Daily rebase cadence |
|------|-------|----------------------|-------------|----------------------|
| 1 | E001, E002 | Yes | E000 merged | rebase |

### E001: Epic One

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: —
- Files/Components: src/components/AvailabilityCard.tsx

### E002: Epic Two

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: —
- Files/Components: src/components/AvailabilityCard.tsx
EOF

if bash "$VALIDATOR" "$TMP/epics-fail-files.md" >/dev/null 2>&1; then
  echo "ERROR: Expected shared files collision to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 4 (failed correctly)"
fi

echo "All validate-wave-safety tests passed successfully!"
exit 0
