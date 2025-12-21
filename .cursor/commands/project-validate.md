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
   ```
   # Project Validation Report: [Project Name]
   
   **Validation Date**: [Date]
   **Project Duration**: [Start] to [End]
   **Overall Status**: [SUCCESS/PARTIAL/FAILED]
   
   ## Executive Summary
   
   [2-3 paragraphs summarizing project outcome vs original vision]
   
   ## Vision Achievement
   
   Original Vision: "[Vision statement from project.md]"
   
   Achievement Assessment:
   - Core vision realized: [Yes/No/Partial]
   - User problems solved: [X of Y]
   - Business value delivered: [Assessment]
   
   ## Goal Completion
   
   | Goal | Target | Actual | Status | Notes |
   |------|--------|--------|--------|-------|
   | [Goal 1] | [Target] | [Actual] | ✅❌⚠️ | [Notes] |
   
   ## Epic Summary
   
   | Epic | Stories | Completed | Coverage | Status |
   |------|---------|-----------|----------|--------|
   | E001 | 8 | 8 | 100% | ✅ Complete |
   | E002 | 12 | 11 | 92% | ⚠️ Partial |
   
   ## Requirements Traceability
   
   ### Functional Requirements
   - Total: [X]
   - Implemented: [Y] ([Z]%)
   - Deferred: [List with reasons]
   - Failed: [List with reasons]
   
   ### Non-Functional Requirements  
   - Performance: [Met/Not Met] [Details]
   - Security: [Met/Not Met] [Details]
   - Scalability: [Met/Not Met] [Details]
   - Accessibility: [Met/Not Met] [Details]
   
   ## Success Metrics Results
   
   ### Business Metrics
   [Detailed analysis of each metric]
   
   ### Technical Metrics
   [Performance, reliability, etc.]
   
   ### User Metrics
   [Satisfaction, adoption, etc.]
   
   ## Quality Validation
   
   ### Test Results
   - Unit Tests: [X]% coverage, [Y] passing
   - Integration Tests: [X] scenarios, [Y] passing
   - E2E Tests: [X] journeys, [Y] passing
   - Performance Tests: [Results vs targets]
   
   ### Code Quality
   - Technical Debt: [Estimated days]
   - Code Duplication: [X]%
   - Complexity: [Average score]
   - Documentation: [Coverage %]
   
   ### Security Audit
   - Vulnerabilities: [Count by severity]
   - Compliance: [Standards met]
   - Penetration Test: [Results if done]
   
   ### Cursor Rules Compliance
   
   **Rules Directory**: `.cursor/rules/` [exists/not found]
   **Total Project Rules**: [X]
   **Epics Evaluated**: [Y]
   **Total Stories Evaluated**: [Z]
   
   | Rule File | Coverage | Pass Rate | Compliance Trend |
   |-----------|----------|-----------|------------------|
   | [rule.mdc] | 12/12 epics, 160 stories | 98% | ✅ Excellent |
   | [rule.mdc] | 8/12 epics, 120 stories | 75% | ⚠️ Needs work |
   | [rule.mdc] | 12/12 epics, 160 stories | 100% | ✅ Perfect |
   
   **Overall Compliance**: [X]% across all rules
   
   **Project-Wide Patterns**:
   - ✅ **Consistently Followed** (>95% compliance):
     * [Rule 1]: [brief description]
     * [Rule 2]: [brief description]
   
   - ⚠️ **Need Improvement** (75-95% compliance):
     * [Rule 3]: [common issues and recommendations]
     * [Rule 4]: [common issues and recommendations]
   
   - ❌ **Systemic Issues** (<75% compliance):
     * [Rule 5]: [root cause analysis and action plan]
   
   **Systemic Violation Analysis**:
   - [Pattern 1]: Occurred in [X] stories across [Y] epics
     * Root cause: [analysis]
     * Impact: [severity assessment]
     * Recommendation: [how to prevent in future]
   
   **Rule Quality Assessment**:
   - Rules that worked well: [list and why]
   - Rules that were unclear: [list and suggested improvements]
   - Rules that were too strict: [list and suggested adjustments]
   - Missing rules: [gaps identified during project]
   
   **Recommendations for Future Projects**:
   - Update/refine existing rules: [specific recommendations]
   - Add new rules: [gaps to address]
   - Add automation/tooling: [rules that could be automated]
   - Team training needed: [areas where violations were common]
   
   ## Deviations from Plan
   
   ### Scope Changes
   | Change | Reason | Impact | Approval |
   |--------|--------|--------|----------|
   
   ### Timeline Variance
   - Planned: [X weeks]
   - Actual: [Y weeks]
   - Variance: [+/- Z weeks]
   - Causes: [List]
   
   ### Resource Utilization
   - Planned: [Team size/skills]
   - Actual: [What was used]
   - Efficiency: [Assessment]
   
   ## Lessons Learned
   
   ### What Went Well
   1. [Success factor]
   2. [Success factor]
   
   ### What Could Improve
   1. [Improvement area]
   2. [Improvement area]
   
   ### Recommendations for Future
   1. [Process improvement]
   2. [Technical recommendation]
   
   ## Production Readiness
   
   ### Deployment Checklist
   - [ ] All epics validated
   - [ ] Performance targets met
   - [ ] Security scan clean
   - [ ] Documentation complete
   - [ ] Monitoring configured
   - [ ] Rollback plan exists
   - [ ] Support team trained
   
   ### Go/No-Go Decision
   
   Recommendation: [GO/NO-GO/CONDITIONAL]
   
   Conditions (if any):
   1. [Condition]
   2. [Condition]
   
   ## Appendices
   
   ### A. Detailed Test Results
   [Links to test reports]
   
   ### B. Performance Benchmarks
   [Detailed performance data]
   
   ### C. Outstanding Items
   [Punch list for post-launch]
   ```

8. Generate actionable next steps:
   ```
   ## Post-Validation Actions
   
   ### Must Do Before Launch
   1. [Critical item]
   2. [Critical item]
   
   ### Should Do Soon
   1. [Important item]
   2. [Important item]
   
   ### Nice to Have
   1. [Enhancement]
   2. [Enhancement]
   
   ### Version 2 Backlog
   [Items deferred to next version]
   ```

9. Save validation artifacts:
   - Full report: `[PROJECT_DIR]/project-validation-report.md`
   - Executive summary: `[PROJECT_DIR]/project-validation-summary.md`
   - Punch list: `[PROJECT_DIR]/project-punch-list.md`

10. Output summary:
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
