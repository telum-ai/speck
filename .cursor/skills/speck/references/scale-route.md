# speck / scale-route

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

Brownfield entry uses the marked canonical Entry line in root `AGENTS.md`; the selected play-level line owns what follows.

## 6. Command order by play level

The exact marked flow in root `AGENTS.md` is already in context and owns all play-level ordering. This router chooses scale; it never restates that sequence.

Build with 4+ epics and Platform require both project architecture and UX before planning. Project analysis then clears before the first epic starts: 3 lenses at Build 4+, all 7 at Platform. `check-epic-prereqs.sh` enforces the boundary.

Grandfather: `<PROJECT_DIR>/.analysis-gate-grandfathered` → advisory until report exists; surface loudly; one `/analyze --level project` spends it.

Do NOT run `/project-validate` until post-implementation.
