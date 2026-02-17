---
name: story-scan
description: Deep analysis of existing codebase to find specific implementations for THIS story
disable-model-invocation: false
---

---
description: Deep analysis of existing codebase to find specific implementations for THIS story.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

**Deep dive** into codebase to find **specific implementations** to guide this story's development.

**Time**: 20-30 minutes (thorough code reading)  
**Confidence**: HIGH - actual code read and analyzed  
**Purpose**: Find EXACTLY how to build THIS story  
**Output**: Implementation guide with copy-paste-adapt examples

## When to Use

- **After `/story-specify` or `/story-clarify`** - Before planning implementation
- **After `/epic-scan`** (optional) - Epic-scan found patterns, story-scan finds specifics
- **Before `/story-plan`** - Inform technical design with real implementations
- **When similar features exist** - "How did we implement X last time?"

**When to SKIP**:
- **Greenfield project** - No existing code to scan
- **Completely novel feature** - Nothing similar exists (epic-scan would have found it)
- **After project-scan said "no similar features"** - Don't waste time

**Relationship to other scans**:
- `/project-scan` → Spotted potential areas (LOW confidence)
- `/epic-scan` → Found relevant patterns (MEDIUM confidence)
- `/story-scan` → Deep implementation guide (HIGH confidence) ← You are here

---

## Subagent Parallelization

This command benefits from parallel speck-scanner execution for domain analysis:

```
├── [Parallel] speck-scanner: "Deep analyze auth patterns in src/"
├── [Parallel] speck-scanner: "Deep analyze API patterns in src/api/"
├── [Parallel] speck-scanner: "Deep analyze data models in src/models/"
├── [Parallel] speck-scanner: "Deep analyze UI components in src/components/"
├── [Parallel] speck-scanner: "Analyze testing patterns in tests/"
├── [Parallel] speck-scanner: "Analyze error handling patterns in src/"
├── [Parallel] speck-scanner: "Quick scan logging patterns in src/"
├── [Parallel] speck-scanner: "Quick scan code conventions in src/"
└── [Wait] → Synthesize into codebase-scan-*.md

Each scanner returns domain-specific patterns and examples.
```

**Speedup**: 5-6x compared to sequential scanning.

## Scan Process

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If `spec.md` exists: Load it to understand story domain
   - Parse $ARGUMENTS for flags: --domain=X, --similar-to="X", --patterns-only

2. Check if codebase exists:
   - Look for source directories (src/, lib/, backend/, frontend/, app/, etc.)
   - If no source found: INFO "No existing codebase detected (greenfield project). Skip /story-scan."

3. Determine project type:
   - Single: src/, lib/, tests/ at root
   - Web: frontend/ and backend/ directories
   - Mobile: api/ with ios/ or android/
   - Monorepo: packages/, apps/, or libs/

4. Perform analysis:
   
   A. **Structure Analysis**:
      - Map directory organization
      - Identify module boundaries
      - Document test organization
   
   B. **Technology Stack**:
      - Check package.json, requirements.txt, go.mod, Cargo.toml, etc.
      - List: Languages, frameworks, ORMs, databases, testing tools
   
   C. **Pattern Detection** (focus on feature domain if specified):
      - Auth patterns (if --domain=auth or feature involves auth)
      - API patterns (if --domain=api or feature involves endpoints)
      - Data patterns (if --domain=data or feature involves models)
      - Error handling, logging, testing patterns
   
   D. **Reference Implementations**:
      - If --similar-to specified: Find that feature
      - Else: Find 2-3 similar features based on domain
      - Extract: File paths, patterns used, code examples (max 20 lines each)
   
   E. **Convention Analysis**:
      - File naming (snake_case, kebab-case, PascalCase)
      - Function/class naming
      - Import organization
      - Documentation style
   
   F. **Conflict Detection**:
      - Check for naming collisions with entities in spec
      - Check for route conflicts with endpoints in spec
      - Flag potential integration issues

5. Generate scan report:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/story/codebase-scan-template.md
   ```
   
   The template is self-documenting - follow all sections and guidelines within it.

6. Save scan report:
   - To: `{STORY_DIR}/codebase-scan-{domain/similar-to}.md`

7. Report completion:
   - Executive summary (3-5 key findings)
   - Reference implementations found
   - Potential conflicts (if any)
   - Recommendations for planning
   - Next suggested command

8. **Confidence statement**:
   ```
   **Confidence Level**: HIGH
   
   This scan involved:
   - ✅ Reading actual source code (not just file names)
   - ✅ Extracting real implementation examples
   - ✅ Validating patterns through code inspection
   - ✅ Identifying specific file paths and line numbers
   
   You can trust these findings for implementation planning.
   However, always verify during implementation that:
   - Code hasn't changed since scan
   - Pattern still fits your specific use case
   - No hidden dependencies exist
   ```

---

Behavior rules:
- Never hallucinate patterns—only report what exists in code
- Include real file paths for every example
- Limit code examples to 20 lines max
- Flag patterns that violate constitution
- If --patterns-only: Skip structure analysis
- If --domain specified: Focus analysis on that domain only
- **HIGH confidence**: This is deep analysis with code reading

---

## Integration with Other Commands

**Optional context**:
- `/project-scan` - May have spotted similar areas
- `/epic-scan` - May have found relevant patterns

**Feeds into**:
- `/story-plan` - Uses findings to create technical design
- `/story-tasks` - Implementation guided by scan examples

**Confidence comparison**:
```
/project-scan  → LOW confidence  (directory scan)
/epic-scan     → MEDIUM confidence (pattern matching)
/story-scan    → HIGH confidence (code reading) ← Most detailed
```

Context: $ARGUMENTS
