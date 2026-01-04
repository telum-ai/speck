<!-- SPECK:START -->

# Speck 🥓 - Speck

You are working in a project using **Speck 🥓**, a multi-level methodology for building software through comprehensive specifications at project, epic, and story levels.

## 🎯 Quick Reference

**When user asks to build something**: Always start with `/speck [description]` - it routes you to the right level  
**When you need methodology details**: Read @.speck/README.md
**When you need command instructions**: Check `.cursor/commands/[level]-[command].md`
**When you need templates**: Use files in `.speck/templates/[level]/`

## 🏗️ How to Navigate Speck Structure

### Understand the Three-Level Hierarchy

Work at the appropriate level:
- **Project Level**: Strategic planning (vision, goals, architecture)
- **Epic Level**: Tactical features (user value, technical design)
- **Story Level**: Implementation tasks (concrete code changes)

### Know the Directory Structure

Find artifacts in these locations:
```
specs/projects/[project-id]/
├── project.md              # TRUTH: Current project vision/goals
├── context.md              # TRUTH: Current constraints
├── constitution.md         # TRUTH: Optional technical principles
├── domain-model.md         # TRUTH: Domain terminology, entities, rules, principles (optional)
├── architecture.md         # TRUTH: Current system design
├── PRD.md                  # TRUTH: Current requirements/features
├── epics.md                # TRUTH: Epic index (generated/updated by project-plan)
├── ux-strategy.md          # TRUTH: Current UX principles
├── design-system.md        # TRUTH: Current UI patterns
├── project-import.md       # TRUTH: Brownfield import notes (optional)
├── project-landscape-overview.md # TRUTH: Brownfield scan output (optional)
├── project-retro.md         # LEARNING: Project retrospective (optional)
├── project-roadmap.md       # TRUTH: Execution roadmap (optional)
├── project-analysis-report.md # VERIFICATION: Read-only analysis output (optional)
├── project-validation-report.md # VERIFICATION: Project validation (optional)
├── project-validation-summary.md # VERIFICATION: Project validation summary (optional)
├── project-punch-list.md    # EXECUTION: Remaining items (optional)
├── project-*-research-prompt-*.md # RESEARCH: Prompts (optional)
├── project-*-research-report-*.md # RESEARCH: Reports (optional)
└── epics/E001-epic-name/        # Format: E###-epic-name (E for epic prefix)
    ├── epic.md             # PROPOSAL: Proposed epic scope
    ├── context.md          # TRUTH: Epic-specific context (optional)
    ├── constitution.md     # TRUTH: Epic principles (optional)
    ├── epic-outline.md     # PROPOSAL: Technical outline (optional)
    ├── epic-analysis-report.md # VERIFICATION: Read-only analysis output (optional)
    ├── epic-validation-report.md # VERIFICATION: Epic validation (optional)
    ├── epic-punch-list.md  # EXECUTION: Remaining items (optional)
    ├── epic-codebase-scan*.md # [Brownfield] Epic code analysis (optional)
    ├── epic-architecture.md # PROPOSAL: Proposed design (optional - see criteria)
    ├── epic-tech-spec.md   # PROPOSAL: Proposed technical approach
    ├── epic-breakdown.md   # EXECUTION: Story mapping + ordering
    ├── user-journey.md     # PROPOSAL: UX journey map (optional)
    ├── wireframes.md       # PROPOSAL: UX wireframes (optional)
    ├── epic-retro.md       # LEARNING: Epic retrospective (optional)
    ├── epic-*-research-prompt-*.md # RESEARCH: Prompts (optional)
    ├── epic-*-research-report-*.md # RESEARCH: Reports (manual or generated)
    └── stories/S001-story-name/   # Format: S###-story-name (S for story prefix)
        ├── spec.md         # PROPOSAL: Proposed story requirements
        ├── outline.md      # PROPOSAL: Research/decision outline (optional)
        ├── codebase-scan-*.md # [Brownfield] Story code analysis (optional)
        ├── story-*-research-prompt-*.md # RESEARCH: Prompts (optional)
        ├── story-*-research-report-*.md # RESEARCH: Reports (manual or generated)
        ├── plan.md         # PROPOSAL: Proposed technical design
        ├── tasks.md        # EXECUTION: Implementation checklist
        ├── data-model.md   # PROPOSAL: Data model (optional)
        ├── contracts/      # PROPOSAL: Contracts (optional)
        ├── quickstart.md   # VERIFICATION: Test scenarios + manual validation steps
        ├── ui-spec.md      # PROPOSAL: UI spec (required for UI-heavy stories)
        ├── validation-report.md  # VERIFICATION: What actually changed (optional)
        └── story-retro.md  # LEARNING: Story retrospective (optional)
```

**Naming Convention**:
- **Epic directories**: `E###-epic-name` (e.g., `E001-authentication`, `E002-user-management`)
- **Story directories**: `S###-story-name` (e.g., `S001-login-form`, `S002-password-reset`)
- **Shorthand reference**: Use `E001` or `S001` when referring to epics/stories in discussions
- **Backwards compatibility**: Directories without E/S prefix (e.g., `001-epic-name`) are still supported

**Truth vs Proposal Model**:
- **Project-level docs** (project.md, PRD.md, architecture.md, etc.) = **Current production state**
- **Epic/Story specs** (epic.md, spec.md) = **Proposed changes** (until validated)
- **After validation** → Update project-level docs to reflect new reality
- **Constitution**: Exists at project and epic levels only; stories inherit from parent epic/project

## 📋 The Speck Command Phases (User Triggers, You Execute)

User triggers commands, you follow instructions inside each command.

### Phase Flow
1. **Ideation** (optional): brainstorm → loose ideas crystallized into project concepts
2. **Discovery**: specify → clarify
3. **Foundation**: [domain (+ research)] → [ux (+ research)] → context (+ research) → [constitution (+ research)]
4. **Technical Design**: architecture (+ research) → [design-system (+ research)]
5. **Planning**: plan (+ research) → [roadmap]
6. **Infrastructure Epic** (E000): Developer Infrastructure (testing, CI/CD, linting, error tracking)
7. **Epic Work**: specify → clarify → [architecture (+ research)] → plan (+ research) → breakdown
8. **Story Work**: specify → clarify → [outline] → [scan] → plan (+ research) → [ui-spec] → tasks → analyze → implement → validate
9. **Learning**: story-retrospective → epic-retrospective → project-retrospective

**Domain Expertise**: For specialized domains (healthcare, fitness, finance, etc.), `/project-domain` captures subject matter expertise (terminology, entities, rules, principles) that informs all downstream decisions.

**Foundation Epic**: After planning, always consider E000: Developer Infrastructure before feature epics. This sets up testing, CI/CD, linting, and error tracking - foundational concerns that every production project needs.

**Note**: Research is performed just-in-time by each command as needed, not as separate steps.

**Recipe Support**: For common project types, recipes in `.speck/recipes/` provide pre-configured starting points. Recipes are detected at multiple entry points:

| Command | Recipe Integration |
|---------|-------------------|
| `/speck` | Detects recipe match, offers to use it |
| `/project-specify` | Detects recipe match, pre-fills project.md |
| `/project-context` | Uses recipe's `context:` section |
| `/project-architecture` | Uses recipe's `stack:` and `architecture:` sections |
| `/project-plan` | Uses recipe's `suggested_epics:` for epic structure |
| `/story-ui-spec` | Uses recipe's `visual_testing:` to define breakpoints/devices and make UI specs verifiable |
| `/story-tasks` | Uses recipe's `visual_testing:` to generate visual smoke-test tasks (so visuals are validated during development) |
| `/story-validate` | Uses recipe's `visual_testing:` for platform-aware visual validation |

**Recipe Metadata**: When a recipe is selected, `_active_recipe: [name]` is stored in project.md for downstream commands to use.

**Visual Testing Configuration**: Each recipe includes a `visual_testing:` section that configures autonomous visual validation:

```yaml
visual_testing:
  platform: [web|mobile-flutter|mobile-rn|desktop-electron|desktop-tauri|extension|api|cli]
  strategy: [browser-mcp|golden-tests|maestro|playwright|playwright-electron|webdriverio|puppeteer|none]
  # Varies by platform (see `.speck/patterns/visual-testing/`), e.g.:
  # - web: "visual-testing/web-visual-testing.md"
  # - mobile-flutter: "visual-testing/mobile-flutter-visual-testing.md"
  # - mobile-rn: "visual-testing/mobile-react-native-visual-testing.md"
  pattern_file: "visual-testing/web-visual-testing.md"
  breakpoints: {mobile: 375, tablet: 768, desktop: 1024, wide: 1280}
  devices: {ios: [...], android: [...]}
  tools: {primary: ..., visual_regression: ...}
  agent_commands: {screenshot: ..., audit_a11y: ..., playwright_test: ...}
  ci_integration: {on_pr: true, block_on_diff: true}
```

- `/story-validate` loads this config and executes platform-specific visual testing
- Platform patterns in `.speck/patterns/visual-testing/` provide detailed guidance
- Results feed into validation-report.md and story retrospectives

### Command Files Reference
Commands are markdown files in `.cursor/commands/`:
- **Project**: `project-*.md`
- **Epic**: `epic-*.md`
- **Story**: `story-*.md`

Each command file contains step-by-step instructions for you to execute when user triggers that command.

## 🔗 How Commands Connect (Read This Carefully!)

### Project-Level Command Flow

**Unified Flow** (Same sequence for both greenfield and brownfield):

**Brownfield Pre-Specify Extraction** (Optional - only for brownfield):
```
1. project-import.md → Extracts non-code aspects → project-import.md
2. project-scan.md → Extracts code aspects → project-landscape-overview.md
   Then continues with unified flow below...
```

**Ideation** (Optional - for vague ideas):
```
0. project-brainstorm.md → Transforms loose ideas into project concepts
   - For users who aren't sure what to build yet
   - Clusters ideas, generates concepts, selects direction
   - Output feeds into project-specify
```

**Core Flow** (Both greenfield and brownfield):
```
1. project-specify.md → Creates project.md
   - Greenfield: Interactive Q&A from scratch (or from brainstorm output)
   - Brownfield: Pre-fills from import/scan data, validates with user

2. project-clarify.md → Fills gaps via Q&A
   - Greenfield: Clarifies all aspects
   - Brownfield: Focuses on non-discoverable aspects (strategy, goals)

3. [OPTIONAL: project-domain.md] → Creates domain-model.md (with embedded research)
   - For specialized domains (healthcare, fitness, finance, legal, etc.)
   - Captures terminology, entities, rules, principles
   - Informs UX and all downstream decisions

3.5. [OPTIONAL: project-ux.md] → Creates ux-strategy.md (with embedded research)
   - Greenfield: Defines UX principles, conducts UX research just-in-time
   - Brownfield: Extracts from existing UI patterns
   - Uses domain-model.md terminology if available

4. project-context.md → Creates context.md (input for architecture & PRD, with embedded research)
   - Greenfield: Interactive definition, conducts standards/compliance research just-in-time
   - Brownfield: Pre-fills from scan, asks for non-code context
   [OPTIONAL: /project-constitution → Creates constitution.md (with embedded research)]

5. project-architecture.md → Creates architecture.md (BEFORE plan!, with embedded research)
   - Greenfield: Designs system architecture, conducts technology evaluation research just-in-time
   - Brownfield: Documents existing architecture from scan
   - USES: context.md, constitution.md, project-landscape-overview.md

6. [OPTIONAL: project-design-system.md] → Creates design-system.md (BEFORE plan!, with embedded research)
   - Greenfield: Creates design tokens and patterns, conducts design research just-in-time
   - Brownfield: Extracts existing design tokens, consolidates
   - USES: ux-strategy.md, architecture.md, project-landscape-overview.md

7. project-plan.md → Creates PRD.md + epics.md (with embedded research)
   - Conducts market/business research just-in-time if needed
   - USES: ux-strategy.md, context.md, architecture.md, design-system.md
   - Brownfield also uses: project-landscape-overview.md for epic candidates
   - REQUIRES: architecture.md (design decisions inform planning!)
   [OPTIONAL: project-roadmap.md → Creates project-roadmap.md (USES: epics.md)]

8. project-analyze.md → Quality check
9. project-validate.md → Go/no-go decision
   [AFTER PROJECT: project-retrospective.md → Evolves Speck methodology]
```

**Key Points**:
- Same command sequence for both greenfield and brownfield
- Commands are context-aware: detect import/scan artifacts and adapt
- Architecture and design-system come BEFORE plan (design before organization)
- All commands consume: user input + import/scan data + existing Speck docs + upstream artifacts (never downstream)

*Project commands: `project-*.md` in `.cursor/commands/`*

### Epic-Level Command Flow

**Standard Path**:
```
1. epic-specify.md → Creates/enhances epic.md (from project-plan placeholder)
2. epic-clarify.md → Resolves ambiguities
   [OPTIONAL: epic-outline.md → Maps research needs, uses JIT research pattern]
3. [OPTIONAL: epic-architecture.md → Creates epic-architecture.md (technical design)]
   → RECOMMENDED when: Cross-cutting concerns, new patterns, complex integrations
   → SKIP when: Simple CRUD, follows existing patterns, single-concern epic
4. epic-plan.md → Creates epic-tech-spec.md (USES: architecture if available)
   [UX-HEAVY: epic-journey.md + epic-wireframes.md → Before plan]
   [COMPLEX: /epic-constitution → Creates `constitution.md` (epic principles)]
5. epic-breakdown.md → Creates epic-breakdown.md (USES: tech-spec)
6. epic-analyze.md → Quality check
7. epic-validate.md → Completion verification
   [AFTER EPIC: epic-retrospective.md → Reads story retros, validates patterns]
```

**Epic Architecture Decision Criteria**:
| Include `/epic-architecture` When | Skip When |
|-----------------------------------|-----------|
| Cross-cutting change (affects 2+ services) | Simple CRUD operations |
| New architectural pattern being introduced | Follows existing project patterns |
| Complex third-party integrations | Single-concern epic |
| Performance-critical with specific targets | Clear implementation path |
| Security-critical epic | UI-only changes |

*Epic commands: `epic-*.md` in `.cursor/commands/`*

### Story-Level Command Flow

**Standard Path**:
```
1. story-specify.md → Creates spec.md
2. story-clarify.md → Resolves ambiguities
   [OPTIONAL: story-outline.md → Maps research needs, uses JIT research pattern]
   [OPTIONAL: story-scan.md → Analyzes existing code]
3. story-plan.md → Creates plan.md, data-model.md, contracts/, quickstart.md
   [UI-HEAVY: story-ui-spec.md → Creates ui-spec.md - REQUIRED if story has UI components]
4. story-tasks.md → Creates tasks.md (USES: plan, data-model, contracts)
5. story-analyze.md → ⚠️ REQUIRED Quality check before implementation
6. story-implement.md → Writes code (FOLLOWS: tasks.md)
7. story-validate.md → Creates validation-report.md (checks spec compliance)
8. story-retrospective.md → Mines .learning.log + commits → Creates story-retro.md
```

**Decision Gates for Optional Commands**:
| Command | Include When |
|---------|--------------|
| `story-outline` | Complex tech decisions, unfamiliar stack, needs research |
| `story-scan` | Brownfield - extending existing codebase |
| `story-ui-spec` | UI-heavy with multiple components/states/animations |

**Note**: `story-analyze` is REQUIRED, not optional. It catches issues before implementation.

*Story commands: `story-*.md` in `.cursor/commands/`*

### Critical Command Dependencies (What NEEDS What)

**At Project Level**:
```
project-architecture.md → NEEDS: context.md + [constitution.md] + [project-landscape-overview.md]
project-plan.md → NEEDS: architecture.md + ux-strategy.md + context.md + [design-system.md] + [constitution.md] + [project-landscape-overview.md]
project-roadmap.md → NEEDS: epics.md (from /project-plan)
```

**At Epic Level**:
```
epic-architecture.md → OPTIONAL: Use when cross-cutting, new patterns, or complex integrations
epic-plan.md → NEEDS: epic.md + [epic-architecture.md] + [epic-codebase-scan*.md]
epic-breakdown.md → NEEDS: epic-tech-spec.md (from plan)
```

**At Story Level**:
```
story-tasks.md → NEEDS: plan.md + data-model.md + contracts/ + [codebase-scan-*.md]
story-implement.md → NEEDS: tasks.md
story-validate.md → NEEDS: spec.md + implementation complete
story-retrospective.md → NEEDS: validation-report.md + .learning.log + git commits
```

**Handling Optional Artifacts**:
- Artifacts in `[brackets]` are optional - commands work without them
- When optional artifact exists: Load and incorporate its content
- When optional artifact missing: Proceed without it, don't error
- Always check for existence before loading optional documents
- Common pattern: "IF [artifact] exists: Use it for [purpose]. IF missing: Proceed without."

## 🔬 Just-In-Time Research Pattern

Research is no longer a separate phase. Instead, each command performs research exactly when needed.

### Recommended: Perplexity MCP

Speck recommends configuring **Perplexity MCP** for automated deep research:

| Tool | Use Case |
|------|----------|
| `perplexity_search` | Quick facts, ranked web results |
| `perplexity_ask` | Conversational queries with web context |
| `perplexity_research` | Comprehensive analysis, detailed reports |
| `perplexity_reason` | Complex logic, decision analysis |

**Setup**: See `.cursor/MCP-SETUP.md` (Speck supports a project overlay + merge script for MCP config).

### How It Works

1. **Commands Identify Knowledge Gaps** - What's missing to make a good decision?
2. **Automated Research** - Use MCP tools (Perplexity/Context7) or fallback to `web_search`
3. **Deep Research If Needed** - Use `perplexity_research` or generate manual prompt
4. **Embed in Output** - Document findings in artifact with sources

### Research Scope by Level

- **Project** (Strategic): Market, UX, architecture, compliance
- **Epic** (Tactical): Integration, performance, security
- **Story** (Operational): API usage, edge cases, testing

For details, see `.speck/patterns/just-in-time-research-pattern.md`.

## 🔧 Recommended MCP Servers

Configure these in `.cursor/mcp.json` (see `.cursor/MCP-SETUP.md`):

| Server | Purpose |
|--------|---------|
| **Perplexity** | Research, web search, reasoning |
| **GitHub** | PRs, issues, repos, code search |
| **Context7** | Up-to-date library documentation |

All optional but recommended. Speck works without them via fallbacks.

## 📚 Context7 MCP - Up-to-Date Library Documentation (Methodology Core)

This section replaces the need for a template-provided `.cursor/rules/context7-mcp.mdc`.

### Critical Rules

- **ALWAYS use Context7 MCP** when implementing features with external libraries, frameworks, or packages
- **Automatically invoke Context7 tools** for code generation, setup steps, or API documentation without requiring explicit user request
- **Use two-step process**: First call `resolve-library-id` to get the Context7-compatible library ID, then call `get-library-docs` with that ID
- **Skip resolution step** if user provides explicit library ID in format `/org/project` or `/org/project/version` - go directly to `get-library-docs`
- **Focus documentation** using the `topic` parameter when you know the specific area (e.g., "routing", "authentication", "hooks")
- **Adjust token limit** based on complexity: use default 5000 for general queries, increase for comprehensive features, decrease for simple lookups
- **Cite Context7 documentation** in responses by referencing specific sections retrieved
- **Prefer Context7 docs** over training data when conflicts arise - Context7 has the most current information
- **Fallback to web search** if Context7 doesn't have documentation after 2-3 reasonable attempts (try alternative library names, check for typos, verify library exists)

### Tool Usage

#### 1) resolve-library-id
**Purpose**: Convert a general library name into a Context7-compatible library ID.

**Required Parameters**:
- `libraryName` (string): the library/package name to search for (e.g. "supabase", "next.js", "mongodb")

**When to use**:
- User mentions a library by common name
- You need to implement a feature with a specific package
- You're unsure of the exact Context7 library ID

#### 2) get-library-docs
**Purpose**: Fetch up-to-date documentation for a specific library.

**Required Parameters**:
- `context7CompatibleLibraryID` (string): exact library ID in format `/org/project` or `/org/project/version`

**Optional Parameters**:
- `topic` (string): focus docs on a specific area (e.g. "hooks", "routing", "authentication")
- `tokens` (number): max tokens to return (default: 5000, min: 1000)

### When to Use Context7

**ALWAYS use for**:
- Setting up new libraries or frameworks
- Implementing features with third-party APIs
- Configuration and initialization code
- Understanding library-specific patterns or best practices
- Resolving API changes or deprecated methods
- Code generation using external packages
- Troubleshooting library-specific errors

**DON'T use for**:
- Language fundamentals (JavaScript, Python, etc.)
- Standard library features
- Project-specific business logic
- Custom internal libraries
- General programming concepts

### Fallback Rule

If Context7 has no docs after **2-3 attempts** (try variants), use `web_search` with a specific query and cite sources.

### Common Library IDs (Shortcuts)

- Next.js: `/vercel/next.js`
- React: `/facebook/react`
- Supabase: `/supabase/supabase`
- MongoDB: `/mongodb/docs`
- Stripe: `/stripe/stripe-node`

### Tips (High Leverage)

- **Topic precision**: prefer specific topics like "server actions" over broad topics like "routing"
- **Token sizing**:
  - Simple query: 1000–2000 tokens
  - Standard implementation: 3000–5000 tokens
  - Complex feature: 7000–10000 tokens
- **Multiple libraries**: do separate Context7 calls per library (don’t combine)

### Troubleshooting

- **No docs found**:
  - Try 2–3 name variants (e.g. `nextjs` vs `next.js`)
  - Verify library exists
  - Then fall back to `web_search` with a specific query and cite sources
- **Docs seem outdated**:
  - Try a versioned ID `/org/project/version` if available
  - Otherwise use `web_search` for latest official docs

## 🎯 Agent Skills (Domain Expertise)

Skills are **agent-decided** expertise packages - automatically loaded when relevant to the current task.

**Location**: `.claude/skills/`

| Category | Examples | When Loaded |
|----------|----------|-------------|
| `external-services/` | Stripe, Supabase, Clerk, AI APIs, Sentry | When working with these services |
| `technologies/` | PWA, Docker, WebSockets, GitHub Actions | When implementing these technologies |
| `domains/` | SaaS billing, multi-tenancy, GDPR | When building domain-specific features |
| `architectures/` | Serverless, offline-first | When designing system architecture |

**Skills complement recipes**: Recipes define WHAT to use; Skills provide HOW to use them effectively.

**Enabling Skills**: Cursor Settings → Rules → Import Settings → Toggle "Agent Skills" on.

See `.claude/skills/README.md` for details.

## 🤖 Subagents (Intra-Command Parallelization)

Subagents are **parallel workers** that speed up command execution. The main agent spawns them for independent sub-tasks within commands.

**Location**: `.cursor/agents/`

**Key principle**: All subagents are spawned directly by the main agent. There is NO hierarchy - subagents never spawn other subagents.

### The 7 Parallel Workers

| Agent | Model | Purpose | Speed |
|-------|-------|---------|-------|
| **speck-explorer** | Haiku | Fast file/pattern finding | ⚡ 1-2s |
| **speck-researcher** | Sonnet + MCP | External research | 🔄 3-10s |
| **speck-scanner** | Sonnet | Deep code/domain analysis | 🔄 5-15s |
| **speck-scribe** | Sonnet | Document section drafting | 🔄 5-20s |
| **speck-auditor** | Sonnet | Validation aspect checking | 🔄 3-10s |
| **speck-architect** | Opus | Complex reasoning/decisions | 🔄 10-30s |
| **speck-coder** | Composer 1 | Code writing for [P] tasks | 🔄 10-60s |

### Skills vs Subagents

| Aspect | Skills (`.claude/skills/`) | Subagents (`.cursor/agents/`) |
|--------|---------------------------|-------------------------------|
| **What** | Knowledge loaded into context | Parallel workers with own context |
| **When** | Auto-loaded when relevant | Spawned for parallel execution |
| **Examples** | Stripe patterns, PWA rules | speck-explorer, speck-coder |

**Skills = WHAT to know** (domain expertise)
**Subagents = HOW to work faster** (parallelization)

### When to Parallelize

- **3+ independent sub-tasks** → Parallelize
- **1-2 items** → Just do it sequentially
- **Tasks share dependencies** → Don't parallelize

### Command-Specific Instructions

Each command file in `.cursor/commands/` contains its own "Subagent Parallelization" section with specific instructions for that command. Check the command file for details.

## 🔄 Guide Users Through the Process

### Unified Flow (Both Greenfield and Brownfield)
Typical flow: 
```
specify → clarify → [domain (+ research)] → [ux (+ research)] → context (+ research) → [constitution (+ research)] → architecture (+ research) → [design-system (+ research)] → plan (+ research) → [roadmap] → analyze → validate
```

### For Greenfield (New Projects)
Start with: `/project-specify`
- Commands ask questions, build artifacts from scratch
- Same flow as above

### For Brownfield (Existing Code)  
Start with: `/project-import` → `/project-scan` → then same flow
- Import/scan extract data first
- Commands pre-fill from extracted data, then follow same guidance process
- Architecture documented before planning

### Key Guidance Points
- Suggest `/speck` when user unsure where to start
- Foundation (ux, context) comes BEFORE planning
- Architecture and design-system come BEFORE planning (design decisions inform planning!)
- Retrospectives after each story/epic/project
- Commands contain detailed execution instructions
- All commands are context-aware and adapt for brownfield projects

## 🎯 Detect the Right Level (Guide User to Appropriate Command)

When user makes a request, determine the appropriate level and suggest:
- **Level 0 (Atomic)**: Fix typo, change color → Suggest `/speck` routing to story
- **Level 1 (Small)**: Add form, create page → Suggest `/speck` routing to story within epic
- **Level 2 (Feature)**: Auth system, shopping cart → Suggest `/speck` routing to epic
- **Level 3-4 (Platform)**: Full product, e-commerce site → Suggest `/speck` routing to project

When unsure, guide user to use `/speck [description]` first - it auto-detects and routes appropriately!

### Project Complexity Scale (Standardized)

| Level | Scope | Examples | Typical Duration | Team Size |
|-------|-------|----------|------------------|-----------|
| **0** | Atomic change | Typo fix, config tweak | Hours | 1 |
| **1** | Single story | Form, button, endpoint | 1-3 days | 1 |
| **2** | Epic/Feature | Auth system, CRUD module | 1-4 weeks | 1-3 |
| **3** | Full product | Complete MVP, SaaS app | 1-3 months | 2-5 |
| **4** | Platform | Multi-product ecosystem | 3-12 months | 5+ |

This scale is used by:
- `/speck` router for level detection
- Recipe `complexity.level_range` field
- `/project-specify` for complexity assessment

## 💡 Remember These Critical Patterns

### Always Run Foundation BEFORE Planning

At project level, follow this order strictly:
```
Run: [domain] → [ux] → context → [constitution] → architecture → [design-system] → plan
Why: plan USES these as inputs, and architecture decisions inform planning
```

At epic level, run architecture before tech spec:
```
Run: clarify → architecture → plan → breakdown
Why: tech spec USES architecture design
```

At story level, run plan before tasks:
```
Run: clarify → [outline] → [scan] → plan → [ui-spec] → tasks → analyze → implement → validate
Why: tasks USES plan's technical design, analyze catches issues before implementation
Optional: [outline]=research mapping, [scan]=brownfield code, [ui-spec]=UI-heavy stories
```

### Understand Context Inheritance

Read artifacts in this order for complete context:
```
1. Project Context (team, budget, tech constraints)
2. Epic Context (adds epic-specific needs)
3. Story Context (cumulative: project + epic)
```

Remember: Stories inherit constraints from BOTH project and epic levels.

For brownfield projects, also read:
```
- project-import.md (non-code aspects)
- project-landscape-overview.md (code aspects)
- epic-codebase-scan*.md (epic-specific code)
- codebase-scan-*.md (story-specific code)
```

### Know What PRD Needs

Before running `/project-plan`, ensure these artifacts exist:
- `architecture.md` → REQUIRED: Provides architectural decisions and constraints
- `ux-strategy.md` → Provides UX principles and user journeys (optional)
- `context.md` → Provides constraints and non-functional requirements
- `design-system.md` → Provides design tokens and patterns (optional)
- `constitution.md` → Provides technical principles (optional)

**CRITICAL**: Never run `/project-plan` before `architecture.md` - design decisions must inform planning!

## 🔧 Follow These Development Standards

### Foundation Epic (E000: Developer Infrastructure)

**Before starting feature epics**, ensure Developer Infrastructure is set up:

| Concern | What It Includes | Why It Matters |
|---------|------------------|----------------|
| **Testing** | Framework setup, test patterns, CI test runs | Catch bugs early, enable TDD |
| **CI/CD** | Lint, test, build, deploy pipeline | Automated quality gates |
| **Linting** | Code style enforcement, auto-fix | Consistent codebase |
| **Error Tracking** | Sentry or equivalent integration | Production visibility |
| **Environment Config** | .env patterns, secrets management | Secure, reproducible deploys |

**When to Include E000**:
- ✅ Any production-bound project (default: YES)
- ✅ Projects using recipes (recipe specifies tech-specific tooling)
- ❌ Throwaway prototypes
- ❌ Brownfield with existing infrastructure

**`/project-plan` asks**: "Should I include Developer Infrastructure epic?" (default: yes)

### Git Workflow
Follow these practices:
- Use GitHub Flow (main + feature branches)
- Write Conventional Commits (`feat:`, `fix:`, `chore:`)
- **Add learning tags to commit messages** (see Learning Capture below)

### Test Strategy
Apply TDD workflow:
- Write tests first (mark pending with `.skip()`)
- Implement features
- Remove skip markers
- Target 95%+ coverage for critical paths
- Check for test strategy documentation in project (TEST_STRATEGY.md files if they exist)

### Database Migrations
Create safe migrations:
- Use idempotent patterns (IF EXISTS/IF NOT EXISTS)
- Use CONCURRENTLY for indexes (where supported)
- Use NOT VALID for constraints (where supported)
- Check for migration safety rules in project Cursor rules (if present)

### Frontend Development
Follow design system rules (if project has them):
- ALWAYS use existing components first
- NO arbitrary CSS/styling values - use design tokens only
- Check accessibility requirements (WCAG standards if specified)
- Check project Cursor rules for design system enforcement (if present)

### Design Context Loading (CRITICAL for UI Work!)

Before planning or implementing UI work at ANY level, ALWAYS load project design context:

**Required Documents**:
```
specs/projects/[PROJECT_ID]/design-system.md  → Tokens, components, patterns
specs/projects/[PROJECT_ID]/ux-strategy.md    → UX principles, voice/tone
```

**Epic-Level Loading** (for `/epic-journey`, `/epic-wireframes`):
- [ ] Load ux-strategy.md for personas, emotional goals, accessibility standards
- [ ] Load design-system.md for components, tokens, interaction patterns
- [ ] Apply voice/tone from ux-strategy.md to journey touchpoints and wireframe content
- [ ] Use design tokens in wireframe specifications

**Story-Level Loading** (for `/story-plan`, `/story-ui-spec`):
- [ ] Extract design tokens (colors, typography, spacing) from design-system.md
- [ ] Note available components before creating new ones
- [ ] Apply voice/tone from ux-strategy.md to copy/microcopy
- [ ] Reference accessibility standards from ux-strategy.md

**If Missing**: Warn user and suggest running `/project-design-system` or `/project-ux` first.

**Anti-Patterns to Avoid**:
- ❌ Creating custom button when Button exists in design-system.md
- ❌ Using `color: #3B82F6` instead of `color: var(--primary-500)`
- ❌ Writing generic "Loading..." when ux-strategy.md specifies friendly voice
- ❌ Designing wireframes without referencing design-system.md grid/spacing
- ❌ Creating journey maps without ux-strategy.md emotional goals

## 📊 Learning Capture System (CRITICAL for Retrospectives!)

### Why This Matters
**Retrospectives are only as good as the learnings captured**. Story retrospectives mine commits to extract patterns, gotchas, and insights. Without tagged commits, retrospectives miss valuable learnings!

### Three Data Sources
1. **Cursor Hook**: Automatically logs file edits to `.learning.log`
2. **Commit Message Tags**: You manually add to commits (see below)
3. **Validation Reports**: Captures spec vs reality gaps

### Commit Learning Tags (Add These When Committing!)

When you commit code, **always check if you discovered something worth capturing**. Add tags at the end of commit message body:

**6 Learning Tag Types**:

1. **PATTERN:** - Reusable code pattern you discovered
   ```
   PATTERN: PostgreSQL window functions for time overlaps - 10x faster than loops
   ```

2. **GOTCHA:** - Surprise or pitfall you encountered
   ```
   GOTCHA: iOS cert requires Apple Developer account - 45min setup time
   ```

3. **PERF:** - Performance insight or optimization
   ```
   PERF: Query time reduced from 500ms to 50ms - Indexed on user_id
   ```

4. **ARCH:** - Architecture decision or structural insight
   ```
   ARCH: Chose WebSocket over polling - <2s latency requirement
   ```

5. **RULE:** - Cursor rule update needed
   ```
   RULE: Update project migration safety rule - Always VACUUM ANALYZE after bulk inserts
   ```

6. **DEBT:** - Technical debt created (what and why)
   ```
   DEBT: No retry logic - Add after validating base functionality
   ```

**Complete Commit Example**:
```bash
git commit -m "feat(matching): implement overlap detection

Uses PostgreSQL window functions for 30-min availability blocks.

PATTERN: Window functions for time overlaps - 10x faster than Python
PERF: Query time 500ms → 50ms with proper indexing
GOTCHA: Timezone must be normalized before comparison
ARCH: Server-side detection only - Privacy-by-design
RULE: Update project testing rule - Add overlap testing pattern
"
```

**When to Skip Tags**:
- Trivial changes (typos, formatting)
- Documentation only (unless significant insight)
- Dependency updates
- Reverting changes

### Cascading Retrospectives Mine These Tags

- **Story retros** mine commits + .learning.log → produce story-retro.md
- **Epic retros** read story-retro.md (validate patterns) → produce epic-retro.md
- **Project retros** read epic-retro.md (validate cross-epic) → evolve Speck methodology

### Sharing Methodology Learnings (Optional)

After retrospectives, you can opt-in to share methodology insights with the Speck team:
- Only methodology improvements are shared (no project-specific data)
- You review before submission
- Creates an issue in the Speck repository

### Pattern Validation Through Frequency
- **1 occurrence** = story-specific (don't promote)
- **2+ in stories** = epic-validated (update rules/project docs)
- **2+ in epics** = project-validated (promote to learned patterns library)

**The Learning Loop**: Your commit tags → Story retro extracts → Epic retro validates → Project retro evolves Speck → Better process for next project!

### Learned Patterns Library

Validated patterns are stored in `.speck/patterns/learned/` for cross-project reuse:
- `code/` - Reusable code patterns
- `architecture/` - Architectural patterns
- `testing/` - Testing strategies
- `process/` - Development process patterns
- `gotchas/` - Anti-patterns to avoid

Patterns flow here through retrospectives, never added manually. See `.speck/patterns/learned/README.md` for details.

## 🚨 Critical Rules to Follow

### Before Creating/Modifying Frontend Components
Check project Cursor rules for design system rules (if present):
- Use existing design system components
- No arbitrary CSS/styling values
- Follow project brand guidelines
- Respect design philosophy

### Before Creating/Modifying Database Migrations
Check project Cursor rules for migration safety rules (if present):
- Use idempotent patterns (IF EXISTS/IF NOT EXISTS)
- Safe index creation (CONCURRENTLY where supported)
- Safe constraint addition (NOT VALID where supported)
- Proper enum/type handling

### Before Skipping ANY Test
Check project Cursor rules for testing rules (if present):
- Only skip for TDD (not yet implemented)
- NEVER skip for convenience
- Research proper testing pattern instead

### When Committing Code
**ALWAYS add learning tags when you discovered something**:
- Add PATTERN:, GOTCHA:, PERF:, ARCH:, RULE:, DEBT: tags (see Learning Capture System above)
- These feed the retrospective system
- Story retros mine your commits to extract patterns
- Without tags, valuable learnings are lost!

### Commit Checkpoints (Proactively Commit at Natural Points!)

The agent SHOULD proactively make commits at these natural completion points (not just suggest - actually commit!):

**After Spec Commands** (project-specify, epic-specify, story-specify):
```
docs([level]): define [name] specification
```

**After Plan Commands** (project-plan, epic-plan, story-plan):
```
docs([level]): design [name] [architecture/tech-spec/implementation]
```

**After Implementation** (story-implement):
```
feat([scope]): implement [story-name]

[Description]

PATTERN: [if applicable]
GOTCHA: [if applicable]
```

**After Validation** (story-validate):
```
docs(story): validate [story-name] completion
```

**Agent Behavior**:
- After completing each command that creates/updates spec files, proactively run `git add` and `git commit` with appropriate message
- Batch related spec file changes into single commits
- Never leave uncommitted spec changes when switching contexts
- Include learning tags in implementation commits when patterns discovered
- Only ask for confirmation if user has explicitly requested review-before-commit mode

## 🎯 Jobs-to-Be-Done (JTBD) Framework

Integrate JTBD theory (Ulwick/Christensen) into specs to focus on **what users are trying to accomplish**.

### Job Statement Format
```
[Action verb] + [object of action] + [contextual clarifier]
```
Example: "Manage project deadlines across distributed teams"

### Outcome Statement Format (ODI)
```
[Direction] + [unit of measure] + [object of control] + [contextual clarifier]
```
Directions: Minimize, Maximize, Increase, Reduce
Example: "Minimize the time it takes to identify which tasks are at risk"

### Apply JTBD at Each Level
- **Project**: Document core functional job, related jobs, emotional/social jobs
- **Epic**: Identify which project job this addresses, list desired outcomes
- **Story**: Include job context in user story, define outcome-based success metrics

## 📝 Spec Format Conventions

### User Stories (JTBD Enhanced)
```markdown
**Job Context**: When [situation/trigger], I'm trying to [core job]...

**User Story**: As a [user type], I want to [action] so that I can [outcome statement].

**Success Metrics** (Outcome-Driven):
- [ ] Minimizes time to [specific activity] by [target]
- [ ] Reduces likelihood of [negative outcome]
```

### Acceptance Criteria (Gherkin + Outcomes)
```markdown
Given [context]
When [action]
Then [outcome - phrased as measurable result]
```

### Requirements (Adopt OpenSpec-style)
```markdown
### Requirement: [Name]
System SHALL [normative statement].

#### Scenario: [Name]
- **GIVEN** [initial state]
- **WHEN** [trigger/action]
- **THEN** [expected outcome]
- **AND** [additional outcomes]
```

### Normative Language (Use Precise Requirements)

Use RFC 2119-style normative language for clarity:

- **SHALL** / **MUST** = Mandatory requirement (must be tested and verified)
  - Example: "System SHALL respond within 200ms"
  - Example: "Users MUST be authenticated"
  
- **SHOULD** / **RECOMMENDED** = Best practice (can deviate with documented reason)
  - Example: "API SHOULD return JSON"
  - Example: "Errors SHOULD include error codes"
  
- **MAY** / **OPTIONAL** = Truly optional behavior
  - Example: "Response MAY include metadata"
  - Example: "UI MAY show loading spinner"

**Default to SHALL/MUST** for all requirements unless explicitly optional.  
Avoid vague language like "might", "could", "would be nice" - use precise normative terms.

## 🎨 Simplicity-First Principles (Enforce These!)

From OpenSpec inspiration - default to simple solutions, require evidence for complexity.

### Default Solution
- **<100 lines** of new code per story
- **Single file** until proven insufficient
- **Standard library** over custom framework
- **Boring, proven tech** over cutting-edge

### Complexity Triggers (REQUIRE EVIDENCE)

Only add complexity when you have:

**1. Performance Evidence**:
- Measurements showing current approach too slow
- Example: "Query takes 500ms, target is <100ms"
- NOT acceptable: "Might be slow at scale"

**2. Scale Evidence**:
- Concrete requirements with data
- Example: "Must support 10,000 concurrent users"
- NOT acceptable: "Should be scalable"

**3. Abstraction Evidence**:
- 3+ proven use cases already exist
- Example: "Same validation logic in 5 forms across 3 stories"
- NOT acceptable: "We might reuse this someday"

### Enforcement in Commands

- `/story-plan` must ask: "Does this need complexity? Show evidence."
- `/story-analyze` flags: Unjustified abstractions, premature optimizations
- `/epic-retrospective` reviews: Were complexity decisions validated?

### Examples

**✅ APPROVED**:
```
Added Redis cache for contact hash lookups
Evidence: Measured 200ms avg, target <50ms  
Result: 10ms with Redis
```

**❌ REJECTED**:
```
Created abstract caching framework
Reason: "For future flexibility"
Evidence: None - only 1 use case currently
Action: Use simple dict cache, extract when 3+ use cases exist
```

**✅ APPROVED**:
```
Extracted validation into shared module
Evidence: Same validation in 5 forms across 3 stories
Complexity: 50 lines, single file
```

**❌ REJECTED**:
```
Built validation framework with plugins
Evidence: Used in 2 forms
Action: Wait until 3+ use cases, then extract
```

### 10-Minute Understandability Rule

**Story Level**: Must be explainable in <5 minutes
- If needs "AND" in description → Split into multiple stories
- Example: "Add login AND registration" → Two stories!

**Epic Level**: Must be explainable in <10 minutes
- If needs extensive context to understand → Too broad, split it
- Example: "Authentication AND user management AND admin" → Three epics!

**Test**: Can you explain this to a new teammate in the time limit? If not, split it.

### Verb-Led Naming Convention

Use verb-led prefixes for clear intent:

**Story Names**:
- `add-login-form/` - Adding new capability
- `update-auth-flow/` - Modifying existing
- `remove-legacy-endpoint/` - Removing feature
- `refactor-validation-service/` - Restructuring without behavior change
- `fix-timezone-bug/` - Bug fixes (if separate story)

**Common Prefixes**: `add-`, `update-`, `remove-`, `refactor-`, `fix-`, `optimize-`, `migrate-`

**Why**: Verb shows intent, makes change lists scannable, consistent structure

**Note**: This is a guideline, not enforced. Existing stories can keep their names.

## 🚦 Decision Gates

### Approval Required Before:
- Starting implementation (after `/story-plan`)
- Starting epic work (after `/epic-plan`)
- Production deployment (after `/project-validate`)

### Validation Gates
- Story: `/story-validate` (requirements, tests, performance, constitution)
- Epic: `/epic-validate` (all stories complete, integration verified)
- Project: `/project-validate` (comprehensive go/no-go decision)

## 🤖 Model Selection (IMPORTANT!)

Different LLMs excel at different tasks. Always instruct the user to switch to the right model for the job.

**Reference**: `.speck/patterns/model-selection-pattern.md` for full details.

### Quick Model Selection Guide

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Complex architecture/domain | **Opus 4.5** | Deep reasoning, multi-system understanding |
| Critical code review | **Opus 4.5** | Highest accuracy |
| Security-sensitive code | **GPT-5.2 Extra High** | Lowest vulnerability rate (16/MLOC) |
| Standard development | **Sonnet 4.5** | Best balance (0% edit error rate) |
| **Story implementation (Cursor)** | **Composer 1** | 4x faster, native Cursor integration |
| Multi-file editing (Cursor) | **Composer 1** | Parallel tool execution |
| UI/Frontend work | **Gemini 3 Flash** | Excels at "vibe coding" and visual polish |
| Interactive/quick fixes | **Gemini 3 Flash** | Speed for flow state |
| Real-time agentic pipelines | **Grok Code** | Fastest (455 tok/s), cheapest |
| Mathematical/algorithmic | **GPT-5.2 Extra High** | 100% AIME 2025, superior reasoning |
| Budget-constrained | **Gemini 3 Flash** | Best price/performance ($0.50/M) |
| Validation | **Different model** | Cross-validation catches blind spots |

### MAX Mode (Cursor) - Use Deliberately!

MAX mode unlocks extended context (up to 1M tokens for Gemini) and 200 tool calls, but at **significant cost**.

**USE MAX mode for**:
- Project-wide refactoring
- Large codebase navigation
- Multi-file coordinated changes requiring >25 tool calls
- Background agents on complex tasks

**AVOID MAX mode for**:
- Single-file edits (explicitly include relevant files instead)
- Small feature implementations
- Bug fixes in specific modules
- Most normal development tasks

**Cost reality**: Single MAX requests can cost $5-$60+. Background agents can exhaust $20/month budget in one session.

**Default to normal mode** + explicit context management. See `model-selection-pattern.md` for decision framework.

### Command-Specific Recommendations

**Use Opus 4.5 for**:
- `/project-domain` - Deep domain understanding
- `/project-architecture` - Complex system design
- `/project-constitution` - Principle extraction
- Critical validation tasks

**Use Sonnet 4.5 for**:
- Most `/project-*` commands
- Most `/epic-*` commands
- `/story-plan` (reasoning needed)
- Tasks with vague/ambiguous requirements

**Use Composer 1 for** (when using Cursor):
- `/story-implement` - 4x faster, native Cursor integration
- `/story-tasks` - Fast, structured output
- Multi-file editing and refactoring
- Zero-to-one project building
- Rapid prototyping

**Use Gemini 3 Flash for**:
- UI/frontend "vibe coding"
- High-volume, budget-sensitive work
- When not using Cursor IDE

### When to Suggest Model Switches

**Suggest upgrading to Opus 4.5** when:
- Task involves complex architectural reasoning
- Multiple systems need to be understood together
- Mission-critical code review is needed
- User is struggling with a complex problem

**Suggest Gemini 3 Flash / GPT-5.2** when:
- User needs fast responses for interactive work
- Simple fixes or quick iterations
- Budget is a concern

**Always suggest cross-validation** when:
- Architecture decisions are finalized
- Security-sensitive code is written
- Production deployment is imminent

### Cross-Validation Pattern

For critical artifacts, recommend review by a different model:

```
💡 This architecture was designed with Sonnet 4.5. For additional 
   confidence, consider having Opus 4.5 review it before proceeding.
```

### ⚠️ Avoid Gemini 3 Pro

Current reliability issues (code deletion, context loss) make it unsuitable for production code without constant oversight.

## 📚 Key Reference Files

**Methodology**:
- @.speck/README.md - Complete Speck guide (includes Spec-Driven Development philosophy)

**Patterns**:
- `.speck/patterns/model-selection-pattern.md` - LLM selection guide

**Commands**:
- `.cursor/commands/` - Project-level commands
- `.cursor/commands/` - Epic-level commands
- `.cursor/commands/` - Story-level commands

**Templates**:
- `.speck/templates/project/` - Project templates
- `.speck/templates/epic/` - Epic templates
- `.speck/templates/story/` - Story templates

**Updates**:
- Daily automatic updates via `.github/workflows/speck-update-check.yml`
- Smart merging preserves your customizations

**MCP Setup**:
- `.cursor/MCP-SETUP.md` - How to configure MCP servers (supports project overlay + merge script)
- `.speck/scripts/bash/merge-mcp-config.sh` - Merge baseline + project MCP configs into local `.cursor/mcp.json`

## 🎯 Before Starting Any Task

1. **Determine level**: Project? Epic? Story? (check directory or ask)
2. **Fetch rules**: If the project defines Cursor rules (recommended), read them (commonly under `.cursor/rules/`)
3. **Read artifacts**: spec.md, plan.md, context.md at appropriate level
4. **Verify understanding**: Check all dependencies clear

## 💻 During Execution

1. **Follow commands**: Execute instructions in triggered command
2. **Read before writing**: Always load spec/plan before coding
3. **Capture learnings**: Add commit tags (PATTERN:, GOTCHA:, PERF:, etc.)
4. **Update artifacts**: Note deviations for retrospectives
5. **Follow TDD**: Tests first, implementation second

## ✅ After Completion

1. **Validate**: Suggest user run validation at appropriate level
2. **Retrospective**: Mine data, produce summary, apply learnings
3. **Update Project Truth**: After validation, update project-level docs
4. **Guide forward**: Suggest next story/epic or higher-level retro

### Updating Project-Level Truth

After story/epic validation, update these project-level documents to reflect current reality:

**When to Update**:
- After `/story-validate` passes for significant features
- After `/epic-validate` completes
- During `/epic-retrospective` or `/project-retrospective`

**What to Update**:
- `project.md` → If project vision/scope evolved
- `PRD.md` → If new features delivered or requirements changed
- `architecture.md` → If architectural patterns added/modified
- `context.md` → If new constraints discovered
- `design-system.md` → If new UI patterns established
- `ux-strategy.md` → If UX principles evolved

**How to Update**:
1. Read validation-report.md to see what actually changed
2. Update relevant sections in project-level docs
3. Add "(Updated after Epic XXX)" or "(Added in Story YYY)" for traceability
4. Update "Last Updated" timestamps
5. Commit with clear message explaining what truth was updated

**Why This Matters**:
- Project-level docs remain **single source of truth** for current state
- New team members read project docs to understand "what exists now"
- Epic/story specs remain as historical **proposals** (what was planned)
- Validation reports capture **deltas** (what actually changed)

Commands contain detailed execution steps - follow them closely.

## 🔄 Brownfield vs Greenfield Approach

**Brownfield** (existing code):
- Flow: import → scan → context (extract) → architecture (document) → plan (organize)
- Extract from code rather than create from scratch

**Greenfield** (new project):
- Flow: specify → clarify → [domain] → [ux] → context → [constitution] → architecture → [design-system] → plan → [roadmap]
- Create from vision rather than extract from code

## 🚀 Follow These Key Principles

### Always Write Spec First
Apply this sequence:
1. Write spec before code
2. Clarify before planning
3. Plan before implementing
4. Validate after implementing

### Always Run Foundation Before Planning
Remember this order:
- UX strategy MUST come before PRD
- Context MUST come before PRD
- Constitution SHOULD come before PRD (if complex project)
- PRD uses these as essential inputs!

### Understand Cascading Retrospectives
Know how learnings flow:
- Story retros mine raw data (.learning.log, commits)
- Epic retros validate patterns across stories (2+ = validated)
- Project retros validate patterns across epics
- Each level improves processes below it

### Default to Simplicity
Apply these rules:
- Default to <100 lines of new code
- Require evidence before adding complexity
- Prefer boring, proven tech
- Apply 10-minute understandability rule (split if longer)

## 🔍 When to Create Spec vs Code Directly

When user makes a request, determine if they need a spec or can code directly:

**Create Spec (Route to /speck)** for:
- ✅ New features or capabilities
- ✅ Breaking changes to existing behavior
- ✅ Architecture or pattern changes
- ✅ Performance optimizations that change behavior
- ✅ Security updates affecting access patterns
- ✅ When unclear or ambiguous (safer to spec)

**Code Directly (No Spec Needed)** for:
- ✅ Bug fixes restoring intended behavior (spec already exists)
- ✅ Typos, formatting, comments
- ✅ Non-breaking dependency updates
- ✅ Adding tests for existing behavior
- ✅ Documentation clarifications
- ✅ Refactoring without behavior change

**Decision Rule**: If it changes user-facing behavior or system architecture → Create spec. If it fixes bugs or polishes existing → Code directly.

## 🔍 How to Respond to User Questions

**"I want to build something"**: 
- Check: New feature or bug fix? (use decision tree above)
- If new feature: Suggest `/speck [description]` to create spec
- If bug fix: Can code directly if spec exists
- You'll route them to the appropriate level

**"I need to understand the project"**: 
- Read and explain `specs/projects/[project-id]/project.md`

**"What's the architecture?"**: 
- Read and explain `architecture.md`
- Or suggest user run `/project-architecture` if not exists

**"How do I test?"**: 
- Read and explain test strategy documentation (TEST_STRATEGY.md files if they exist)
- Check for project-specific Cursor testing rules (if any)

**"What are the constraints?"**: 
- Read and explain `context.md`

**"What's next?"**: 
- Suggest `/speck continue` or show current epic/story status

## ⚠️ Never Do These Things When Executing Commands

**NEVER**:
- ❌ Execute `/project-plan` if context.md doesn't exist (PRD NEEDS constraints!)
- ❌ Skip asking clarification questions (ambiguity causes rework)
- ❌ Modify specs without reading current versions first
- ❌ Generate commits without learning tags when patterns discovered
- ❌ Use arbitrary CSS/style values (use design system tokens only)
- ❌ Create non-idempotent migrations (production risk)
- ❌ Skip tests for convenience (only for TDD - not yet implemented)
- ❌ Start coding without reading spec

## ✅ Always Do These Things When User Triggers Commands

**ALWAYS**:
- ✅ Suggest `/speck` when user unsure which command to use
- ✅ Fetch relevant Cursor rules BEFORE starting work (proactive!)
- ✅ Read existing specs/artifacts before modifying them
- ✅ Suggest retrospectives after completion
- ✅ Follow TDD workflow (tests first)
- ✅ Run validation before considering work complete
- ✅ Include learning tags in generated commits

## 📊 Validate Before Marking Complete

Each level has validation requirements (detailed in validation commands):
- **Story**: Requirements implemented, tests pass, performance met, constitution compliant
- **Epic**: All stories validated, epic goals achieved, integration verified
- **Project**: All epics complete, project goals achieved, end-to-end validated

Always run retrospectives after validation passes.

## 🎓 How Learnings Improve the System

**Story retros** can update:
- Future story specs (non-meta)
- Epic docs (non-meta)
- Flag for epic validation (meta)

**Epic retros** can update:
- Future epic specs (non-meta)
- Project docs (non-meta)
- Story/Epic commands (meta)
- Cursor rules (meta - validated patterns only)

**Project retros** can update:
- Anything (meta - most powerful)
- Speck methodology itself
- Commands/templates at ALL levels
- Guidelines for next project

Remember: Each project makes Speck better. Capture learnings and suggest retrospectives.

## 🔗 Integration Points to Know

- **Git hooks**: May have pre-commit (formatting, linting) and pre-push (tests)
- **Cursor hooks**: Logs file edits to .learning.log automatically + **validates templates**
- **CI/CD**: Check `.github/workflows/` or similar for automation

### Cursor Hook Validation

After every file edit in `specs/`, automated validation runs:
- **Story specs** (spec.md): User story format, scenarios, normative language
- **Epic specs** (epic.md): Overview length, success criteria, dependencies
- **Story plans** (plan.md): Technical approach, simplicity checks, test strategy
- **Story tasks** (tasks.md): Task count, parallel markers, completion %

**Validation Types**:
- ERROR: Must fix (blocks quality)
- WARNING: Should fix (best practice)
- SUCCESS: Check passed

**Benefits**:
- Immediate feedback during writing
- Prevents common mistakes
- Enforces quantitative thresholds
- Non-blocking (guides, doesn't prevent saves)

See `.cursor/hooks/VALIDATION.md` for details.

### Autonomous Development: Cursor + GitHub Copilot

Speck supports **autonomous development** through both **Cursor Background Agents** and **GitHub Copilot Coding Agent**.

**Core Principle**: All runtimes execute the **same commands** from `.cursor/commands/`. 

**When executing commands autonomously**:
1. Read this file (`AGENTS.md`) for methodology
2. Navigate to the story directory
3. Follow the Story-Level Command Flow
4. Execute each command from `.cursor/commands/story-*.md` step-by-step
5. Story is complete when `validation-report.md` exists with PASS status

**Dependency Management**:

Stories declare dependencies in `spec.md` (or `spec-draft.md`) YAML front matter:

```yaml
---
depends_on: [S001, S003]  # Stories that must be validated first
blocks: [S005]            # Stories waiting on this one (informational)
---
```

- The `/story-tasks` command extracts dependencies from `epic-breakdown.md`
- The orchestrator checks dependencies by looking for `validation-report.md` with PASS status
- Blocked stories get `speck:blocked` label
- When dependencies are validated, blocked stories auto-unblock

**Execution Order**: 
- Epics are processed in numeric order (E000, E001, E002...)
- Stories are processed in numeric order within each epic
- Dependencies override numeric order (blocked stories wait)

**Validation**: Run `/story-validate` as the final step. Use validators in `.cursor/hooks/hooks/validators/`

## 📖 Where to Find Information

**Speck Methodology**: @.speck/README.md (complete guide)  
**Command Instructions**: `.cursor/commands/[level]-[command].md`  
**Templates**: `.speck/templates/[level]/`  
**Project Cursor Rules (optional)**: `.cursor/rules/*.mdc`

**Current Project**: `specs/projects/[project-id]/`
- `project.md` (vision)
- `PRD.md` (requirements)  
- `context.md` (constraints)
- `architecture.md` (design)

**Guide Users**: Suggest `/speck continue` or `/speck [description]` based on context

---

**Speck Version**: 4.0.0  
**Updated**: 2025-12-28  
**Methodology**: Speck (Multi-Level with Retrospectives)

**When you have questions**: Ask to explain @.speck/README.md or specific commands from `.cursor/commands/`.

<!-- SPECK:END -->
