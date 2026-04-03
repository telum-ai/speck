<!-- SPECK:START -->

# Speck 🥓 - Speck

You are working in a project using **Speck 🥓**, a multi-level methodology for building software through comprehensive specifications at project, epic, and story levels.

## 🎯 Quick Reference

**When user asks to build something**: Always start with `/speck [description]` - it routes you to the right level  
**When you need methodology details**: Read @.speck/README.md
**When you need skill instructions**: Check `.cursor/skills/[level]-[command]/SKILL.md` (or `.claude/skills/...` in Claude Code)
**When you need templates**: Use files in `.speck/templates/[level]/`

**When executing any Speck command that generates an artifact** (spec.md, plan.md, tasks.md, epic.md, etc.):
1. **Load the skill file** — read `SKILL.md` with the Read tool before taking any action
2. **Read the template file** — listed in the skill as "Step 0" or "CRITICAL: Load and follow the template" — read it NOW before Q&A, before context loading, before writing anything
Skipping either step produces structurally incorrect output. This is not optional for any model.

## 🎚️ Play Levels (READ THIS FIRST — Affects Everything Downstream!)

Speck adapts its rigor to match your project's stage. **Before starting any task in an existing project, check the play level** — it determines which artifacts are required, optional, or skipped entirely.

### How to Detect the Play Level

**Read `.speck/project.json`** in the workspace root:

```json
{ "play_level": "sprint" }   // or "build" or "platform"
```

| Level | When | Required Artifacts | What to Skip |
|-------|------|--------------------|--------------|
| **Sprint** | 1-2 week experiments, simple tools | `PRD.md` (sprint template) + `sprint-log.md` | context, constitution, architecture, design-system, epics, stories |
| **Build** | Products with subscriptions, dashboards, teams | `PRD.md` + `context.md` | constitution, design-system; architecture is optional |
| **Platform** | Enterprise, marketplace, multi-system | Full flow — everything | Nothing |

**⚠️ No `project.json` = Platform** (backward compatible with all pre-6.0 Speck projects)

### Build Complexity Gate (CRITICAL)

**Build-level shortcuts are NOT appropriate for large projects.** If a Build project has **4+ epics**, the following artifacts become **mandatory** (same as Platform):

| Artifact | Why |
|----------|-----|
| `architecture.md` | 4+ epics = multi-system — how do epics connect? Without this, each epic is designed in isolation. |
| `ux-strategy.md` | 4+ epics with UI = real product — how does the user navigate between features? Without this, each epic builds its own disconnected UI. |

**`/project-plan` enforces this**: If play_level is "build" and the plan produces 4+ epics, it MUST warn the user and require architecture.md and ux-strategy.md before proceeding. Otherwise the project risks the **composition fallacy** — each epic passes validation individually, but the product doesn't work as a whole.

**Promote instead**: If a Build project hits 4+ epics, seriously consider `/project-promote` to Platform level rather than patching Build with extra requirements.

### Why This Matters for Reading the Rest of AGENTS.md

The "full Platform flow" described throughout this document (`domain → ux → context → constitution → architecture → design-system → plan`) is **NOT required for Sprint or Build projects**. Whenever AGENTS.md says "REQUIRED" or "CRITICAL", interpret it through the lens of the current play level:

| Claim in docs | Sprint | Build (1-3 epics) | Build (4+ epics) | Platform |
|---------------|--------|-------------------|-------------------|----------|
| `architecture.md` REQUIRED before plan | ✗ Skip | Optional | ✓ Required | ✓ Required |
| `ux-strategy.md` recommended | ✗ Skip | Optional | ✓ Required (if UI) | Optional |
| `constitution.md` recommended | ✗ Skip | ✗ Skip | ✗ Skip | Optional |
| `design-system.md` recommended | ✗ Skip | ✗ Skip | ✗ Skip | Optional |
| Full epic + story artifacts required | ✗ Skip | spec + plan | spec + plan | Full artifacts |

**Abbreviated flows by play level**:
- **Sprint**: `project-specify` → ship it → `project-promote` if it gets traction
- **Build (1-3 epics)**: `specify → clarify → context → [architecture] → plan → epics → stories`
- **Build (4+ epics)**: `specify → clarify → context → ux-strategy → architecture → plan → epics → stories`
- **Platform**: Everything described in the sections below

### Play Level Signals (for NEW projects where `project.json` doesn't exist yet)
- **Sprint**: "this weekend", "48 hours", "quick", "simple tool", "ship it", "prototype"
- **Build**: "subscription", "dashboard", "expand this", multi-user features, v2
- **Platform** (play level): enterprise, marketplace, multi-system, or explicit request for full governance / full foundation flow — *not* the same as "complexity Level 3–4" (see table above)

**Promote** between levels as your project grows: `/project-promote`

### Complexity scale vs play level (two different axes)

Do **not** conflate these — they answer different questions:

| | **Complexity scale (0–4)** | **Play level (Sprint / Build / Platform)** |
|---|---|---|
| **Answers** | How big is the request? **Where** in Speck to work (story vs epic vs project). | How much rigor and which artifacts? **How** to run the methodology. |
| **Stored** | Not persisted — a routing hint from `/speck` and scale analysis. | **`play_level` in `.speck/project.json`** — affects every command. |
| **Examples** | "Add a button" → complexity **1** → story. "Build a SaaS MVP" → complexity **3** → project. | Same SaaS might be **Build** (lighter docs) or **Platform** (full foundation) depending on signals. |

**Important**: Complexity **Level 4** (multi-product ecosystem *scope*) is **not** the same word as play level **`platform`** (full Speck rigor in `project.json`). A complexity **3** full product can still be play level **Build**; the Build **4+ epic gate** then tightens required artifacts.

**Heuristic** (not a rule): Sprint play ↔ tiny scope; Build play ↔ most products; Platform play ↔ enterprise / multi-system / explicit full-governance intent — often overlaps with complexity **3–4**, but **routing is not the same as rigor**.

---

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

> **This is the Platform-level full flow.** Sprint and Build skip significant portions — see the [Play Levels section](#️-play-levels-read-this-first--affects-everything-downstream) above.

1. **Ideation** (optional): brainstorm → loose ideas crystallized into project concepts
2. **Discovery**: specify → clarify
3. **Foundation** *(Platform only)*: [domain (+ research)] → [ux (+ research)] → context (+ research) → [constitution (+ research)]
4. **Technical Design** *(Platform; optional for Build)*: architecture (+ research) → [design-system (+ research)]
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

**Visual Testing Configuration**: Each recipe includes a `visual_testing:` section (platform, strategy, breakpoints, devices). `/story-validate` reads this config and loads the appropriate visual-testing skill. See `.cursor/skills/visual-testing/SKILL.md` and platform-specific skills (`visual-testing-web`, `visual-testing-mobile-flutter`, etc.) for details.

### Skill Files Reference
Skills are in `.cursor/skills/` with `SKILL.md` in each directory:
- **Project**: `project-*/SKILL.md`
- **Epic**: `epic-*/SKILL.md`
- **Story**: `story-*/SKILL.md`

Each skill file contains step-by-step instructions for you to execute when user triggers that skill.

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

*Project skills: `project-*/SKILL.md` in `.cursor/skills/`*

### Epic-Level Command Flow

**Standard Path**:
```
1. epic-specify.md → Creates/enhances epic.md (from project-plan placeholder)
2. epic-clarify.md → Resolves ambiguities
   [OPTIONAL: epic-outline.md → Maps research needs, uses JIT research pattern]
3. [OPTIONAL: epic-constitution.md → Creates constitution.md (epic-specific principles)]
   → USE WHEN: Complex domain/compliance rules, multi-team boundaries, special security/perf requirements
   → SKIP WHEN: Simple epics that follow project constitution without additional constraints
   → **MUST run BEFORE epic-plan** — the tech spec must be written knowing the rules, not the other way around
4. [OPTIONAL: epic-architecture.md → Creates epic-architecture.md (technical design)]
   → RECOMMENDED when: Cross-cutting concerns, new patterns, complex integrations
   → SKIP when: Simple CRUD, follows existing patterns, single-concern epic
5. [IF USER-FACING UI: epic-journey.md + epic-wireframes.md → REQUIRED before plan]
   → Maps the user path through this epic — prevents "each story builds disconnected UI"
   → SKIP ONLY for: backend-only, API-only, CLI-only, infra/devops epics
6. epic-plan.md → Creates epic-tech-spec.md (USES: constitution.md + architecture if available)
7. epic-breakdown.md → Creates epic-breakdown.md (USES: tech-spec + constitution if present)
8. epic-analyze.md → **Pre-implementation quality gate** on planning artifacts (spec + breakdown)
   → Run BEFORE starting any story work; catches spec drift and missing coverage early
9. **[STORY WORK]** → For each story: specify → clarify → plan → [ui-spec] → tasks → analyze → implement → validate → retrospective
10. epic-validate.md → **Post-implementation** completion verification + JTBD walkthrough
    → Run AFTER ALL stories are implemented and their `validation-report.md` shows PASS
    → NOT a planning step — requires working software to validate against
    [AFTER EPIC: epic-retrospective.md → Reads story retros, validates patterns]
```

**⚠️ UX Commands Are REQUIRED for UI Epics — Not Optional**

For any epic with user-facing UI, `/epic-journey` and `/epic-wireframes` are **required** before `/epic-plan`. Without them:
- No user journey is mapped → features exist but aren't connected
- No wireframes exist → each story invents its own UI independently
- The epic passes validation but users can't complete the workflow

This is a hard gate, not a suggestion. Skip only for genuinely non-UI epics.

**Epic Architecture Decision Criteria**:
| Include `/epic-architecture` When | Skip When |
|-----------------------------------|-----------|
| Cross-cutting change (affects 2+ services) | Simple CRUD operations |
| New architectural pattern being introduced | Follows existing project patterns |
| Complex third-party integrations | Single-concern epic |
| Performance-critical with specific targets | Clear implementation path |
| Security-critical epic | UI-only changes |

*Epic skills: `epic-*/SKILL.md` in `.cursor/skills/`*

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
8. story-retrospective.md → Mines git commits → Creates story-retro.md
```

**Decision Gates for Optional/Required Commands**:
| Command | When |
|---------|------|
| `story-outline` | Optional — complex tech decisions, unfamiliar stack, needs research |
| `story-scan` | Optional — brownfield, extending existing codebase |
| `story-ui-spec` | **REQUIRED if story has any user-facing UI.** Skip only for pure backend/API/CLI stories |

**Note**: `story-analyze` is REQUIRED, not optional. It catches issues before implementation.

*Story skills: `story-*/SKILL.md` in `.cursor/skills/`*

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
story-retrospective.md → NEEDS: validation-report.md + git commits
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

For details, see `.cursor/skills/just-in-time-research/SKILL.md`.

## 🔧 Recommended MCP Servers

Configure these in `.cursor/mcp.json` (see `.cursor/MCP-SETUP.md`):

| Server | Purpose |
|--------|---------|
| **Perplexity** | Research, web search, reasoning |
| **GitHub** | PRs, issues, repos, code search |
| **Context7** | Up-to-date library documentation |

All optional but recommended. Speck works without them via fallbacks.

## 📚 Context7 MCP - Up-to-Date Library Documentation

### Critical Rules

- **ALWAYS use Context7** when implementing features with external libraries/frameworks
- **Two-step process**: `resolve-library-id` → `get-library-docs` (or skip to docs if user provides `/org/project` format)
- **Use `topic` parameter** to focus docs (e.g., "routing", "authentication")
- **Prefer Context7** over training data when conflicts arise
- **Fallback**: After 2-3 attempts (try name variants), use `web_search`

### When to Use

**USE for**: Library setup, third-party APIs, configuration, resolving deprecated methods  
**DON'T use for**: Language fundamentals, standard library, project business logic

### Quick Reference

| Library | ID |
|---------|-----|
| Next.js | `/vercel/next.js` |
| React | `/facebook/react` |
| Supabase | `/supabase/supabase` |
| Stripe | `/stripe/stripe-node` |

**Token sizing**: Simple (1-2k), Standard (3-5k), Complex (7-10k)

## 🎯 Agent Skills (Domain Expertise)

Skills are **agent-decided** expertise packages - automatically loaded when relevant to the current task.

**Location**: `.cursor/skills/`

| Category | Examples | When Loaded |
|----------|----------|-------------|
| `external-services/` | Stripe, Supabase, Clerk, AI APIs, Sentry | When working with these services |
| `technologies/` | PWA, Docker, WebSockets, GitHub Actions | When implementing these technologies |
| `domains/` | SaaS billing, multi-tenancy, GDPR | When building domain-specific features |
| `architectures/` | Serverless, offline-first | When designing system architecture |

**Skills complement recipes**: Recipes define WHAT to use; Skills provide HOW to use them effectively.

**Enabling Skills**: Cursor Settings → Rules → Import Settings → Toggle "Agent Skills" on.

See `.cursor/skills/` for details.

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

| Aspect | Skills (`.cursor/skills/`) | Subagents (`.cursor/agents/`) |
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

### Hallucination Chain Prevention

When spawning subagents or receiving their output, prevent hallucination chains:

**Validation Between Agents**:
- **Never trust** subagent output without verification
- **Deterministic checks** between agents where possible (e.g., file exists, tests pass)
- **Cross-validate** critical outputs with different approaches or tools

**Anti-Patterns to Avoid**:
- ❌ Agent A generates code → Agent B builds on it without checking if it compiles
- ❌ Researcher claims a library has a feature → Coder implements without checking docs
- ❌ Multiple agents referencing hallucinated files/functions from earlier in chain

**Verification Strategies**:
| Subagent Output | Verification |
|-----------------|--------------|
| File paths/names | Check file exists with `read_file` or `list_dir` |
| API/library usage | Verify with Context7 or official docs |
| Code correctness | Run linter/compiler/tests |
| Research findings | Cross-check with `web_search` or second source |

**Error Gate Pattern**: For multi-phase workflows, insert verification gates:
```
Phase 1 (Agent A) → [GATE: Verify output] → Phase 2 (Agent B) → [GATE: Verify] → Phase 3
```

If verification fails at any gate, stop and diagnose with `/speck-debug` rather than propagating errors.

### Command-Specific Instructions

Each skill in `.cursor/skills/` contains its own "Subagent Parallelization" section with specific instructions for that skill. Check the skill file for details.

## 🎯 Detect the Right Level (Guide User to Appropriate Command)

Use the **complexity scale (0–4)** below to decide **where** to route (story vs epic vs project). Use **play level** (section at top) for **artifact rigor** — they are independent; see **Complexity scale vs play level** under Play Levels above.

When user makes a request, determine the appropriate **Speck hierarchy** level and suggest:
- **Complexity 0 (Atomic)**: Fix typo, change color → Route to story
- **Complexity 1 (Small)**: Add form, create page → Route to story (within epic)
- **Complexity 2 (Feature set)**: Auth system, shopping cart → Route to epic
- **Complexity 3–4 (Major product / ecosystem)**: Full product, e-commerce site, multi-product ecosystem → Route to project

When unsure, guide user to use `/speck [description]` first — it auto-detects and routes appropriately!

### Project Complexity Scale (Standardized)

| Level | Scope | Examples | Typical Duration | Team Size |
|-------|-------|----------|------------------|-----------|
| **0** | Atomic change | Typo fix, config tweak | Hours | 1 |
| **1** | Single story | Form, button, endpoint | 1-3 days | 1 |
| **2** | Epic/Feature | Auth system, CRUD module | 1-4 weeks | 1-3 |
| **3** | Full product | Complete MVP, SaaS app | 1-3 months | 2-5 |
| **4** | Ecosystem scale | Multi-product ecosystem | 3-12 months | 5+ |

**Note**: Level **4** here = *scope* of the work. It is **not** `play_level: platform` in `.speck/project.json` (that is the *rigor* tier).

This scale is used by:
- `/speck` router for **routing** (which hierarchy level)
- Recipe `complexity.level_range` field
- `/project-specify` for complexity assessment

**Play level** is set separately in `project-specify` (conversation signals) and stored in `.speck/project.json`.

## 💡 Remember These Critical Patterns

### Always Run Foundation BEFORE Planning

> **Play level matters here.** This section describes the Platform-level requirements. Sprint skips all of this. Build skips constitution and design-system (architecture is optional).

At project level, follow this order strictly **(Platform)**:
```
Run: [domain] → [ux] → context → [constitution] → architecture → [design-system] → plan
Why: plan USES these as inputs, and architecture decisions inform planning
```

At project level **(Build)**:
```
Run: context → [architecture] → plan
Why: context is always needed; architecture helps but isn't blocking for Build
```

At project level **(Sprint)**:
```
Run: project-specify (creates PRD + sprint-log) → ship it
Why: No planning overhead — just capture the idea and start building
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

Before running `/project-plan`, ensure the appropriate artifacts exist for the project's **play level**:

**Platform** (all of the below):
- `architecture.md` → **REQUIRED**: Provides architectural decisions and constraints
- `ux-strategy.md` → Provides UX principles and user journeys (optional)
- `context.md` → Provides constraints and non-functional requirements
- `design-system.md` → Provides design tokens and patterns (optional)
- `constitution.md` → Provides technical principles (optional)

**Build** (streamlined):
- `context.md` → **REQUIRED**: Provides constraints
- `architecture.md` → Optional but recommended for complex projects
- (ux-strategy, design-system, constitution → skip)

**Sprint** (no pre-plan artifacts needed):
- `project-specify` creates PRD + sprint-log directly — there is no separate plan phase

**CRITICAL (Platform only)**: Never run `/project-plan` before `architecture.md` — design decisions must inform planning!

**Note**: For Build and Sprint, skipping architecture.md before plan is intentional and correct.

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

Before planning or implementing any UI work, ALWAYS load:
- `specs/projects/[PROJECT_ID]/design-system.md` → tokens, components, patterns
- `specs/projects/[PROJECT_ID]/ux-strategy.md` → UX principles, voice/tone

If either is missing: warn the user and suggest `/project-design-system` or `/project-ux` first.

**Never**: create custom components that already exist in design-system.md, use hardcoded colour values instead of tokens, or design without referencing the grid/spacing/voice from these docs.

## 📊 Learning Capture System (CRITICAL for Retrospectives!)

### Why This Matters
**Retrospectives are only as good as the learnings captured**. Story retrospectives mine commits to extract patterns, gotchas, and insights. Without tagged commits, retrospectives miss valuable learnings!

### Two Data Sources
1. **Commit Message Tags**: You add to commits (see below)
2. **Validation Reports**: Captures spec vs reality gaps

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

- **Story retros** mine commits → produce story-retro.md
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

Integrate JTBD theory into specs to focus on **what users are trying to accomplish**, not how the system works. At each level:
- **Project**: Document the core functional job and desired outcomes
- **Epic**: Identify which project job this addresses, list outcome metrics
- **Story**: Frame user story around the job context, define measurable success

Spec format details (Gherkin, OpenSpec-style requirements, normative language) are in the story-specify skill and spec templates.

## 🎨 Simplicity-First Principles

Default to simple solutions; require **evidence** before adding complexity:
- **Performance evidence**: Measured slowness, not "might be slow at scale"
- **Scale evidence**: Concrete user/load numbers, not "should be scalable"
- **Abstraction evidence**: 3+ existing use cases, not "might reuse someday"

`/story-plan` challenges complexity. `/story-analyze` flags unjustified abstractions. Story names use verb-led prefixes (`add-`, `update-`, `fix-`, `refactor-`). Stories must be explainable in <5 minutes — if it needs "AND", split it.

## 🚦 Decision Gates

### Approval Required Before:
- **Starting implementation**: ALL of the following must exist in the story directory:
  1. `spec.md` with lifecycle state `Specified` — created/completed by `/story-specify` (a Draft placeholder does NOT count)
  2. `plan.md` — created by `/story-plan`
  3. `tasks.md` — created by `/story-tasks`
  4. `analysis-report.md` with no unresolved CRITICALs — created by `/story-analyze`
  
  If a user asks to "implement", "build", or "write the code" for a story and any of these are missing, route to the missing step — never skip ahead to implementation.
- **Starting epic work** (after `/epic-plan` + `/epic-breakdown` + `/epic-analyze`)
- **Production deployment** (after `/project-validate`)

### Validation Gates
- Story: `/story-validate` (requirements, tests, performance, constitution, **user-reachability**)
- Epic: `/epic-validate` (all stories complete, integration verified, **JTBD walkthrough**, **cross-epic integration**)
- Project: `/project-validate` (comprehensive go/no-go decision, **end-to-end JTBD completion**)

## 🧪 Product Coherence Validation (CRITICAL — Prevents the Composition Fallacy)

**The Composition Fallacy**: Each story/epic passes validation individually, but the product doesn't work as a whole. Every API returns 200, every component renders, but no user can complete a workflow.

### The Fix: Top-Down JTBD Walkthrough

**Bottom-up validation** (spec compliance) is necessary but insufficient. Speck also requires **top-down validation** — actually attempting to complete the core JTBD from a user's perspective.

### Story-Level: User Reachability Check

After verifying spec compliance, `/story-validate` MUST also check:

> **"Can a real user reach and use this feature?"**

| Check | Question | FAIL if |
|-------|----------|---------|
| Discoverability | Is this feature reachable from navigation/UI? | Feature exists but has no entry point |
| Auth | Can a user authenticate to reach this? | Feature requires dev-mode headers or hardcoded UUIDs |
| Scaffolding | Are any dev shortcuts still in the UI? | UUID text fields, debug headers, placeholder auth |
| End-to-end | Can a user complete the story's workflow without developer knowledge? | Workflow requires knowing internal IDs or API details |

If any check fails, validation status is **CONDITIONAL_PASS** at best — the code works but the feature isn't usable.

### Epic-Level: JTBD Walkthrough

After all story validations pass, `/epic-validate` MUST perform a **top-down JTBD walkthrough**:

1. **Identify the epic's core JTBD** from `epic.md` — what workflow does this epic enable?
2. **Walk the journey end-to-end** — start from app entry, attempt to complete the full workflow
3. **Check composition** — do the stories connect into a coherent flow, or are they isolated islands?
4. **Verify navigation** — can a user find and move between all features in this epic?
5. **Check auth continuity** — does authentication carry through the entire flow?

**Output**: Include a "JTBD Walkthrough" section in `epic-validation-report.md`:
```
## JTBD Walkthrough

Core Job: [What the user is trying to accomplish]
Entry Point: [Where the user starts]
Path: [Step-by-step journey through the epic's features]

| Step | Action | Result | Status |
|------|--------|--------|--------|
| 1 | Open app | See [what?] | ✅/❌ |
| 2 | Navigate to [feature] | Can find it via [how?] | ✅/❌ |
| ... | ... | ... | ... |

JTBD Completion: [COMPLETE / PARTIAL / BLOCKED]
Blocking Issues: [List if not COMPLETE]
```

**If JTBD completion is BLOCKED or PARTIAL**: Epic validation is **FAIL** regardless of individual story results.

### Epic-Level: Cross-Epic Integration Check

For epics that depend on or are depended on by other epics (per `epics.md` dependency map):

1. **Test the arrows** — if Epic A produces data that Epic B consumes, verify the handoff works end-to-end
2. **Check shared state** — auth tokens, user context, org context carry between epics
3. **Verify navigation** — can users move between features from different epics?
4. **Platform coverage** — if features span web + mobile, verify both platforms connect

### Project-Level: Full JTBD Smoke Test

`/project-validate` MUST include:

1. **Core JTBD walkthrough** — complete the primary job from the project's `project.md`
2. **Cross-epic flow verification** — user journeys that span multiple epics
3. **Platform coherence** — if multi-platform, verify each platform delivers a usable experience
4. **No dead ends** — every reachable feature has a way back, every action has feedback

## 🤖 Model Selection (IMPORTANT!)

Different LLMs excel at different tasks. Prompt the user to switch models when task characteristics indicate a better choice.

**Full Details**: `.cursor/skills/model-selection/SKILL.md`

### Quick Reference

| Task Type | Model | Why |
|-----------|-------|-----|
| Complex architecture | **Opus 4.5** | Deep reasoning |
| Critical code review | **Opus 4.5** | Highest accuracy |
| Security-sensitive | **GPT-5.2 Extra High** | Lowest vulns |
| Standard development | **Sonnet 4.5** | Best balance |
| Story implementation | **Composer 1** | 4x faster in Cursor |
| UI/Frontend "vibe" | **Gemini 3 Flash** | Speed + visual polish |
| Budget-constrained | **Gemini 3 Flash** | Best price/performance |
| Validation | **Different model** | Cross-validation |

### When to Prompt for Switch

**Upgrade to Opus 4.5**: Complex architecture, deep domain (`/project-domain`, `/project-architecture`), critical review  
**Use Composer 1**: `/story-implement`, multi-file editing, rapid prototyping  
**Use Gemini 3 Flash**: Interactive work, quick fixes, budget concerns  
**Cross-validate**: Architecture finalized, security code, pre-deployment

**Avoid** for single-file edits, small features, bug fixes.

## 📚 Key Reference Files

**Methodology**:
- @.speck/README.md - Complete Speck guide (includes Spec-Driven Development philosophy)

**Patterns** (`.cursor/skills/`):
- `visual-testing/` - Autonomous visual testing across platforms
- `model-selection/` - LLM selection guide
- `just-in-time-research/` - Research integration pattern
- `visual-testing-web/` - Web platform visual testing
- `visual-testing-mobile-flutter/` - Flutter visual testing
- `visual-testing-mobile-react-native/` - React Native visual testing
- `visual-testing-desktop-electron/` - Electron visual testing
- `visual-testing-desktop-tauri/` - Tauri visual testing
- `visual-testing-extension/` - Browser extension visual testing

**Learned Patterns** (project-specific):
- `.speck/patterns/learned/` - Patterns validated through retrospectives

**Skills**:
- `.cursor/skills/` - Project-level skills
- `.cursor/skills/` - Epic-level skills
- `.cursor/skills/` - Story-level skills

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

1. **Detect play level**: Read `.speck/project.json` → get `play_level` ("sprint", "build", or "platform"). If missing, default to Platform. This determines which artifacts are required vs. skippable — see the [Play Levels section](#️-play-levels-read-this-first--affects-everything-downstream) at the top of this document.
2. **Determine level**: Project? Epic? Story? (check directory or ask)
3. **Fetch rules**: If the project defines Cursor rules (recommended), read them (commonly under `.cursor/rules/`)
4. **Read artifacts**: spec.md, plan.md, context.md at appropriate level
5. **Verify understanding**: Check all dependencies clear

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

After validation passes, update project-level docs (project.md, PRD.md, architecture.md, context.md, design-system.md, ux-strategy.md) to reflect what actually changed. Project-level docs are the single source of truth for "what exists now" — story/epic specs are historical proposals. The `/story-validate` skill prompts you through this step.

## 🔄 Brownfield vs Greenfield Approach

**Brownfield** (existing code):
- Flow: import → scan → context (extract) → architecture (document) → plan (organize)
- Extract from code rather than create from scratch

**Greenfield** (new project):
- Flow: specify → clarify → [domain] → [ux] → context → [constitution] → architecture → [design-system] → plan → [roadmap]
- Create from vision rather than extract from code

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

**⚠️ Stories always require the full pipeline — no exceptions**:
Even if a story sounds simple or obvious ("just add a button", "add a login form"), it still requires:
`/story-specify` → `/story-plan` → `/story-tasks` → `/story-analyze` → `/story-implement`

"Code Directly" **never** applies to new stories or features. It only applies to the maintenance tasks listed above. If a user asks to "implement story X" or "build feature Y" without a `spec.md`, always route to `/story-specify` first.

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
- ❌ Execute `/project-plan` if context.md doesn't exist and play_level is Build or Platform (PRD NEEDS constraints!)
- ❌ Skip asking clarification questions (ambiguity causes rework)
- ❌ Modify specs without reading current versions first
- ❌ Generate commits without learning tags when patterns discovered
- ❌ Use arbitrary CSS/style values (use design system tokens only)
- ❌ Create non-idempotent migrations (production risk)
- ❌ Skip tests for convenience (only for TDD - not yet implemented)
- ❌ Start coding without reading spec
- ❌ Generate any Speck artifact (spec.md, plan.md, tasks.md, epic.md, analysis-report.md, validation-report.md, etc.) without first reading its template file — generating from memory produces wrong structure
- ❌ Execute a Speck command without loading the corresponding SKILL.md first — skills contain required steps, gates, and template paths that cannot be reconstructed from training data

## ✅ Always Do These Things When User Triggers Commands

**ALWAYS**:
- ✅ Suggest `/speck` when user unsure which command to use
- ✅ Fetch relevant Cursor rules BEFORE starting work (proactive!)
- ✅ Read existing specs/artifacts before modifying them
- ✅ Suggest retrospectives after completion
- ✅ Follow TDD workflow (tests first)
- ✅ Run validation before considering work complete
- ✅ Load the SKILL.md AND read the template before generating any artifact — in that order, before any other action
- ✅ Include learning tags in generated commits

## 📊 Validate Before Marking Complete

Each level has validation requirements (detailed in validation commands):
- **Story**: Requirements implemented, tests pass, performance met, constitution compliant, **user can reach and use the feature** (no dev shortcuts)
- **Epic**: All stories validated, epic goals achieved, integration verified, **JTBD walkthrough passes** (user can complete the full workflow), **cross-epic integration tested**
- **Project**: All epics complete, project goals achieved, end-to-end validated, **core JTBD smoke test passes** (user can complete the product's primary job from scratch)

**CRITICAL**: Bottom-up validation (spec compliance) is necessary but NOT sufficient. Top-down validation (can users actually use this?) is equally required. See the [Product Coherence Validation](#-product-coherence-validation-critical--prevents-the-composition-fallacy) section.

Always run retrospectives after validation passes.

## 🎓 How Learnings Cascade

Story retros → epic retros → project retros. Each level can update the next: story retros flag patterns for epic validation; epic retros can update project docs and Cursor rules; project retros can evolve the Speck methodology itself. Run retrospectives — each project makes Speck better.

## 🔗 Integration Points to Know

- **Git hooks**: May have pre-commit (formatting, linting) and pre-push (tests)
- **Cursor hooks**: Validates spec/plan/task templates on save (see `.cursor/hooks/VALIDATION.md`)
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

**Core Principle**: All runtimes execute the **same skills** from `.cursor/skills/`. 

**When executing commands autonomously**:
1. Read this file (`AGENTS.md`) for methodology
2. Navigate to the story directory
3. Follow the Story-Level Command Flow
4. Execute each skill from `.cursor/skills/story-*/SKILL.md` step-by-step
5. Story is complete when `validation-report.md` exists with PASS status

**Dependency Management**:

Stories declare dependencies in `spec.md` YAML front matter:

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
**Skill Instructions**: `.cursor/skills/[level]-[command]/SKILL.md`  
**Templates**: `.speck/templates/[level]/`  
**Project Cursor Rules (optional)**: `.cursor/rules/*.mdc`

**Current Project**: `specs/projects/[project-id]/`
- `project.md` (vision)
- `PRD.md` (requirements)  
- `context.md` (constraints)
- `architecture.md` (design)

**Guide Users**: Suggest `/speck continue` or `/speck [description]` based on context

---

**Speck Version**: 6.1.14  
**Updated**: 2026-04-02  
**Methodology**: Speck (Multi-Level with Retrospectives)

**When you have questions**: Ask to explain @.speck/README.md or specific skills from `.cursor/skills/`.

<!-- SPECK:END -->
