#!/usr/bin/env bash
# Speck v6 → v7 additive migration script.
#
# Strategy: NEVER delete v6 artifacts. Add v7 artifacts as scaffolds; flag them
# for the agent to fill in via the corresponding skills. The agent runs the
# skills to populate content based on existing v6 docs.
#
# Usage:
#   ./migrate.sh <project-dir>
#   ./migrate.sh specs/projects/my-product
#
# Output:
#   - .speck/project.json updated with speck_version: 7.0.0
#   - product-contract.md scaffolded (if missing)
#   - evidence-contract.md scaffolded (if missing)
#   - project-decisions-log.md scaffolded (if missing)
#   - project-state.md scaffolded (if missing — agent should run /project-state to fill)
#   - design-system/primitives.md scaffolded (if UI project + missing)
#   - Migration report: <project>/migration-report.md

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-dir>"
  echo ""
  echo "  <project-dir>  Path to specs/projects/<project-id>/"
  exit 1
fi

PROJECT_DIR="$1"
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: project directory not found: $PROJECT_DIR"
  exit 1
fi

# Locate workspace root (search up for .speck/)
WORKSPACE_ROOT="$(pwd)"
while [[ "$WORKSPACE_ROOT" != "/" && ! -d "$WORKSPACE_ROOT/.speck" ]]; do
  WORKSPACE_ROOT="$(dirname "$WORKSPACE_ROOT")"
done

if [[ ! -d "$WORKSPACE_ROOT/.speck" ]]; then
  echo "Error: could not find .speck/ directory (searched up from current dir)"
  exit 1
fi

TEMPLATES="$WORKSPACE_ROOT/.speck/templates"
SCRIPTS="$WORKSPACE_ROOT/.speck/scripts"
REPORT="$PROJECT_DIR/migration-report.md"
DATE="$(date -u +%Y-%m-%d)"

echo "🥓 Speck v6 → v7 migration"
echo "  Project: $PROJECT_DIR"
echo "  Workspace: $WORKSPACE_ROOT"
echo ""

CREATED=()
SKIPPED=()
NEEDS_AGENT=()

# --- 1. Update project.json speck_version ---
PROJECT_JSON="$WORKSPACE_ROOT/.speck/project.json"
if [[ -f "$PROJECT_JSON" ]]; then
  if grep -q '"speck_version"' "$PROJECT_JSON"; then
    # Update in-place via Python (most portable JSON-aware edit)
    python3 -c "
import json, sys
with open('$PROJECT_JSON') as f:
    d = json.load(f)
d['speck_version'] = '7.0.0'
with open('$PROJECT_JSON', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
    echo "✅ Updated .speck/project.json speck_version → 7.0.0"
  else
    python3 -c "
import json
with open('$PROJECT_JSON') as f:
    d = json.load(f)
d['speck_version'] = '7.0.0'
with open('$PROJECT_JSON', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
    echo "✅ Added speck_version to .speck/project.json"
  fi
else
  cat > "$PROJECT_JSON" <<EOF
{
  "play_level": "build",
  "speck_version": "7.0.0",
  "migrated_from_v6": true,
  "migrated_at": "$DATE"
}
EOF
  echo "✅ Created .speck/project.json (defaulted to play_level: build)"
fi

# --- Helper: scaffold a file from template if missing ---
scaffold() {
  local target="$1"
  local template="$2"
  local description="$3"
  if [[ -f "$target" ]]; then
    SKIPPED+=("$target (already exists)")
    return
  fi
  if [[ ! -f "$template" ]]; then
    echo "⚠️  Template not found: $template — skipping $target"
    return
  fi
  mkdir -p "$(dirname "$target")"
  cp "$template" "$target"
  # Prepend a banner
  TMPFILE=$(mktemp)
  cat > "$TMPFILE" <<EOF
<!-- v7 MIGRATION SCAFFOLD — DO NOT TREAT AS REAL TRUTH UNTIL FILLED IN.    -->
<!-- This file was scaffolded on $DATE from a v6 → v7 migration.            -->
<!-- Primary path:  /speck-catch-up    (brownfield reconstruction)          -->
<!-- Manual path:   $description                              -->

EOF
  cat "$target" >> "$TMPFILE"
  mv "$TMPFILE" "$target"
  CREATED+=("$target (scaffold; run $description)")
  NEEDS_AGENT+=("$description → $target")
}

# --- 2. Scaffold product-contract.md ---
scaffold \
  "$PROJECT_DIR/product-contract.md" \
  "$TEMPLATES/project/product-contract-template.md" \
  "/project-product-contract"

# --- 3. Scaffold evidence-contract.md ---
scaffold \
  "$PROJECT_DIR/evidence-contract.md" \
  "$TEMPLATES/project/evidence-contract-template.md" \
  "/project-evidence-contract"

# --- 4. Scaffold project-decisions-log.md ---
scaffold \
  "$PROJECT_DIR/project-decisions-log.md" \
  "$TEMPLATES/project/project-decisions-log-template.md" \
  "/speck-decision-log (populate from existing decisions)"

# --- 5. Scaffold project-state.md (agent will regen via /project-state) ---
scaffold \
  "$PROJECT_DIR/project-state.md" \
  "$TEMPLATES/project/project-state-template.md" \
  "/project-state (auto-regenerate)"

# --- 6. Scaffold design-system/primitives.md if UI project ---
HAS_UI="no"
if [[ -d "$PROJECT_DIR" ]] && grep -rli "design-system\|ui-spec\|wireframe\|react\|svelte\|flutter\|swiftui\|tsx\|jsx" "$PROJECT_DIR" >/dev/null 2>&1; then
  HAS_UI="yes"
fi

if [[ "$HAS_UI" == "yes" ]]; then
  scaffold \
    "$PROJECT_DIR/design-system/primitives.md" \
    "$TEMPLATES/project/primitives-registry-template.md" \
    "/project-design-system (registry mode) — populate from existing components"
fi

# --- 7. Apply SHA stamps to existing v6 truth artifacts ---
echo ""
echo "📝 Applying SHA stamps to existing truth artifacts…"
TRUTH_FILES=(
  "$PROJECT_DIR/project.md"
  "$PROJECT_DIR/PRD.md"
  "$PROJECT_DIR/architecture.md"
  "$PROJECT_DIR/context.md"
  "$PROJECT_DIR/constitution.md"
  "$PROJECT_DIR/ux-strategy.md"
  "$PROJECT_DIR/design-system.md"
  "$PROJECT_DIR/domain-model.md"
  "$PROJECT_DIR/epics.md"
)
STAMPED=0
for f in "${TRUTH_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    if ! grep -q "as of SHA" "$f"; then
      bash "$SCRIPTS/stamp-truth.sh" "$f" 2>/dev/null && STAMPED=$((STAMPED + 1)) || true
    fi
  fi
done
echo "  Stamped $STAMPED files"

# --- 8. Write migration report ---
cat > "$REPORT" <<EOF
# v7 Migration Report

**Date**: $DATE 
**Project**: $PROJECT_DIR 
**Migration mode**: Additive (no v6 artifacts deleted)

## What changed

### Created (scaffolds — need agent population)

$(printf '%s\n' "${CREATED[@]:-(none)}" | sed 's/^/- /')

### Skipped (already exist)

$(printf '%s\n' "${SKIPPED[@]:-(none)}" | sed 's/^/- /')

### Truth artifacts SHA-stamped

$STAMPED files stamped with current HEAD.

## Next actions for the agent

**This project needs a catch-up pass.** Migration only scaffolded empty templates — it didn't fill them, didn't audit existing implementations, didn't downgrade over-optimistic v6 status claims. Run:

\`\`\`
/speck-catch-up
\`\`\`

This brownfield skill:
1. Backfills product-contract.md from project.md + PRD.md + ux-strategy.md + …
2. Backfills evidence-contract.md from the active recipe's defaults
3. Reconstructs project-decisions-log.md from git history
4. Honesty-pass on existing stories: downgrades unsupported PASS claims to IMPL-GREEN
5. Writes project-catch-up-plan.md with prioritized remediation work

After catch-up, run \`/project-state\` to regenerate the engagement-pickup view.

### Skills you can also run individually (if catch-up was already done)

$(printf '%s\n' "${NEEDS_AGENT[@]:-(none)}" | sed 's/^/1. /')

## v6 artifacts (preserved, still valid)

- All v6 \`project.md\`, \`PRD.md\`, \`architecture.md\`, etc. remain in place
- Constitution / domain-model / ux-strategy / design-system retain their content; if play level is Build, that content should also be merged into \`product-contract.md\` over time (not by this script — the agent does it via \`/project-product-contract\`)
- Existing epic and story directories are untouched

## Compatibility

The agent will operate in **v7 mode** but will read v6 artifacts as inputs where v7 equivalents don't yet exist (e.g., reading \`ux-strategy.md\` if \`product-contract.md\` Section 6 isn't filled in yet).

*[as of SHA $(git -C "$WORKSPACE_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown) | verified $DATE | speck v7.0.0]*
EOF

bash "$SCRIPTS/stamp-truth.sh" "$REPORT" 2>/dev/null || true

# Drop a marker so engagement-time agents detect that catch-up is needed.
# The marker lives at workspace root (not project root) because the agent
# checks for it on every engagement, before touching any project.
MARKER="$WORKSPACE_ROOT/.speck/.migration-needs-catchup"
if [[ ! -f "$MARKER" ]]; then
  cat > "$MARKER" <<MARKEREOF
# Speck v6 → v7 migration marker
#
# This file signals that one or more projects were migrated from v6 → v7
# and still need a catch-up pass to:
#   - Backfill product-contract.md + evidence-contract.md from v6 docs
#   - Reconstruct project-decisions-log.md from git history
#   - Downgrade unsupported PASS claims on existing stories
#   - Emit project-catch-up-plan.md
#
# Agents that read this file on engagement MUST run /speck-catch-up
# before any new feature work. Delete this file only after catch-up
# has completed for every migrated project.
#
# Created: $DATE
# Projects in scope: appended below as migrations run
MARKEREOF
fi

echo "$PROJECT_DIR" >> "$MARKER"

echo ""
echo "✅ Migration scaffolding complete"
echo "  Report: $REPORT"
echo "  ⚠️  CATCH-UP REQUIRED: run /speck-catch-up to actually fill the scaffolded artifacts"
echo "      and downgrade over-optimistic v6 status claims to v7-honest readiness states."
echo "  (Marker written: $MARKER)"
