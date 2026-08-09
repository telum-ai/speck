# speck-catch-up / detect

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
