---
name: epic-validate
description: Load after all stories in an epic are individually validated to verify the epic's goals were achieved as a whole. Produces epic validation report — required before epic-retrospective. FIRST ACTION after loading: read templates at .speck/templates/epic/epic-validation-report-template.md and .speck/templates/epic/epic-punch-list-template.md before any context loading or artifact generation.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Templates First

**Before any other action** — read BOTH templates now using the Read tool:
```
.speck/templates/epic/epic-validation-report-template.md
.speck/templates/epic/epic-punch-list-template.md
```
This skill produces two artifacts. Read both templates now so your validation findings and punch list land in the structure the project retrospective expects.

**Checkpoint**: After reading both, note each template's top-level sections. Then continue to Step 1.

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
   - Collect screenshots from all `stories/[STORY_ID]/screenshots/`
   - Check each story's validation-report.md for visual validation section
   - Aggregate design token compliance percentages
   - Aggregate accessibility audit results
   
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
