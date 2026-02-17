---
name: project-analyze
description: Perform comprehensive analysis of project plan, PRD, and epic structure to identify issues before execution begins
disable-model-invocation: false
---

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

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/project/project-analysis-report-template.md
   ```

   Write output to: `[PROJECT_DIR]/project-analysis-report.md`

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
