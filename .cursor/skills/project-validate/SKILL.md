---
name: project-validate
description: Load when all epics are validated and /audit has run for the project. Verifies the project meets its original vision and product-contract.md paid promise. Runs end-to-end JTBD smoke test via /larp across all personas. Declares a project-level readiness state. Produces project-validation-report.md — required before project-retrospective. FIRST ACTION after loading is read templates at .speck/templates/project/project-validation-report-template.md, .speck/templates/story/validation-report-template.md, .speck/templates/project/project-validation-summary-template.md, and .speck/templates/project/project-punch-list-template.md.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Templates First

**Before any other action** — read templates now:
```
.speck/templates/project/project-validation-report-template.md
.speck/templates/story/validation-report-template.md   # readiness state structure
.speck/templates/project/project-validation-summary-template.md
.speck/templates/project/project-punch-list-template.md
```

**Checkpoint**: After reading, note the v7 readiness states and the v7 gate criteria.

---

## 🚦 Pre-Validate Gates (v7 — Mandatory)

Before doing ANY project-level validation, verify:

1. **Every epic has `epic-validation-report.md` with verified state >= UX-RC** (or higher per project ambition)
   - If any epic is still IMPL-GREEN or lower: STOP. Tell user "Epic <id> needs to reach UX-RC before project-validate. Run `/larp` + `/epic-validate` first."

2. **`/recheck` was run within the last 7 days**
   - If missing or stale: STOP. Tell user "Run `/recheck` first — project-validate requires fresh drift detection."

3. **`evidence-contract.md` and `product-contract.md` exist**
   - If missing: STOP.

4. **Full JTBD walkthrough captured for every named persona** in `evidence-contract.md`
   - For each persona: latest `<persona>-findings.md` from `/larp` against launch build
   - If missing for any persona: STOP. Tell user "Run `/larp <persona>` for [list]."

5. **PROFILE gates for SHIP-RC+ claims**
   - Run `bash .speck/scripts/validation/validators/validate-readme.sh --strict` and `bash .speck/scripts/profile-drift-check.sh`
   - If any `PROFILE_DRIFT.P1`: STOP. Tell user "Resolve PROFILE drift before project-validate at SHIP-RC."

If any pre-gate fails: refuse to proceed.

---

## 🎯 v7 Project Validation Algorithm

1. Read every epic's `epic-validation-report.md` — extract verified states
2. The project's MAX claimable state = MIN(epic states)
3. Read `audit-report.md` files — any P0 lowers max claimable state
4. Read `/recheck` report — drift lowers max claimable state
5. End-to-end JTBD smoke test per persona (cross-epic walkthrough)
6. Cross-platform coherence check (if multi-platform per evidence-contract)
7. No dead ends check: every reachable feature has a way back, every action has feedback
8. Banned-phrase self-check on this report's own language
9. Apply SHA stamp; trigger `/project-state` regeneration
10. Re-stamp all truth artifacts with fresh `verified` date

The legacy v6 project validation algorithm follows below (use for governance details, but verdict MUST be a readiness state).

---

## Play Level Check

Read `.speck/project.json` (if it exists) for `play_level`.

- **Sprint**: Tell the user: "Sprint validation is simple — did you hit your Success Metric? Check your `sprint-log.md` outcome section. If yes and it's growing, run `/project-promote`."
- **Build**: Validate PRD requirements, epic completion, product-contract delivery, and v7 readiness state gates. Skip constitution compliance and design-system coverage sections.
- **Platform** (or no project.json): Full validation flow below.

---

## Play Level Check

Read `.speck/project.json` (if it exists) for `play_level`.

- **Sprint**: Tell the user: "Sprint validation is simple — did you hit your Success Metric? Check your `sprint-log.md` outcome section. If yes and it's growing, run `/project-promote`."
- **Build**: Validate PRD requirements, epic completion, and core quality gates. Skip constitution compliance and design-system coverage sections.
- **Platform** (or no project.json): Full validation flow below.

---

Comprehensive validation of project completion, ensuring all goals are met and the system is ready for production.

## Subagent Parallelization

This command benefits from parallel validation checks:

```
├── [Parallel] speck-auditor: "Check project.md goals are achieved"
├── [Parallel] speck-auditor: "Verify all PRD requirements are implemented"
├── [Parallel] speck-auditor: "Confirm all epics are complete"
├── [Parallel] speck-auditor: "Test cross-epic integration flows"
├── [Parallel] speck-auditor: "Check code quality, security, accessibility"
├── [Parallel] speck-auditor: "Verify Cursor rules compliance"
└── [Wait] → Synthesize into project-validation-report.md

Each auditor returns PASS | FAIL | PARTIAL with evidence.
```

**Speedup**: 5-6x compared to sequential validation.

---

1. Load project artifacts and status:
   - Original: project.md, PRD.md, epics.md
   - Epic status: Check each epic directory for completion
   - Implementation: Aggregate all story validations
   - Metrics: Gather performance and quality data
   - If files missing: ERROR "Project planning artifacts not found"

2. Epic completion verification:
   ```
   For each epic in epics.md:
   - Check `epics/*/epic-validation-report.md` (and epic-punch-list.md as needed)
   - Verify all stories completed
   - Confirm success criteria met
   - Note any deviations from plan
   ```

3. Multi-level validation:

   **Project Vision Validation**
   - Original vision from project.md achieved?
   - All primary goals met?
   - Target user problems solved?
   - Success metrics reached?

   **PRD Requirement Validation**
   - All functional requirements implemented?
   - Non-functional requirements met?
   - Scope boundaries respected?
   - Edge cases handled?

   **Epic Integration Validation**
   - All epics work together seamlessly?
   - Cross-epic workflows function?
   - No integration gaps?
   - Performance at scale?

   **Quality Standards Validation**
   - Code quality gates passed?
   - Security requirements met?
   - Accessibility standards achieved?
   - Documentation complete?
   - Cursor rules compliance across project?

4. Cursor rules compliance project-wide aggregation:
   - Check if `.cursor/rules/` directory exists
   - If exists, load all rule files (`*.mdc` or `*.md`)
   - Aggregate rule compliance across all epics and stories:
     * Review epic-validation-report.md files for rules compliance sections
     * Collect project-wide compliance patterns
     * Identify systemic issues vs isolated violations
   - Generate project-level rules compliance summary:
     ```
     ## Cursor Rules Compliance (Project Summary)
     
     **Rules Directory**: `.cursor/rules/` [exists/not found]
     **Total Rules**: [X]
     **Epics Evaluated**: [Y]
     **Stories Evaluated**: [Z]
     
     | Rule File | Epic Coverage | Overall Pass Rate | Trend |
     |-----------|---------------|-------------------|-------|
     | [rule.mdc] | 12/12 epics | 98% (156/160 stories) | ✅ Excellent |
     | [rule.mdc] | 8/12 epics | 75% (90/120 stories) | ⚠️ Needs attention |
     | [rule.mdc] | 12/12 epics | 100% (160/160 stories) | ✅ Perfect |
     
     **Project-Wide Patterns**:
     - Rules consistently followed: [list rules with >95% compliance]
     - Rules needing improvement: [list rules with <80% compliance]
     - Rules causing frequent violations: [analysis and recommendations]
     
     **Systemic Issues**:
     - [Pattern 1]: Violated in [X] stories across [Y] epics → [Root cause analysis]
     - [Pattern 2]: Violated in [X] stories across [Y] epics → [Root cause analysis]
     
     **Recommendations for Future**:
     - Update rules that are unclear or too strict
     - Add tooling/automation for commonly violated rules
     - Training needed on specific rule areas
     ```
   - If no `.cursor/rules/` directory: Note "No project-specific rules found"
   - If systemic patterns: Include in lessons learned

5. Execute validation suites:

   **Automated Validation**
   - Run full test suite across all epics
   - Execute integration test scenarios
   - Performance benchmarks
   - Security scanning
   - Accessibility audits

   **Manual Validation**
   - User acceptance test scenarios
   - Cross-epic user journeys
   - Edge case verification
   - Production readiness checklist

6. Metrics collection and analysis:
   ```
   Original Success Metrics (from project.md):
   - [Metric 1]: Target [X]
     * Actual: [Y]
     * Status: [Met/Not Met/Exceeded]
   
   - [Metric 2]: Target [X]
     * Actual: [Y]
     * Status: [Met/Not Met/Exceeded]
   ```

7. Generate comprehensive validation report:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/project/project-validation-report-template.md
   ```

   Write output to: `[PROJECT_DIR]/project-validation-report.md`

8. Generate executive summary:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/project/project-validation-summary-template.md
   ```

   Write output to: `[PROJECT_DIR]/project-validation-summary.md`

9. Generate punch list:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/project/project-punch-list-template.md
   ```

   Write output to: `[PROJECT_DIR]/project-punch-list.md`

10. Save validation artifacts:
   - Full report: `[PROJECT_DIR]/project-validation-report.md`
   - Executive summary: `[PROJECT_DIR]/project-validation-summary.md`
   - Punch list: `[PROJECT_DIR]/project-punch-list.md`

11. Output summary:
   ```
   ✅ Project Validation Complete!
   
   Project: [Name]
   Status: [SUCCESS/PARTIAL/FAILED]
   
   Key Results:
   - Vision Achievement: [X]%
   - Goals Met: [Y of Z]
   - Requirements: [A]% complete
   - Quality Gates: [B of C] passed
   
   Production Readiness: [GO/NO-GO/CONDITIONAL]
   
   Critical Items:
   1. [If any]
   2. [If any]
   
   Reports Generated:
   - project-validation-report.md (full details)
   - project-validation-summary.md (executive summary)  
   - project-punch-list.md (remaining items)
   
   Next Steps:
   [If GO]: Proceed with deployment
   [If NO-GO]: Address critical items, re-validate
   [If CONDITIONAL]: Complete conditions, then deploy
   ```

---

## 🔥 Exhaustive Torture Tier (`--exhaustive` — opt-in, expensive)

The default `/project-validate` runs the JTBD smoke test across personas. `--exhaustive` is the opt-in **breadth orchestrator** — the level where cross-epic *composition* defects live (a banned word on a flagship surface, contradictory advice across cards, duplicate greetings) that isolated per-epic LARPs structurally cannot surface.

**Always-on (cheap) — GENERATE.** Regardless of tier, (re)generate the checked-in coverage-matrix skeleton so breadth GAPs are visible, not silent, then surface them (non-strict) in the report:
```bash
.speck/scripts/validation/generate-coverage-matrix.sh --level project specs/projects/<PROJECT_ID>
bash .speck/scripts/validation/validators/validate-coverage-matrix.sh specs/projects/<PROJECT_ID>
```

**Opt-in (expensive) — FILL** (`--exhaustive`). Compute the coverage universe (persona-army × route × {happy,error,empty,loading} × viewport × theme, + an N-sample input-variety matrix on §8 AI-generative surfaces), then fan out UNCHANGED `/speck-larp <persona> --tier=torture` runs via parallel `@speck-validator` subagents grouped by build fingerprint (one cold-start serves many cells). Per generative cell, run `banned-language-lint.sh` **deterministically across all N samples** (the deterministic cure for a stale banned word slipping a single happy-path seed). Add full-page axe (not element-scoped) + Lighthouse per screen, and the evidence-contract §11 resilience class as the resilience cells (for `infra_service`/`backend_api`, §11 *is* the torture grid). Record each cell's Job A/B/C verdict + a real `larp-recordings/…` evidence path (no surrogate) into `coverage-matrix.md`.

**Verdict.** The breadth verdict from the coverage-matrix **caps** (never raises) the claimable state. Run `validate-coverage-matrix.sh --strict` before a project SHIP-RC claim when the project declared the coverage-matrix as a required gate in `evidence-contract.md` §8. Opt-in everywhere; advisory-recommended before the first consumer SHIP-RC.

---

## Full JTBD Smoke Test (REQUIRED — Product-Level Coherence)

**This is the ultimate composition check** — verifying the product works as a whole, not just as a collection of validated epics.

### Step A: Core JTBD End-to-End Walkthrough

1. Read `project.md` and identify the **primary job the user hired this product to do**
2. Start from scratch — open the app as a brand-new user would
3. Attempt to complete the core JTBD without any developer knowledge:
   - No dev-mode headers
   - No hardcoded UUIDs or API keys
   - No terminal commands or direct API calls
   - No "you need to go to the other platform for this"
4. Record every step, every dead end, every moment of confusion

### Step B: Cross-Epic Flow Verification

For each dependency arrow in `epics.md`:
- Test the actual data/auth/navigation flow between epics
- Verify a user can move between features from different epics seamlessly
- Check that context (auth, org, user) carries through the entire product

### Step C: Platform Coherence

If the project spans multiple platforms (web + mobile, desktop + API, etc.):
- Each platform MUST deliver a usable version of the core JTBD
- "Use the other platform for this" is acceptable for secondary features only
- Primary features must be reachable on every supported platform

### Step D: No Dead Ends

- Every reachable feature has a way back
- Every user action has feedback (success, error, loading)
- No features require dev knowledge to operate
- No scaffolding (UUID inputs, debug headers) remains in production UI

### Step E: Generate JTBD Smoke Test Section

Include in `project-validation-report.md`:

```markdown
## Product Coherence — JTBD Smoke Test

**Primary JTBD**: [From project.md — what the user hired this product to do]
**Test Date**: [When performed]
**Platforms Tested**: [Web, Mobile, etc.]

### Core Journey

| Step | User Action | Expected | Actual | Status |
|------|-------------|----------|--------|--------|
| 1 | First visit / signup | [Expected] | [Actual] | ✅/❌ |
| 2 | [Next action] | [Expected] | [Actual] | ✅/❌ |
| ... | ... | ... | ... | ... |

**JTBD Completion**: [COMPLETE / PARTIAL / BLOCKED]

### Cross-Epic Flows

| Flow | Epics Involved | Status | Issues |
|------|---------------|--------|--------|
| [User journey spanning epics] | E001 → E003 | ✅/❌ | [Details] |
| ... | ... | ... | ... |

### Platform Coherence

| Platform | Core JTBD Completable? | Missing Features | Status |
|----------|----------------------|------------------|--------|
| Web | Y/N | [List] | ✅/❌ |
| Mobile | Y/N | [List] | ✅/❌ |

### Dead Ends Found

- [List any features that are unreachable, have no navigation, or require dev knowledge]

### Scaffolding Remaining

- [List any dev-mode shortcuts still in production UI]
```

### Step F: First-Time User Comprehension / Legibility Check

**This is the ultimate clarity and value-articulation check**:
1. Within 5 seconds of cold-starting the app walkthrough, can a first-time user articulate:
   - Exactly what the product is?
   - Why it matters (value proposition)?
   - What the primary call-to-action (CTA) is?
2. If the interface is cluttered, uses confusing technical jargon, or fails to make the core value immediately clear:
   - Flag a **`LEGIBILITY.P1`** finding.
   - **CAP project readiness below `SHIP-RC`** (limit to `UX-RC` or lower) until copy and design are clarified to ensure commercial viability and user success. "Technically correct but functionally unintelligible" is a failure.

### Step G: JTBD Status Overrides Project Status

| JTBD Smoke Test | Project Status |
|-----------------|----------------|
| COMPLETE (and Legibility is PASS) | GO (if all other checks pass) |
| PARTIAL (or has LEGIBILITY.P1) | CONDITIONAL — list missing pieces / cap below SHIP-RC |
| BLOCKED | NO-GO — product cannot deliver its core value |

**CRITICAL**: A project with all epics validated but a BLOCKED JTBD or unresolved `LEGIBILITY.P1` is a NO-GO / capped below SHIP-RC.

---

Note: This is the final gate before production deployment. Be thorough and honest about readiness. Check both bottom-up (all specs met) AND top-down (product actually works for users).
