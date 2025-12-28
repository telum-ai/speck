---
description: Create story mapping showing all stories within the epic, their dependencies, and parallelization opportunities.
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

5. Create story directories with parallel spec drafting:

   **Subagent Parallelization** - Spawn speck-scribe for each story spec:
   ```
   ├── [Parallel] speck-scribe: Draft S001 spec.md from epic-tech-spec.md
   ├── [Parallel] speck-scribe: Draft S002 spec.md from epic-tech-spec.md
   ├── [Parallel] speck-scribe: Draft S003 spec.md from epic-tech-spec.md
   └── [Wait] → Create all story directories with drafted specs
   ```
   
   Each speck-scribe receives:
   - Story requirements from epic-breakdown.md
   - Technical context from epic-tech-spec.md
   - Template from .speck/templates/story/story-template.md
   
   **Speedup**: Nx (where N = number of stories)

   Create story directories:
   ```
   [EPIC_DIR]/
   └── stories/
       ├── S001-technical-setup/
       ├── S004-story-name/
       └── .../
   ```

6. Execution examples:
   ```
   ## Parallel Execution Example
   
   # Terminal 1:
   cd stories/S002-database-setup
   /story-specify
   /story-plan
   /story-tasks
   /story-analyze
   /story-implement
   
   # Terminal 2:
   cd stories/S003-api-scaffolding
   /story-specify
   /story-plan
   /story-tasks
   /story-analyze
   /story-implement
   ```

7. Save as `[EPIC_DIR]/epic-breakdown.md`

8. Output summary:
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
   
   Next Steps:
   1. Review task breakdown with team
   2. Begin Phase 1:
      cd stories/S001-*
      /story-specify
   3. Or run /epic-analyze for validation
   ```

Note: This breakdown organizes stories for planning and coordination. Each story will generate its own concrete implementation tasks via /story-tasks.
