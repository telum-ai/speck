# Speck Changelog

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

*[as of SHA `df17138` | verified 2026-05-16 | speck v7.1.0]*
