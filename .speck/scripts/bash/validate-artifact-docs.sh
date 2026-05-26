#!/usr/bin/env bash
set -euo pipefail

# Validates that Speck's primary docs enumerate the full artifact set.
#
# v7 behavior (V6 fix):
# - AGENTS.md is the strict source of truth (canonical routing table)
# - .speck/README.md is checked for v7 center-of-gravity artifacts (warnings only)
# - Deprecated v6 names (epic-outline.md, outline.md) are NOT required
#
# Scope: methodology docs only (not specs/** in user projects)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

agents_path="$REPO_ROOT/AGENTS.md"
speck_readme_path="$REPO_ROOT/.speck/README.md"

if [[ ! -f "$agents_path" ]]; then
  echo "ERROR: Missing AGENTS.md at repo root" >&2
  exit 1
fi

errors=0
warnings=0

check_agents() {
  local needle="$1"
  if ! grep -Fq "$needle" "$agents_path"; then
    echo "❌ Missing in AGENTS.md: $needle"
    errors=1
  fi
}

check_readme_warn() {
  local needle="$1"
  if [[ ! -f "$speck_readme_path" ]]; then
    return
  fi
  if ! grep -Fq "$needle" "$speck_readme_path"; then
    echo "⚠️  Missing in .speck/README.md (non-blocking): $needle"
    warnings=1
  fi
}

echo "🔍 Validating artifact coverage (AGENTS.md strict, README.md advisory)..."

# === AGENTS.md — canonical routing table (Speck v7) ===

# Project-level
for needle in \
  project.md product-contract.md evidence-contract.md project-state.md project-decisions-log.md \
  context.md constitution.md architecture.md PRD.md epics.md \
  ux-strategy.md design-system.md domain-model.md \
  project-import.md project-landscape-overview.md \
  project-recheck-report.md project-audit-report.md project-punch-list.md \
  sprint-log.md project-retro.md project-validation-report.md \
  "personas/" "design-system/primitives.md"; do
  check_agents "$needle"
done

check_agents "project-*-research-report-*.md"

# Epic-level
for needle in \
  epic.md epic-architecture.md epic-tech-spec.md epic-breakdown.md experience-chain.md \
  user-journey.md wireframes.md audit-report.md epic-validation-report.md \
  epic-analysis-report.md epic-retro.md; do
  check_agents "$needle"
done

check_agents "epic-codebase-scan*.md"
check_agents "epic-*-research-report-*.md"

# Story-level
for needle in \
  spec.md plan.md tasks.md data-model.md "contracts/" ui-spec.md quickstart.md \
  validation-report.md story-retro.md; do
  check_agents "$needle"
done

check_agents "codebase-scan-*.md"
check_agents "story-*-research-report-*.md"

# === .speck/README.md — v7 center-of-gravity (warnings only) ===
for needle in \
  product-contract.md evidence-contract.md project-state.md experience-chain.md audit-report.md; do
  check_readme_warn "$needle"
done

# Deprecated v6 artifacts must NOT be required
if grep -Fq "epic-outline.md" "$agents_path" && ! grep -Fq "DEPRECATED" "$agents_path"; then
  echo "⚠️  AGENTS.md still references epic-outline.md without DEPRECATED marker"
  warnings=1
fi

if [[ "$errors" -eq 1 ]]; then
  echo ""
  echo "❌ Artifact doc validation failed. Update AGENTS.md to include missing canonical artifacts."
  exit 1
fi

if [[ "$warnings" -eq 1 ]]; then
  echo ""
  echo "⚠️  Advisory README gaps found — consider updating .speck/README.md directory structure."
fi

echo "✅ Artifact doc validation passed"
exit 0
