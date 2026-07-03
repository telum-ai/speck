#!/usr/bin/env bash
# staleness-check.sh — SHA-stamp staleness detector for Speck v7 truth artifacts
#
# Usage:
#   .speck/scripts/staleness-check.sh [PROJECT_DIR]
#
# If PROJECT_DIR is omitted, walks up from cwd until specs/projects/<id>/ is found.
#
# Output: For each truth artifact, prints one of:
#   ✅ FRESH    <path>    (sha matches HEAD AND verified within 14 days)
#   ⚠️  STALE    <path>    (verified > 14 days ago)
#   ⚠️  DRIFT    <path>    (sha differs from HEAD)
#   ⚠️  NOSTAMP  <path>    (no SHA stamp found — treated as proposal)
#   ❌ MISSING  <path>    (artifact required by play level but doesn't exist)
#
# Exit code:
#   0 = all artifacts FRESH
#   1 = at least one STALE/DRIFT/NOSTAMP
#   2 = at least one MISSING (required artifact)
#   3 = invocation error

set -euo pipefail

PROJECT_DIR="${1:-}"

# If no project dir given, walk up from cwd
if [[ -z "$PROJECT_DIR" ]]; then
  cur="$(pwd)"
  while [[ "$cur" != "/" ]]; do
    if compgen -G "$cur/specs/projects/*/project.md" >/dev/null 2>&1; then
      PROJECT_DIR="$(echo "$cur"/specs/projects/*/ | head -n1)"
      break
    fi
    cur="$(dirname "$cur")"
  done
fi

if [[ -z "$PROJECT_DIR" ]] || [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Could not locate project directory. Pass it as \$1 or run from inside a Speck project." >&2
  exit 3
fi

# Strip trailing slash, then resolve to absolute
PROJECT_DIR="${PROJECT_DIR%/}"
if [[ ! "$PROJECT_DIR" = /* ]]; then
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
fi

CURRENT_SHA=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "")
if [[ -z "$CURRENT_SHA" ]]; then
  echo "ERROR: Not inside a git repository." >&2
  exit 3
fi

# Detect play level (defaults to platform if no project.json)
PLAY_LEVEL="platform"
PROJECT_JSON=""
# Walk up from PROJECT_DIR to find .speck/project.json
cur="$PROJECT_DIR"
while [[ "$cur" != "/" ]]; do
  if [[ -f "$cur/.speck/project.json" ]]; then
    PROJECT_JSON="$cur/.speck/project.json"
    break
  fi
  cur="$(dirname "$cur")"
done

if [[ -n "$PROJECT_JSON" ]]; then
  PLAY_LEVEL=$(grep -o '"play_level"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_JSON" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || echo "platform")
fi

# Required artifacts per play level
REQUIRED_ARTIFACTS=()
OPTIONAL_ARTIFACTS=()

case "$PLAY_LEVEL" in
  sprint)
    REQUIRED_ARTIFACTS=("PRD.md")
    OPTIONAL_ARTIFACTS=("sprint-log.md" "project.md")
    ;;
  build)
    REQUIRED_ARTIFACTS=("project.md" "PRD.md" "context.md" "product-contract.md" "evidence-contract.md")
    OPTIONAL_ARTIFACTS=("architecture.md" "constitution.md" "domain-model.md" "ux-strategy.md" "design-system.md")
    ;;
  platform|*)
    REQUIRED_ARTIFACTS=("project.md" "PRD.md" "context.md" "architecture.md" "product-contract.md" "evidence-contract.md")
    OPTIONAL_ARTIFACTS=("constitution.md" "domain-model.md" "ux-strategy.md" "design-system.md")
    ;;
esac

# Date helpers (BSD/macOS-compatible)
today_epoch=$(date +%s)
threshold_days=14
threshold_secs=$((threshold_days * 86400))

ANY_STALE=0
ANY_MISSING=0
FRESH_COUNT=0
STALE_COUNT=0
DRIFT_COUNT=0
NOSTAMP_COUNT=0
MISSING_COUNT=0
V8STALE_COUNT=0

check_artifact() {
  local artifact="$1"
  local required="$2"
  local path="$PROJECT_DIR/$artifact"

  if [[ ! -f "$path" ]]; then
    if [[ "$required" == "yes" ]]; then
      echo "❌ MISSING  $artifact (required at $PLAY_LEVEL level)"
      ANY_MISSING=1
      MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
    return
  fi

  # Look for the SHA stamp footer: *[as of SHA `<hash>` | verified <date> | speck v7.0.0]*
  local stamp_line
  stamp_line=$(grep -E '^\*\[as of SHA' "$path" | tail -n1 || true)

  if [[ -z "$stamp_line" ]]; then
    echo "⚠️  NOSTAMP  $artifact"
    ANY_STALE=1
    NOSTAMP_COUNT=$((NOSTAMP_COUNT + 1))
    return
  fi

  # Extract SHA hash from stamp
  local stamp_sha
  stamp_sha=$(echo "$stamp_line" | sed -nE 's/.*as of SHA `([^`]+)`.*/\1/p')

  # Extract verified date (YYYY-MM-DD format)
  local stamp_date
  stamp_date=$(echo "$stamp_line" | sed -nE 's/.*verified ([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p')

  # Version-as-staleness (Speck v8): an artifact stamped by a pre-v8 Speck is
  # v8-stale — its "green" was produced under v7 verification, not v8 evaluation.
  # This takes precedence over SHA/date freshness and routes to /speck-reprove.
  local stamp_speck_major
  stamp_speck_major=$(echo "$stamp_line" | sed -nE 's/.*speck v?([0-9]+)\..*/\1/p')
  if [[ -n "$stamp_speck_major" ]] && [[ "$stamp_speck_major" -lt 8 ]]; then
    echo "⚠️  V8_STALE  $artifact (stamped speck v$stamp_speck_major — pre-v8 proof; run /speck-reprove)"
    ANY_STALE=1
    V8STALE_COUNT=$((V8STALE_COUNT + 1))
    return
  fi

  # Check SHA drift — use commit count on this file since stamp.
  # Count <= 1 means only the stamp commit touched the file (normal commit flow) → FRESH.
  # Count > 1 means substantive content changed after stamp → DRIFT.
  if [[ -n "$stamp_sha" ]] && [[ "$stamp_sha" != "$CURRENT_SHA" ]]; then
    local change_count
    change_count=$(git -C "$PROJECT_DIR" rev-list --count "${stamp_sha}..HEAD" -- "$artifact" 2>/dev/null || echo "0")
    if [[ "$change_count" -gt 1 ]]; then
      echo "⚠️  DRIFT    $artifact (stamped $stamp_sha, HEAD is $CURRENT_SHA, $change_count commits changed file)"
      ANY_STALE=1
      DRIFT_COUNT=$((DRIFT_COUNT + 1))
      return
    fi
  fi

  # Check date staleness
  if [[ -n "$stamp_date" ]]; then
    local stamp_epoch
    # BSD vs GNU date compatibility
    if date -j -f "%Y-%m-%d" "$stamp_date" "+%s" >/dev/null 2>&1; then
      stamp_epoch=$(date -j -f "%Y-%m-%d" "$stamp_date" "+%s")
    else
      stamp_epoch=$(date -d "$stamp_date" "+%s")
    fi
    local age=$((today_epoch - stamp_epoch))
    if [[ $age -gt $threshold_secs ]]; then
      local age_days=$((age / 86400))
      echo "⚠️  STALE    $artifact (verified $stamp_date, $age_days days ago)"
      ANY_STALE=1
      STALE_COUNT=$((STALE_COUNT + 1))
      return
    fi
  fi

  # Check structural template drift
  local workspace_root
  workspace_root="$(dirname "$(dirname "$PROJECT_DIR")")"
  local drift_script="$workspace_root/.speck/scripts/validation/check-artifact-template-drift.sh"
  if [[ -f "$drift_script" ]]; then
    local drift_output
    drift_output=$("$drift_script" "$path" 2>/dev/null || true)
    if echo "$drift_output" | grep -q "TEMPLATE_DRIFT:"; then
      local missing_sections
      missing_sections=$(echo "$drift_output" | grep -A100 "MISSING_SECTIONS:" | tail -n +2 | sed -E 's/^[[:space:]]*- //g' | tr '\n' ',' | sed 's/,$//')
      echo "⚠️  STRUCTURAL_DRIFT $artifact (missing: $missing_sections)"
      ANY_STALE=1
      STALE_COUNT=$((STALE_COUNT + 1))
      return
    fi
  fi

  echo "✅ FRESH    $artifact"
  FRESH_COUNT=$((FRESH_COUNT + 1))
}

echo "Speck staleness check — Project: $PROJECT_DIR"
echo "Play level: $PLAY_LEVEL"
echo "Current HEAD: $CURRENT_SHA"
echo ""

for a in "${REQUIRED_ARTIFACTS[@]}"; do
  check_artifact "$a" "yes"
done

for a in "${OPTIONAL_ARTIFACTS[@]}"; do
  check_artifact "$a" "no"
done

echo ""
echo "Summary: $FRESH_COUNT fresh / $STALE_COUNT stale / $DRIFT_COUNT drift / $NOSTAMP_COUNT no-stamp / $V8STALE_COUNT v8-stale / $MISSING_COUNT missing"

if [[ $ANY_MISSING -eq 1 ]]; then
  exit 2
elif [[ $ANY_STALE -eq 1 ]]; then
  exit 1
else
  exit 0
fi
