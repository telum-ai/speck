---
name: epic-validate
description: Load after all stories in an epic are individually validated and /audit has run for the epic. Verifies the epic's goals were achieved as a whole. Performs end-to-end JTBD walkthrough via /larp. Declares a readiness state for the epic. Produces epic-validation-report.md — required before epic-retrospective. FIRST ACTION after loading is read templates at .speck/templates/epic/epic-validation-report-template.md, .speck/templates/story/validation-report-template.md (for readiness state guidance), and .speck/templates/epic/epic-punch-list-template.md.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Templates First

**Before any other action** — read templates now:
```
.speck/templates/epic/epic-validation-report-template.md
.speck/templates/story/validation-report-template.md   # readiness state structure (epic uses same taxonomy)
.speck/templates/epic/epic-punch-list-template.md
```

**Checkpoint**: After reading, note the v7 readiness states (`NO-SHIP`, `IMPL-GREEN`, `INTEGRATION-GREEN`, `UX-RC`, `API-RC`, `COMMERCIAL-RC`, `SHIP-RC`, `SHIP`) and the v7 gate criteria.

---

## 🚦 Pre-Validate Gates (v7 — Mandatory)

Before doing ANY epic-level validation work, verify:

1. **Every story in the epic has its own `validation-report.md` with verified state >= IMPL-GREEN**
   - If any story is still NO-SHIP: STOP. Tell user "Story <id> is at NO-SHIP. Fix and re-validate before epic-validate."

2. **`/audit --epic <id>` was run** producing `audit-report.md` at the epic level
   - If missing: STOP. Tell user "Run `/audit --epic <id>` first — epic-validate requires the cross-story audit."
   - If P0 findings: STOP. Resolve before proceeding.

3. **Check Project Archetype & UI Presence**:
   - Read `.speck/project.json` → `project_archetype` (and `play_level`).
   - If `project_archetype` is `infra_service` or `backend_api`, or if the epic has no user-facing UI components: **Bypass human `/larp` and Premise-Challenge requirements**. Proceed directly.
   - For all UI-facing epics (archetypes `consumer_product`, `b2b_saas`, `internal_tool` with user-facing interfaces):
     - **full-flow `/larp` MUST have been run** for every persona per evidence-contract
       - Captures the JTBD walkthrough end-to-end across stories (not just per-story segments)
       - If missing: STOP. Tell user "Run `/larp` for each persona's full epic flow first."
     - **Premise-Challenge (Anti-Spec) Pass**: If the epic touches high-impact surfaces (onboarding/first-run, empty states, paywalls/billing, error/degraded states, celebration surfaces), a **Premise-Challenge pass MUST have been run** (using `/speck-premise-challenge`) and documented.
       - If missing or failed: cap the maximum claimable state at `IMPL-GREEN` or `INTEGRATION-GREEN` (cannot claim `UX-RC` or higher).

4. **`evidence-contract.md` exists**
   - If missing: STOP.

If any pre-gate fails: refuse to proceed. Surface what's missing.

---

## 🎯 v7 Epic Validation Algorithm

1. Read every story's `validation-report.md` — extract verified states + evidence paths.
2. The epic's MAX claimable state = MIN(story states).
2b. Evaluate verifiability tiers (agent-LARP vs. device-walk):
    - Check if any story spec in the epic or the epic spec contains criteria marked `device-walk`.
    - If `device-walk` criteria exist and no valid human-attestation file is recorded in `larp-recordings/<sha>-human-attestation.md` at the epic level (or linked from the stories), the AI agent's maximum claimable epic state is capped at `UX-RC` (agent-verified) and the agent CANNOT claim `SHIP-RC` or higher, marking the epic as "Awaiting human device walk" to complete `SHIP-RC+`.
2c. **Parallel-Auditor Graceful Degradation Protocol**:
    - The `/audit --epic` step uses parallel `speck-auditor` subagents. If any subagent stalls (e.g., reaches maximum timeout or watchdogs on large file reads), the main orchestrator MUST NOT block the entire validation.
    - Instead, the orchestrator MUST gracefully degrade, take over the stalled subagent's scope, complete the check sequentially or via lighter heuristics, and explicitly disclose in `audit-report.md` and `epic-validation-report.md` that a fallback check was performed.
2d. **Evaluate FELT-GOOD taste review** (for consumer archetypes):
    - Read `.speck/project.json` → `project_archetype`.
    - If `project_archetype` is `consumer_product` and the claimed state is `SHIP-RC` or higher:
      - Check if a valid human FELT attestation file exists at `larp-recordings/<sha>-felt-attestation.md` at the epic level (or linked from the stories).
      - If missing: the AI agent **MUST** cap the verified state at `UX-RC` (with `FELT: uncovered (human required)`) and refuse to claim `SHIP-RC` or higher, detailing that the epic is "Awaiting human FELT taste attestation" to complete `SHIP-RC+`.
3. Read `audit-report.md` — any P0 lowers max claimable state.
4. **Primary UI Gate — JTBD Cold-Start LARP (Mandatory Centerpiece)**:
    - Running the individual stories' validations is necessary but completely insufficient to prove a product works, because stories are isolated islands and are vulnerable to the composition fallacy.
    - For all UI-facing epics, the **JTBD cold-start LARP walkthrough is the absolute centerpiece of validation and is REQUIRED and non-deferrable**. You must execute a complete end-to-end walkthrough starting from a clean, non-seeded, cold-booted target build (no dev shortcuts, real navigation paths, real login flows).
    - Read epic-level `larp-recordings/` — full JTBD walkthrough must PASS for UX-RC+.
    - **Drive the real built app — do not substitute a code-level reading.** Whenever a browser/preview/simulator tool is available, the agent MUST drive the actual built artifact (browser/operator LARP) and **store the axe-core JSON**, rather than concluding "the stories compose end-to-end" by inspecting code. A code-level composition reading is NOT UX-RC evidence. This autonomous portion (build + browser LARP + stored axe + JTBD walkthrough) is REQUIRED. Deferring the browser cold-start LARP is strictly prohibited. If there is an infrastructure limitation, it must be reported as a hard blocker (`NO-SHIP`) rather than allowing a bypass, unless a named infrastructure blocker is explicitly identified and the attempt is logged (in which case the state is capped at `INTEGRATION-GREEN`).
    - Run the **First-Time User Comprehension Rubric** on the walkthrough (What am I seeing? Why does it matter? What do I do next?).
    - If the JTBD cold-start LARP walkthrough fails, or if first-time user comprehension is blocked on any primary screen/step (e.g. dead-end placeholders, broken navigation headers, hard 404s), **the epic validation is FAIL regardless of story-level results**, and the maximum claimable/verified state is strictly capped at `IMPL-GREEN`.

### 💡 UI LARP Setup Recipe (Sandbox-Friendly)

To execute browser LARPs successfully in sandboxed or restricted environments without real production databases/credentials:
1. **Throwaway/Local DB**: Seed a local/SQLite or Docker-based database with minimal test fixtures.
2. **Loopback/Review-Session Backdoor**: Implement a secure backdoor route or environment flag (e.g. `VITE_DEV_HTTP=true` or `process.env.PLAYWRIGHT_TEST=true`) that bypasses external OAuth/Clerk redirects and logs in a test user.
3. **localStorage Token Re-injection**: Pre-populate `localStorage` or cookies with mock JWTs or session tokens before navigating, to simulate an authenticated state.
4. **Loopback/Mock Server**: Run a lightweight local mock server (e.g., MSW or wiremock) to intercept and mock third-party API calls (e.g., Stripe, Resend) during the browser run.

4b. **Verify Deferrals / What this validation did NOT verify**:
    - Require that the epic validation report populates the `## 🔬 What this validation did NOT verify / Deferrals` section. Failure to declare what was unchecked or untested will fail the validation.
    - **Cap Status enforcement**: every deferral row MUST include `Cap Status` (`evidence-pending` or `implementation-pending`). Any row tagged `implementation-pending` (code path not built) → verified state MUST cap at `NO-SHIP`. Any row tagged `autonomous-not-done` is NOT allowed for the browser cold-start LARP; any other autonomous deferral row tagged `autonomous-not-done` → cap at `IMPL-GREEN`/`INTEGRATION-GREEN` (cannot claim UX-RC/API-RC).
4c. **INTEGRATION-GREEN gate** (when epic depends on external services in evidence-contract §7 or is DB-backed):
    - If §7 lists services this epic touches, verify at least one **real round-trip** succeeded per service across the epic's stories (not mock-only). Capture logs/traces.
    - If the project is DB-backed, run `validate-schema-drift.sh --strict` to verify live database schema matches migrations. Ensure at least one real write path is exercised (reads can fail-close or swallow missing tables).
    - Mock-green + adversarial audit alone is insufficient — the E002 LLM epic passed both with zero real Gemini calls; INTEGRATION-GREEN requires proof of at least one live call per §7 service + schema-drift validation.
    - If no §7 services apply and the project is not DB-backed, INTEGRATION-GREEN auto-passes.
5. For non-UI epics (e.g. `infra_service` / `backend_api`): Validate the core system transaction flow via the Option B "System Operational Scenario Walkthrough". Verify all performance, load-handling, and failover invariants hold under disruption. Declare `API-RC` when autonomous API-RC criteria pass (see evidence-contract §8).

5b. **Promise Conservation Re-Walk + Evaporation Audit (REQUIRED — gates the readiness state)**:
   - **Re-walk the matrix with evidence**: run
     ```
     bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --require-evidence [EPIC_DIR]
     ```
     (For a quick, status-only check without cross-referencing story validation reports, you can append `--status-only`.)
     Every `PRM-NNN` row MUST be `discharged` (a validated story cited it with evidence — see story-validate Spec Coverage), `descoped` (a DEC), or `pilot-gated` (deferred to the pilot program with a valid backing reference). The JTBD walkthrough is necessary but **NOT sufficient** — a passing JTBD sample does not prove the long tail of promised screens/elements/seams exists. **Any open/undischarged row → the epic CANNOT claim any readiness state** (cap at the last clean state, surface the gap).
   - **Evaporation audit (dead-seam detection)**: grep the shipped data model + code for affordances that exist but are never populated, rendered, or wired — e.g. an `urgent` enum value never set by any writer, a prop-gated button with no caller, a status column no query reads, a route with no link. These are promises that were half-built then abandoned — **descope-by-silence**. Each finding must become either a DEC (intentional descope) or a P1 fix; record them in the report's Promise Conservation section. A drawn-but-dead seam is not "done", it is evaporated.
6. Cross-epic integration check: any seams to other epics tested?
7. If any previous rating, state, or recommendation has changed, write the `### Evaluative Drift / Change Explanation` section with detailed logical rationale.
8. Run banned-phrase self-check on this report's own language before publishing
9. Apply SHA stamp; trigger `/project-state` regeneration
9b. **Run FELT-GOOD axis validation:** run `bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict epic-validation-report.md` to ensure three-axis compliance and human FELT attestation for consumer SHIP-RC+.

### 🚦 Continuous Feedback Capture Trigger
If any story-level validation is bypassed or the JTBD LARP is blocked by infrastructure, you **MUST** run `/speck-feedback` (or read `.cursor/skills/speck-feedback/SKILL.md`) to document the block and propose an upstream fix. Do not let workarounds go undocumented.
10. **If readiness >= UX-RC:** run `.speck/scripts/regenerate-project-readme.sh --epic-validated <E###>` to update README magic-moments / recently-validated sections

The legacy v6 epic validation algorithm follows below (use for cross-story integration details, but verdict MUST be a readiness state).

---

Comprehensive validation that the epic delivers on its promises and integrates properly with the system.

## Subagent Parallelization

This command benefits from parallel validation checks:

```
├── [Parallel] speck-auditor: "Verify all story validations pass"
├── [Parallel] speck-auditor: "Check epic goals from epic.md are achieved"
├── [Parallel] speck-auditor: "Verify architecture matches epic-architecture.md"
├── [Parallel] speck-auditor: "Test integration with other epics works"
├── [Parallel] speck-auditor: "Check code quality, tests, and docs"
├── [Parallel] speck-auditor: "Verify Cursor rules compliance"
└── [Wait] → Synthesize into epic-validation-report.md

Each auditor returns PASS | FAIL | PARTIAL with evidence.
```

**Speedup**: 5-6x compared to sequential validation.

---

1. Load epic completion status:
   - Original specs: epic.md, epic-tech-spec.md
   - Story status: Check epic-breakdown.md completion
   - Story validations: Check each story directory
   - Integration with other epics
   - If files missing: ERROR "Epic planning artifacts not found"

2. Story completion verification:
   ```
   For each story in epic-breakdown.md:
   - Check stories/[story-id]/validation-report.md
   - Verify implementation matches spec
   - Confirm tests passing
   - Note any deviations
   ```

3. Multi-level validation:

   **Epic Vision Validation**
   - Original value proposition achieved?
   - All user stories implemented?
   - Success criteria met?
   - Business value delivered?

   **Technical Implementation Validation**
   - Architecture as designed?
   - All APIs implemented correctly?
   - Data models match spec?
   - Performance targets met?

   **Integration Validation**
   - Works with dependent epics?
   - Provides promised interfaces?
   - No breaking changes?
   - End-to-end flows work?

   **Quality Standards Validation**
   - Code quality gates passed?
   - Test coverage adequate?
   - Documentation complete?
   - Security requirements met?
   - Cursor rules compliance across stories?

4. Cursor rules compliance aggregation:
   - Check if `.cursor/rules/` directory exists
   - If exists, load all rule files (`*.mdc` or `*.md`)
   - Aggregate rule compliance from story validation reports:
     * For each story in epic, check if validation-report.md includes Cursor Rules section
     * Collect compliance status for each applicable rule across all stories
     * Identify patterns: rules consistently passed vs consistently violated
   - For epic-level validation, check rules that apply to epic scope:
     * Cross-story integration patterns
     * Epic-wide architectural rules
     * Consistency rules (e.g., same patterns used across stories)
   - Generate epic-level rules compliance summary:
     ```
     ## Cursor Rules Compliance (Epic Summary)
     
     **Rules Directory**: `.cursor/rules/` [exists/not found]
     **Total Rules**: [X]
     **Applicable to Epic**: [Y]
     
     | Rule File | Stories Using | Pass Rate | Common Issues |
     |-----------|---------------|-----------|---------------|
     | [rule.mdc] | 8/8 | 100% (8/8) | None |
     | [rule.mdc] | 5/8 | 60% (3/5) | [pattern] violated in S002, S005, S007 |
     
     **Epic-Level Rule Checks**:
     - Consistency across stories: [✅/⚠️/❌]
     - Integration patterns: [✅/⚠️/❌]
     - Cross-story architectural compliance: [✅/⚠️/❌]
     ```
   - If no `.cursor/rules/` directory: Note "No project-specific rules found"
   - If patterns of violations across stories: Flag for epic-level retrospective

4.5. **Visual Design Validation** (if epic has UI components):

   **Reference**: `.cursor/skills/visual-testing/SKILL.md`
   
   **Load Epic-Level Visual Artifacts**:
   - `[EPIC_DIR]/wireframes.md` → Layout expectations
   - `[EPIC_DIR]/user-journey.md` → Touchpoint visual requirements
   - `specs/projects/[PROJECT_ID]/design-system.md` → Tokens, patterns
   - `specs/projects/[PROJECT_ID]/ux-strategy.md` → Voice/tone, accessibility
   
   **Aggregate Story Visual Results**:
   - Collect screenshots from all story `larp-recordings/` and story validation folders.
   - Check each story's validation-report.md for visual validation section.
   - Aggregate design token compliance percentages.
   - Aggregate accessibility audit results.
   
   **LOCAL-FIRST MULTI-MODAL VISUAL REVIEW (CRITICAL FOR AGENTS)**:
   - If screenshots or recordings exist, and you are a multi-modal AI agent, **you MUST use the `Read` tool on these image files** to visually inspect the overall coherence, layouts, spacing, and brand feel of the epic.
   - Evaluate the screens against the user journey touchpoints to ensure transitions and page flows feel integrated and smooth, citing the specific screenshot path read in your review.
   
   **Wireframe Adherence Check**:
   - Compare implemented screens against wireframes.md layouts
   - Check grid alignment, spacing, hierarchy
   - Verify responsive breakpoints match wireframe variants
   - Note deviations with justification
   
   **User Journey Visual Completion**:
   - For each touchpoint in user-journey.md:
     * Verify screen exists and is implemented
     * Check visual treatment matches emotional goals
     * Verify transitions/animations between touchpoints
   - Flag missing or incomplete touchpoints
   
   **Cross-Story Visual Consistency**:
   - Same components look identical across stories
   - Consistent spacing, typography, colors
   - No one-off styling deviations
   - All use design system tokens (no hardcoded values)
   
   **Design System Adoption**:
   - Calculate % of components using design-system.md patterns
   - Flag custom components that should use existing patterns
   - Note design system gaps (patterns needed but not defined)
   
   **Voice/Tone Consistency**:
   - Aggregate voice/tone compliance from story validations
   - Check consistency across epic (same voice everywhere)
   - Flag mixed messaging or tonal inconsistencies

5. Execute validation suites:

   **Automated Testing**
   - Run all story unit tests
   - Run epic integration tests
   - Run cross-epic tests
   - Performance benchmarks
   - Security scans

   **Manual Validation**
   - User acceptance scenarios
   - Epic-level user journeys
   - Edge case verification
   - Stakeholder demos

6. Generate validation report:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/epic-validation-report-template.md
   ```

   Write output to: `[EPIC_DIR]/epic-validation-report.md`

7. Generate punch list:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/epic-punch-list-template.md
   ```

   Write output to: `[EPIC_DIR]/epic-punch-list.md`

8. Save validation artifacts:
   - Report: `[EPIC_DIR]/epic-validation-report.md`
   - Punch list: `[EPIC_DIR]/epic-punch-list.md`

9. Update epic status:
   - Update epic.md status field
   - Note completion date
   - Link validation report

10. Output summary:
   ```
   ✅ Epic Validation Complete!
   
   Epic: [Name]
   Status: [COMPLETE/PARTIAL/FAILED]
   
   Results:
   - Stories Complete: [X of Y]
   - Tests Passing: [A]%
   - Performance: [Met/Not Met]
   - Quality Gates: [Passed/Failed]
   
   Outstanding Issues: [Count]
   - Critical: [X]
   - Important: [Y]
   - Minor: [Z]
   
   [If APPROVED]:
   Epic ready for production!
   Next: Integration with other epics
   
   [If CONDITIONAL]:
   Fix required items, then re-validate
   
   Reports:
   - epic-validation-report.md
   - epic-punch-list.md
   ```

---

## JTBD Walkthrough (REQUIRED — Top-Down Product Coherence)

**This section prevents the composition fallacy** — where each story passes individually but the epic doesn't work as a product.

After all bottom-up validation passes (steps 1-10), perform a **top-down walkthrough** of the epic's core JTBD:

### Step A: Identify the Epic's Core JTBD

Read `epic.md` and extract:
- What workflow does this epic enable?
- What is the user trying to accomplish?
- What does success look like from the user's perspective?

### Step B: Walk the Journey End-to-End

Starting from the app's entry point (login page, home screen, etc.):
1. Attempt to complete the epic's core workflow as a real user would
2. Do NOT use dev shortcuts, hardcoded UUIDs, or API headers
3. Do NOT assume knowledge of internal IDs or system internals
4. Record every step, noting what works and what doesn't

### Step C: Check Composition

| Check | Question | FAIL if |
|-------|----------|---------|
| Discoverability | Can a user find every feature in this epic? | Features exist but aren't reachable from navigation |
| Auth continuity | Does authentication work through the entire flow? | Dev-mode headers, hardcoded tokens, or missing login |
| Scaffolding | Are any dev shortcuts still in the UI? | UUID text fields, debug panels, placeholder auth |
| Connected flow | Do the stories connect into a coherent journey? | Stories are isolated islands with no navigation between them |
| Platform coverage | If multi-platform, does each platform deliver usable experience? | "Use the other platform for this" for core features |

### Step D: Cross-Epic Integration (if dependencies exist)

Read `epics.md` or `epic-breakdown.md` for this epic's dependencies:
- For each upstream epic: verify data/auth/context flows correctly into this epic
- For each downstream epic: verify this epic exposes what dependents need
- Test navigation between features from different epics
- Verify shared state (auth tokens, user context, org context) carries through

### Step E: Generate JTBD Walkthrough Section

Include in `epic-validation-report.md`:

```markdown
## JTBD Walkthrough

**Core Job**: [What the user is trying to accomplish]
**Entry Point**: [Where the user starts — e.g., login page, home dashboard]
**Date**: [When walkthrough was performed]

### Journey Steps

| Step | User Action | Expected Result | Actual Result | Status |
|------|-------------|-----------------|---------------|--------|
| 1 | Open app | See login/home | [What happened] | ✅/❌ |
| 2 | Navigate to [feature] | Find via [nav element] | [What happened] | ✅/❌ |
| ... | ... | ... | ... | ... |

### Composition Assessment

- **JTBD Completion**: [COMPLETE / PARTIAL / BLOCKED]
- **Blocking Issues**: [List if not COMPLETE]
- **Scaffolding Remaining**: [List any dev shortcuts still in UI]
- **Platform Coverage**: [Which platforms deliver this workflow]

### Cross-Epic Integration

- **Upstream Dependencies Tested**: [List epics and results]
- **Downstream Interfaces Verified**: [List epics and results]
- **Shared State**: [Auth/context carries through? Y/N]
```

### Step F: Determine Final Status

**CRITICAL**: If JTBD completion is BLOCKED or PARTIAL, the epic validation is **FAIL** — regardless of whether all individual story validations passed. Each part working is not enough; the whole must work.

| JTBD Status | Epic Validation |
|-------------|-----------------|
| COMPLETE | PASS (if all other checks also pass) |
| PARTIAL | CONDITIONAL_PASS — list what's missing, create punch-list items |
| BLOCKED | FAIL — users cannot accomplish the core job |

---

Note: Epic validation ensures the feature set works as a cohesive whole — both bottom-up (spec compliance) AND top-down (product coherence).
