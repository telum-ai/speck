---
name: epic-breakdown
description: Load after epic-tech-spec.md exists to create the story map, dependencies, and implementation order (epic-breakdown.md). Required before starting any individual story in the epic. Use when user says 'break this into stories' or 'what stories do we need?'.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

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
   - Configuration stories

   **Quality Stories**
   - Testing stories
   - Documentation stories
   - Performance validation stories
   - Security review stories

4. Generate epic breakdown:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/breakdown-template.md
   ```

   Write output to: `[EPIC_DIR]/epic-breakdown.md`

5. Create story directories with placeholder specs:

   **Subagent Parallelization** - Spawn speck-scribe for each story spec:
   ```
   ├── [Parallel] speck-scribe: Draft S001 spec.md (Draft state) from epic-tech-spec.md
   ├── [Parallel] speck-scribe: Draft S002 spec.md (Draft state) from epic-tech-spec.md
   ├── [Parallel] speck-scribe: Draft S003 spec.md (Draft state) from epic-tech-spec.md
   └── [Wait] → Create all story directories with drafted specs
   ```

   Each speck-scribe receives:
   - Story requirements from epic-breakdown.md
   - Technical context from epic-tech-spec.md
   - Template from .speck/templates/story/story-template.md
   - **Dependencies from epic-breakdown.md** (for YAML frontmatter)

   **Speedup**: Nx (where N = number of stories)

   **IMPORTANT**: Placeholder specs are saved as `spec.md` with lifecycle state `Draft (Placeholder)`.
   The **lifecycle state** — not the filename — is what signals that `/story-specify` still needs to run.
   This eliminates the `spec-draft.md` vs `spec.md` confusion: there is always exactly one file.

   **CRITICAL — Lifecycle state for placeholder spec.md files**:
   Set `**Current State**: Draft (Placeholder)` and mark lifecycle checkboxes as:
   ```
   - [x] **Draft** - Placeholder spec.md created by `/epic-breakdown` (not yet specified)
   - [ ] **Specified** - spec.md enhanced by `/story-specify`
   ```
   **NEVER set `**Current State**: Specified` in a placeholder** — that falsely signals
   that `/story-specify` has already been run and can be skipped.

   **CRITICAL**: Include dependencies in YAML frontmatter:
   ```yaml
   ---
   depends_on: [S004]  # From "Depends on" in epic-breakdown.md
   blocks: [S006]      # From Inter-Story Dependencies table
   ---
   ```

   The orchestrator reads `depends_on` from `spec.md` to determine which stories are blocked.

   Create story directories:
   ```
   [EPIC_DIR]/
   └── stories/
       ├── S001-technical-setup/
       │   └── spec.md (lifecycle: Draft, depends_on: [] in frontmatter)
       ├── S005-story-name/
       │   └── spec.md (lifecycle: Draft, depends_on: [S004] in frontmatter)
       └── .../
   ```

6. Save as `[EPIC_DIR]/epic-breakdown.md`

7. Output summary:
   ```
   ✅ Epic Story Breakdown Complete!
   
   Epic: [Name]
   Total Stories: [X]
   
   Phase Breakdown:
   - Phase 1: [Y] stories (setup)
   - Phase 2: [Z] stories (core)
   - Phase 3: [A] stories (integration)  
   - Phase 4: [B] stories (quality)
   
   Parallel Opportunities: [Count]
   Critical Path Length: [Duration]
   
   Story Directories Created: [Count]
   Placeholder specs created: [Count] (spec.md with lifecycle: Draft — awaiting /story-specify)

   Next Steps:
   1. Review story breakdown with team
   2. Run /story-specify on Phase 1 stories to complete the draft specs
   3. Stories marked [P] can be specified/implemented in parallel
   4. Or run /epic-analyze for validation first

   Note: Placeholder specs have lifecycle state "Draft (Placeholder)" in their spec.md.
   /story-specify reads this state and fills in the full specification in-place.
   ```

Note: This breakdown organizes stories for planning and coordination. Each story will generate its own concrete implementation tasks via /story-tasks. Placeholder specs provide a starting point but require /story-specify to reach "Specified" state before planning or implementation.
