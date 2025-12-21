#!/usr/bin/env bash
set -euo pipefail

# Validates that Speck's primary docs enumerate the full artifact set.
#
# This prevents drift where commands/templates produce files that are not reflected
# in AGENTS.md and .speck/README.md directory structure sections.
#
# Scope:
# - Checks methodology docs only (not specs/**)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

agents_path="$REPO_ROOT/AGENTS.md"
speck_readme_path="$REPO_ROOT/.speck/README.md"

if [[ ! -f "$agents_path" ]]; then
  echo "ERROR: Missing AGENTS.md at repo root" >&2
  exit 1
fi
if [[ ! -f "$speck_readme_path" ]]; then
  echo "ERROR: Missing .speck/README.md" >&2
  exit 1
fi

missing=0

check_in_file() {
  local needle="$1"
  local file="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "❌ Missing in $(basename "$file"): $needle"
    missing=1
  fi
}

check_both() {
  local needle="$1"
  check_in_file "$needle" "$agents_path"
  check_in_file "$needle" "$speck_readme_path"
}

echo "🔍 Validating artifact coverage in AGENTS.md and .speck/README.md..."

# Project-level artifacts (explicit)
check_both "project.md"
check_both "context.md"
check_both "constitution.md"
check_both "architecture.md"
check_both "PRD.md"
check_both "epics.md"
check_both "ux-strategy.md"
check_both "design-system.md"
check_both "project-import.md"
check_both "project-landscape-overview.md"
check_both "project-roadmap.md"
check_both "project-analysis-report.md"
check_both "project-validation-report.md"
check_both "project-validation-summary.md"
check_both "project-punch-list.md"
check_both "project-retro.md"

# Project-level artifacts (patterns)
check_both "project-*-research-prompt-*.md"
check_both "project-*-research-report-*.md"

# Epic-level artifacts (explicit)
check_both "epic.md"
check_both "epic-outline.md"
check_both "epic-architecture.md"
check_both "epic-tech-spec.md"
check_both "epic-breakdown.md"
check_both "epic-analysis-report.md"
check_both "epic-validation-report.md"
check_both "epic-punch-list.md"
check_both "epic-retro.md"
check_both "user-journey.md"
check_both "wireframes.md"

# Epic-level artifacts (patterns)
check_both "epic-codebase-scan*.md"
check_both "epic-*-research-prompt-*.md"
check_both "epic-*-research-report-*.md"

# Story-level artifacts (explicit)
check_both "spec.md"
check_both "outline.md"
check_both "plan.md"
check_both "tasks.md"
check_both "data-model.md"
check_both "contracts/"
check_both "quickstart.md"
check_both "ui-spec.md"
check_both "validation-report.md"
check_both "story-retro.md"

# Story-level artifacts (patterns)
check_both "codebase-scan-*.md"
check_both "story-*-research-prompt-*.md"
check_both "story-*-research-report-*.md"

if [[ "$missing" -eq 1 ]]; then
  echo ""
  echo "❌ Artifact doc validation failed. Update AGENTS.md and/or .speck/README.md to include missing artifacts."
  exit 1
fi

echo "✅ Artifact doc validation passed"
