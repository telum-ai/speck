# project-clarify — load-rules

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
