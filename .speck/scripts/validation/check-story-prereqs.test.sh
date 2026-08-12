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
# analysis_required: false is only honored when the LIVE play_level agrees (finding 3 / problem 2
# below) — a nested .speck/project.json shadows the outer TMP one (build) so this genuinely is a
# Sprint-tier workspace, the case this test's name and assertion claim to cover.
mkdir -p "$sprint/.speck"
printf '{"play_level":"sprint"}\n' > "$sprint/.speck/project.json"
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

placeholder="$TMP/placeholder-story"
make_story "$placeholder"
python3 - "$placeholder/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nanalysis_required: [ANALYSIS_REQUIRED]\n"))
PY

echo "Test: unsubstituted [ANALYSIS_REQUIRED] placeholder fails closed on a Build project"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$placeholder" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'ANALYSIS_REQUIRED_UNPARSEABLE.P1' <<<"$out"
grep -q 'GATES REJECTED' <<<"$out"

quoted_true="$TMP/quoted-true-story"
make_story "$quoted_true"
python3 - "$quoted_true/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", 'status: pending\nanalysis_required: "true"\n'))
PY

echo "Test: quoted \"true\" parses as a genuine true and reaches the mandatory gate"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$quoted_true" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'UNANALYZED_CORPUS.P1' <<<"$out"

yaml_true="$TMP/yaml-true-story"
make_story "$yaml_true"
python3 - "$yaml_true/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nanalysis_required: True  # Build/Platform\n"))
PY

echo "Test: YAML-cased True with a trailing comment also reaches the mandatory gate"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$yaml_true" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'UNANALYZED_CORPUS.P1' <<<"$out"

legacy_critical="$TMP/legacy-critical-story"
make_story "$legacy_critical"
printf '%s\n' '# Analysis' '- [ ] CRITICAL: the plan contradicts the spec on the auth boundary' > "$legacy_critical/analysis-report.md"

echo "Test: an open CRITICAL in analysis-report.md blocks even when analysis_required is unset"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$legacy_critical" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'Unresolved CRITICAL issues found' <<<"$out"
grep -q 'GATES REJECTED' <<<"$out"

canonical_critical="$TMP/canonical-critical-story"
make_story "$canonical_critical"
printf '%s\n' '# Analysis' '- [ ] CRITICAL: the plan contradicts the spec on the auth boundary' > "$canonical_critical/story-analysis-report.md"

echo "Test: an open CRITICAL in a legacy-format story-analysis-report.md also blocks with no analysis_required key"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$canonical_critical" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'Unresolved CRITICAL issues found' <<<"$out"

# --- repair-round regression tests (adversarial re-review) -----------------------------------
# Writes a canonical v11 story-analysis-report.md: frontmatter-bound (artifact_type:
# story-analysis-report), findings expressed as a TABLE ROW with a Status cell — the shape
# .speck/templates/story/story-analysis-report-template.md:30-32 actually produces. The legacy
# checkbox scan (`grep -E '\[[[:space:]]\]|todo'`) cannot see this shape at all; only
# validate-project-analysis.sh --gate can, which is why it must be the detector, not a second
# hand-rolled one.
write_v11_report() {
  local dir="$1" status="$2"
  cat > "$dir/story-analysis-report.md" <<EOF
---
template_version: "11.0.0"
artifact_type: story-analysis-report
speck_version: "11.0.0"
analyzed_sha: "unknown"
play_level: "build"
lenses:
  - id: S1
    name: implementation-readiness
    reviewer: reviewer-a
    authored_corpus: false
---

# Story Analysis Report

**Gate verdict**: NEEDS_FIXES

## Lens Roster

| Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings |
|---|---|---|---|---|
| S1 | What will fail during implementation? | reviewer-a | no | 1 |

## Flow Fit

| Slot | Trigger evidence | Artifact or rationale | Verdict |
|---|---|---|---|
| story-extract | New-scope test story | No prior implementation to extract | not-applicable |
| speck-scan | New-scope test story | No brownfield code to scan | not-applicable |
| story-ui-spec | No UI behavior in fixture | No UI states or interaction contract | not-applicable |

## Issues Found

| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |
|---|---|---|---|---|---|---|---|
| SA-001 | correctness | CRITICAL | plan contradicts the spec on the auth boundary | rework the plan | reviewer-b | confirmed | ${status} |

## Promise Coverage

| Promise dimension | Source | Epic / story coverage | Status |
|---|---|---|---|
| AC-001 | spec.md | plan section 2 | uncovered |

## Quality Opportunities

- None found.

## Required Corrections

- Rework the plan.
EOF
}

# Problem 1 (BLOCKER): the restored CRITICAL scan is format-blind to the canonical v11 TABLE row
# shape and printed an affirmative green on an open CRITICAL. Reproduced exactly as the reviewer
# ran it: analysis_required: false alongside a bound report with an open CRITICAL row.
v11_critical_false="$TMP/v11-critical-analysis-false"
make_story "$v11_critical_false"
python3 - "$v11_critical_false/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nspeck_version: 11.0.0\nanalysis_required: false\n"))
PY
write_v11_report "$v11_critical_false" "open"

echo "Test: an open CRITICAL in a canonical v11 TABLE-format report blocks even when analysis_required: false"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$v11_critical_false" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'ANALYSIS_CRITICAL_OPEN.P1' <<<"$out"
grep -q 'Unresolved CRITICAL issues found' <<<"$out"
grep -q 'GATES REJECTED' <<<"$out"

# Neighbouring input: the reviewer's repro also confirmed the false green "Repeated with the key
# absent entirely (no analysis_required line): also RC=0 with the same false green."
v11_critical_absent="$TMP/v11-critical-analysis-absent"
make_story "$v11_critical_absent"
write_v11_report "$v11_critical_absent" "open"

echo "Test: an open CRITICAL in a canonical v11 TABLE-format report also blocks with no analysis_required key at all"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$v11_critical_absent" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'ANALYSIS_CRITICAL_OPEN.P1' <<<"$out"

# Neighbouring input: a v11 TABLE-format report whose CRITICAL is genuinely resolved must NOT
# block — proves the delegated detector reads Status, not just Severity, and the repair did not
# open a false-positive hole on every CRITICAL row regardless of state.
v11_critical_resolved="$TMP/v11-critical-analysis-resolved"
make_story "$v11_critical_resolved"
write_v11_report "$v11_critical_resolved" "resolved"

echo "Test: a RESOLVED CRITICAL in a canonical v11 TABLE-format report does not block"
out="$(cd "$ROOT" && bash "$CHECK" "$v11_critical_resolved" 2>&1)"
grep -q 'PREREQUISITE GATES PASSED' <<<"$out"
! grep -q 'ANALYSIS_CRITICAL_OPEN.P1' <<<"$out"

# Problem 2 (MAJOR / finding 3): analysis_required is self-declared and was never cross-checked
# against the live .speck/project.json play_level on the PARSEABLE-value paths — only the
# unparseable branch walked up to project.json. Reproduced exactly as the reviewer ran it.
contradicts_build="$TMP/contradicts-play-level-build"
make_story "$contradicts_build"
python3 - "$contradicts_build/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nanalysis_required: false\n"))
PY

echo "Test: analysis_required: false is rejected when the live play_level is build"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$contradicts_build" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'ANALYSIS_REQUIRED_FALSE_CONTRADICTS_PLAY_LEVEL.P1' <<<"$out"
grep -q 'GATES REJECTED' <<<"$out"

# Neighbouring input: the same contradiction under play_level: platform.
contradicts_platform="$TMP/contradicts-play-level-platform"
make_story "$contradicts_platform"
mkdir -p "$contradicts_platform/.speck"
printf '{"play_level":"platform"}\n' > "$contradicts_platform/.speck/project.json"
python3 - "$contradicts_platform/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nanalysis_required: false\n"))
PY

echo "Test: analysis_required: false is rejected when the live play_level is platform"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$contradicts_platform" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'ANALYSIS_REQUIRED_FALSE_CONTRADICTS_PLAY_LEVEL.P1' <<<"$out"

# Problem 3 (MAJOR): deleting the analysis_required line was a cheaper escape hatch than fixing
# it, even on a tasks.md whose own frontmatter declares speck_version: 11.0.0. Reproduced exactly
# as the reviewer ran it.
missing_on_v11="$TMP/missing-analysis-required-v11"
make_story "$missing_on_v11"
python3 - "$missing_on_v11/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nspeck_version: 11.0.0\nartifact_type: story-tasks\n"))
PY

echo "Test: a v11-versioned tasks.md missing analysis_required entirely fails closed on Build"
set +e
out="$(cd "$ROOT" && bash "$CHECK" "$missing_on_v11" 2>&1)"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
grep -q 'ANALYSIS_REQUIRED_MISSING_ON_V11.P1' <<<"$out"
grep -q 'GATES REJECTED' <<<"$out"

# Neighbouring input: a genuinely pre-v11 versioned tasks.md (speck_version below the version
# that introduced analysis_required) missing the key must still be advisory-only — proves the
# repair does not over-trigger on true legacy files just because SOME speck_version is present.
missing_pre11="$TMP/missing-analysis-required-pre11"
make_story "$missing_pre11"
python3 - "$missing_pre11/tasks.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("status: pending\n", "status: pending\nspeck_version: 9.0.0\n"))
PY

echo "Test: a pre-v11-versioned tasks.md missing analysis_required stays advisory"
out="$(cd "$ROOT" && bash "$CHECK" "$missing_pre11" 2>&1)"
grep -q 'PREREQUISITE GATES PASSED' <<<"$out"
grep -q 'does not declare analysis_required' <<<"$out"

echo "All story prerequisite tests passed"
