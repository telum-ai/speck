---
description: Create technical specification for epic implementation based on epic spec, research, and code analysis.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Generate a comprehensive technical specification that bridges epic requirements to implementable stories.

**Research Approach**: Uses just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`) for implementation patterns, integration strategies, and technical approaches

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
   - Epic architecture (epic-architecture.md) if exists
   - Check for existing research reports: epic-*-research-report-*.md (from earlier commands)
   - Codebase scans (epic-codebase-scan*.md)
   - Related epic tech specs for consistency
   - If epic.md missing: ERROR "Run /epic-specify first"

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
   - Apply scan recommendations from epic-codebase-scan.md
   
   **Direct Mode** (no epic-architecture.md):
   - Analyze epic.md for technical needs
   - Make architectural decisions inline
   - Perform just-in-time research for gaps

4. Just-In-Time Research (before tech spec generation):
   
   **Reference**: Follow the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)
   
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
   
   Generated Artifact:
   - epic-tech-spec.md (technical blueprint with embedded research)
   
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
   3. Optional: /epic-constitution (if complex governance needed)
   4. Validation: /epic-analyze then /epic-validate
   5. Then: Start story development with /story-specify
   ```

Note: This tech spec becomes the blueprint for all story implementation within the epic.
