# project-clarify / question-sets

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

3. **User Validation** (Important)
   - Query: "Developer workflow integration patterns for AI tools"
   - Why: UX approach needs real-world usage patterns

Next Steps:
- If research needed: Apply the just-in-time research pattern
  (`.cursor/skills/just-in-time-research/SKILL.md`) to answer the queries above, then continue
- If UX-heavy product: /project-ux (define experience strategy)
- If standard product: /project-context (define constraints and standards)
- If very simple (Level 0-1): Skip to /project-plan

Note: Foundation commands (ux, context, constitution) provide essential
inputs for PRD creation. Running them before /project-plan ensures complete PRD.
```

Error conditions:
- No project.md found → ERROR with instructions
- Project already has PRD → WARN "Project already planned, clarifications may require re-planning"
- User skips all questions → WARN about incomplete specification risks
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
