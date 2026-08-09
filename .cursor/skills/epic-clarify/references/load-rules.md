# epic-clarify / load-rules

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
