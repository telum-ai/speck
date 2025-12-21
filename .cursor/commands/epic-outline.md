---
description: Analyze epic specification to identify technical decisions and research needs before creating tech spec.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

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
   ```
   # Epic Technical Outline: [Epic Name]
   
   ## Summary
   [2-3 sentences on epic technical scope]
   
   ## Key Technical Decisions
   
   ### Architecture
   1. **[Decision Name]**
      - Current thinking: [Initial approach]
      - Options: [List 2-3]
      - Research needed: [What would help decide]
      - Priority: Critical/Important/Nice-to-have
   
   ### Technology Stack
   [Similar structure]
   
   ### Implementation Patterns
   [Similar structure]
   
   ## Research Priorities
   
   ### Priority 1: Critical (Blocks design)
   1. **[Area]**: [Specific questions]
      - Why critical: [Impact]
      - Approach: [How to research]
   
   ### Priority 2: Important
   [Similar structure]
   
   ## Integration Analysis
   
   ### Dependencies
   - [Epic/System]: [What we need to know]
   
   ### Provided Interfaces
   - [What we expose]: [Design considerations]
   
   ## Risk Areas
   
   ### Technical Risks
   1. **[Risk]**: [Mitigation research needed]
   
   ## Recommended Research Queries
   1. "[Specific research query]"
   2. "[Specific research query]"
   ```

5. Save as `[EPIC_DIR]/epic-outline.md`

6. Output summary:
   ```
   ✅ Epic Technical Outline Complete!
   
   Key Decisions Identified: [X]
   Research Areas: [Y] critical, [Z] important
   
   Next Steps:
   1. Use the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)
      to address the outline’s highest-priority questions (web search first; generate a deep
      research prompt only if needed)
   2. Then: /epic-plan
   ```
