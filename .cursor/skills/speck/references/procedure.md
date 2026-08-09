# speck — procedure

Universal router. Input: `$ARGUMENTS`. Output: route to the correct workflow with context.

## 0. First-actions ladder (stop at first hit)

0. `.speck/.v9-graph-needed` → `/speck-graph-up`. Else `python3 .speck/scripts/graph/speck_graph.py build` + `check`. Hard `.P1` blocks; repair first. `GRAPH_CAP` caps claims. python3 absent → WARN + proceed.
1. `.speck/.v8-reprove-needed` → `/speck-reprove`. Cap INTEGRATION-GREEN; FELT uncovered until re-earned.
2. `.speck/.migration-needs-catchup` OR `<!-- v7 MIGRATION SCAFFOLD -->` in truth docs → `/speck-catch-up`.
3. Read `specs/projects/<id>/project-state.md` if present.
4. Play level from `.speck/project.json` (`play_level`; missing = platform).
5. Engagement gap (missing/stale>2w/`< speck 8`/new agent) → `/recheck`.
6. Then route user request.

## 1. Gap routing (`/goal` companion)

Each turn: print `speck_graph.py check` + `gap` stdout; terminate on literal `SPECK-GAP: none`. Route top gap:

| gap | route |
|-----|-------|
| untraced/undischarged/phantom promise | story-specify → plan → tasks → implement → audit → story-validate |
| audit P0/P1 | harden |
| uncovered FELT / unjudged MM | larp |
| forks-open TASTE · contract pivot · price · deploy | STOP-BLOCKED owner decision |
| stale graph | speck_graph.py build |

## 2. Pre-routing (before scale analysis)

### Post-completion triage (validated/shipped project)

| Input kind | Route |
|------------|-------|
| Defect / bug / incident | `/harden` |
| Story redesign / visual overhaul | `/story-adjust` |
| Epic structural / IA pivot | `/epic-adjust` |
| Project contract / direction pivot | `/project-adjust` + `compute-cascade.sh` → fan out epic/story-adjust |
| New feature / scope expansion | `/epic-specify` or `/story-specify` |
| Engagement gap / "still working?" | `/recheck` |
| Play-level outgrowth | `/project-promote` |

### Brainstorm detection

Vague ideation ("I have an idea", "not sure what to build", stream-of-consciousness) → `/project-brainstorm`.

### Recipe detection

Match `$ARGUMENTS` against `.speck/recipes/*/recipe.yaml` `keywords:` (case-insensitive). Top 3 matches → offer use / scratch / other. Selected recipe → load `recipe.yaml`, pre-fill project artifacts. Vendor APIs: Context7 / official docs JIT — not domain pattern skills.

### Concurrent multi-epic spawn

1. Read `epics.md` → `## Epic Concurrency Waves & Rebase Cadence`.
2. Wave safety: all requested epics in same current wave; none are integrator epics (2+ upstream deps unmerged). Unsafe → STOP + list blockers.
3. `git push origin main` before spawn (worktrees branch from `origin/main`).
4. Per epic: `git worktree add ../<repo>-eNNN -b epic/eNNN origin/main`; guard prompt verifies spec path exists.
5. Tell user DEC band per epic; `project-state.md` regen is merge-only on epic branches.
6. Route each to `/epic` in its worktree. After merge: `git worktree remove --force ../<repo>-eNNN`.
7. See `.speck/patterns/learned/process/parallel-epic-execution.md`.

## 3. Complexity scale vs play level

Two concepts — do not merge:

| | Complexity scale (0–4) | Play level (`sprint`/`build`/`platform`) |
|---|---|---|
| Purpose | Routing: story vs epic vs project | Rigor: which artifacts, how much planning |
| When set | Ephemeral during `/speck` scale analysis | Persisted at `/project-specify` |

Complexity 3–4 ≠ `play_level: platform`. Use play signals (enterprise, marketplace, governance) for Platform; use scale for routing target.

## 4. Play level signals

Agent-detected from conversation — never flag-declared.

| Level | Signals | Flow |
|-------|---------|------|
| Sprint | Time-bounded; tiny scope; ship-first; no revenue complexity | `sprint-prd-template.md` + `sprint-log.md`; skip epics/stories |
| Build | Subscription/payment; dashboard; multi-user; v2 expansion | PRD + contracts + epics; no constitution/design-system required |
| Platform | Microservices/enterprise/regulated; explicit full foundation request | Full foundation flow (see §6) |

Promotion signals ("getting traction", "need more structure") → `/project-promote`.

## 5. Context resolution

1. Parse explicit markers: `project:XXX`, `epic:YYY`, natural language ("in project", "for epic").
2. Continuation keywords (`continue`, `resume`, `next`, empty args) → find most recent work via `project-state.md`.
3. Validate context: `specs/projects/[PROJECT_ID]/project.md`, `epics/[EPIC_ID]/epic.md`. Invalid → list available.
4. No context → scale analysis:

```bash
bash .speck/scripts/bash/analyze-scale.sh --json "$ARGUMENTS"
```

5. Present analysis + route. User override → honor it.

### Level separation (no overlap)

- **Project**: vision, goals, epic identification, roadmap
- **Epic**: feature design, architecture, story mapping
- **Story**: implementation details, dev tasks

### Scale → route

| Scale | Examples | Route | Architecture |
|-------|----------|-------|--------------|
| 0–1 | typo fix, color change | `/story-specify` | skip |
| 2 | auth system, shopping cart | `/epic-specify` | optional `/epic-architecture` |
| 3–4 | full product, platform | `/project-specify` | `/project-architecture` before `/project-plan` |

Brownfield: `/project-import` → `/speck-scan` → `/project-specify` → play-level flow → `/project-architecture` (as-is extraction).

## 6. Command order by play level

Canonical detail: `.speck/reference/command-phases.md`. Critical ordering:

**Build**: specify → clarify → product-contract → readme → evidence-contract → context → [architecture if cross-system] → plan → [/project-analyze required at 4+ epics] → epic loop → story loop (specify…implement→audit→validate→larp) → project-validate.

**Build 4+ / Platform**: `/project-architecture` + `/project-ux` required before plan. `/project-analyze` required after plan, before first `/epic-specify` (3 lenses at Build 4+; 7 at Platform). `check-epic-prereqs.sh` enforces.

**Platform**: domain → ux → context → constitution → architecture → design-system → product-contract → readme → evidence-contract → plan → project-analyze (all 7 lenses) → roadmap.

**Sprint**: project-specify → ship → promote?

Grandfather: `<PROJECT_DIR>/.analysis-gate-grandfathered` → advisory until report exists; surface loudly; one `/project-analyze` spends it.

Do NOT run `/project-validate` until post-implementation.

## 7. Key transitions

**Project → Epic**: after `/project-plan` → `/project-analyze` (when required) → `/project-roadmap` (optional) → `/epic-specify` per epic.

**Epic → Story**: after `/epic-clarify` → [/epic-architecture if complex] → `/epic-plan` → `/epic-breakdown` → `/story-specify` per story.

## 8. Routing output

After decision, state: target command, detected scope, complexity scale, location context. Execute routed command with original arguments.

## NEVER / ALWAYS

- NEVER skip first-actions ladder
- NEVER route to `/story-implement` on engagement gap without `/recheck`
- NEVER set Platform play level solely from complexity 3–4
- NEVER invent filenames under `specs/` (see `.speck/reference/canonical-routing.md`)
- NEVER skip `/project-analyze` before `/epic-specify` when gate applies
- ALWAYS read `project-state.md` Next action on continuation
- ALWAYS run scale analysis when no context provided
- ALWAYS respect user override of routing recommendation
- ALWAYS block feature work when catch-up or v8-reprove markers present
