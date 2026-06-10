---
name: epic-plan
description: Load after epic.md exists (and optional architecture/journey/wireframes) to produce epic-tech-spec.md with the full technical design. Required before epic-breakdown. Use when user says 'plan this epic' or 'write the tech spec'. FIRST ACTION after loading: read template at .speck/templates/epic/epic-tech-spec-template.md before any context loading or artifact generation.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/epic/epic-tech-spec-template.md
```
The template defines required sections and formatting for `epic-tech-spec.md`. Reading it first tells you what the research, architecture analysis, and design phases need to produce, and what the story breakdown will consume. Generating `epic-tech-spec.md` from memory without reading this template produces structurally incorrect output.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to Step 1.

Generate a comprehensive technical specification that bridges epic requirements to implementable stories.

**Research Approach**: Uses just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`) for implementation patterns, integration strategies, and technical approaches

## Subagent Parallelization

This command benefits from parallel execution:

**Research Phase** - Spawn parallel speck-researcher:
```
├── [Parallel] speck-researcher: "Implementation patterns for [feature]"
├── [Parallel] speck-researcher: "Library comparison for [purpose]"
├── [Parallel] speck-researcher: "Integration strategy for [service]"
├── [Parallel] speck-researcher: "Testing approaches for [functionality]"
└── [Wait] → Embed findings in tech spec
```

**Speedup**: 3-4x compared to sequential research.

1. Load epic planning context:
   - Epic specification (epic.md) - required
   - Project PRD and technical constraints
   - **`product-contract.md`** (if it exists) — the sections routed to this epic (§1 paid promise, §3 differentiator pillars, §3a anti-differentiators, §4 JTBD/invariants, §5 magic moments, §10 trust moments). REQUIRED input for the traceability matrix (step 6b). *(This was previously NOT loaded — a real promise-coverage gap.)*
   - **`experience-chain.md`** (if it exists, UI epics) — every seam rule (§2–§9 tables). Each seam is a promise. *(Also previously NOT loaded.)*
   - **`wireframes.md`** / `user-journey.md` (if they exist) — the screen inventory and every per-screen element/state.
   - Epic architecture (epic-architecture.md) if exists
   - Check for existing research reports: epic-*-research-report-*.md (from earlier commands)
   - Codebase scans (epic-codebase-scan*.md)
   - Related epic tech specs for consistency
   - If epic.md missing: ERROR "Run /epic-specify first"

   **Load Epic Constitution (if present)**:
   - `[EPIC_DIR]/constitution.md` (from `/epic-constitution`) — if present:
     * Extract all MUST/SHOULD principles, boundary rules, and measurable standards
     * These are non-negotiable constraints on the tech spec — every architectural decision,
       API contract, data handling pattern, and testing requirement must comply
     * Note any deviations in the tech spec as "Deviation from constitution: [reason]"
   - `specs/projects/[PROJECT_ID]/constitution.md` (project-level) — if present:
     * Epic constitution extends (never contradicts) the project constitution
     * Load both and treat combined rule set as the authority
   - If no constitution exists at either level: proceed, architecture is unconstrained by explicit rules

   **Load UX Design Artifacts (CRITICAL if UI epic)**:
   - `[EPIC_DIR]/user-journey.md` → User journey map (from `/epic-journey`)
     * If present: Extract stage names, touchpoints, pain points, emotional targets, and
       opportunity areas. These directly shape story boundaries, UX quality requirements,
       and the E2E section of the testing strategy.
     * If absent on a UI epic: WARN "No user journey found. Consider running `/epic-journey`
       before planning — the tech spec will lack UX-grounded story structure."
   - `[EPIC_DIR]/wireframes.md` → Screen-by-screen wireframes (from `/epic-wireframes`)
     * If present: Extract screen inventory, layout decisions, interaction patterns, and
       responsive requirements. Map each screen to the story that implements it.
     * If absent on a UI epic: WARN "No wireframes found. Consider running `/epic-wireframes`
       before planning — otherwise story UI boundaries will be guessed during implementation."
   - `specs/projects/[PROJECT_ID]/ux-strategy.md` → UX principles and accessibility standards
   - `specs/projects/[PROJECT_ID]/design-system.md` → Design tokens and component patterns
   
   **Incorporate UX artifacts into the tech spec** (not just load them — USE them):
   - Surface journey stages as story groupings (e.g., "Onboarding flow → S001–S003")
   - Surface wireframe screen inventory as the UI story list in "Stories & Breakdown Guidance"
   - Surface pain points and emotional targets as UX quality requirements
   - Add a "UX Design Context" section to the generated epic-tech-spec.md

2. **Architecture Decision Gate** (From OpenSpec: Only create detailed architecture when needed):

   Evaluate if this epic needs comprehensive architectural planning:
   
   **Create detailed architecture (run /epic-architecture separately) if ANY of**:
   - [ ] Cross-cutting epic (affects multiple services/domains)
   - [ ] New architectural pattern for the project
   - [ ] New external dependencies (APIs, services, libraries)
   - [ ] Complex data model (>5 entities, complex relationships)
   - [ ] Security-critical features (auth, payments, PII handling)
   - [ ] Performance-critical with strict SLAs
   - [ ] High ambiguity requiring technical decisions upfront
   
   **Skip separate architecture (embed in tech-spec) if ALL of**:
   - [x] Epic follows established project patterns
   - [x] Limited to single domain/service
   - [x] Standard data operations
   - [x] Clear implementation approach
   - [x] Low technical risk
   
   **Note**: If `/epic-architecture` was already run, load epic-architecture.md.
   If not run and criteria met, suggest user run it before continuing with `/epic-plan`.
   
   Default to embedded architecture unless complexity requires separate deep dive!

3. Planning mode determination:
   
   **Architecture-Informed Mode** (epic-architecture.md exists):
   - Use architecture decisions from epic-architecture.md
   - Incorporate any research referenced in architecture
   - Apply scan recommendations from epic-codebase-scan*.md
   
   **Direct Mode** (no epic-architecture.md):
   - Analyze epic.md for technical needs
   - Make architectural decisions inline
   - Perform just-in-time research for gaps

4. Just-In-Time Research (before tech spec generation):
   
   **Reference**: Follow the just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`)
   
   Before making implementation decisions, identify knowledge gaps and conduct research:
   
   ### Research Areas for Epic Tech Spec
   
   **1. Implementation Patterns**:
   - Decision: What patterns should we use for [feature]?
   - Web Search: Code examples, best practices, framework patterns
   - Deep Research (if needed): Complex implementation strategies
   
   **2. Technology Libraries**:
   - Decision: Should we use [library] for [purpose]?
   - Web Search: Library comparisons, compatibility, performance benchmarks
   - Deep Research (if needed): Library evaluation, proof-of-concept
   
   **3. Integration Strategies**:
   - Decision: How do we integrate with [system/service]?
   - Web Search: Integration patterns, API documentation, SDKs
   - Deep Research (if needed): Complex integration scenarios
   
   **4. Testing Approaches**:
   - Decision: How should we test [functionality]?
   - Web Search: Testing patterns, framework test utilities, best practices
   - Deep Research (rarely needed): Most testing patterns are well-documented
   
   **5. Performance Optimization**:
   - Decision: How do we achieve [performance target]?
   - Web Search: Optimization techniques, benchmarks, profiling strategies
   - Deep Research (if needed): Complex performance analysis
   
   ### Execute Research
   
   For each area with knowledge gaps:
   1. **Quick web search** for patterns and examples
   2. **Generate deep research prompt** if web search insufficient
   3. **Document findings** in "Research Informing This Specification" section of output
   
   If deep research needed, PAUSE and instruct user:
   ```
   ⏸️ Deep Research Needed
   
   Topic: [Research Area]
   Prompt Generated: epic-plan-research-prompt-[topic].md
   
   Please:
   1. Review research prompt in epic directory
   2. Run in Perplexity/Claude/Gemini/Grok
   3. Save results as: epic-plan-research-report-[topic].md
   4. Re-run this command to continue
   ```

5. Generate epic technical specification:
   - Load template: `.speck/templates/epic/epic-tech-spec-template.md`
   - Fill it systematically using:
     * epic.md (requirements + story intent)
     * project PRD.md + project.md (goals/constraints)
     * epic-architecture.md (if it exists)
     * epic-codebase-scan*.md (if it exists)
     * epic-plan-research-report-*.md (if any)
   - Embed research in "Research Informing This Specification" with sources/links
   - Keep this file a durable blueprint for `/epic-breakdown`
   - Save to: `[EPIC_DIR]/epic-tech-spec.md`

6. Save artifacts:
   - Location: `[EPIC_DIR]/epic-tech-spec.md` (technical blueprint with research embedded)
   - Update epic.md status to "Technical Specification Complete"

6b. **Produce the Promise Traceability Matrix (conservation law — REQUIRED)**:
   - Read the template FIRST: `.speck/templates/epic/traceability-matrix-template.md`.
   - Enumerate **every** promise from the sources loaded in step 1 and give each a `PRM-NNN` id:
     * `product-contract.md` sections routed to this epic (§1/§3/§3a/§4/§5/§10)
     * every `FR-[EPIC]-###` and `NFR-###` in `epic.md`
     * every wireframe screen (screen-inventory) AND every element/state drawn per screen (Default/Loading/Empty/Error/Success)
     * every `experience-chain.md` seam rule (§2–§9)
     * If a source is absent (e.g. backend-only epic, no wireframes), write "N/A — no UI surface" — state absence, never assume it.
   - Write `[EPIC_DIR]/traceability-matrix.md` with all rows at **status=open** (the Discharge and DEC columns are filled later by `/epic-breakdown` + `/story-specify`, then verified at `/story-validate`).
   - This is the ledger `/epic-analyze` blocks on and `/epic-validate` re-walks. A drawn wireframe element or stated seam with no row is a silently-evaporated promise.

7. Validation checks:
   - All stories have technical approach
   - Architecture supports requirements
   - Performance targets achievable
   - Security properly addressed
   - Research findings properly incorporated

8. Output summary:
   ```
   ✅ Epic Technical Specification Complete!
   
   Epic: [Name]
   Architecture: [Pattern]
   
   Generated Artifacts:
   - epic-tech-spec.md (technical blueprint with embedded research)
   - traceability-matrix.md (promise conservation ledger — all PRM rows at status=open)
   
   Research Integration:
   - Web searches conducted: [X topics]
   - Deep research reports: [Y reports] (if any)
   - Research directly embedded in specification
   
   Technology Decisions:
   - [Key decision 1]
   - [Key decision 2]
   
   Story Breakdown:
   - Total stories: [X]
   - Technical stories: [Y]
   - Phases: [Z]
   
   New Dependencies: [Count]
   Reused Components: [Count]
   
   Estimated Duration: [Timeframe]
   
   Next Steps:
   1. Review tech spec with team
   2. Required: /epic-breakdown (generate story mapping and dependencies)
   3. Required: /epic-analyze (pre-implementation quality gate on spec + breakdown — run before ANY story work)
   4. Then: Start story development with /story-specify for each story in the breakdown
   
   ⚠️  /epic-constitution must be run BEFORE /epic-plan (not after) — the tech spec
       must be written knowing the rules. If you realise you need a constitution now,
       run /epic-constitution, then re-run /epic-plan so the spec incorporates the rules.
   
   ⚠️  /epic-validate is NOT a planning step. Run it only AFTER all stories
       are implemented and every story's validation-report.md shows PASS.
   ```

Note: This tech spec becomes the blueprint for all story implementation within the epic.
