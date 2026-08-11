---
speck_version: 11.0.0
template_version: "11.0.0"
artifact_type: story-analysis-report
analyzed_sha: [ANALYZED_SHA]
play_level: [PLAY_LEVEL]
lenses: []
---

# Story Analysis Report: [Story Name]

**Story**: [STORY_ID]
**Date**: [DATE]
**Gate verdict**: [GATE_VERDICT]

## Lens Roster

| Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings |
|------|------------------|----------|-------------------------------|----------|
| [S1 implementation-readiness] | [Question used] | [Reviewer] | no | [Count] |

## Analysis Results

### Issues Found

Severity: `CRITICAL | HIGH | MEDIUM | LOW`. Verdict: `confirmed | refuted`. Status: `open | resolved | waived DEC-####`.

Cross-artifact contradictions and uncovered promises are CRITICAL by construction. A CRITICAL or HIGH finding needs a verifier distinct from its raising lens.

| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |
|----|----------|----------|-------------|----------------|----------|---------|--------|
| [S1-1] | [Category] | [Severity] | [Finding] | [Correction] | [Verifier] | [Verdict] | [Status] |

### Promise Coverage

Inventory every story-owned FR, acceptance scenario, inherited promise, and explicit gate. A row is resolved only when the plan and tasks carry it without contradiction.

| Promise dimension | Source | Epic / story coverage | Status |
|-------------------|--------|----------------------|--------|
| [FR-001 / AC-001 / MM-N / JOB-N] | [spec or inherited contract] | [plan section and task ids] | [resolved/open/waived DEC-####] |

## Quality Opportunities

- [A concrete simplification, stronger user outcome, or quality improvement worth applying before implementation]

## Required Corrections

- [Open correction, owner, and affected artifact; write `None` only when the gate verdict is CLEAN]
