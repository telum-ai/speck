---
name: epic-outline
description: DEPRECATED in Speck v7. Use /speck-skeptical-review + /speck-decision-log instead — they replace the outline pattern with structured tradeoff enumeration and lockable decisions. The v6 epic-outline pattern (research mapping) is now embedded in /epic-plan's just-in-time research step. This skill remains for v6 compatibility but redirects new invocations to the v7 equivalents.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ v7 Deprecation Notice

This skill is **deprecated in Speck v7**. The v6 epic-outline was a separate research-mapping step; in v7 that work is folded into:

- `/speck-skeptical-review` — for enumerating alternatives at the epic's technical approach
- `/speck-decision-log` — for locking the chosen approach with rationale and SHA stamp
- `/epic-plan` — performs just-in-time research as needed (per the v7 just-in-time research pattern)

**Recommended v7 path**: `/epic-clarify` → `/speck-skeptical-review` (if approach unclear) → `/epic-plan`

This skill continues to work for v6 projects (back-compat). For new v7 work, prefer the path above.

---

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
