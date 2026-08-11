#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CHECK="$ROOT/.speck/scripts/validation/check-story-prereqs.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.speck"
printf '{"play_level":"build"}\n' > "$TMP/.speck/project.json"

make_story() {
  local dir="$1"
  mkdir -p "$dir"
  printf '# Story\n\n**Current State**: Specified\n' > "$dir/spec.md"
  printf '# Plan\n' > "$dir/plan.md"
  printf '%s\n' '---' 'status: pending' '---' '# Tasks' > "$dir/tasks.md"
}

legacy="$TMP/legacy-story"
make_story "$legacy"
echo "Test: pre-v11 tasks remain advisory"
out="$(cd "$ROOT" && bash "$CHECK" "$legacy")"
grep -q 'PREREQUISITE GATES PASSED' <<<"$out"

sprint="$TMP/sprint-story"
make_story "$sprint"
python3 - "$sprint/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nanalysis_required: false\n"))
PY
echo "Test: Sprint task marker skips analysis explicitly"
out="$(cd "$ROOT" && bash "$CHECK" "$sprint")"
grep -q 'Sprint tasks declare story analysis not required' <<<"$out"

required="$TMP/required-story"
make_story "$required"
python3 - "$required/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nanalysis_required: true\n"))
PY

echo "Test: v11 tasks fail closed without story analysis"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$required" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'UNANALYZED_CORPUS.P1' <<<"$out"

cat > "$required/story-analysis-report.md" <<'EOF'
---
speck_version: 11.0.0
template_version: "11.0.0"
artifact_type: story-analysis-report
analyzed_sha: unknown
play_level: build
lenses:
  - id: S1
    name: implementation-readiness
    reviewer: reviewer-a
    authored_corpus: false
---

# Story Analysis Report: Ready story

**Story**: S001
**Date**: 2026-08-11
**Gate verdict**: CLEAN

## Lens Roster

| Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings |
|------|------------------|----------|-------------------------------|----------|
| S1 implementation-readiness | What will fail during implementation? | reviewer-a | no | 1 |

## Flow Fit

| Slot | Trigger evidence | Artifact or rationale | Verdict |
|------|------------------|-----------------------|---------|
| story-extract | New-scope test story | No prior implementation to extract | not-applicable |
| speck-scan | New-scope test story | No brownfield code to scan | not-applicable |
| story-ui-spec | No UI behavior in fixture | No UI states or interaction contract | not-applicable |

## Analysis Results

### Issues Found

| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |
|----|----------|----------|-------------|----------------|----------|---------|--------|
| S1-1 | testability | LOW | One optional simplification exists | Apply during implementation | reviewer-b | confirmed | resolved |

### Promise Coverage

| Promise dimension | Source | Epic / story coverage | Status |
|-------------------|--------|----------------------|--------|
| AC-001 | spec.md | plan section 2 and task T001 | resolved |

## Quality Opportunities

- Keep the implementation boundary small.

## Required Corrections

- None.
EOF

echo "Test: bound Build story analysis clears implementation gate"
out="$(cd "$ROOT" && bash "$CHECK" "$required")"
grep -q 'Required story analysis is present and clear' <<<"$out"

echo "All story prerequisite tests passed"
