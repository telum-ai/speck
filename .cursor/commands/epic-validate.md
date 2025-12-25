---
description: Validate epic implementation against specifications and technical design after story completion.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Comprehensive validation that the epic delivers on its promises and integrates properly with the system.

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

Note: Epic validation ensures the feature set works as a cohesive whole.
