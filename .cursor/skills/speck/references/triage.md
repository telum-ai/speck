# speck / triage

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

## 7. Key transitions

**Project → Epic**: after `/project-plan` → `/project-analyze` (when required) → `/project-roadmap` (optional) → `/epic-specify` per epic.

**Epic → Story**: after `/epic-clarify` → [/epic-architecture if complex] → `/epic-plan` → `/epic-breakdown` → `/story-specify` per story.

## 8. Routing output

After decision, state: target command, detected scope, complexity scale, location context. Execute routed command with original arguments.
