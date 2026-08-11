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

Error conditions:
- No project.md found → ERROR with instructions
- Project already has PRD → WARN "Project already planned, clarifications may require re-planning"
- User skips all questions → WARN about incomplete specification risks
4. Ask the highest-impact unresolved questions. Give 2–3 mutually exclusive options when useful and explain which project decision each answer resolves.

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
