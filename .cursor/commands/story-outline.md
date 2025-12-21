---
description: Analyze story specification and identify technical decisions that need research, preparing for planning phase.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: ask the user to `cd` into the story directory or run `/speck` to route

2. Load and analyze the story specification:
   - Read `{STORY_DIR}/spec.md` to understand requirements, user stories, constraints
   - Extract: Technologies mentioned, patterns implied, performance requirements, integrations needed

3. Detect project type from repository structure:
   - Check for: frontend/, backend/, src/, app/, api/, ios/, android/, packages/
   - Determine: Single project / Web app / Mobile app / Monorepo
   - Set project type for planning decisions

4. Fill Technical Context by analyzing spec:
   - **Language/Version**: Detect from spec or mark NEEDS CLARIFICATION
   - **Primary Dependencies**: Extract frameworks/libraries mentioned or mark NEEDS CLARIFICATION
   - **Storage**: Identify database/storage needs or mark N/A
   - **Testing**: Determine test frameworks needed or mark NEEDS CLARIFICATION
   - **Target Platform**: Server/mobile/desktop/web or mark NEEDS CLARIFICATION
   - **Performance Goals**: Extract from non-functional requirements or mark NEEDS CLARIFICATION
   - **Constraints**: Identify technical constraints or mark NEEDS CLARIFICATION
   - **Scale/Scope**: Estimate from requirements or mark NEEDS CLARIFICATION

5. Identify research areas:
   - For each NEEDS CLARIFICATION: Determine if external research needed
   - For each unfamiliar technology/pattern: Flag for research
   - For each architectural decision: Identify tradeoffs to research
   - Generate research questions:
     * "What are best practices for [technology] in [context]?"
     * "How to choose between [option A] and [option B] for [use case]?"
     * "What are performance implications of [approach]?"

6. Save Technical Context and research needs to `{STORY_DIR}/outline.md`:
   ```markdown
   # Technical Outline: [STORY]
   
   **Date**: [YYYY-MM-DD]
   **Spec**: `spec.md`
   
   ## Project Type
   [Detected project type and structure]
   
   ## Technical Context
   [Filled technical context with NEEDS CLARIFICATION markers]
   
   ## Research Areas Identified
   
   ### High Priority (blocking decisions)
   1. **[Technology/Pattern]**: [Why research needed]
      - Question: [Specific research question]
      - Blocking: [What planning decision this blocks]
   
   ### Medium Priority (optimization decisions)
   [...]
   
   ### Low Priority (nice to have)
   [...]
   
   ## Suggested Research Queries
   - "[Generated research query 1]"
   - "[Generated research query 2]"
   
   Use the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`):
   - Do quick web search for each high-priority query
   - If web search is insufficient, generate a deep research prompt file and incorporate results
   
   ## Codebase Analysis Needed
   [Yes/No - if extending existing codebase]
   - Suggested: /story-scan --domain=[detected domain]
   
   ## Next Steps
   1. Use the suggested research queries (web search first; deep research prompt only if needed)
   2. Run /story-scan if extending existing codebase
   3. Run /story-plan to generate implementation plan (and embed/incorporate research)
   
   Or skip directly to /story-plan to use built-in just-in-time research (current behavior)
   ```

7. Report completion:
   - Path to outline.md
   - Number of research areas identified (high/medium/low priority)
   - Suggested next commands with specific research queries
   - Note: "Run /story-plan directly to skip outline phase (uses built-in research)"

Behavior rules:
- Mark things as NEEDS CLARIFICATION only if truly ambiguous from spec
- Don't guess at technology choices - flag for research if unclear
- Prioritize research areas by impact on architectural decisions
- Generate specific, actionable research queries
- If project structure unclear, mark for investigation but don't block

Context: $ARGUMENTS
