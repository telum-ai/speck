# speck / triage

## 2. Pre-routing (before scale analysis)

### Post-completion triage (validated/shipped project)

| Input kind | Route |
|------------|-------|
| Defect / bug / incident | `/harden` |
| Story redesign / visual overhaul | `/adjust --level story` |
| Epic structural / IA pivot | `/adjust --level epic` |
| Project contract / direction pivot | `/adjust --level project` + `compute-cascade.sh` → fan out `/adjust --level epic|story` |
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
3. Load `.cursor/skills/parallel-execution/SKILL.md` and follow its wave, worktree, and merge branches.
4. Route each safe epic to `/epic` in its worktree. Regenerate `project-state.md` on the integration branch only.

## 7. Transition source

After choosing scope, re-read the marked canonical flow in root `AGENTS.md` and resume at its first incomplete applicable slot. This router does not carry project-to-epic or epic-to-story sequences.

## 8. Routing output

After decision, state: target command, detected scope, complexity scale, location context. Execute routed command with original arguments.
