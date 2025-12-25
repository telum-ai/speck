---
description: Validate entire project implementation against original vision, PRD, and success metrics.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Comprehensive validation of project completion, ensuring all goals are met and the system is ready for production.

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

Note: This is the final gate before production deployment. Be thorough and honest about readiness.
