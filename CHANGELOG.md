# Speck Changelog

## v7.10.0 — 2026-05-26 — E000 execution feedback (templates, patterns, validators)

Incorporates post-E000 feedback: version-pin freshness, typecheck in verification, orchestrator clarity, feedback round-trip visibility, and validator fixes V6/V7.

### Templates (P1–P2)
- **`epic-tech-spec-template.md`** — Version-Pin Freshness Check with `npm view` command + verification table
- **`tasks-template.md`** — Phase 5 verification includes explicit **typecheck** step (Vitest/esbuild masks strict TS errors)

### Skills (P3)
- **`/story` and `/epic` orchestrators** — driving-pattern clarification: agent drives chain directly; sub-skills are not auto-invoked

### Methodology docs (P5–P6)
- **`.speck/templates/feedback/template.md`** — canonical feedback file structure (symptom + repro + patch + proposal)
- **`.speck/patterns/constitution-as-code.md`** — Platform pattern for ESLint/CI mechanical constitution enforcement
- **`.speck/scripts/banned-language-lint-staged.sh`** — lint-staged wrapper with auto project-dir detection

### CLI (P4)
- **`speck upgrade`** — prints which prior feedback items (V1–V7, H1–H4, P1–P6) are addressed by the upgrade

### Validators (V6–V7)
- **`validate-artifact-docs.sh`** — aligned to v7 AGENTS.md routing; deprecated `epic-outline.md`/`outline.md` removed; README gaps advisory only
- **`validate-recipes.sh`** — validates `extends:` chain integrity (missing parents, cycles); wired into CI

## v7.9.2 — 2026-05-25 — larp-play import fix

- **`larp-play.js`** — remove unused `readlineInteractive` import from `feedback.js` (would fail at module load if the export is absent)

## v7.9.1 — 2026-05-25 — Validator robustness pass

Fixes five false-positive / lifecycle-blindness classes in the pre-commit validation pipeline reported during a Platform-level E000 session (see `feedback.md`).

### Pre-commit hook (V1)
- **`pre-commit-hook.sh`** — empty `staged_specs` array no longer fails with `unbound variable` under `set -u`; early-exit before array expansion when no specs or README are staged

### Placeholder scanner (V2–V4)
- **Multi-line bracket false-positive** — bracket regex constrained to single lines (`[^\]\n]+`) so multi-line TypeScript/JSON/YAML blocks are not treated as one giant placeholder
- **Fenced code block skip** — Python scanner ignores all content inside ` ``` ` blocks (eliminates substring hits like `[{ "name": "next" }]`)
- **Generic-ID descriptive references** — `FR-XXX`-style mentions in citation context (`(e.g. FR-XXX)`, `-style`, `no FR-XXX`, `descriptive`, etc.) no longer flagged as unreplaced template tokens

### Story spec lifecycle (V5)
- **`validate-story-spec.sh`** — `Draft (Placeholder)` specs from `/epic-breakdown` get loose validation (YAML frontmatter + Draft checkbox only); full user-story/FR/Purpose gates engage once `/story-specify` advances to `Specified`

### Regression tests
- **`.speck/scripts/validation/test-fixtures/`** — known-good fixtures for each false-positive class
- **`validate-template.test.sh`** — wired into `npm test`

## v7.9.0 — 2026-05-25 — Visual assets pipeline + autonomous LARP playback

Engine-and-Steering-Wheel release: deterministic CLI engines for LARP playback, context compaction, learning-tag enforcement, and programmatic validation gates — all wired into skills so agents never need to "break the glass."

### Autonomous LARP Player
- **`speck larp-play`** — headless Playwright playback of persona scripts from `personas/*.md`; guided manual walkthrough fallback when Playwright is unavailable
- Captures screenshots and accessibility trees to `larp-recordings/` for evidence-backed validation

### Learning-tag commit hook
- **`.speck/scripts/validation/commit-msg-hook.sh`** — enforces `PATTERN:` / `GOTCHA:` / `PERF:` / `ARCH:` / `RULE:` / `DEBT:` tags on code commits
- Platform play level: hard block; Build/Sprint: friendly warning
- Auto-installed via `speck upgrade` / `speck init` sync (`installCommitMsgHook` in `sync.js`)

### Context compaction
- **`speck compress`** — bundles validated epic story folders into `.speck/archive/<project>-<epic>-stories.tar.gz`; generates `validated-summary.md`
- **`speck decompress`** — restores story directories on demand

### Visual assets pipeline
- **`design-system-template.md`** — Visual Assets Registry section
- **`ui-spec-template.md`** — Declared Visual Assets Manifest table
- **`story-tasks`** skill — auto-generates asset creation tasks from ui-spec manifest
- **`validate-visual-assets.sh`** — programmatic SVG/WebP existence and well-formedness checks

### Readiness evidence + pre-impl gates
- **`validate-readiness-evidence.sh`** — blocks `UX-RC`+ claims without `larp-recordings/` evidence files
- **`check-story-prereqs.sh`** — deterministic gate before `/story-implement` (spec/plan/tasks/analysis-report)
- **`story-validate` / `epic-validate`** — local-first multi-modal visual review instructions for agents (Read tool on screenshots)

## v7.8.0 — 2026-05-25 — Claude settings sync + lifecycle Stop hook

Fixes Stop-hook infinite loops on epic/project sessions and closes the silent-drift gap for `.claude/settings.json`.

### Stop hook (H1)
- **`.claude/hooks/stop-gate.sh`** — command-type Stop gate; lifecycle-scoped by directory walk
- Story directories: informational `tasks.md` / YAML status checks only
- Epic/project/workspace: never gates on `tasks.md` — eliminates prompt-loop token waste

### Settings reconciliation (H2 + H4)
- **`_speck_managed`** sentinel in `settings.json.example` — Speck owns `hooks.Stop`, `hooks.SessionStart`, `hooks.PostToolUse`
- **`packages/cli/lib/claude-settings.js`** — drift detection + reconcile preserving user `permissions`, `env`, custom hooks
- **`speck reconcile-settings`** CLI command (`--dry-run` supported)
- **`speck upgrade` / `speck init`** auto-reconcile Speck-managed blocks after sync

### Drift detection (H3)
- **`.speck/scripts/settings-drift-check.sh`** — `SETTINGS_DRIFT.P0` for managed-block diffs + legacy prompt Stop hooks
- **`/recheck`** skill runs settings drift in parallel with PROFILE drift
- **`speck feedback`** surfaces SETTINGS friction signals

### Upstream (H5)
- Documented ask: Claude Code Stop hooks could support `cwd_matcher`, `max_iterations`, and prompt-type exit semantics — filed as coordination need in feedback channel

## v7.7.0 — 2026-05-25 — PROFILE pillar enforcement

Completes PROFILE as a structurally enforced fourth pillar (validators, readiness gates, graded drift, multi-surface hooks).

### Structural enforcement
- **`validate-readme.sh`** + **`profile-drift-check.sh`** — P1/P2/P3 graded drift; README validator mirrors product-contract validators
- **Pre-commit** validates staged root `README.md` via `validate-profile.sh`
- **`evidence-contract.md`** — PROFILE Gate Criteria subsection under Section 7 readiness gates
- **SHIP-RC+** blocked on `PROFILE_DRIFT.P1` (story-validate, project-validate, recheck)

### Propagation
- **`speck upgrade`** auto-runs README footer regen via `runReadmeRegen()`
- **`regenerate-project-readme.sh`** — `--check`, `--surface=package|landing`, `--epic-validated=E###`, `PROFILE:AUTO-SYNC` markers
- **Epic validate/retro** updates README magic-moments / recently-validated sections
- **`/speck-catch-up --phase=profile`** — brownfield backfill for v7.6→v7.7 projects

### Templates + skills
- `project.md` PROFILE surfaces table; `ui-spec-template.md` PROFILE impact section
- `readme-template.md` magic-moments + recently-validated tables
- Updated project-readme, recheck, catch-up, story-validate, project-validate skills

## v7.6.0 — 2026-05-25 — README ownership + PROFILE pillar

Minor release fixing root README identity confusion and introducing PROFILE as a fourth methodology pillar.

### Root README ownership (CLI)
- **Behavior Before**: `speck init` copied Speck marketing content to root `README.md`. `speck upgrade` silently overwrote it whenever the first line still read `# Speck 🥓`.
- **Behavior After**: Init writes a project skeleton from `.speck/templates/project/readme-template.md`. Upgrade merges only the `<!-- SPECK:START -->` footer, auto-repairs legacy Speck-marketing READMEs, and never copies the Speck repo README to projects.

### `/project-readme` skill + regeneration script
- New `.speck/scripts/regenerate-project-readme.sh` fills scaffold sections from `project.md`, `product-contract.md`, and `project-state.md` while preserving user-edited content.
- Wired into `/project-specify`, `/project-product-contract`, `/project-state`, `/recheck`, and `/speck-catch-up` finalize — README evolves with the canonical workflow, not manual-only.

### PROFILE pillar
- Extended mental model: PROMISE → BUILD → PROVE → **PROFILE** (public face).
- Root `README.md` is the center-of-gravity PROFILE artifact; drift vs `product-contract.md` flagged on `/recheck`.

### Other
- `speck feedback`: fixed workspace `.speck/project.json` detection; added PROFILE friction signals.
- Docs updated for dual-README distinction (root vs `.speck/README.md`).

## v7.5.2 — 2026-05-25 — Pre-commit placeholder false-positive fix

Patch release tightening the template placeholder scanner so legitimate spec content no longer blocks commits.

### Pre-commit placeholder validation
- **Behavior Before**: The placeholder scanner (added in v7.5.0) flagged any bracketed text with a space as an unreplaced template token — including SHA stamp footers, prose annotations like `[moved E007]`, and lines that cite template markers in passing.
- **Behavior After**: Allowlists SHA stamp footers, skips citation-context lines, and only flags brackets that match known template placeholder patterns. Documented `git commit --no-verify` as the intentional bypass in `pre-commit-hook.sh`.

## v7.5.1 — 2026-05-25 — Methodology ordering fixes and timeless templates

Patch release correcting misleading phase guidance and removing historical version chatter from core templates.

### 1. Project-validate ordering (skills)
- **Behavior Before**: Several skills (`project-plan`, `project-architecture`, `speck`) suggested running `/project-validate` immediately after planning or `/project-analyze`, before epic implementation — treating it as a design go/no-go gate.
- **Behavior After**: Skills now state that `/project-analyze` is a planning-phase quality check and `/project-validate` is strictly the final post-implementation release gate (after all epics are validated).

### 2. Timeless template copy (no narrative version labels)
- **Behavior Before**: Core templates embedded comparative copy (`Speck v7`, `v6`, `v7.2+`) in comments and hardcoded `speck v7.0.0` footer examples, leaking migration history into every new project artifact.
- **Behavior After**: Sanitized `product-contract`, `evidence-contract`, `project-decisions-log`, `experience-chain`, and `story` templates — version-neutral guidance, `PLACEHOLDER CONVENTION` without version suffixes, and `Speck Version` fields left for `stamp-truth.sh` at verify time.

## v7.5.0 — 2026-05-25 — Speck v7 Script Consolidation & Contract Validation

Speck v7.5.0 completes our validation coverage by introducing first-class template validators for the project-level contracts (Product Contract and Evidence Contract), while consolidating duplicated v7 scripts to enforce a single source of truth.

### 1. Script Consolidation & Symlink Parity (Single Source of Truth)
*   **Behavior Before**: Duplicate versions of core methodology scripts (like `stamp-truth.sh`, `staleness-check.sh`, `banned-language-lint.sh`) were maintained under `.speck/scripts/` and `.speck/scripts/v7/`. These versions frequently diverged, leading to silent bugs where older scripts were missing features (like dynamic version parsing).
*   **Behavior After**: Completely deleted legacy files (`migrate-to-v7.sh` and `add-recipe-evidence-defaults.sh`) and consolidated duplicated files under `.speck/scripts/v7/` into relative symbolic links pointing directly back to their parent folder equivalents. This establishes a clean, unified execution base with zero-drift.

### 2. First-Class Promise & Prove Contract Validators
*   **Behavior Before**: While story and epic template structures were strictly validated by git and editor hooks, the Product Contract (governing the Paid Promise) and Evidence Contract (governing target platforms and proof sources) were completely unvalidated, allowing incorrect or incomplete contract files to pass through unnoticed.
*   **Behavior After**: Built two brand new, custom validation scripts under `.speck/scripts/validation/validators/`:
    *   `validate-product-contract.sh`: Validates YAML frontmatter, enforces the existence of Sections 1 to 7, and strictly blocks unreplaced `REPLACE_BEFORE_SHIP` placeholders.
    *   `validate-evidence-contract.sh`: Validates YAML frontmatter, enforces the existence of target platforms, valid/invalid proof sources, and sections 1 to 6.
    *   Updated the central `validate-template.sh` router to automatically parse and dispatch `product-contract.md` and `evidence-contract.md` files to their new validators.

## v7.4.0 — 2026-05-24 — Speck v7 Claude-First Compatibility & Advanced Orchestration

Speck v7.4.0 is a major upgrade leveraging modern Claude Code automation, scheduled loops, and specialized agent teams, while establishing a robust, host-agnostic validation core that guarantees zero regressions and flawless compatibility for Cursor and Codex.

### 1. Unified Validation Core & Single Source of Truth
*   **Behavior Before**: Template validators (e.g. `validate-story-spec.sh`, `validate-story-tasks.sh`) lived in Cursor-specific directories under `.cursor/hooks/hooks/validators/`. This made validation logic unavailable to other environments unless manually duplicated, causing spec-checking behavior to diverge across tools.
*   **Behavior After**: Centralized all template validation rules into a unified, host-agnostic bash core under `.speck/scripts/validation/validators/`, reducing duplicate code by over 1,100 lines. All hosts (Claude Code, Cursor, Codex, and CI) now call the exact same validation engine.

### 2. Claude-Native Hooks and settings.json Safeguards
*   **Behavior Before**: Non-interactive template validation was only available on Cursor via `afterFileEdit` hooks, while Claude Code had no automated spec enforcement or session safeguards.
*   **Behavior After**: Overhauled `.claude/settings.json.example` to declare narrow, safe Claude hooks:
    *   **`PostToolUse` (Edit|Write)**: Intercepts file edits via a custom adapter at `.claude/hooks/after-file-edit.sh` to validate markdown specs on the fly.
    *   **`SessionStart` (Compaction Reminders)**: Automatically re-injects `project-state.md` into the LLM context at start and compaction, preventing context-rot during long turns.
    *   **`Stop` (Exit Gates)**: Intercepts exit prompts to verify task completion and decision log status before allowing the session to close.

### 3. Dynamic Dual-Host MCP Config Merger
*   **Behavior Before**: MCP server setup and template sync guides were Cursor-exclusive, forcing Claude Code users to manually copy configurations and manage separate environments.
*   **Behavior After**: Created `.speck/mcp/servers.example.json` as the unified baseline source. Extended `.speck/scripts/bash/merge-mcp-config.sh` to generate local configs for BOTH Cursor (`.cursor/mcp.json`) and Claude Code (`.mcp.json`) simultaneously, with both safely gitignored to avoid secret leaks.

### 4. Specialized Checked-In Subagents
*   **Behavior Before**: Orchestrator commands only ran sequentially in the main conversation. Spawning specialized perspectives or running concurrent task teams was not structurally supported.
*   **Behavior After**: Checked in five custom subagents (`speck-scribe`, `speck-planner`, `speck-coder`, `speck-auditor`, `speck-validator`) under `.cursor/agents/` (cleanly symlinked to `.claude/agents/` and `.codex/agents/` via sync script). 
    *   **Worktree Isolation**: The `@speck-coder` is configured with `isolation: worktree` so it automatically implements tasks in a dedicated, conflict-free checkout of the codebase.
    *   **Agent Teams**: Users can now spin up parallel peer reviews or dual-implementations using Claude's teammate mode with custom roles (e.g. "@speck-coder" + "@speck-auditor").

### 5. Speck Maintenance Loops (`loop.md`)
*   **Behavior Before**: Spec drift, staleness, and scaffolding tokens could only be caught by manually triggering `/recheck` or waiting until a final validation command.
*   **Behavior After**: Checked in `.claude/loop.md` to establish a scheduled workspace guard. Running `/loop 1h` now automates staleness-checks, replace-marker scans, and lints dynamically in the background.

### 6. Host Capability Matrix & Fallbacks
*   **Behavior Before**: No explicit documentation outlining feature differences across platforms.
*   **Behavior After**: Added a dedicated **Host Capability Matrix** to `AGENTS.md` and updated key process skills (`speck-larp`, `speck-recheck`, `story-validate`) with clear fallbacks. If running on a host without subagents, the agent is directed to execute the same checklist items sequentially in the main context, maintaining complete procedural parity.

## v7.3.0 — 2026-05-16 — Speck v7 Generalization Tightening

Speck v7.3.0 introduces a major evolutionary step, transitioning Speck from a SaaS-focused web/mobile methodology into a **universally generalized, always-on development framework**. It resolves key cross-primitive orchestration gaps, enforces strict gate discipline, and introduces first-class project archetypes so that infrastructure, backends, internal tools, and client products are all spec-driven and validated with equal rigor.

### 1. Canonical Ordering Authority (`AGENTS.md`)
*   **Behavior Before**: Individual skill files (e.g. `project-specify`, `speck`, `story-ui-spec`) had their own ad-hoc "next steps" and "Smart Suggestions" sections. Agents reading these files would frequently diverge from the canonical phases in `AGENTS.md`, resulting in flow "split-brain" where they skipped required contract or context phases.
*   **Behavior After**: `AGENTS.md` is established as the **only** canonical ordering authority. All individual skills have had their ad-hoc suggestions normalized or stripped; they now explicitly redirect agents to `AGENTS.md`'s `## 📋 The Speck Command Phases` for phase transitions, while skills focus strictly on their own executional step.

### 2. First-Class Archetype Axis & System Proof Profile (PROMISE/BUILD/PROVE)
*   **Behavior Before**: Product contracts, evidence contracts, and validation checkpoints heavily overfit B2C/SaaS UI-heavy assumptions. Infrastructure, API, and pure backend epics were forced to include fake human personas, user-facing "banned words", and UI-based "magic moments", or bypass validation entirely.
*   **Behavior After**: Introduced `project_archetype` in `.speck/project.json` (values: `consumer_product`, `b2b_saas`, `internal_tool`, `infra_service`, `backend_api`). All core templates and skills adapt dynamically:
    *   **The Promise**: Under `infra_service` or `backend_api`, Section 1 ("Paid Promise") becomes the **Operational SLA**, Section 2 ("Primary Persona") becomes the **Primary Consumer/Client Service**, Section 4 ("JTBD Scorecard") becomes the **Operational Invariants Scorecard** (Latency, Throughput, Durability, Resiliency, Security), and Section 5 ("Magic Moments") becomes **Operational Milestones**. Section 6/7 transform into **API & System Taxonomy** and **Banned System Anti-Patterns**.
    *   **The Prove**: Pre-validation gates (`story-validate`, `epic-validate`, `/recheck`) automatically bypass human `/larp` for non-UI archetypes, requiring **System Operational Scenario Walkthroughs** (Options B stress-testing, schema conformance, concurrency race-condition lints, and connection pooling tests) instead.

### 3. Hard-Enforced Mandatory-Next Gates
*   **Behavior Before**: Agents could finish `story-implement` and immediately jump into editing or specifying a completely different story, leaving implementation un-audited or un-validated, propagating spec/code drift.
*   **Behavior After**: Stateful, hard-coded checks now block drift:
    *   `story-implement` completion strictly requires `/audit` then `/story-validate` next. Transitioning to another story's tasks or code is blocked until validation passes.
    *   Starting or specifying a new epic via `/epic-specify` is blocked if any prior completed epic in the workspace is outstanding validation (unless it is the Infrastructure `E000` epic).

### 4. First-Time Comprehension Gate & Evaluative Change Explanation
*   **Behavior Before**: Validation reports passed if components rendered and tests succeeded, completely ignoring whether a first-time user actually understood what they were looking at, why it mattered, or what to do next.
*   **Behavior After**:
    *   All UI validation gates (`story-validate` and `epic-validate`) now enforce a **First-Time User Comprehension Rubric** (What am I seeing? Why does it matter? What do I do next?). If user comprehension is blocked or has friction (scoring ❌ on visual clutter or clear calls-to-action), the UI validation **fails**, and the verified state is hard-capped at `IMPL-GREEN`.
    *   Any evaluative step (`/story-validate`, `/epic-validate`, `/recheck`) that changes or overrides a previous verdict/rating is required to write an explicit `### Evaluative Drift / Change Explanation` section documenting the exact reasoning.

### 5. New Orchestration Wrapper Commands (`/epic`, `/story`)
*   **Behavior Before**: Users and agents had to manually invoke separate, granular phase commands (specify → clarify → plan → tasks → implement → validate) sequentially, leading to execution lag and high command overhead.
*   **Behavior After**: Created two stateful wrapper skills (`/epic` and `/story`) that act as deterministic orchestrators. They automatically scan the workspace, detect the active item's current lifecycle state, resume the sequence, and execute downstream commands step-by-step, halting only on genuine decision-gates (unlocked questions) or P0 quality/drift findings.

### 6. Minimalist Scaffolding Bootstrap
*   **Behavior Before**: Initializing a new project generated placeholder templates for all nine possible documents (`PRD.md`, `architecture.md`, `ux-strategy.md`, etc.) immediately. This cluttered the directory and confused state engines, making it appear that those phases were complete when they were actually empty stubs.
*   **Behavior After**: The `create-new-project.sh` script is strictly stripped back. It now scaffolds only the folder boundaries and `project.md`. All other artifacts are created and populated on demand by their corresponding canonical command phases (e.g. `/project-context` creates `context.md` only when run), keeping the workspace clean and honest.

---

## v7.2.0 — 2026-05-16 — Splang field-test response

Speck v7.2.0 is the first version shaped by **real field-test feedback** from a v6 → v7 upgrade on a 21-UI-epic, 12-ship-round brownfield project (Splang). The feedback was high quality and identified 10 concrete friction points that broke the v7.1.0 model at scale. v7.2.0 addresses every one of them.

### Recipe composition (F2 — biggest leverage)

Recipes can now compose. A recipe declares `extends: <parent-recipe>` and `overlay:` blocks; the loader walks the chain and shallow-merges the parent, then applies the overlay. List fields use `_additional` suffix to indicate append semantics.

- **New recipe**: `capacitor-wrapped-web` — `extends: react-fastapi-postgres` with iOS + Android native-shell evidence rules, store-launch epics, and native-shell bootstrap epic
- **Updated docs**: `.speck/recipes/README.md` now explains composition with worked examples
- Hybrid stacks (React + FastAPI + Postgres + Capacitor, e.g.) no longer require manual evidence-contract surgery

### Phased catch-up (F3 — makes large brownfield usable)

`/speck-catch-up` now accepts `--phase=<name>`:

```
/speck-catch-up --phase=triage         (Phase 0 only — produces migration-estimate.md)
/speck-catch-up --phase=contracts      (Phases 1+2)
/speck-catch-up --phase=decisions      (Phase 3)
/speck-catch-up --phase=epic-artifacts (Phase 4)
/speck-catch-up --phase=honesty        (Phase 5 — auto-detects 5a/5b/5c)
/speck-catch-up --phase=state          (Phase 6)
/speck-catch-up --phase=plan           (Phase 7)
/speck-catch-up --phase=finalize       (Phase 8)
/speck-catch-up --phase=all            (default — runs everything)
```

Large brownfield projects (10+ epics) can checkpoint and commit between phases instead of doing one giant change.

### Auto-detected Phase 5 honesty pass (F1)

Phase 5 now auto-detects which sub-mode applies based on what's on disk:

- **Mode 5a** — story-level `validation-report.md` files exist → per-story walk, downgrades unsupported PASS claims
- **Mode 5b** — only ship docs (`docs/archive/ship/SHIP_R*.md` etc.) exist → feature-area floor at IMPL-GREEN + per-magic-moment LARP requirements in catch-up plan
- **Mode 5c** — no prior readiness claims → no-op

Splang-shaped projects (ship-doc-only readiness records) now have a real honesty path instead of catch-up silently no-op-ing.

### REPLACE_BEFORE_SHIP markers (F4)

Templates now use the literal token `REPLACE_BEFORE_SHIP: <hint>` for placeholders that MUST be filled. Easy to grep, impossible to miss.

- New script: `.speck/scripts/check-replace-markers.sh` — exit code 1 if any token remains
- `/speck-recheck` now runs this scanner in its drift detection
- Any artifact carrying a `REPLACE_BEFORE_SHIP:` token cannot claim a readiness state above `IMPL-GREEN`
- The catch-up skill is required to replace every token in artifacts it fills

### Canonical retroactive caveat (F5)

The decisions-log template now ships with a `<!-- CATCH-UP-ONLY -->` caveat block that `/speck-catch-up` uncomments when reconstructing the log from git history. No more agents inventing their own retroactive-hypothesis language. Per-entry `Reconstructed: true` flag makes retroactive entries searchable.

### User-review surface (F6)

`project-state.md` now includes auto-populated appendices:

- **Sections Awaiting User Review** — every `[NEEDS USER REVIEW]` marker across truth artifacts, in one place
- **Outstanding REPLACE_BEFORE_SHIP markers** — every incomplete token, in one place

The user no longer has to grep for ambiguous sections — they show up on the first read.

### Feedback command (F7)

```bash
npx github:telum-ai/speck feedback --topic catchup
```

Drafts a `.speck/feedback/<date>-<topic>.md` file with auto-collected (non-source) context: workspace version, repo HEAD, projects detected, friction signals (e.g., un-filled scaffold banners, `REPLACE_BEFORE_SHIP:` token counts, `[NEEDS USER REVIEW]` counts, large catch-up plans).

**No network calls. No telemetry.** The file is yours. You decide whether to submit it as a GitHub issue. Topics: `catchup | migration | recipe | methodology | cli | docs | other`.

### Two-step upgrade messaging (F8)

The `npx speck upgrade` banner and `migration-report.md` now explicitly say:

1. This was step 1 (scaffolding)
2. **Do NOT commit yet**
3. Run `/speck-catch-up` on a `speck-v7-migration` staging branch
4. Bundle scaffolding + catch-up into one commit (or one PR for review)

No more confusing the user into committing scaffolded-template state to main.

### Migration estimate before commitment (F9)

`/speck-catch-up --phase=triage` now writes `migration-estimate.md` listing:

- Engagement triage table (what was found)
- Phase 5 mode (5a/5b/5c) and why
- Per-phase effort estimate (minutes/hours)
- Post-catch-up remediation backlog estimate (deferred to project-catch-up-plan.md)

Set realistic expectations before starting the long-running work.

### Brownfield experience-chain exemption (F10)

UI epics that pre-date v7 no longer block catch-up on `experience-chain.md`. Instead:

- New template: `.speck/templates/epic/experience-chain-historical-template.md` (`brownfield_exempt: true`)
- Catch-up Phase 4 generates one historical stub per pre-v7 UI epic from story specs + git history
- `/epic-plan` accepts the historical marker (won't refuse to run)
- `/epic-validate` generates the FULL `experience-chain.md` on the fly when the epic is next re-validated (deferred-generation pattern)
- New epics still require a real upfront chain — exemption is one-time, per-epic

Removes "20-hour silent debt" of v7 migration on UI-heavy brownfield projects.

### Other improvements

- `migrate.sh` marker append is now idempotent (re-runs don't duplicate)
- `stamp-truth.sh` reads version dynamically from `.speck/VERSION`
- CLI banner includes `feedback` command and links the staging-branch pattern

### Files added

- `.cursor/skills/speck-catch-up/SKILL.md` (rewritten for phases + auto-detection)
- `.speck/scripts/check-replace-markers.sh`
- `.speck/templates/epic/experience-chain-historical-template.md`
- `.speck/recipes/capacitor-wrapped-web/recipe.yaml`
- `packages/cli/lib/commands/feedback.js`

### Files updated

- Five templates (product-contract, evidence-contract, experience-chain, decisions-log, project-state) — `REPLACE_BEFORE_SHIP:` convention
- `.cursor/skills/speck-recheck/SKILL.md` — marker scanning
- `.speck/recipes/README.md` — composition primitive docs
- `.speck/scripts/migrate.sh` — staging-branch guidance + idempotent marker
- `packages/cli/bin/speck.js`, `packages/cli/lib/commands/upgrade.js` — feedback command + two-step messaging

### Migration from v7.1.0

No data migration. The new behavior kicks in on the next `npx speck upgrade`. If you upgraded to v7.0.0 or v7.1.0 already and have lingering scaffold-banner artifacts, run `/speck-catch-up --phase=triage` to see what needs filling.

### Acknowledgment

Thanks to the Splang field test for the high-quality feedback that shaped this release. The `SPECK_V7_UPGRADE_FEEDBACK.md` from that project is the template for how feedback should look. `npx speck feedback` exists to make that kind of feedback easier to produce going forward.

---

## v7.1.0 — 2026-05-16 — Brownfield catch-up + cleanup

The first follow-up to v7.0.0. Targets one specific gap: when a v6 project upgrades to v7, the migration script only scaffolds **empty** template artifacts. The project itself still carries v6 debt — over-optimistic PASS claims with no runtime evidence, surrogate proof from old validation reports, scattered specs that haven't been consolidated, decisions buried in git history rather than logged. v7.0.0 left it to the user to know they should run the seven individual filler skills.

v7.1.0 makes the brownfield catch-up **canonical and automatic**.

### Added

- **`/speck-catch-up`** — A new brownfield reconstruction skill. Treats a freshly-migrated project as a brownfield import and:
  1. Backfills `product-contract.md` from `project.md` + `PRD.md` + `ux-strategy.md` + `domain-model.md` + `constitution.md`
  2. Backfills `evidence-contract.md` from the active recipe's `evidence_contract:` defaults
  3. Reconstructs `project-decisions-log.md` from git history (architecture / design-system / plan commits + learning tags)
  4. Backfills `experience-chain.md` for each existing UI epic
  5. **Honesty pass** — for each existing story marked PASS in v6: cross-references with `evidence-contract.md`, downgrades unsupported claims to `IMPL-GREEN`, flags surrogate proof
  6. Regenerates `project-state.md` to reflect the post-honesty-pass reality
  7. Writes `project-catch-up-plan.md` with prioritized P0–P3 remediation work
- **`.speck/.migration-needs-catchup`** marker file — written by `.speck/scripts/migrate.sh` whenever it runs. Lists every project that needs catch-up.
- **AGENTS.md "First Actions" rule #1** — agents now check for the marker / scaffold banner on every engagement and run `/speck-catch-up` BEFORE any feature work
- **CLI `upgrade` output** — when v6 → v7 migration runs, the CLI's final banner now spells out exactly what catch-up does and why it's required, instead of pretending the scaffolds are sufficient

### Changed

- `.speck/scripts/migrate.sh` — scaffold banners now name `/speck-catch-up` as the primary path; the individual skills are the manual fallback
- `.speck/README.md` — "Migrating from v6" section rewritten as a two-step process (scaffolding then catch-up)
- Symlinks confirmed canonical: `.claude/{skills,agents}` and `.codex/{skills,agents}` are already symlinks to `.cursor/{skills,agents}` (git mode `120000`) — no work needed here, just confirmed during this release

### Removed

- `.speck/field-test-protocol.md` — internal release-prep doc that shouldn't have been distributed as part of Speck. Per-project field-testing is the user's responsibility, not something Speck prescribes globally.

### Migration

There is no migration required from v7.0.0 to v7.1.0. The new behavior kicks in:
- On the next `npx github:telum-ai/speck upgrade` (which syncs the new skill + updated migrate.sh + updated AGENTS.md)
- On the next engagement where an agent sees a v6 project being upgraded — the marker is detected, catch-up runs automatically

If you upgraded to v7.0.0 already and have lingering scaffold-banner artifacts, run `/speck-catch-up` directly.

---

## v7.0.0 — 2026-05-16 — Promise → Build → Prove

The biggest release in Speck's history. Speck shifts from *spec-driven development* (write specs, then code) to **evidence-driven specification** (every spec assertion compiles to evidence; every claim ties to runtime proof; every truth artifact is SHA-stamped against current HEAD).

**Migration is automatic.** Running `npx github:telum-ai/speck upgrade` from any v6 project will detect the major-version bump, sync the new files, and additively scaffold v7 artifacts into every project under `specs/projects/`. No deletions, no destructive moves. You can also run `npx github:telum-ai/speck migrate` at any time to re-run the migration idempotently.

### Three new pillars

| Pillar | Center-of-gravity artifact | What it carries |
|--------|----------------------------|------------------|
| **PROMISE** (the contract) | `product-contract.md` | Paid promise, differentiator, JTBD scorecard, magic moments, public/banned language, AI behavior contract, longitudinal axes |
| **BUILD** (the work) | `spec.md`, `tasks.md`, `experience-chain.md` | Reordered story spec (UX first, implementation last); mandatory `experience-chain.md` for UI epics; primitives registry |
| **PROVE** (the truth) | `project-state.md`, `evidence-contract.md`, runtime LARP | Auto-regenerated state, per-platform proof rules, persona-driven runtime evidence |

### New commands

- **`/recheck`** — Mandatory on engagement gaps. SHA-drift detection, persona LARP cold-start, third-party risk surface scan, principle compliance scan
- **`/larp [persona]`** — First-class runtime LARP per platform (driven by recipe `visual_testing` config). Produces checked-in evidence: screenshots, AX trees, transcripts, timings
- **`/audit`** — Adversarial skeptical audit between implement and validate. Auditor doesn't trust the implementer's report
- **`/project-state`** — Auto-regenerated single-page status. First read on engagement
- **`/project-product-contract`** — Creates `product-contract.md`
- **`/project-evidence-contract`** — Creates `evidence-contract.md`
- **`/epic-experience-chain`** — Required for UI epics; defines screen seams + emotional state
- **`/speck-skeptical-review`** — Anti-premature-commitment primitive (N≥3 alternatives with tradeoff scoring)
- **`/speck-decision-log`** — Append-only `project-decisions-log.md` at every phase boundary
- **`/speck-scan`** — Unified scan skill replacing project-scan / epic-scan / story-scan
- **`/speck-migrate`** — Idempotent v6→v7 migration (runs automatically on upgrade)

### New mechanisms (always-on, unconditional)

| Discipline | When | Why |
|------------|------|-----|
| First-read `project-state.md` | Every engagement | Single-page current state, replaces ad-hoc handoff docs |
| Engagement-gap `/recheck` | >2 weeks idle OR new agent pickup | Drift detection before any new feature work |
| Decision-lock log | Every phase boundary | Locked decisions with SHA + alternatives in `project-decisions-log.md` |
| Skeptical-review | Before any non-trivial proposal locks | N≥3 alternatives with tradeoff scoring + rationale |
| Skeptical `/audit` | Between implement and validate | Auditor independence from implementer |
| Runtime `/larp` | Every UI story/epic validate gate | Specs are hypotheses; runtime is truth |
| Readiness-state declaration | At every validate | One of NO-SHIP / IMPL-GREEN / UX-RC / COMMERCIAL-RC / SHIP-RC / SHIP |
| SHA stamps | On every truth artifact write | Detects drift; stale = "proposal" |
| Banned-phrase detector | In every agent self-summary | Phrases like "ready for launch" trigger re-audit |
| Banned-language lint | On every commit + at `/audit` | Catches terminology drift before it ships |
| Evidence-or-it-didn't-happen | Every validation gate | "Tests pass" is one signal, not proof |

### New readiness state taxonomy (replaces PASS/FAIL)

| State | Meaning | Gate criteria |
|-------|---------|---------------|
| `NO-SHIP` | One or more hard blockers remain | Default when blocked |
| `IMPL-GREEN` | Tests / lint / types pass | Unit + integration green |
| `UX-RC` | Primary user flows pass in target runtime | Persona LARP recorded against built artifact (not dev server) |
| `COMMERCIAL-RC` | Billing / entitlements / support / legal pass | Per `evidence-contract.md` (paid products only) |
| `SHIP-RC` | All core gates pass, pending release ops | Runtime LARP against launch build (not dev server) |
| `SHIP` | Production / live proof complete | Post-deploy smoke + healthcheck green |

### Subtractions and consolidations

- `AGENTS.md`: 1269 → ~330 lines. Now a table of contents + routing tree, not an encyclopedia
- `.speck/README.md`: 1535 → ~430 lines
- Story spec template **reordered**: user experience first, implementation last
- `domain-model.md`, `ux-strategy.md`, `constitution.md`, `design-system.md` standalone files are **optional at Build** (their content lives in `product-contract.md`); still required at Platform
- `architecture.md` optional at Build (required if 4+ epics — composition fallacy gate)
- `epic-outline`, `story-outline`, `story-analyze` deprecated with shims (folded into `/audit` + `/speck-skeptical-review`)
- `project-scan`, `epic-scan`, `story-scan` consolidated into single `/scan [level]` skill
- 20 domain skills (Stripe, Clerk, Supabase, Firebase, etc.) moved to lazy-loaded patterns library — no longer pre-loaded into every agent context

### Context-rot defenses

- Layered loading: `project-state.md` first, deeper docs on-demand
- SHA-stamped truth: stale artifacts revert to "proposal" status and cannot serve as inputs to downstream decisions until re-verified
- Canonical-doc routing tree in `AGENTS.md`: forbids non-canonical filenames in `specs/`
- File-size discipline: SKILL.md target ~150 lines, templates are checklists

### Recipes

- All 14 recipes (`.speck/recipes/*/recipe.yaml`) gained an `evidence_contract:` block with platform-specific valid/invalid proof sources, required LARP scope per readiness state, and required static/live-service evidence

### Migration mechanics

- `.speck/scripts/migrate.sh` — additive migration script (never deletes v6 artifacts)
- `.speck/scripts/stamp-truth.sh` — apply/update SHA stamp footer
- `.speck/scripts/staleness-check.sh` — detect drift between artifacts and HEAD
- `.speck/scripts/banned-language-lint.sh` — enforce product-contract banned language
- `.speck/scripts/banned-phrase-detector.sh` — flag methodology-hostile phrases in agent summaries
- `.speck/scripts/detect-version.sh` — version detection from `project.json` / frontmatter / footer
- `.speck/scripts/regenerate-project-state.sh` — hint script for project-state regeneration
- `.speck/scripts/add-recipe-evidence-defaults.sh` — one-off applied to v6 recipes during release prep
- CLI `upgrade` command **auto-detects** the v6→v7 boundary and runs the migration for every project — no user action required

### Compatibility

- v6 projects continue to work — the migration is additive
- v6 commands (`/story-analyze`, `/epic-outline`, `/story-outline`, `/project-scan`, etc.) remain present with deprecation notices in their descriptions pointing to their v7 equivalents
- Recipes are backward-compatible; the new `evidence_contract:` block is additive
- `speck_version` in `.speck/project.json` defaults to `7.0.0` for new projects; v6 projects get bumped automatically on upgrade

---

## v6.x

See git history. v6 was the spec-driven development era. v7 is the evidence-driven specification era.

---

*[as of SHA `6cdfad8` | verified 2026-05-16 | speck v7.2.0]*
