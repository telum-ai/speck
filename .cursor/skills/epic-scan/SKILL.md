---
name: epic-scan
description: Scan existing codebase for patterns and implementations relevant to THIS epic's domain
disable-model-invocation: false
---

---
description: Scan existing codebase for patterns and implementations relevant to THIS epic's domain.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Analyze codebase for existing patterns, similar implementations, and reusable components **specifically relevant to this epic's scope**.

**Time**: 15-20 minutes (focused domain analysis)  
**Confidence**: MEDIUM - validated by presence, not deep code reading  
**Purpose**: Find what's relevant to YOUR epic  
**Output**: Epic-specific scan with reusable patterns

## Subagent Parallelization

This command benefits from parallel speck-scanner execution for domain analysis:

```
├── [Parallel] speck-scanner: "Analyze API patterns relevant to this epic in src/"
├── [Parallel] speck-scanner: "Analyze data models relevant to this epic in src/models/"
├── [Parallel] speck-scanner: "Analyze auth patterns relevant to this epic in src/"
├── [Parallel] speck-scanner: "Analyze integration patterns relevant to this epic in src/"
└── [Wait] → Synthesize into epic-codebase-scan.md

Focus each scanner on domains relevant to THIS epic.
```

**Speedup**: 3-4x compared to sequential scanning.

## When to Use

- **After `/epic-specify` or `/epic-clarify`** - Understand existing patterns before planning
- **After `/project-scan`** - Validate and deepen project-level findings for this epic area
- **Before `/epic-plan`** - Find patterns to incorporate into technical design
- **When unsure about existing implementations** - "Have we built something similar?"

**Not for**: Project-wide analysis (use `/project-scan`) or story-specific deep dives (use `/story-scan`)

---

## Scan Process

1. **Load epic context**:
   - Find and load `epic.md` to understand epic scope
   - **Extract key domains**: What is this epic about? (auth, payments, admin, etc.)
   - Load project-level landscape overview if exists
   - Parse optional `--domain=X` argument for sub-focus

2. **Determine relevance filter**:
   - Based on epic scope, identify what's relevant vs irrelevant
   - Example: If epic is "Authentication & Authorization"
     - **Relevant**: Auth middleware, login flows, session management, JWT patterns
     - **Irrelevant**: Product catalog, payment processing, reporting
   - Create search terms for this epic's domain

3. **Epic-focused scan** (MEDIUM depth - read file names and shallow code):

   **A. Find Similar Features** (relevant to THIS epic):
   ```bash
   # Search for similar functionality in this domain
   find [CODEBASE] -type f -name "*[domain-keyword]*"
   
   # Example for auth epic:
   find [CODEBASE] -type f -name "*auth*" -o -name "*login*" -o -name "*session*"
   
   # Shallow grep for relevant patterns
   grep -r "class.*Auth\|def.*login\|authenticate" [CODEBASE] | head -20
   ```
   
   Extract:
   - Files that handle similar functionality
   - Patterns that could be extended
   - Components that could be reused
   - **Confidence**: MEDIUM - found by pattern matching, not deep reading
   
   **B. Find Integration Points** (that THIS epic touches):
   ```bash
   # APIs this epic will integrate with
   grep -r "import.*[domain]\|from.*[domain]" [CODEBASE]
   
   # Database models related to this domain
   find [CODEBASE] -path "*/models/*" -name "*[domain]*.py"
   ```
   
   Extract (only relevant to this epic):
   - APIs this epic will use (not all APIs)
   - Services to integrate with (only ones this epic touches)
   - Data models to extend (only related models)
   
   **C. Extract Relevant Code Patterns** (shallow examples):
   ```bash
   # Find 2-3 good examples
   # Read just enough to understand the pattern (10-20 lines each)
   ```
   
   Extract (domain-specific only):
   - Error handling in this domain
   - Testing approaches for similar features
   - State management patterns (if applicable)
   - Security patterns (if applicable)

4. **Filter out irrelevant findings**:
   - For each finding, ask: "Does this relate to MY epic's domain?"
   - If NO → Skip it (mention skipped count in report)
   - If MAYBE → Note as "potentially relevant"
   - If YES → Include in report

5. **Generate focused epic scan report**:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/epic-codebase-scan-template.md
   ```

   The template is self-documenting - follow all sections and constraints within it (this command should not re-state the template headings inline).

6. **Save scan results**:
   - Full report: `[EPIC_DIR]/epic-codebase-scan.md`
   - Domain-specific: `[EPIC_DIR]/epic-codebase-scan-[domain].md`

7. **Output summary**:
   ```
   ✅ Epic Codebase Scan Complete!
   
   Epic: [Epic Name]
   Domain: [What this epic focuses on]
   Confidence: MEDIUM (Pattern matching + shallow code reading)
   
   Findings (Relevant to YOUR Epic):
   - Similar features: [X] found
   - Reusable components: [Y] identified
   - Integration points: [Z] relevant
   - Patterns extracted: [N]
   
   Filtering Applied:
   - Analyzed: [X] items in epic's domain
   - Skipped: [Y] items (not relevant to this epic)
   
   Key Insights:
   1. [Most important relevant finding]
   2. [Second relevant finding]
   
   Recommendations for YOUR Epic:
   - Reuse [component] from [location]
   - Follow [pattern] from [location]
   - Avoid [anti-pattern] seen in [location]
   
   Full report: epic-codebase-scan.md
   
   Next: Run /epic-plan to incorporate findings into technical design
   ```

---

## Key Principles

1. **Relevance filtering**: Only show what matters to THIS epic
2. **Medium confidence**: Patterns found, not deeply analyzed
3. **Actionable**: Clear recommendations for epic planning
4. **Efficient**: 15-20 minutes, not hours
5. **Honest about limitations**: Clear about what wasn't analyzed

---

## Integration with Other Commands

**Requires**:
- `/epic-specify` or `/epic-clarify` - Need epic scope defined

**Optional context**:
- `/project-scan` - Can use landscape overview to guide search

**Feeds into**:
- `/epic-plan` - Incorporates patterns and recommendations
- `/epic-architecture` - Uses integration points and patterns

**Related**:
- `/story-scan` - Deeper analysis for specific stories (HIGH confidence)

---

This helps ensure epics build on existing relevant code rather than reinventing wheels or copying irrelevant patterns.
