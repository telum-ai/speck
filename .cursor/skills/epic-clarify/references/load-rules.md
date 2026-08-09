# epic-clarify — load-rules

epic.md in current directory or parent epic directory
   - Load parent project's PRD.md and epics.md
   - Load epic-codebase-scan.md if exists (brownfield code analysis)
   - Understand epic's role in larger project
   - If no epic.md: ERROR "No epic specification found. Run /epic-specify first"
   
   **Brownfield Adaptation**: If epic-codebase-scan.md exists, focus
