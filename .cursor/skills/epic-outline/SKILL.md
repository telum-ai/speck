---
name: epic-outline
description: Load before epic-plan when the epic involves unfamiliar technology, complex integrations, or has significant unknowns that need research. Optional — skip when the implementation path is clear and existing project patterns already apply. FIRST ACTION after loading: read template at .speck/templates/epic/outline-template.md before any context loading or artifact generation.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/epic/outline-template.md
```
The template defines required sections and formatting for `epic-outline.md`. Reading it first tells you what research gaps and decision points to document.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to Step 1.

Create a technical outline that identifies key architectural decisions and research areas needed for epic implementation.

1. Load epic context:
   - Find epic.md in current or parent directory
   - Load project PRD.md for technical constraints
   - Check for existing epic-outline.md
   - Review other epics for integration patterns
   - If no epic.md: ERROR "Run /epic-specify first"

2. Technical decision categories:

   **Architecture Decisions**
   - Component structure approach
   - State management strategy
   - API design patterns
   - Data flow architecture
   
   **Technology Choices**
   - Libraries/frameworks needed
   - Build vs buy decisions
   - Integration approaches
   - Testing strategies
   
   **Implementation Patterns**
   - Error handling approach
   - Logging/monitoring strategy
   - Security implementation
   - Performance optimizations

3. Research need identification:
   - Technology evaluation needs
   - Best practice research
   - Integration documentation
   - Performance benchmarks needed

4. Generate epic outline:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/outline-template.md
   ```

   Write output to: `[EPIC_DIR]/epic-outline.md`

5. Save as `[EPIC_DIR]/epic-outline.md`

6. Output summary:
   ```
   ✅ Epic Technical Outline Complete!
   
   Key Decisions Identified: [X]
   Research Areas: [Y] critical, [Z] important
   
   Next Steps:
   1. Use the just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`)
      to address the outline’s highest-priority questions (web search first; generate a deep
      research prompt only if needed)
   2. Then: /epic-plan
   ```
