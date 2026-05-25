<!-- SPECK:START -->

# Speck 7 — Promise → Build → Prove

You are working in a project using **Speck 🥓 v7**, an evidence-driven specification methodology.

**Speck's core promise**: produce excellent products regardless of how hands-on the human is. The discipline (decision logs, skeptical audits, runtime LARP, evidence gates, drift detection) is **unconditional** — not a mode you opt into.

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

| Pillar | Purpose | Center-of-gravity artifact |
|--------|---------|----------------------------|
| **PROMISE** | What product are we building? Who pays? What's banned? What's magic? | `product-contract.md` |
| **BUILD** | Implement evidence-producing slices | `spec.md`, `tasks.md`, `experience-chain.md` |
| **PROVE** | Runtime evidence that promise = reality | `project-state.md`, `evidence-contract.md`, runtime LARP |
| **PROFILE** | How the project presents itself to outsiders (GitHub, npm, first-time contributors) | Root `README.md` (managed footer + workflow-driven scaffold) |

> Every spec assertion compiles to evidence. Every evidence claim ties to runtime proof. Every truth artifact is SHA-stamped against current HEAD. PROFILE surfaces derive from PROMISE + PROVE — drift between README and contracts is externally embarrassing; `/recheck` flags it.

## 🚦 First Actions on Any Engagement

Run these checks **in order**. Stop at the first hit, run the indicated skill, then resume the list.

1. **Catch-up needed?** Check `.speck/.migration-needs-catchup`. If the file exists OR any of `product-contract.md`, `evidence-contract.md`, `project-state.md` contains the literal text `<!-- v7 MIGRATION SCAFFOLD -->` → run `/speck-catch-up` BEFORE anything else. The project was just migrated from v6 and the artifacts are empty scaffolds. No feature work, no implementations, no validation gates until catch-up is done.
2. **Read `specs/projects/<PROJECT_ID>/project-state.md`** if it exists (single page, current state, open questions, locked decisions, known issues, next action). This is always your first read once catch-up is clear.
3. **Detect play level** from `.speck/project.json` → `play_level` (sprint/build/platform). No file = platform.
4. **Detect engagement gap**. If `project-state.md` is missing, stale (>2 weeks), or you're a new agent picking up: route to `/recheck` before any new feature work.
5. **Then proceed** with whatever the user asked for.

## 🎚️ Play Levels (affects rigor, not discipline)

| Level | When | Required PROMISE | Optional PROMISE | Discipline (PROVE) |
|-------|------|------------------|-------------------|----------------------|
| **Sprint** | Weekend bets, prototypes, simple tools | `PRD.md` (sprint) + `sprint-log.md` | none | LARP at validate |
| **Build** | Products with subscriptions, dashboards, teams | `product-contract.md` + `context.md` + `evidence-contract.md` | architecture (req. if 4+ epics), constitution, design-system, domain-model | LARP + `/audit` + decision log + readiness states |
| **Platform** | Enterprise, marketplace, multi-system | Full Platform flow | n/a — full flow | Full PROVE pillar; `/recheck` on every engagement gap |

Discipline (skeptical review, LARP, audit, decision locks, banned-phrase detection) applies at **all** levels — the difference is the artifact depth and number of gates, not their existence.

**Build complexity gate**: If a Build project hits **4+ epics**, `architecture.md` and `ux-strategy.md` become **required** (composition fallacy prevention). Consider `/project-promote` to Platform instead of patching Build.

## 📁 Canonical Directory Structure

```
specs/projects/<PROJECT_ID>/
├── project-state.md            # PROVE: Auto-regenerated, single page. First read on engagement.
├── product-contract.md         # PROMISE: Paid promise + JTBD + magic moments + banned language + AI contract (v7 core)
├── evidence-contract.md        # PROVE: What counts as proof for this product (v7 core)
├── project-decisions-log.md    # PROVE: Decision locks with SHA + alternatives (v7 core)
├── project.md                  # PROMISE: Vision (current state — TRUTH)
├── PRD.md                      # PROMISE: Requirements (current state — TRUTH)
├── context.md                  # PROMISE: Constraints (current state — TRUTH)
├── architecture.md             # PROMISE: System design (current state — TRUTH; req. Platform / 4+ epic Build)
├── epics.md                    # BUILD: Epic index
├── constitution.md             # PROMISE: Principles + enforcement mechanisms (optional at Build)
├── domain-model.md             # PROMISE: Terminology (optional at Build; merged into product-contract)
├── ux-strategy.md              # PROMISE: UX principles (optional at Build; merged into product-contract)
├── design-system.md            # PROMISE: Design tokens + primitives index (optional at Build)
├── design-system/
│   └── primitives.md           # BUILD: Live primitive registry (UI projects)
├── personas/<id>.md            # PROVE: Detection signals + LARP script per persona
├── adaptive-axes/<name>.md     # PROMISE: Adaptive behavior decomposition (if product adapts)
├── project-import.md           # Brownfield only
├── project-landscape-overview.md  # Brownfield only
└── epics/E###-name/
    ├── epic.md                 # PROMISE: Epic scope
    ├── experience-chain.md     # BUILD: Required for UI epics (v7)
    ├── epic-tech-spec.md       # BUILD: Approach
    ├── epic-breakdown.md       # BUILD: Story mapping
    ├── epic-validation-report.md  # PROVE: JTBD walkthrough included
    └── stories/S###-name/
        ├── spec.md             # PROMISE+BUILD: User experience-first spec (v7 reorder)
        ├── plan.md             # BUILD: Technical approach
        ├── tasks.md            # BUILD: Implementation checklist
        ├── audit-report.md     # PROVE: Skeptical audit (v7)
        ├── validation-report.md  # PROVE: Evidence-backed, declares readiness state
        ├── screenshots/        # PROVE: Runtime LARP evidence (checked in)
        └── larp-recordings/    # PROVE: Recorded execution traces
```

**Naming**: `E###-epic-name`, `S###-story-name`. Shorthand: `E001`, `S001`.

## 🗺️ Canonical-Doc Routing (FORBID non-canonical filenames in `specs/`)

When you have content to write down, route it to its canonical home. **Never invent a new filename** in `specs/`. If you can't find a canonical home below, you've misidentified the content type — re-read this table, then ask the user before creating anything bespoke.

### Project-level (`specs/projects/<id>/`)

| Content type | Canonical home |
|---|---|
| Project vision changes | `project.md` |
| Requirements/features delivered | `PRD.md` |
| Architectural decisions | `architecture.md` |
| Constraints discovered | `context.md` |
| Paid promise / differentiator / JTBD / magic moments / banned language | `product-contract.md` |
| Proof requirements / readiness gates / valid/invalid evidence sources | `evidence-contract.md` |
| Phase-boundary decisions (locked) | `project-decisions-log.md` |
| Current state for next-session pickup (auto-regen) | `project-state.md` |
| Drift / re-engagement report | `project-recheck-report.md` |
| Project-level skeptical audit findings | `project-audit-report.md` |
| Project punch list (remaining work to ship) | `project-punch-list.md` |
| Sprint progress (Sprint play level only) | `sprint-log.md` |
| Domain terminology + entities + rules (Platform; merges to product-contract at Build) | `domain-model.md` |
| UX principles + voice/tone (Platform; merges to product-contract at Build) | `ux-strategy.md` |
| Technical principles (Platform; optional Build) | `constitution.md` |
| Design tokens / system (Platform; optional Build) | `design-system.md` |
| Live UI primitives registry (UI projects, all levels) | `design-system/primitives.md` |
| Per-persona detection + LARP script | `personas/<id>.md` |
| Adaptive behavior axes | `adaptive-axes/<name>.md` |
| Project retrospective | `project-retro.md` |
| Project validation evidence | `project-validation-report.md` |
| Project-level research report | `project-*-research-report-*.md` |
| Brownfield non-code import | `project-import.md` |
| Brownfield landscape overview | `project-landscape-overview.md` |
| Methodology learnings to feed back | (don't create file — use `/speck-learn`) |

### Workspace-level (repo root — not under `specs/`)

| Content type | Canonical home |
|---|---|
| GitHub / public project identity | Root `README.md` (user-owned body; Speck manages `<!-- SPECK:START -->` footer) |
| Agent methodology instructions | `AGENTS.md` (Speck manages `<!-- SPECK:START -->` block) |
| Speck methodology reference | `.speck/README.md` (always methodology — never project identity) |

### Epic-level (`specs/projects/<id>/epics/E###-name/`)

| Content type | Canonical home |
|---|---|
| Epic scope + value proposition | `epic.md` |
| Epic-specific principles (rare) | `constitution.md` (epic-level) |
| Epic-specific context (rare) | `context.md` (epic-level) |
| Epic technical architecture (cross-cutting epics) | `epic-architecture.md` |
| Epic technical approach (output of epic-plan) | `epic-tech-spec.md` |
| Story map + ordering | `epic-breakdown.md` |
| Cross-screen UI flow + emotional state (REQUIRED for UI epics) | `experience-chain.md` |
| User journey map | `user-journey.md` |
| Wireframes (epic-level) | `wireframes.md` |
| Epic-level skeptical audit findings | `audit-report.md` |
| Epic validation report (JTBD walkthrough) | `epic-validation-report.md` |
| Epic-level pre-impl analysis (v6) | `epic-analysis-report.md` |
| Epic retrospective | `epic-retro.md` |
| Epic-scoped research report | `epic-*-research-report-*.md` |
| Brownfield epic-scoped code scan | `epic-codebase-scan*.md` |

### Story-level (`specs/projects/<id>/epics/E###-name/stories/S###-name/`)

| Content type | Canonical home |
|---|---|
| Story requirements + acceptance LARP + evidence required | `spec.md` |
| Story technical design | `plan.md` |
| Implementation task checklist | `tasks.md` |
| Data model | `data-model.md` |
| API/library contracts | `contracts/*.md` |
| UI spec (REQUIRED for UI-bearing stories) | `ui-spec.md` |
| Test scenarios / quickstart / manual validation | `quickstart.md` |
| Story-level skeptical audit findings | `audit-report.md` |
| Story validation evidence (declares readiness state) | `validation-report.md` |
| Story retrospective | `story-retro.md` |
| Runtime LARP screenshots / recordings (checked-in evidence) | `screenshots/`, `larp-recordings/`, `larp-evidence/` |
| Story-scoped research report | `story-*-research-report-*.md` |
| Brownfield story-scoped code scan | `codebase-scan-*.md` |

If a user requests bespoke docs (e.g., "create a positioning brief", "make a launch plan doc") — route the content into the canonical home and tell them where it landed. The ONLY exception is the user explicitly authoring a one-off note to themselves that should NOT inform agent decisions; in that case, name it `notes/<topic>.md` and exclude it from canonical reads.

## 📋 The Speck Command Phases

> Read each phase's `SKILL.md` for the full procedure. AGENTS.md only lists the **what** and **order**. The skill files contain the **how**.

### Sprint flow
```
/project-specify  →  ship it  →  /project-promote (if it gets traction)
```

### Build flow (1-3 epics)
```
/project-specify → /project-clarify → /project-product-contract → /project-readme → /project-evidence-contract
  → /project-context → [/project-architecture if cross-system]
  → /project-plan (creates PRD + epics + E000 infrastructure epic)
  → per epic: /epic-specify → /epic-clarify → [/epic-architecture] → [/epic-experience-chain if UI]
              → /epic-plan → /epic-breakdown → /epic-analyze
  → per story: /story-specify → /story-clarify → [/story-scan] → /story-plan
              → [/story-ui-spec if UI] → /story-tasks → /story-implement
              → /audit → /story-validate → /larp → /story-retrospective
  → /audit (epic-level) → /epic-validate → /larp (full JTBD walkthrough) → /epic-retrospective
  → /project-validate → /project-retrospective
```

### Build flow (4+ epics) — gate triggers required architecture + ux-strategy
Same as Build but `/project-architecture` and `/project-ux` are required before `/project-plan`.

### Platform flow
Full flow: includes `/project-domain` → `/project-ux` → `/project-context` → `/project-constitution` → `/project-architecture` → `/project-design-system` → `/project-product-contract` → `/project-readme` → `/project-evidence-contract` → `/project-plan` → `/project-roadmap`. `/project-state` keeps README status current after validation gates.

### Reengagement
On any new session: read `project-state.md`. If missing or stale (>2 weeks since last verified-against-runtime), run `/recheck` before any feature work.

## ⚖️ Always-On Discipline (unconditional, regardless of human hands-on intensity)

These apply at every play level, in every command, on every project:

| Discipline | When | What |
|------------|------|------|
| **Catch-up first** | After v6 → v7 migration | If `.speck/.migration-needs-catchup` exists OR truth artifacts still carry the `v7 MIGRATION SCAFFOLD` banner → run `/speck-catch-up` BEFORE any feature work |
| **First-read state** | Every engagement | Read `project-state.md` before anything else |
| **Engagement-gap recheck** | >2 weeks since last verified-against-runtime stamp OR new agent | Run `/recheck` to detect drift before new feature work |
| **Decision-lock log** | Every phase boundary | Enumerate decisions, log SHA + alternatives in `project-decisions-log.md` |
| **Skeptical-review** | Before any non-trivial proposal locks | Produce N≥3 alternatives + tradeoff scoring + rationale |
| **Skeptical audit** | Between `implement` and `validate` | Run `/audit` — auditor doesn't trust the implementer's report |
| **Runtime LARP** | Every UI story/epic validate gate | Run `/larp [persona]` — produces checked-in evidence |
| **PROFILE drift check** | Every `/recheck` | Compare root README one-liner vs `product-contract.md`; refresh via `/project-readme` when placeholders remain |
| **Readiness-state declaration** | At every validate | Claim one of IMPL-GREEN / UX-RC / COMMERCIAL-RC / SHIP-RC / SHIP / NO-SHIP |
| **SHA stamps** | On every truth artifact write | Footer with `[as of SHA <hash> | verified against runtime <date>]` |
| **Banned-phrase detector** | In every agent self-summary | Phrases like "ready for launch", "outside autonomous reach", "premium polish complete", "should work in production", "tests pass therefore done" trigger re-audit or enumeration |
| **Banned-language lint** | On every commit + at `/audit` | Run `.speck/scripts/banned-language-lint.sh` against `product-contract.md` banned terms |
| **Evidence-or-it-didn't-happen** | At every validation gate | "Tests pass" is one signal, not proof. Require runtime evidence linked to claim. |

A more hands-on human intervenes at decision locks. A more hands-off human lets the agent confirm and proceed. **Same methodology either way.**

## 🚦 Readiness States (the new PASS/FAIL taxonomy)

| State | Meaning | Gate criteria |
|-------|---------|---------------|
| `NO-SHIP` | One or more hard blockers remain | Default when blocked |
| `IMPL-GREEN` | Tests / lint / types pass | Unit + integration green |
| `UX-RC` | Primary user flows pass in target runtime | Persona LARP recorded against built artifact (not dev server) |
| `COMMERCIAL-RC` | Billing / entitlements / support / legal pass | Paid products only — checklist in `evidence-contract.md` |
| `SHIP-RC` | All core gates pass, pending release ops | Runtime LARP against launch build (not dev server) |
| `SHIP` | Production / live proof complete | Post-deploy smoke + healthcheck green |

Stories/epics/projects declare which state they're claiming. Validation only marks the claimed state. **Never let `IMPL-GREEN` be confused with `SHIP`.**

## 🧠 Context-Rot Defenses

Context rot is real — old decisions get deprioritized as tokens accumulate. Speck v7 fights it structurally:

- **Layered loading**: `project-state.md` first (one page). Load deeper docs only when the active skill needs them. **Never** pre-load all foundation docs at task start.
- **File-size discipline**: This file (AGENTS.md) is the table of contents. SKILL.md files target ~150 lines. Templates are checklists, not narratives.
- **Auto-regenerated state**: `project-state.md` updates on every truth-affecting command. Replaces ad-hoc handoff docs and human reconstruction.
- **SHA-stamped truth**: Stale truth artifacts revert to "proposal" status and cannot serve as inputs to downstream decisions until re-verified.
- **Fresh windows per phase**: For large features, break into phases that complete within a fresh context window. Use `project-state.md` as the persistent foundation across resets.
- **No bespoke docs**: All `specs/` content routes to canonical homes (see table above). No `positioning-brief.md`, no `premium-launch-plan-2026-04-23.md`.

## 🔌 MCP Servers (configure in `.cursor/mcp.json` — all optional)

| Server | Purpose |
|--------|---------|
| **Perplexity** | Just-in-time research; embedded in commands as needed |
| **GitHub** | PRs, issues, repos |
| **Context7** | Up-to-date library documentation (always prefer over training data for library specifics) |

See `.cursor/MCP-SETUP.md` for setup.

## 🎛️ Host Capability Matrix

Speck is designed to run seamlessly across all major AI coding environments. Core behavioral expectations, artifact rules, and evidence requirements are identical, while each environment offers different optional accelerators.

| Capability | Claude Code | Cursor | Codex |
|------------|-------------|--------|-------|
| **Core Process Commands** | ✅ Supported (via `.claude/skills/`) | ✅ Supported (via `.cursor/skills/`) | ✅ Supported (via `.codex/skills/`) |
| **Local MCP Config** | `.mcp.json` (root) | `.cursor/mcp.json` | Host-specific config |
| **Automatic Template Linting** | ✅ `PostToolUse` edit hooks | ✅ `afterFileEdit` hooks | Manual or CI-driven checks |
| **Structured Workflows** | ✅ `/loop` maintenance, `/goal` | Manual or scheduled CI | Manual or scheduled CI |
| **Custom Agent Roles** | ✅ `speck-*` subagents checked in | Optional `.cursor/rules/` | Optional skills guidelines |
| **Isolated Implementations** | ✅ `isolation: worktree` | Fallback to main branch | Fallback to main branch |

### Portability Guarantees & Fallbacks
1. **Shared Validation Engine**: All validation hooks (`validate-template.sh`) route to a unified, host-agnostic bash core inside `.speck/scripts/validation/`.
2. **Subagents Fallback**: Spawning parallel subagents (e.g. `speck-auditor`, `speck-scanner`) is a Claude-specific optimization. When executing on Cursor or Codex, checklists run sequentially in the main conversation.
3. **CI Backstop**: Regardless of local host hooks or capabilities, the ultimate validation gate is portable and runs in your standard CI pipeline (`.github/workflows/speck-validation.yml`).

## 🦾 Claude-First Autonomous & Agentic Workflows

When running Speck with Claude Code, the methodology provides first-class autonomous features to dramatically accelerate development loops without sacrificing rigor.

### 🎭 Specialized Subagents
Speck defines five custom subagents in `.claude/agents/` that can be invoked via `@-mentions` or deployed as peer reviewers on an agent team:
* **`@speck-scribe`**: Drafts and refines `spec.md` and `epic.md` using precise normative language (`SHALL/MUST`).
* **`@speck-planner`**: technical planning (`plan.md`, `epic-tech-spec.md`) and task lists (`tasks.md`) enforcing simplicity-first principles and TDD.
* **`@speck-coder`**: Implements code in isolated, conflict-free environments using git worktrees (`isolation: worktree`).
* **`@speck-auditor`**: Conducts adversarial audits and drafts `audit-report.md`.
* **`@speck-validator`**: Validates readiness, executes persona LARP, and stamps evidence files.

### 🚀 Agent Teams
Leverage Claude's session orchestration to run multi-perspective teammate sessions (e.g. peer review / dual implementation) concurrently:
```text
Create an agent team to design and build story S005. Assign one teammate as a @speck-coder to implement the service and another as a @speck-auditor to review edge-cases.
```

### 🔄 Speck Maintenance Loops
You can start a scheduled workspace babysitting or maintenance loop. This executes `.claude/loop.md` to run test suites, check for spec drift, and scan for scaffolding tokens dynamically:
```text
/loop 1h
```

### 🎯 Exit/Stop Verification Gates
Our `Stop` hooks act as deterministic safeguards. Whenever you instruct Claude to finish or stop, a background validation is triggered to ensure tasks are completed, lints are green, and decisions log boundaries are fully respected before allowing the session to exit.

## 🧪 Agent Skills

Skills are agent-decided expertise packages — auto-loaded when relevant.

- **Process skills** (`speck-*`): `/speck`, `/recheck`, `/larp`, `/audit`, `/speck-debug`, `/speck-learn`
- **Level commands** (`project-*`, `epic-*`, `story-*`): the Speck workflow
- **Domain patterns** (`.cursor/skills/patterns/`): Stripe, Clerk, Supabase, Firebase, RevenueCat, etc. — lazy-loaded when implementing those integrations

Commands are invoked by reading the corresponding `SKILL.md` file. **Always read the skill AND the template before generating any artifact** — never reconstruct from training data.

## 🚨 Critical Rules

**NEVER**:
- Skip reading `project-state.md` on engagement
- Skip `/recheck` on engagement gap >2 weeks or new-agent pickup
- Mark a validation gate passed without checked-in evidence
- Use dev-server screenshots as launch proof for a native app
- Edit a scorecard upward without product changes and fresh validation
- Create non-canonical filenames in `specs/` (use the routing table)
- Claim `SHIP-RC` based on dev-mode evidence — must be the launch build
- Generate a Speck artifact without reading its template and SKILL.md first
- Run `/project-plan` before required PROMISE artifacts exist (varies by play level)
- Skip the skeptical audit (`/audit`) between implement and validate
- Let "outside autonomous reach" stand without enumerating what CAN be done autonomously
- Trust historical PASS docs over current runtime proof
- Allow generic AI cheerleading copy in user-visible surfaces for premium products
- Hand-wave dev/prod separation as "cleanup work" — it's infrastructure

**ALWAYS**:
- Read `project-state.md` first
- Read SKILL.md AND template before generating an artifact
- Stamp truth artifacts with `[as of SHA <hash> | verified <date>]`
- Surface 3+ alternatives at non-trivial decisions
- Run `/larp` on UI stories at validate time
- Run `/audit` between implement and validate
- Declare a readiness state at every validate gate
- Log decisions to `project-decisions-log.md` at phase boundaries
- Update project truth docs after story validation passes
- Treat live runtime as the source of truth, not stale validation reports
- Treat AI-generated user-facing text as governed product copy
- Add commit learning tags (`PATTERN:`, `GOTCHA:`, `PERF:`, `ARCH:`, `RULE:`, `DEBT:`) when you discover something

## 📊 Commit Learning Tags

When committing, ALWAYS add tags if you discovered something:

```
git commit -m "feat(matching): implement overlap detection

Uses PostgreSQL window functions for 30-min availability blocks.

PATTERN: Window functions for time overlaps - 10x faster than Python
PERF: Query time 500ms → 50ms with proper indexing
GOTCHA: Timezone must be normalized before comparison
"
```

Tag types: `PATTERN:` (reusable pattern), `GOTCHA:` (surprise/pitfall), `PERF:` (optimization), `ARCH:` (architectural decision), `RULE:` (cursor-rule update needed), `DEBT:` (tech debt created).

These feed retrospectives. Without tags, learnings are lost.

## 🎯 When User Makes a Request

| User says | You do |
|-----------|--------|
| "/speck [something]" | Read `.cursor/skills/speck/SKILL.md` — it routes by complexity and play level |
| "Make it premium / shippable" | Read `project-state.md`. Then `/recheck`. Then surface findings with severities. Do not start polish until reconciled. |
| "Build [feature]" | Determine level (story/epic/project). Route to the matching `*-specify` skill. Never skip ahead to implementation. |
| "Is this done?" | Run `/larp` against target runtime + `/audit`. Declare a readiness state with evidence. |
| "What's the status?" | Read `project-state.md`. Surface it. Note staleness if stamps are old. |
| "Continue from last time" | Read `project-state.md`'s "Next action" field. |
| "Audit / make ship-ready" | Run `/recheck` first. Block new feature work until drift reconciled. |

## 📚 Where to Find More

- **Methodology guide**: `.speck/README.md` (canonical reference — don't read on every task)
- **All skills**: `.cursor/skills/` (each has `SKILL.md`)
- **All templates**: `.speck/templates/{project,epic,story}/`
- **Recipes (stack starting points)**: `.speck/recipes/`
- **Learned patterns** (cross-project, validated through retros): `.speck/patterns/learned/`
- **Project Cursor rules** (if defined): `.cursor/rules/*.mdc`

---

**Speck Version**: 7.6.0  
**Methodology**: Promise → Build → Prove (evidence-driven specification)

<!-- SPECK:END -->
