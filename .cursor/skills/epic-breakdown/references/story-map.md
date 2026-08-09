# epic-breakdown / story-map

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).



## Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/epic/breakdown-template.md
```
The template defines required sections and formatting for `epic-breakdown.md`, including story table format, dependency mapping, parallel markers, and phase grouping. Without reading it, generated breakdowns have wrong structure. Also note: placeholder `spec.md` files created here must use lifecycle state `Draft (Placeholder)` — the template documents this.

**Checkpoint**: After reading, note the story table format and dependency notation. Then continue to Step 1.

Create a comprehensive story breakdown that maps all user stories within the epic, showing dependencies, parallelization opportunities, and suggested implementation order. This is NOT about concrete development tasks - it's about story organization and sequencing.

1. Load epic implementation context:
   - Epic specification (epic.md)
   - Technical specification (epic-tech-spec.md) - required (includes embedded research)
   - Epic codebase scan (epic-codebase-scan.md) - if exists, for brownfield code analysis
   - Project constraints from PRD
   - If tech spec missing: ERROR "Run /epic-plan first"
   
   **Load Constitution Chain (if present)**:
   - `[EPIC_DIR]/constitution.md` — epic-level principles governing story boundaries, interfaces,
     and quality standards. Use when deciding how to slice stories (e.g., data ownership rules
     might force a story boundary; API versioning rules might require a dedicated contract story).
   - `specs/projects/[PROJECT_ID]/constitution.md` — project-level principles to honour across all stories.
   
   **Brownfield Adaptation**: If epic-codebase-scan.md exists, use it to identify existing code that needs refactoring or enhancement as part of story breakdown.
   
   **Note**: Research is now embedded in epic-tech-spec.md - no separate research.md file to load.

2. Story extraction and analysis:
   - Extract all user stories from epic.md
   - Map to technical implementation from tech spec
   - Identify story dependencies
   - Determine parallelization opportunities

3. Story breakdown approach:

   **User Stories**
   - Extract all user stories from epic.md
   - Map to technical approach from tech spec
   - Include acceptance criteria
   - Identify dependencies between stories

   **Technical Stories**
   - Infrastructure setup stories
   - Integration stories
   - Migration stories
