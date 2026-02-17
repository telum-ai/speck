---
name: epic-clarify
description: Identify underspecified areas in the current epic spec by asking targeted clarification questions about scope and approach
disable-model-invocation: false
---

---
description: Identify underspecified areas in the current epic spec by asking targeted clarification questions about scope and approach.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Goal: Detect and reduce ambiguity in the epic specification before moving to technical planning.

1. Load epic context:
   - Find epic.md in current directory or parent epic directory
   - Load parent project's PRD.md and epics.md
   - Load epic-codebase-scan.md if exists (brownfield code analysis)
   - Understand epic's role in larger project
   - If no epic.md: ERROR "No epic specification found. Run /epic-specify first"
   
   **Brownfield Adaptation**: If epic-codebase-scan.md exists, focus questions on non-discoverable aspects (strategy, future direction) rather than existing features.

2. Analyze epic specification for ambiguities:

   **Epic Scope & Boundaries**
   - Clear separation from other epics?
   - All user stories well-defined?
   - Edge cases identified?
   
   **Integration Points**
   - Dependencies fully specified?
   - API contracts defined?
   - Data flow clear?
   
   **Technical Approach**
   - Major technical decisions identified?
   - Performance requirements specific?
   - Security needs clear?
   
   **User Experience**
   - User journeys complete?
   - Error scenarios covered?
   - Accessibility requirements?

3. Generate clarification questions (max 5):
   - Focus on epic-specific concerns
   - Prioritize blockers for story breakdown
   - Include context for each question
   - Suggest options where helpful

4. Present questions professionally:
   ```
   I've analyzed the epic specification and found areas to clarify:
   
   1. **[Area] - [Specific Question]**
      Context: [Why this matters for epic success]
      Options:
      a) [Option 1]
      b) [Option 2]
      (This will clarify the [Section] section)
   ```

5. Update epic.md with clarifications:
   - Add "## Clarifications" section
   - Document each Q&A
   - Update affected sections
   - Remove [NEEDS CLARIFICATION] markers

6. Report completion:
   - Clarifications added: [Count]
   - Sections updated: [List]
   - Next steps:
     ```
     ✅ Epic Clarifications Complete!
     
     Clarified: [X] questions
     
     Next Steps:
     - If UX-heavy: /epic-journey (map user flows)
     - If complex architecture: /epic-architecture (design technical approach with research)
     - Default: /epic-plan (create technical spec with research as needed)
     
     Note: Subsequent commands will perform just-in-time research for any knowledge gaps.
     ```

Error conditions:
- No epic.md → Instruct to run /epic-specify
- Already has tech spec → Note that clarifications may affect design
