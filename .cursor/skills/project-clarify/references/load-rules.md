# project-clarify / load-rules

Goal: Detect and reduce ambiguity through targeted Q&A, identify areas requiring deeper research, and prepare the project for comprehensive planning.

Note: This clarification workflow is expected to run (and be completed) BEFORE invoking `/project-plan`. If the user explicitly states they are skipping clarification (e.g., proof of concept), you may proceed, but must warn that downstream rework risk increases.

Execution steps:

1. Determine active project directory:
   - Check current working directory for project.md
   - If not found, scan specs/projects/ for most recent project
   - Parse PROJECT_DIR and PROJECT_SPEC paths
   - If no project found: ERROR "No active project found. Run /project-specify first"

1. **Scope - Should the v1 include mobile apps or web-only?**
   Context: This significantly impacts timeline and resource needs.
   Options:
   a) Web-only for v1, mobile in v2
   b) Mobile-first, web later
   c) Both platforms from start
   (This will clarify the Project Type & Scale section)

User: Let's go with option a - web first, mobile later

AI: Understood. Web-only for v1 with mobile planned for v2.

[Continues through all questions...]

AI:  Project Clarification Complete!

- Clarifications Added: 5
- Sections Updated: Project Type, Scope, Technical Constraints

Research Needed: 3 areas identified
1. **Market Analysis** (Critical)
   - Query: "AI code review tool competitive landscape 2024"
   - Why: Need competitive positioning before defining features

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

2. **Technical Feasibility** (Important)
   - Query: "LLM fine-tuning costs and performance at scale"
   - Why: Architecture decisions depend on cost constraints
