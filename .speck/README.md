# 🥓 Speck v7 — Promise → Build → Prove

**Speck** is an evidence-driven specification methodology for AI-led software development. It produces excellent products regardless of how hands-on the human is.

> **The shift from v6**: v6 was *spec-driven development* (write specs, then code). v7 is *evidence-driven specification* — every spec assertion compiles to evidence, every claim ties to runtime proof, every truth artifact is SHA-stamped against current HEAD.

---

## 🎯 Quick Start

Just type `/speck` followed by what you want to do:

```
/speck Build a social networking app
/speck Add user authentication
/speck Fix the login button
/speck Import my existing codebase at ~/projects/myapp
/speck Continue from last session
/speck Make this premium and shippable
```

The `/speck` router detects:
- The right level (project / epic / story)
- The right play level (sprint / build / platform)
- The right next command
- Whether you need `/recheck` first (engagement gap detection)

**That's it!** No need to memorize commands — just describe what you want to accomplish.

---

## 📦 Installation & Setup

### First Time Setup

If you're starting a new project with Speck:

```bash
# Initialize Speck in your project
npx github:telum-ai/speck init
```

This sets up:
- Skill files (`.cursor/skills/` and `.claude/skills/`)
- Templates (`.speck/templates/`)
- A **project skeleton** `README.md` at repo root (your product identity — not Speck marketing)
- Validation hooks (`.cursor/hooks/`)
- Update workflows (`.github/workflows/`)

Runtime source of truth:
- Canonical runtime source is `.cursor/skills/` + `.cursor/agents/`
- `.claude/skills/` + `.claude/agents/` are symlinked from `.cursor/` for Claude Code compatibility
- Sync manually with: `bash .speck/scripts/bash/sync-claude-runtime.sh` (manages symlinks)

Instruction source of truth:
- `AGENTS.md` is the single instruction source for both Cursor and Claude Code
- We intentionally avoid `CLAUDE.md` to reduce instruction drift risk

### Claude Code advanced setup (recommended)

To leverage Claude-native features beyond Cursor:
- Subagents via `.claude/agents/` (symlinked from `.cursor/agents/`)
- Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Claude settings baseline at `.claude/settings.json.example`
- Claude hooks/settings scopes (project/user/local) via `.claude/settings*.json`

Start from:
```bash
cp .claude/settings.json.example .claude/settings.json
```

### Recommended: MCP Setup

For the best experience, configure MCP servers for research and documentation:

1. See `.cursor/MCP-SETUP.md` for setup instructions
2. Recommended servers:
   - **Perplexity** — Research and web search
   - **GitHub** — PRs, issues, code search
   - **Context7** — Up-to-date library docs

> Speck works without MCP servers, but they're highly recommended for research capabilities.

---

## 🔄 Keeping Speck Updated

### Automatic Updates (Recommended)

Speck includes a workflow that **automatically checks for updates daily** and creates PRs:

- **Works out of the box** for public Speck repos
- **Smart merging** preserves your customizations
- For private repos: Add `SPECK_GITHUB_TOKEN` secret

### Manual Updates

```bash
# Check for available updates
npx github:telum-ai/speck check

# Upgrade to latest version
npx github:telum-ai/speck upgrade

# Preview changes without applying
npx github:telum-ai/speck upgrade --dry-run

# Upgrade to specific version
npx github:telum-ai/speck upgrade v7.14.2
```

### What Gets Updated

Updates preserve your customizations:
- Your `AGENTS.md` content outside `SPECK:START..END` tags
- Your `.gitignore` entries
- Your custom hooks and MCP config
- Your root `README.md` (project identity — Speck only merges the `<!-- SPECK:START -->` footer)

---

## 🧭 The Mental Model

```
PROMISE          BUILD            PROVE
(the contract) → (the work)   →   (the truth)
                       ↑               │
                       └── drift ──────┘
                              │
                              ↓
                          PROFILE
                     (the public face)
```

Every Speck project lives in this loop:

| Pillar | Purpose | Center-of-gravity artifact |
|--------|---------|----------------------------|
| **PROMISE** | What product are we building? Who pays? What's banned? What's magic? | `product-contract.md` |
| **BUILD** | Implement evidence-producing slices | `spec.md`, `tasks.md`, `experience-chain.md` |
| **PROVE** | Runtime evidence that promise = reality | `project-state.md`, `evidence-contract.md`, runtime LARP |
| **PROFILE** | How the project presents itself to outsiders | Root `README.md` + declared surfaces — **enforced v7.7+** via validators and readiness gates |

The loop closes via drift detection. PROFILE derives from PROMISE + PROVE; `validate-readme.sh` and `profile-drift-check.sh` enforce it at commit and SHIP-RC gates.

---

## 📄 Root README vs `.speck/README.md`

| Context | Root `README.md` | `.speck/README.md` |
|---------|------------------|---------------------|
| **Speck framework repo** (`telum-ai/speck`) | Symlink → `.speck/README.md` | **Canonical** methodology + setup docs (this file) |
| **User projects** (after `speck init`) | **Project identity** — your product, how to run it | Methodology reference — synced by `speck upgrade` |

In the **Speck framework repo**, root `README.md` is a symlink to this file so GitHub visitors and agents see one source of truth. **Do not copy that symlink into user projects** — the CLI sync engine never overwrites a user's root README with Speck marketing.

On `speck init`, Speck writes a **project skeleton** README from `.speck/templates/project/readme-template.md` (not this file). Speck only manages the `<!-- SPECK:START -->` … `<!-- SPECK:END -->` footer on upgrade. The `/project-readme` skill (and `/project-state` regeneration) keeps PROFILE status current.

---

## 🏗️ The Three Levels

```
Project Level (Strategic)
├── Epic Level (Tactical)
└── Story Level (Implementation)
```

- **Project**: Overall product vision, JTBD, magic moments, evidence requirements
- **Epic**: Feature sets that deliver specific JTBD value
- **Story**: Individual implementable slices producing evidence

---

## 🎚️ Play Levels (rigor dial)

Speck adapts artifact depth to project stage. Play level lives in `.speck/project.json` → `play_level`. **Discipline (skeptical review, LARP, audit, decision locks, banned-phrase detection) applies at every level** — only artifact depth changes.

| Level | When | Required PROMISE artifacts | Required PROVE gates |
|-------|------|---------------------------|----------------------|
| **Sprint** | Weekend bets, prototypes, simple tools | `PRD.md` (sprint) + `sprint-log.md` | LARP at validate |
| **Build** | Products with subscriptions, dashboards, teams | `product-contract.md` + `evidence-contract.md` + `context.md` | LARP + `/audit` + decision log + readiness states |
| **Platform** | Enterprise, marketplace, multi-system | Full foundation (incl. domain-model, ux-strategy, design-system, constitution, architecture) | Full PROVE pillar + `/recheck` on every engagement gap |

**Build complexity gate**: If a Build project hits **4+ epics**, `architecture.md` and `ux-strategy.md` become required. Consider `/project-promote` to Platform instead of patching Build.

**Signals for detection**:
- **Sprint**: "this weekend", "48 hours", "quick", "prototype", "simple tool"
- **Build**: "subscription", "dashboard", "expand this", multi-user features
- **Platform**: enterprise, marketplace, multi-system, explicit "full governance"

**Promote between levels**: `/project-promote`. No `project.json` = treated as Platform (back-compat).

---

## 📁 Canonical Directory Structure

```
specs/projects/<PROJECT_ID>/
├── project-state.md            # PROVE: Auto-regenerated single-page status. First read.
├── product-contract.md         # PROMISE: Paid promise, JTBD, magic moments, banned language, AI contract
├── evidence-contract.md        # PROVE: What counts as proof for THIS product
├── project-decisions-log.md    # PROVE: SHA-stamped decisions + alternatives considered
├── project.md                  # PROMISE: Vision (TRUTH)
├── PRD.md                      # PROMISE: Requirements (TRUTH)
├── context.md                  # PROMISE: Constraints (TRUTH)
├── architecture.md             # PROMISE: System design (TRUTH — required for Platform / 4+ epic Build)
├── epics.md                    # BUILD: Epic index
├── constitution.md             # PROMISE: Principles + enforcement (optional at Build)
├── domain-model.md             # PROMISE: Terminology (optional at Build)
├── ux-strategy.md              # PROMISE: UX principles (optional at Build)
├── design-system.md            # PROMISE: Design tokens + primitives index (optional at Build)
├── design-system/primitives.md # BUILD: Live primitive registry (UI projects)
├── personas/<id>.md            # PROVE: Detection signals + LARP script per persona
├── adaptive-axes/<name>.md     # PROMISE: Adaptive behavior decomposition (if product adapts)
├── project-import.md           # Brownfield only
├── project-landscape-overview.md  # Brownfield only
└── epics/E###-name/
    ├── epic.md                 # PROMISE: Epic scope
    ├── experience-chain.md     # BUILD: Required for UI epics
    ├── epic-tech-spec.md       # BUILD: Approach
    ├── epic-breakdown.md       # BUILD: Story mapping
    ├── audit-report.md         # PROVE: Skeptical audit
    ├── epic-validation-report.md  # PROVE: JTBD walkthrough included
    └── stories/S###-name/
        ├── spec.md             # User experience-first spec
        ├── plan.md             # Technical approach
        ├── tasks.md            # Implementation checklist
        ├── audit-report.md     # PROVE: Skeptical audit
        ├── validation-report.md  # PROVE: Evidence + readiness state
        ├── screenshots/        # PROVE: Runtime LARP evidence
        └── larp-recordings/    # PROVE: Recorded execution traces
```

**Naming**: `E###-epic-name`, `S###-story-name`. Shorthand: `E001`, `S001`.

---

## 📋 The Speck Workflow (Build flow shown)

### 1. Project Foundation (PROMISE)

```mermaid
graph TD
    A[/speck Build XYZ] --> B[/project-specify]
    B --> C[/project-clarify]
    C --> D[/project-product-contract]
    D --> E[/project-evidence-contract]
    E --> F[/project-context]
    F --> G{4+ epics<br/>expected?}
    G -->|Yes| H[/project-architecture]
    G -->|Yes| I[/project-ux]
    H --> J[/project-plan]
    I --> J
    G -->|No| J
    J --> K[Epics & E000 Infrastructure]
```

Required artifacts at Build level:
- `product-contract.md` — defines the paid promise, differentiator, banned language, magic moments, JTBD scorecard, AI behavior contract (if AI-using), longitudinal axes (if adaptive)
- `evidence-contract.md` — defines what valid evidence looks like for this product (valid/invalid proof sources, runtime LARP scope, commercial gates, readiness state gate criteria)
- `context.md` — constraints

Optional at Build (required at Platform):
- `architecture.md`, `ux-strategy.md`, `constitution.md`, `design-system.md`, `domain-model.md`

### 2. Epic Work (BUILD)

```mermaid
graph TD
    A[/epic-specify] --> B[/epic-clarify]
    B --> C{UI Epic?}
    C -->|Yes| D[/epic-experience-chain]
    C -->|Yes| E[/epic-journey]
    C -->|Yes| F[/epic-wireframes]
    D --> G[/epic-plan]
    E --> G
    F --> G
    C -->|No| G
    G --> H[/epic-breakdown]
    H --> I[/epic-analyze]
    I --> J[Story Work]
    J --> K[/audit epic-level]
    K --> L[/epic-validate]
    L --> M[/larp full JTBD]
    M --> N[/epic-retrospective]
```

For UI epics, `experience-chain.md` is required before `/epic-plan` (prevents the "seven different apps stitched together" failure).

### 3. Story Work (BUILD → PROVE)

```mermaid
graph TD
    A[/story-specify] --> B[/story-clarify]
    B --> C{Brownfield?}
    C -->|Yes| D[/story-scan]
    C -->|No| E[/story-plan]
    D --> E
    E --> F{UI Story?}
    F -->|Yes| G[/story-ui-spec]
    F -->|No| H[/story-tasks]
    G --> H
    H --> I[/story-implement]
    I --> J[/audit]
    J --> K[/story-validate]
    K --> L[/larp]
    L --> M[/story-retrospective]
```

Note: `/story-analyze` is folded into `/story-tasks` final pass and `/audit` in v7. `/audit` runs **between** implement and validate — it's not optional.

### 4. Reengagement (PROVE)

Any new session reads `project-state.md` first.

If `project-state.md` is missing or stale (>2 weeks since last `verified-against-runtime` stamp, OR a new agent picks up): run `/recheck` before any new feature work.

`/recheck`:
- Compares assertions in truth docs to current HEAD via SHA stamps
- Persona LARP cold-start (does fresh user flow still work?)
- Third-party integration risk surface scan (ToS posture, auth model)
- Constitution/principle compliance scan
- Updates `project-state.md` with findings
- Blocks new feature work until drift is reconciled

---

## ⚖️ Always-On Discipline

These apply at every play level, in every command, on every project — unconditionally:

| Discipline | When | What |
|------------|------|------|
| **First-read state** | Every engagement | Read `project-state.md` before anything else |
| **Engagement-gap recheck** | >2 weeks since verified OR new agent | Run `/recheck` before new work |
| **Decision-lock log** | Every phase boundary | Enumerate decisions, log SHA + alternatives |
| **Skeptical-review** | Before any non-trivial proposal locks | Produce N≥3 alternatives + tradeoff scoring |
| **Skeptical audit** | Between implement and validate | Run `/audit` — auditor doesn't trust implementer |
| **Runtime LARP** | Every UI story/epic validate gate | Run `/larp [persona]` — checked-in evidence |
| **Readiness-state declaration** | At every validate | Declare IMPL-GREEN / UX-RC / COMMERCIAL-RC / SHIP-RC / SHIP / NO-SHIP |
| **SHA stamps** | On every truth artifact write | Footer with `[as of SHA | verified <date>]` |
| **Banned-phrase detector** | In every self-summary | "ready for launch", "outside autonomous reach" etc. trigger re-audit |
| **Banned-language lint** | On every commit + at audit | `banned-language-lint.sh` against product-contract.md |
| **Evidence-or-it-didn't-happen** | Every validation gate | "Tests pass" is one signal, not proof |

---

## 🚦 Readiness States

Replaces single PASS/FAIL with a meaningful gradient:

| State | Meaning | Gate criteria |
|-------|---------|---------------|
| `NO-SHIP` | One or more hard blockers remain | Default when blocked |
| `IMPL-GREEN` | Tests / lint / types pass | Unit + integration green |
| `INTEGRATION-GREEN` | External API/LLM deps exercised for real | Real round-trip smoke per §7 service + live DB schema matches migrations (DB-backed) |
| `UX-RC` / `API-RC` | Primary flows pass in target runtime | Persona LARP (UI) or operational walkthrough (backend) |
| `COMMERCIAL-RC` | Billing / entitlements / support / legal pass | Paid products only — checklist in `evidence-contract.md` |
| `SHIP-RC` | All core gates pass, pending release ops | Runtime LARP against launch build (not dev server) |
| `SHIP` | Production / live proof complete | Post-deploy smoke + healthcheck green |

Validation only marks the claimed state. Never let `IMPL-GREEN` be confused with `SHIP`.

---

## 🆕 Core v7 Concepts

### `product-contract.md` — The PROMISE center of gravity

Merges what was scattered across v6 (domain-model + ux-strategy voice/tone + constitution principles + tone-of-voice + magic moments). The canonical single contract:

- **Paid promise** + primary persona
- **Differentiator** + anti-differentiators ("we are NOT")
- **Inspiration sources** with "principle, not template" frame
- **JTBD scorecard**: functional / emotional / social / trust / commercial
- **Magic moments**: the surfaces a user would pay for
- **Public language** + **banned language** (per locale if multilingual)
- **AI behavior contract** (if AI is user-visible)
- **Longitudinal axes** (if the product adapts over time)

Downstream artifacts MUST reference the product-contract. Stories that violate banned language fail linting.

### `evidence-contract.md` — The PROVE center of gravity

Defines what counts as proof for THIS product:

- Per-platform valid proof sources (e.g., for native iOS: standalone simulator/TestFlight with production-like bundle ID + AXe screenshots + AX trees + native logs)
- Per-platform **invalid** proof sources (e.g., browser localhost ≠ launch proof for native iOS)
- Required runtime LARP scope (which personas, which flows, which platforms)
- Commercial readiness gates (for paid products)
- Readiness state gate criteria

### `project-state.md` — The auto-regenerated agent first-read

A single-page status doc that any AI reads on engagement:

- **Current state**: what's built, validated, drifted
- **Open questions** awaiting user decision
- **Locked decisions** with rationale (linked to `project-decisions-log.md`)
- **Known issues** (severity-ranked, from recent `/recheck`)
- **Next action**: what the last session ended on / what the next should pick up
- **Truth staleness** flags (any SHA stamps that drifted from HEAD)

Replaces ad-hoc handoff docs, ad-hoc summaries, and human reconstruction. Auto-regenerates on truth-affecting commands.

### `/recheck`, `/larp`, `/audit` — The PROVE commands

- **`/recheck`**: Engagement-gap drift detector. Mandatory on >2-week gap or new-agent pickup. Compares truth-doc assertions to current HEAD, runs persona LARP cold-start, scans for security/legal red flags.
- **`/larp`**: First-class persona-based runtime LARP. Recipe-driven (uses `visual_testing` config). Produces checked-in evidence: screenshots, AX trees, transcripts, timings, taste notes. Required at every UI validate gate.
- **`/audit`**: Adversarial skeptical audit between `implement` and `validate`. Required for every epic. Auto-checks: adversarial inputs, dep failure modes, concurrency, N+1, env vars, observability reach, related-table cascade behavior.

### `experience-chain.md` — Required for UI epics

Defines the seams between screens so each story doesn't get optimized in isolation:

- Entry state per screen
- Single job per screen
- Emotional state on arrival vs handoff
- First-time / returning / interrupted / resumed variants
- No-repetition rule between adjacent screens
- "Why now?" for the first viewport

Without `experience-chain.md`, UI epics build "seven different apps stitched together."

### `design-system/primitives.md` — The live registry

Eagerly maintained list of required UI primitives (PageHeader, Section, Eyebrow, StatGrid, EmptyState, ActionGroup, FormField, etc.). UI stories MUST use registered primitives. `/audit` greps for inline-styled re-implementations. Prevents drift across pages.

---

## 🚀 Where Things Live

| Want to... | Look here |
|------------|-----------|
| Find a skill | `.cursor/skills/<skill>/SKILL.md` |
| Find a template | `.speck/templates/{project,epic,story}/` |
| Find a recipe (stack starting point) | `.speck/recipes/` |
| Read learned cross-project patterns | `.speck/patterns/learned/` |
| Configure project Cursor rules | `.cursor/rules/*.mdc` |
| See AGENT routing rules | `AGENTS.md` (workspace root) |
| Run drift detection manually | `.speck/scripts/staleness-check.sh` |
| Run banned-language lint manually | `.speck/scripts/banned-language-lint.sh` |
| Migrate v6 project to v7 | `/speck-migrate` |

---

## 🔌 MCP Servers (all optional)

Configure in `.cursor/mcp.json` (see `.cursor/MCP-SETUP.md`):

| Server | Purpose |
|--------|---------|
| **Perplexity** | Just-in-time research; embedded in commands as needed |
| **GitHub** | PRs, issues, repos |
| **Context7** | Up-to-date library documentation (always prefer over training data) |

Speck works without them via fallbacks.

---

## 📊 Commit Learning Tags

When committing, ALWAYS add tags if you discovered something:

| Tag | Use for |
|-----|---------|
| `PATTERN:` | Reusable code pattern discovered |
| `GOTCHA:` | Surprise or pitfall encountered |
| `PERF:` | Performance insight or optimization |
| `ARCH:` | Architecture decision or structural insight |
| `RULE:` | Cursor rule update needed |
| `DEBT:` | Technical debt created (with reason) |

Example:
```
git commit -m "feat(matching): implement overlap detection

PATTERN: Window functions for time overlaps - 10x faster than Python
PERF: Query time 500ms → 50ms with proper indexing
GOTCHA: Timezone must be normalized before comparison
"
```

These feed retrospectives. Without tags, learnings are lost.

---

## 🚨 Critical Rules (NEVER / ALWAYS)

**NEVER**:
- Skip reading `project-state.md` on engagement
- Skip `/recheck` on engagement gap >2 weeks or new-agent pickup
- Mark a validation gate passed without checked-in evidence
- Use dev-server screenshots as launch proof for native apps
- Create non-canonical filenames in `specs/` (use the routing table in AGENTS.md)
- Claim `SHIP-RC` based on dev-mode evidence
- Generate a Speck artifact without reading its template and SKILL.md first
- Run `/project-plan` before required PROMISE artifacts exist
- Skip `/audit` between implement and validate
- Trust historical PASS docs over current runtime proof

**ALWAYS**:
- Read `project-state.md` first
- Read SKILL.md AND template before generating an artifact
- Stamp truth artifacts with `[as of SHA <hash> | verified <date>]`
- Surface 3+ alternatives at non-trivial decisions
- Run `/larp` on UI stories at validate time
- Run `/audit` between implement and validate
- Declare a readiness state at every validate gate
- Log decisions to `project-decisions-log.md` at phase boundaries
- Add commit learning tags when you discover something
- Treat AI-generated user-facing text as governed product copy

---

## 🔄 Migrating from v6 — a two-step process

Migration is **automatic on `npx github:telum-ai/speck upgrade`** when crossing the v6 → v7 boundary, but it has two distinct phases:

### Step 1 — Scaffolding (automatic, runs by the CLI)

`bash .speck/scripts/migrate.sh <project-dir>` (invoked automatically per project):

1. Adds `speck_version: 7.0.0` to `.speck/project.json`
2. Scaffolds **empty** templates: `product-contract.md`, `evidence-contract.md`, `project-decisions-log.md`, `project-state.md`, `design-system/primitives.md` (each with a `<!-- v7 MIGRATION SCAFFOLD -->` banner)
3. SHA-stamps existing v6 truth artifacts (`project.md`, `PRD.md`, `architecture.md`, etc.) with current HEAD
4. Writes a `migration-report.md` per project
5. Drops a `.speck/.migration-needs-catchup` marker at workspace root
6. **Does NOT delete any v6 content**

### Step 2 — Catch-up (brownfield reconstruction — `/speck-catch-up`)

This is where the actual work happens. The next time any agent engages the project, AGENTS.md's first-action rule detects the marker and runs `/speck-catch-up` automatically. The skill:

1. **Backfills `product-contract.md`** from `project.md` + `PRD.md` + `ux-strategy.md` + `domain-model.md` + `constitution.md`
2. **Backfills `evidence-contract.md`** from the active recipe's `evidence_contract:` block (every recipe ships per-platform defaults)
3. **Reconstructs `project-decisions-log.md`** from git history (architecture / design-system / plan commits + commit learning tags)
4. **Backfills `experience-chain.md`** for each existing UI epic from `user-journey.md` + `wireframes.md` + story specs
5. **Honesty pass** — for each existing story marked PASS in v6: cross-references with `evidence-contract.md`, downgrades unsupported claims to `IMPL-GREEN`, flags surrogate proof
6. **Regenerates `project-state.md`** with the post-honesty-pass reality
7. **Writes `project-catch-up-plan.md`** with prioritized remediation work (P0–P3)
8. Removes the `.speck/.migration-needs-catchup` marker

**Without `/speck-catch-up`, a migrated project carries v6 debt under v7 paint.** The scaffolded templates are empty, the old PASS claims still stand, and the seven v6 failure modes are still latent. The skill is mandatory for any project that wasn't built v7-native from day one.

### v6 command compatibility

v6 commands (`/story-analyze`, `/epic-outline`, `/story-outline`, `/project-scan`, etc.) continue to work via shims that route to v7 equivalents (with deprecation warnings in their description).

---

## 📚 Learn More

- **AI agent rules**: `AGENTS.md` (workspace root) — the table-of-contents the agent reads on every task
- **Setup MCP**: `.cursor/MCP-SETUP.md`
- **Recipes**: `.speck/recipes/README.md`
- **Patterns library**: `.speck/patterns/learned/README.md`

---

## 🛠️ Development

For contributing to Speck itself (CLI, sync system, versioning, releases), see **[DEVELOPMENT.md](../DEVELOPMENT.md)**.

## 🤝 Contributing Methodology Insights

After running retrospective commands (`/story-retrospective`, `/epic-retrospective`, `/project-retrospective`), you can opt-in to share methodology insights with the Speck team. Only process improvements are shared — no project-specific data.

---

**Need help?** Just type `/speck` and describe what you want to build. Speck will guide you through the rest!

**Speck Version**: 7.14.2
**Methodology**: Promise → Build → Prove + Profile (evidence-driven specification)
