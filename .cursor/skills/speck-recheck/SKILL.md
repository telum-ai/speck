---
name: speck-recheck
description: Mandatory engagement-gap drift detector for Speck v7. Compares truth-doc assertions to current HEAD via SHA stamps, runs persona LARP cold-start, scans for third-party integration risk + ToS posture, checks constitution principle compliance, updates project-state.md, and blocks new feature work if drift is found. Load when reengagement gap is >2 weeks since last verified-against-runtime, when a new agent picks up a project, or when user says "audit", "make ship-ready", "is this still working".
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`/recheck` is the **engagement-gap drift detector** that prevents Speck v7's #1 failure mode: an agent (or human) picks up a project after time has passed and starts new feature work on top of stale assumptions.

Six v6 projects independently described this pattern:
- Odd: B0 ToS violation shipped through 7 epics of validation; would have surfaced via persona LARP cold-start
- Pust: validation docs said GO-SHIP while real app had broken fresh-user flow
- Splang: R12 was "no more hand-waving" but worktree backend had never booted
- Brightstance: old PASS docs disagreed with current HEAD's runtime

The fix is structural: every engagement above a threshold gap runs `/recheck` BEFORE any new work.

## When to Run

`/recheck` is **mandatory** when any of:
- More than 14 days since the latest truth artifact's `verified` stamp
- A new agent picks up the project (no record of prior session continuity)
- User explicitly requests audit / "make ship-ready" / "is this still working"
- The "Next action" in `project-state.md` is unknown or empty

`/recheck` is **optional but recommended** when:
- Major dependency updates (framework, language, lib) since last validation
- Multiple parallel branches merged since last validation

## Prerequisites

- Inside a Speck project (find `specs/projects/<id>/` by walking up)
- Git repository (for SHA comparison)

## Execution Steps

### 1. Locate project and prerequisites

Find `specs/projects/<PROJECT_ID>/`. Determine play level from `.speck/project.json`.

Required artifacts to check:
- `project-state.md` (if exists; if not, that's already drift)
- All truth artifacts per play level (per `staleness-check.sh`)
- `product-contract.md` (banned language, magic moments)
- `evidence-contract.md` (proof requirements)

### 2. Run subagent-parallel drift detection

```
├── [Parallel] shell: Run .speck/scripts/staleness-check.sh
├── [Parallel] shell: Run .speck/scripts/check-replace-markers.sh specs/projects/<id>/
├── [Parallel] speck-scanner: Spec-vs-code reconciliation — for each truth assertion in product-contract.md / PRD.md / architecture.md, find supporting code or flag as ungrounded
├── [Parallel] speck-auditor: Third-party integration risk surface scan — for each external service in context.md/architecture.md, verify auth model, ToS posture, data residency, worst-case story
├── [Parallel] speck-auditor: Constitution principle compliance scan — for each principle in constitution.md (or product-contract.md principles section), verify enforcement mechanism is current
├── [Parallel] speck-auditor: Banned-language scan via .speck/scripts/banned-language-lint.sh
├── [Parallel] shell: grep -rln "\[NEEDS USER REVIEW\]" specs/projects/<id>/   (surface to project-state.md)
└── [Wait] → Synthesize drift report
```

Each subagent returns: FRESH | STALE | DRIFTED | MISSING with evidence.

**REPLACE_BEFORE_SHIP markers** (added in Speck v7.2+):
- Any truth artifact carrying a `REPLACE_BEFORE_SHIP:` token is **incomplete**
- The artifact CANNOT support a readiness state claim above `IMPL-GREEN` while tokens remain
- Treat as **P0 drift** if the artifact is referenced by an active `UX-RC` or higher claim
- Treat as **P1 drift** otherwise (a scaffolded artifact that hasn't been filled)
- The catch-up flow (`/speck-catch-up`) is the standard remediation path

### 3. Run persona LARP cold-start / Integration stress-test sanity check

- **WHEN: consumer_product / b2b_saas / internal_tool**:
  - For each persona in `personas/<id>.md`, run persona LARP cold-start.
  - Cold-start the app from a fresh state (no logged-in user, clean storage, etc.).
  - Execute the LARP script for the persona's primary JTBD; capture screenshots, AX trees, timings, and compare against `product-contract.md` magic moments.
  - Use the `/larp` skill for the actual execution; `/recheck` orchestrates and aggregates.
- **WHEN: infra_service / backend_api**:
  - Run the integration / stress-test scenarios (from Option B in `evidence-contract.md`).
  - Warm up the system, send concurrent mock client requests, and verify latency histograms, error-code stability, connection pooling recovery, and DB-isolation invariants.

If any check fails: drift detected (P0).

### 4. Compute the drift report

For each finding:
- Severity (P0-P3)
- Type: SPEC_VS_CODE | TRUTH_STALE | LARP_FAIL | INTEGRATION_RISK | PRINCIPLE_VIOLATION | BANNED_LANGUAGE
- Where (file:line or surface)
- Evidence (link to artifact)
- Recommended fix

### 5. Update project-state.md

Trigger `/project-state` to regenerate with drift findings in:
- Blocking issues section (P0/P1 drift)
- Truth staleness report (all stale artifacts)
- Next action: "Resolve drift before new feature work"

### 6. Decision gate

If P0 drift found:
- **BLOCK new feature work**
- Surface P0 findings to user with proposed remediations
- Recommend running `/audit` for affected stories
- Refuse to proceed with any `/story-implement`, `/epic-plan` until P0 resolved

If only P1-P3:
- Surface findings; allow user to proceed at their discretion
- Add follow-up stories to the active epic's backlog

If no drift:
- Re-stamp all checked truth artifacts with fresh `verified` date
- Proceed normally

### 7. Write the recheck report

Write to `specs/projects/<PROJECT_ID>/project-recheck-report-<YYYYMMDD>.md`. See claude skill for the full report template.

### 8. Apply stamp + report to user

```
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/project-recheck-report-<YYYYMMDD>.md
```

Report summary fields per claude skill.

## Behavior Rules

- NEVER skip persona LARP cold-start
- NEVER claim "no drift" without running `staleness-check.sh` AND `banned-language-lint.sh` AND `check-replace-markers.sh`
- NEVER mark a truth artifact "fresh" while it still contains `REPLACE_BEFORE_SHIP:` or `[NEEDS USER REVIEW]` tokens
- ALWAYS write a dated report (even if green)
- ALWAYS re-stamp truth artifacts on green (with fresh `verified` date)
- ALWAYS update `project-state.md` regardless of verdict (including the new "Sections Awaiting User Review" and "Outstanding REPLACE_BEFORE_SHIP markers" appendices)
- BLOCK new feature work on P0 findings

## Integration Points

- Reads: all truth artifacts, all `personas/*.md` LARP scripts, `.speck/scripts/staleness-check.sh`, `.speck/scripts/banned-language-lint.sh`
- Invokes: `/larp` (for persona cold-start), `/project-state` (regeneration)
- Writes: `project-recheck-report-<date>.md`, re-stamps truth artifacts on green
- Updates: `project-state.md` blocking issues, next action

## Context: $ARGUMENTS
