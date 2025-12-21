---
description: Analyze epic plan, tech spec, and task breakdown for consistency and completeness before implementation.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Validate epic planning artifacts to identify issues before story implementation begins.

1. Load epic artifacts:
   - epic.md (specification)
   - epic-tech-spec.md (technical design with embedded research)
   - epic-breakdown.md (story mapping)
   - Related scan reports (epic-codebase-scan*.md)
   - Project-level PRD and constraints
   - If core files missing: ERROR "Complete epic planning first"
   
   **Note**: Research is now embedded in epic-tech-spec.md - no separate research.md to validate.

2. Multi-aspect analysis:

   **A. Requirement Coverage**
   - All user stories have tasks?
   - All acceptance criteria addressable?
   - Technical requirements mapped?
   - Edge cases handled?

   **B. Technical Coherence**
   - Architecture supports all stories?
   - Technology choices consistent?
   - Integration points defined?
   - Performance strategy adequate?

   **C. Task Completeness**
   - All stories broken into tasks?
   - Dependencies correctly mapped?
   - Parallel opportunities identified?
   - Effort estimates reasonable?

   **D. Risk Assessment**
   - Technical risks addressed?
   - Dependencies manageable?
   - Fallback plans exist?
   - Critical path reasonable?

   **E. Quality Coverage**
   - Test strategy comprehensive?
   - Documentation planned?
   - Security addressed?
   - Performance validated?

3. Deep analysis checks:

   **Story Traceability Matrix**
   ```
   | User Story | Tech Spec Section | Task ID | Test Coverage |
   |------------|------------------|---------|---------------|
   | Story 1.1 | Section 4.1 | S004 | Unit, Integration |
   ```

   **Dependency Analysis**
   - Circular dependencies?
   - External blockers?
   - Critical path too long?
   - Parallel opportunities missed?

   **Technical Debt Assessment**
   - Shortcuts taken?
   - Future refactoring needed?
   - Technical compromises?

4. Generate analysis report:
   ```
   # Epic Analysis Report: [Epic Name]
   
   **Date**: [Date]
   **Status**: [Ready/Issues Found/Blocked]
   
   ## Executive Summary
   [Overall assessment and recommendations]
   
   ## Coverage Analysis
   
   ### Requirement Coverage
   - User Stories: [X] total
   - With Tasks: [Y] ([Z]%)
   - With Tests: [A] ([B]%)
   
   ### Technical Coverage
   - Architecture complete: Yes/No
   - APIs specified: [X of Y]
   - Data models defined: Yes/No
   
   ## Issues Found
   
   | ID | Category | Severity | Description | Fix |
   |----|----------|----------|-------------|-----|
   | E1 | Coverage | HIGH | Story 2.1 has no task | Create task |
   | E2 | Dependency | MEDIUM | S005 and S006 circular | Refactor |
   
   ## Dependency Analysis
   
   ### Critical Path
   [S001] → [S004] → [S005] → [S020]
   Duration: [X] days
   
   ### Parallel Opportunities
   - Phase 2: [X] stories can run parallel
   - Phase 3: [Y] stories can run parallel
   
   ### Blockers
   - External: [List]
   - Technical: [List]
   
   ## Technical Validation
   
   ### Architecture
   - Supports all stories: ✅/❌
   - Scalable design: ✅/❌
   - Security addressed: ✅/❌
   
   ### Technology Stack
   - All choices justified: ✅/❌
   - Licenses compatible: ✅/❌
   - Team skills adequate: ✅/❌
   
   ## Risk Summary
   
   | Risk | Level | Mitigation | Status |
   |------|-------|------------|--------|
   | [Risk] | High | [Strategy] | ⚠️ Partial |
   
   ## Quality Gates
   
   ### Test Coverage Plan
   - Unit: [Target]% specified
   - Integration: [X] scenarios
   - E2E: [Y] journeys
   - Performance: [Z] benchmarks
   
   ### Documentation
   - API docs: Planned/Missing
   - User docs: Planned/Missing
   - Dev docs: Planned/Missing
   
   ## Recommendations
   
   ### Must Fix
   1. [Critical issue]
   2. [Critical issue]
   
   ### Should Fix
   1. [Important issue]
   2. [Important issue]
   
   ### Consider
   1. [Enhancement]
   2. [Enhancement]
   
   ## Readiness Checklist
   
   - [ ] All stories have tasks
   - [ ] Dependencies mapped
   - [ ] Architecture complete
   - [ ] Tests planned
   - [ ] Risks mitigated
   - [ ] Team aligned
   
   **Overall**: [Ready/Fix Issues First]
   ```

5. Generate fix suggestions:
   ```
   ## Quick Fixes
   
   For missing task:
   Add to epic-breakdown.md Phase 2:
   - [ ] S006 [Story 2.1 implementation]
   
   For circular dependency:
   Refactor S006 to not depend on S005
   ```

6. Save as `[EPIC_DIR]/epic-analysis-report.md`

7. Output summary:
   ```
   ✅ Epic Analysis Complete!
   
   Status: [Ready/Issues Found]
   
   Coverage:
   - Stories with tasks: [X]%
   - Technical coverage: [Y]%
   - Risk mitigation: [Z]%
   
   Critical Issues: [Count]
   Warnings: [Count]
   
   [If Ready]:
   Next: Begin implementation with Phase 1 stories
   
   [If Issues]:
   Fix critical issues then re-run /epic-analyze
   
   Full report: epic-analysis-report.md
   ```

This ensures epic plan is solid before story work begins.
