---
description: Perform comprehensive analysis of project plan, PRD, and epic structure to identify issues before execution begins.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Analyze project planning artifacts for consistency, completeness, and feasibility before moving to epic-level work.

1. Load all project artifacts:
   - project.md (specification)
   - PRD.md (requirements document)
   - epics.md (epic breakdown)
   - project-roadmap.md (if exists)
   - architecture.md (system design with embedded research)
   - project-landscape-overview.md (if exists - brownfield scan)
   - If core files missing: ERROR "Required files not found. Run /project-plan first"

2. Multi-dimensional analysis:

   **A. Strategic Alignment**
   - PRD goals match project.md vision?
   - Success metrics measure stated goals?
   - Scope aligns with constraints?
   - Research findings incorporated?

   **B. Epic Coherence**
   - Epic boundaries logical and clear?
   - Each epic delivers standalone value?
   - Dependencies correctly identified?
   - No gaps between epics?
   - No overlapping responsibilities?

   **C. Scope Feasibility**
   - Total scope matches scale estimate?
   - Timeline realistic for scope?
   - Resource needs identified?
   - Technical risks addressed?

   **D. Requirement Coverage**
   - All PRD requirements mapped to epics?
   - All user problems addressed?
   - Non-functional requirements distributed?
   - Edge cases considered?

   **E. Risk Assessment**
   - Critical risks have mitigation?
   - Dependencies create bottlenecks?
   - Technical unknowns identified?
   - Fallback plans exist?

3. Deep-dive checks:

   **Epic Boundary Analysis**
   ```
   For each epic pair:
   - Check for overlap (same requirement in multiple epics)
   - Check for gaps (requirements not in any epic)
   - Validate dependencies (A needs B but B needs A?)
   - Assess coupling (too tightly coupled to split?)
   ```

   **Requirement Traceability**
   ```
   For each requirement in PRD:
   - Which epic implements it?
   - Is success criteria defined?
   - Can it be tested/validated?
   - Priority clear?
   ```

   **Scale Validation**
   ```
   Sum all epic story estimates:
   - Level 1: Should be 1-10 total
   - Level 2: Should be 5-15 total
   - Level 3: Should be 12-40 total
   - Level 4: Should be 40+ total
   - Flag if mismatch
   ```

4. Generate analysis report:
   ```
   # Project Analysis Report: [Project Name]
   
   **Date**: [Date]
   **Scale**: Level [X]
   **Status**: [Ready/Issues Found/Blocked]
   
   ## Executive Summary
   [High-level findings and recommendations]
   
   ## Analysis Results
   
   ### ✅ Strengths
   - [What's well-designed]
   - [What's clear and actionable]
   - [What reduces risk]
   
   ### ⚠️ Issues Found
   
   | ID | Category | Severity | Description | Recommendation |
   |----|----------|----------|-------------|----------------|
   | P1 | Epic Overlap | HIGH | E002 and E003 both handle user auth | Consolidate into E002 |
   | P2 | Missing Req | MEDIUM | Performance requirements not assigned | Add to E001 |
   
   ### 📊 Metrics
   
   #### Requirement Coverage
   - Total requirements: [X]
   - Mapped to epics: [X] ([Y]%)
   - Orphaned: [List]
   
   #### Epic Analysis
   - Total epics: [X]
   - Dependencies: [Y] identified
   - Parallel opportunities: [Z]
   - Critical path length: [N] epics
   
   #### Scope Validation
   - Estimated total stories: [X]
   - Expected for Level [N]: [Y-Z]
   - Assessment: [On track/Over/Under]
   
   #### Risk Summary
   - High risks: [X]
   - Medium risks: [Y]
   - Unmitigated: [Z]
   
   ## Detailed Findings
   
   ### Epic Boundary Issues
   [Detailed description of any overlap/gap issues]
   
   ### Requirement Issues  
   [Detailed list of unmapped or unclear requirements]
   
   ### Dependency Concerns
   [Analysis of dependency chains and bottlenecks]
   
   ### Resource Gaps
   [Skills or resources needed but not identified]
   
   ## Recommendations
   
   ### Immediate Actions
   1. [Most critical fix]
   2. [Second priority]
   
   ### Before Epic Planning
   1. [What must be resolved]
   2. [What should be clarified]
   
   ### Process Improvements
   1. [For this project]
   2. [For future projects]
   
   ## Readiness Assessment
   
   - [ ] Strategic alignment confirmed
   - [ ] Epic boundaries clean
   - [ ] Dependencies manageable  
   - [ ] Scope appropriate for scale
   - [ ] Risks identified and mitigated
   - [ ] Resources available
   - [ ] Success metrics defined
   
   **Overall Status**: [Ready to proceed / Address issues first]
   ```

5. Severity classification:
   - **CRITICAL**: Blocks project execution
   - **HIGH**: Will cause significant problems  
   - **MEDIUM**: Should be addressed before starting
   - **LOW**: Can be fixed during execution

6. Generate actionable fix commands:
   ```
   ## Suggested Fixes
   
   For epic overlap:
   /edit epics.md [specific edit]
   
   For missing requirements:
   /edit PRD.md [specific section]
   
   For scope issues:
   Consider splitting epic E003 into two
   ```

7. Save report as `[PROJECT_DIR]/project-analysis-report.md`

8. Output summary:
   ```
   ✅ Project Analysis Complete!
   
   Status: [Ready/Issues Found]
   
   Summary:
   - Strengths: [X] items
   - Issues: [Y] items ([Z] critical)
   - Coverage: [N]% requirements mapped
   
   Critical Issues:
   1. [Issue if any]
   2. [Issue if any]
   
   Next Steps:
   [If Ready]:
   - Proceed with epic planning
   - Start with: /epic-specify "E001: [Name]"
   
   [If Issues]:
   - Fix critical issues first
   - Re-run /project-analyze
   - Then proceed with epics
   
   Full report: project-analysis-report.md
   ```

This ensures the project plan is solid before investing effort in epic-level planning.
