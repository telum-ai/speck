---
name: speck-catch-up
description: Backfills v6→v7 migration scaffolds into honest artifacts. Use when catch-up markers or empty migrated contracts remain.
---

# speck-catch-up

Reconstruct v7 truth artifacts from v6 brownfield state. Downgrade over-optimistic readiness to what runtime actually proves.

Input: `$ARGUMENTS`. Parse `--phase=<name>`. Default: `--phase=all`.

**Block feature work** (`/story-implement`, `/epic-plan`, etc.) until catch-up complete. Refuse: *"v7 truth artifacts are still scaffolds. Run `/speck-catch-up` first."*

## When to run

Any of:
1. `<!-- v7 MIGRATION SCAFFOLD -->` in `product-contract.md`, `evidence-contract.md`, or `project-state.md`
2. `.speck/.migration-needs-catchup` marker exists
3. User says "catch up", "/speck-catch-up", or equivalent
4. `/recheck` shows >50% truth artifacts in scaffold state OR `check-replace-markers.sh` flags unfilled tokens

## Prerequisites

- Project at `specs/projects/<id>/` exists
- `migration-report.md` present
- Git history available
- At least `project.md` + (`PRD.md` OR `sprint-log.md`)

Missing minimal v6 docs → STOP: *"Not enough v6 history. Restore docs or start fresh with `/project-specify`."*

## Phase arguments

| Phase | Runs | Output |
|-------|------|--------|
| `--phase=triage` | Phase 0 | `migration-estimate.md` |
| `--phase=contracts` | Phases 1+2 | filled contracts |
| `--phase=decisions` | Phase 3 | `project-decisions-log.md` |
| `--phase=epic-artifacts` | Phase 4 | experience-chain stubs |
| `--phase=honesty` | Phase 5 | downgraded validation reports |
| `--phase=state` | Phase 6 | refreshed `project-state.md` |
| `--phase=plan` | Phase 7 | `project-catch-up-plan.md` |
| `--phase=finalize` | Phase 8 | marker removed |
| `--phase=profile` | PROFILE backfill | PROFILE sections |
| `--phase=refresh` | TEMPLATE_DRIFT refresh | missing sections appended |
| `--phase=all` | 0→8 (+ profile/refresh if needed) | everything |

Large projects: run phases in separate sessions, commit each. Small (1–3 epics): `--phase=all` in one session.

## Phase 0 — Triage (always runs first)

Parallel inventory:
- List `specs/projects/<id>/**/*.md`
- Read project.md, PRD.md, ux-strategy.md, domain-model.md, constitution.md, architecture.md, design-system.md
- Find every epic.md + latest validation-report.md
- Inventory screenshots/ directories
- `git log --since=1.year --pretty=oneline -- specs/projects/<id>/`
- Find ship docs (`docs/**/SHIP_R*.md`, `docs/release/*.md`, `RELEASES.md`)

Build engagement-triage table: artifact presence, state (full/stale/minimal), epic/story counts, recipe match %, banned-language hits.

Detect Phase 5 sub-mode:

| Condition | Mode |
|-----------|------|
| ≥1 story `validation-report.md` with PASS | `5a` — per-story honesty |
| 0 story reports BUT ≥1 ship doc with readiness claims | `5b` — per-feature-area floor |
| Neither | `5c` — skip honesty pass |

Write `migration-estimate.md` with triage table, Phase 5 mode, effort estimate, remediation backlog preview. SHA-stamp.

If `--phase=triage` only → STOP. Tell user to review estimate and continue.

## Phase 1 — Backfill `product-contract.md`

Read `.speck/templates/project/product-contract-template.md`.

| Section | Sources |
|---------|---------|
| Paid Promise | project.md + PRD.md + pricing*.md |
| Primary Persona | project.md + personas/ |
| Differentiator / Anti-Differentiators | project.md + constitution.md |
| Inspiration / JTBD / Magic Moments | ux-strategy.md + PRD.md + epic-journey.md |
| Public Language / Banned Language | ux-strategy.md + constitution.md |
| AI Behavior Contract | AI epic specs or `(N/A)` |
| Longitudinal Axes | adaptive-axes/ or `(none)` |

Clear answer → fill. Ambiguity → N≥3 alternatives, mark `[NEEDS USER REVIEW]`, add to catch-up plan. Replace every `REPLACE_BEFORE_SHIP:` token. Remove scaffold banner only when content is real. SHA-stamp. Log via `/speck-decision-log`.

## Phase 2 — Backfill `evidence-contract.md`

Active recipe from `.speck/project.json` or `project.md` `_active_recipe`. Read `.speck/recipes/<name>/recipe.yaml` `evidence_contract:` block; walk `extends:` chain and shallow-merge.

No recipe → infer platform from architecture.md; document inference in catch-up plan.

Hybrid stack (e.g. React + Capacitor): find composed recipe first; else splice per-platform sections + P3 row "author composed recipe."

Third-party risk surface (Stripe, Clerk, Firebase, etc.): pull current vendor language from **Context7 / official docs JIT** — not domain pattern skills.

Replace all `REPLACE_BEFORE_SHIP:` tokens. Remove scaffold banner. SHA-stamp.

## Phase 3 — Reconstruct `project-decisions-log.md`

Uncomment canonical catch-up caveat block (remove `<!-- CATCH-UP-ONLY: ... -->` wrapper).

Mine git for: `feat(architecture):`, `docs(design-system):`, `feat(plan):`, `feat(epic-*):`, commits with `ARCH:`/`PATTERN:`/`RULE:` tags.

Per decision → `/speck-decision-log` with `Reconstructed: true`, `sha:`, `date:`, `alternatives:` (≥2 plausible reconstructions), `status: locked`.

## Phase 4 — Epic-level artifacts

For each `epics/E###-*/`:

1. UI epic missing `experience-chain.md`:
   - Default: scaffold `experience-chain-historical.md` from brownfield template; populate shipped screens from story specs + git; `brownfield_exempt: true`.
   - Exception: both `user-journey.md` AND `wireframes.md` exist → generate full `experience-chain.md`.
2. Missing `epic-architecture.md` on cross-cutting epic → note only (optional artifact).
3. Replace all `REPLACE_BEFORE_SHIP:` tokens. SHA-stamp.

## Phase 5 — Honesty pass

Use sub-mode from Phase 0. Do not skip (5c is the only no-op).

### Mode 5a — story validation reports exist

Per story with PASS `validation-report.md`:

| Check | FAIL action |
|-------|-------------|
| Runtime LARP on target build (not dev server) | Downgrade to IMPL-GREEN; P0 |
| Surrogate proof (wrong platform per evidence-contract §3) | Downgrade to IMPL-GREEN; P0 |
| Missing audit-report.md | Downgrade to IMPL-GREEN; P1 |
| User-reachability unanswered | P1 |
| Banned-language in user-facing strings | P2 |

Rewrite report with `## Catch-Up Downgrade` section explaining why.

### Mode 5b — ship docs only

Per ship doc: extract feature areas + claimed readiness → map to epics/stories → floor at IMPL-GREEN (exception: ship doc cites valid checked-in evidence meeting evidence-contract → may stay UX-RC).

Write `catch-up-honesty-pass.md` at project root. Do not rewrite nonexistent story reports.

### Mode 5c

No historical readiness claims. Note in catch-up plan: *"Ships under v7 standards from here; no downgrades needed."*

Confirm with user before 5a rewrites in non-CI context. 5b may proceed without confirmation.

## Phase 6 — Regenerate `project-state.md`

Invoke `/project-state`. Reflect post-honesty readiness, blocking issues, `[NEEDS USER REVIEW]` markers, remaining `REPLACE_BEFORE_SHIP:` tokens. Next action: work through catch-up plan.

## Phase 7 — Write `project-catch-up-plan.md`

Prioritized P0–P3 remediation backlog: downgraded stories, magic moments needing LARP, sections awaiting review, REPLACE markers, experience-chain-historical deferred conversions. SHA-stamp.

## Phase 8 — Finalize

1. Remove project from `.speck/.migration-needs-catchup` (delete file if empty).
2. Run `/project-readme`.
3. Re-run `/recheck`.
4. Update project-state: "Catch-up complete. Resume normal workflow."

## Phase PROFILE (v7.7+, idempotent)

If missing: append `## PROFILE surfaces` to project.md, `PROFILE Gate Criteria` to evidence-contract.md (from templates, marked `[FROM PROFILE CATCH-UP]`). Log decision. Run `regenerate-project-readme.sh`, `validate-readme.sh`, `profile-drift-check.sh`. Skip steps where section exists.

## Phase REFRESH (idempotent)

For each file with template drift (`check-artifact-template-drift.sh`): append missing sections from template; preserve existing content. Log decision. Regenerate project-state.

## NEVER / ALWAYS

- NEVER silently downgrade validation reports without `## Catch-Up Downgrade` section
- NEVER invent magic moments or differentiators — mark `[NEEDS USER REVIEW]`
- NEVER delete v6 artifacts
- NEVER mark story UX-RC+ without checked-in runtime evidence; floor = IMPL-GREEN
- NEVER leave `REPLACE_BEFORE_SHIP:` in "filled" artifacts
- ALWAYS SHA-stamp reconstructed artifacts
- ALWAYS invoke `/speck-decision-log` for reconstruction decisions
- ALWAYS produce `project-catch-up-plan.md` (even if empty/clean)
- ALWAYS auto-detect Phase 5 sub-mode — do not ask user

## Idempotency

Safe to re-run. Skip phases where scaffold banner already removed. `--phase=<name>` targets one phase explicitly.
