---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Given the implementation details provided as an argument, do this:

**Research Approach**: Uses just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`) for implementation patterns, code examples, and API usage

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: instruct user to `cd` into the story directory or run `/speck` to route
   - Define:
     - SPEC_PATH = `{STORY_DIR}/spec.md`
     - PLAN_PATH = `{STORY_DIR}/plan.md`

   Clarification gate (reduce rework):
   - Inspect SPEC_PATH for unresolved `[NEEDS CLARIFICATION: …]` markers or obvious ambiguities.
   - If unresolved markers remain and user did not explicitly override, PAUSE and instruct them to run `/story-clarify` first.

2. **Architecture Decision Gate** (From OpenSpec: Only create architecture/design docs when needed):

   Check if this story needs architecture documentation:
   
   **Create architecture/design artifacts if ANY of**:
   - [ ] Cross-cutting change (affects 2+ services/components/modules)
   - [ ] New architectural pattern being introduced  
   - [ ] New external dependency (API, library, service)
   - [ ] Significant data model (>3 entities or complex relationships)
   - [ ] Security-critical implementation
   - [ ] Performance-critical with specific targets
   - [ ] High technical ambiguity or multiple approach options
   
   **Skip architecture if ALL of**:
   - [x] Single-file implementation
   - [x] Follows existing patterns from codebase-scan
   - [x] Clear how to implement
   - [x] Standard operations (CRUD, form, component)
   
   If criteria met for architecture:
   - Create comprehensive plan.md with architecture section
   - Consider running `/story-outline` for research if ambiguity high
   
   If criteria NOT met:
   - Create minimal plan.md (just data-model, contracts, quickstart)
   - Skip detailed architecture discussion
   - Let design emerge during implementation
   
   Default to minimal unless evidence shows architecture needed!

3. **Determine planning mode** (enables new workflow while preserving backward compatibility):
   
   **Check for outline.md** at `{STORY_DIR}/outline.md`:
   - **IF outline.md EXISTS**: 
     * Mode: Post-research planning
     * Load outline.md for Technical Context
     * Skip to step 4 (constitution check) then proceed with Phase 0 consolidation
   - **IF outline.md MISSING**:
     * Mode: Full planning (current behavior)
     * Continue with step 3 (analyze spec and fill Technical Context)

3. **IF full planning mode** (outline.md missing - current behavior):
   - Read and analyze the feature specification to understand:
     * Feature requirements and user stories
     * Functional and non-functional requirements
     * Success criteria and acceptance criteria
     * Technical constraints or dependencies mentioned
   - Fill Technical Context by analyzing spec (as in plan-template.md step 2)
   - Detect project type from repository structure
   
   **Check for available context**:
  - **Codebase Scan**: Check STORY_DIR for `codebase-scan-*.md`
     * If present: Use existing tech stack, patterns, conventions in Technical Context

4. **ELSE (post-research mode)** - outline.md exists:
   - Load Technical Context from outline.md (already filled)
   - Note research areas that were flagged
   
   **Load available context artifacts**:
   - **Research Reports**: Check STORY_DIR for `research-report-*.md` files
     * Incorporate recommendations directly into plan.md (research is embedded)
  - **Codebase Scans**: Check STORY_DIR for `codebase-scan-*.md` files
     * Load ALL scan reports (auth, user, design-system, api, data, etc.)
     * Use for consistency in Phase 1 design (data-model, contracts, quickstart)
     * Reference existing patterns, naming conventions, file organization
     * Validate architecture choices against existing tech stack
     * Use existing component patterns when designing new features
     * **Brownfield Adaptation**: Prioritize refactoring existing code over creating new when scan shows overlapping functionality
   
   **IF no research reports found**:
   - Note: "No research reports found. /story-plan will proceed with just-in-time research (current behavior)"
   - This is fine - outline is optional
   
   **IF no codebase scans found**:
   - Note: "No codebase scans found. Planning will proceed without existing pattern references"
   - Still valid for greenfield projects or new domains

5. Read the project constitution at `specs/projects/[PROJECT_ID]/constitution.md` if it exists to understand constitutional requirements.

6. **Load Project Design Context** (CRITICAL for UI/UX stories):
   
   Determine PROJECT_ID from the story path (e.g., `specs/projects/001-myproject/epics/...`).
   
   **Check for and load design documents**:
   - `specs/projects/[PROJECT_ID]/ux-strategy.md` → UX principles, voice/tone, design vision
   - `specs/projects/[PROJECT_ID]/design-system.md` → Design tokens, components, patterns
   
   **IF ux-strategy.md exists**:
   - Extract UX principles for Constitution Check
   - Note voice/tone guidelines for Brand Voice Copy Bank
   - Apply accessibility standards from the document
   
   **IF design-system.md exists**:
   - Extract design tokens (colors, typography, spacing)
   - Note available components for Design System Component Registry
   - Use token values in any UI-related contract specifications
   
   **IF neither exists AND story has UI requirements**:
   - WARN: "No project design documents found. Consider running `/project-ux` and `/project-design-system` first for UI consistency."
   - Proceed but note in plan.md that design decisions may need alignment later

8. Just-In-Time Research (before executing plan template):
   
   **Reference**: Follow the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)
   
   Before making implementation decisions, identify knowledge gaps and conduct research:
   
   ### Research Areas for Story Planning
   
   **1. API Usage & Code Examples**:
   - Decision: How do we use [library/API] for [feature]?
   - Web Search: API documentation, code examples, SDK tutorials
   - Deep Research (rarely needed): Most APIs have good docs
   
   **2. Implementation Patterns**:
   - Decision: What's the best pattern for [functionality]?
   - Web Search: Framework patterns, best practices, code snippets
   - Deep Research (if needed): Complex pattern analysis
   
   **3. Edge Case Handling**:
   - Decision: How should we handle [edge case]?
   - Web Search: Error handling patterns, validation strategies
   - Deep Research (rarely needed): Most patterns are well-documented
   
   **4. Integration Approaches**:
   - Decision: How do we integrate with [service/component]?
   - Web Search: Integration guides, SDK documentation, examples
   - Deep Research (if needed): Complex integration scenarios
   
   **5. Testing Strategies** (tactical):
   - Decision: How do we test [specific functionality]?
   - Web Search: Test patterns for framework, mocking strategies
   - Deep Research (rarely needed): Most testing patterns are standard
   
   ### Execute Research
   
   For each area with knowledge gaps:
   1. **Quick web search** for code examples and patterns
   2. **Generate deep research prompt** if web search insufficient (rare at story level)
   3. **Document findings** - will be embedded in plan.md's research section
   
   If deep research needed (rare), PAUSE and instruct user:
   ```
   ⏸️ Deep Research Needed
   
   Topic: [Research Area]
   Prompt Generated: story-plan-research-prompt-[topic].md
   
   Please:
   1. Review research prompt in story directory
   2. Run in Perplexity/Claude/Gemini/Grok
   3. Save results as: story-plan-research-report-[topic].md
   4. Re-run this command to continue
   ```

9. Execute the implementation plan template:
   - Load `.speck/templates/story/plan-template.md`
   - Write output to PLAN_PATH
   - Run the Execution Flow (main) function steps 1-9
   - The template is self-contained and executable
   - Follow error handling and gate checks as specified
   - Let the template guide artifact generation in STORY_DIR:
     * Phase 1 generates data-model.md, contracts/, quickstart.md
       - Use codebase-scan-*.md for existing patterns (naming, file organization, conventions)
       - Reference existing entities/models from scans to avoid conflicts
       - Follow existing API patterns from codebase-scan-api.md (if exists)
       - Use existing component patterns from codebase-scan-design-system.md (if exists)
     * Phase 1.5 generates Implementation Guidance section in plan.md:
       - Extract ALL FRs from spec.md with IDs, summaries, acceptance criteria
       - **Embed research findings from just-in-time research** (code examples, patterns)
       - Catalog codebase patterns to reuse with file:line references (from codebase-scan-*.md)
       - List performance targets with optimization techniques
       - Document security requirements with implementation checklists
       - Specify design system components to use (from codebase-scan-design-system.md)
       - Include brand voice copy examples
       - Map constitution gates to specific implementation requirements
       - Add "Research Informing This Plan" section with web search findings and sources
     * Phase 2 describes task approach (tasks.md generation deferred to /story-tasks command)
   - Incorporate user-provided details from arguments into Technical Context: $ARGUMENTS
   - Update Progress Tracking as you complete each phase
   
   **Note**: Research is embedded directly in plan.md (follow the just-in-time research pattern).

10. Verify execution completed:
   - Check Progress Tracking shows all phases complete
   - Ensure all required artifacts were generated
   - Confirm no ERROR states in execution

11. Report results with branch name, file paths, and generated artifacts:
   ```
   ✅ Story Technical Plan Complete!
   
   Story: [Name]
   Path: {STORY_DIR}
   
   Generated Artifacts:
   - plan.md (implementation guidance with embedded research)
   - data-model.md (entities and relationships)
   - contracts/ (API specifications)
   - quickstart.md (test scenarios)
   
   Research Integration:
   - Web searches conducted: [X topics]
   - Code examples found: [Y]
   - Research embedded in plan.md
   
   Next Steps:
   1. Review technical design with team
   2. Required: /story-tasks (generate implementation tasks)
   3. Optional: /story-analyze (quality check before implementation)
   4. Then: /story-implement (execute the tasks)
   
   Note: /story-tasks will use these artifacts to generate concrete,
   numbered tasks that /story-implement can execute.
   ```

Use absolute paths with the repository root for all file operations to avoid path issues.
