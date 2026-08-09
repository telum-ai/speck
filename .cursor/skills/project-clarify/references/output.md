# project-clarify — output

completed) BEFORE invoking `/project-plan`. If the user explicitly states they are skipping clarification (e.g., proof of concept), you may proceed, but must warn that downstream rework risk increases.

Execution steps:

1. Determine active project directory:
   - Check current working directory for project.md
   - If not found, scan specs/projects/ for most recent project
   - Parse PROJECT_DIR and PROJECT_SPEC paths
   - If no project found: ERROR "No active project found. Run /project-specify first"

2. Load ONLY upstream context (do NOT load downstream artifacts):
   
   **ALWAYS Load** (upstream/input to clarify):
   - `project.md` (the spec to clarify)
   - `project-import.md` (if exists - brownfield non-code extraction)
   - `project-landscape-overview.md` (if exists - brownfield code extraction)
   
   **NEVER Load** (downstream/created AFTER clarify):
   -  `PRD.md` - Created by /project-plan (comes AFTER clarify)
   -  `context.md` - Created by /project-context (comes AFTER clarify)
   -  `architecture.md` - Created by /project-architecture (comes AFTER clarify)
   -  `design-system.md` - Created later (comes AFTER clarify)
   -  `ux-strategy.md` - Created by /project-ux (parallel/before clarify)
   -  `epics.md` - Created by /project-plan (comes AFTER clarify)
   
   **Why**: Clarify refines the INPUT (project.md). Don't confuse it with OUTPUT artifacts.

3. Perform a structured ambiguity & coverage scan using this taxonomy. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output raw map unless no questions will be asked).

   Strategic Scope & Vision:
   - Project boundaries and success definition
   - Explicit exclusions and v2+ deferrals
   - Stakeholder alignment and priorities
   
   User & Market Understanding:
   - User segment definition and validation
   - Problem severity and frequency
   - Alternative solutions evaluation
   - Market timing and urgency
   
   Business Model & Constraints:
   - Revenue/cost model implications
   - Monetization strategy clarity
   - Pricing approach and validation plan
   - Unit economics assumptions (CAC, LTV)
   - Go-to-market strategy
   - Resource availability and skills
   - Timeline drivers and flexibility
   - Compliance and policy requirements
   
   Technical Landscape:
   - Integration requirements specificity
   - Performance and scale expectations
   - Security and privacy requirements
   - Platform and deployment constraints
   
   Risk & Dependencies:
   - Critical path dependencies
   - Technical feasibility concerns
   - Organizational change requirements
   - Market/competitive risks

3. Generate clarifying questions:
   - Maximum 7 questions for project-level (strategic focus)
   - Prioritize by: Risk > Scope > Users > Technical > Other
   - Each question must be specific and actionable
   - Provide 2-3 answer options where helpful
   - Mark which section each answer will clarify
   
   **Brownfield Adaptation**:
   - If project-landscape-overview.md exists, SKIP questions about:
     * Existing features (already discovered in scan)
     * Current tech stack (already documented)
     * Current architecture patterns (already identified)
   - FOCUS brownfield questions on:
     * Strategic direction and future goals
     * User needs not evident in code
     * Business model and monetization
     * Constraints not visible in codebase (team, budget, timeline)
     * Planned enhancements or pivots

4. Present questions professionally:
   ```
   I've analyzed the project specification and identified some areas that would benefit from clarification before planning.

   1. **[Category] - [Specific Question]**
      Context: [Why this matters for project success]
      Options: 
      a) [Option 1]
      b) [Option 2]
      c) [Other/Custom]
      (This will clarify the [Section Name] section)

   [Continue for all questions...]
   ```

5. Process each answer:
   - Acknowledge the response
   - Ask follow-up if answer is ambiguous
   - Identify which section(s) to update

6. Update project.md systematically:
   - Add new "## Clarifications" section after Project Context if not exists
   - Create subsection "### Session YYYY-MM-DD"
   - List each Q&A pair concisely
   - Update relevant sections with clarified information
   - Remove any [NEEDS CLARIFICATION] markers that were resolved
   - Preserve all existing content structure

7. Validate updates:
   - Re-scan for remaining ambiguities
   - Ensure internal consistency
   - Check no contradictions introduced

8. Research need assessment (NEW - happens after Q&A):
   - Review remaining ambiguities after clarification
   - Identify which require research vs simple decisions
   - For each research need, determine:
