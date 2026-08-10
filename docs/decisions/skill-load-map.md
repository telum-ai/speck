# Speck skill load map (complete)

**Status: implemented** in `.cursor/skills/**`. Not a paper inventory.

Canonical inventory for ADR-0005. Every skill is exactly one class:

| Class | Rule |
|-------|------|
| `inline` | Always-path → dense `SKILL.md` only (0 refs). No fake multi-ref “DAG”. |
| `dag` | Router ≤80 lines states **cheap branch keys inline**, then conditional `MUST Read` / `Do not Read`. ≥2 refs. |
| `shim` | Thin compatibility alias or explicit convenience router; user-only |

**Hard rule:** The agent must decide whether to load a ref from the router alone. Never “Read X when that domain applies” — that forces loading X to learn the predicate and defeats JIT.

CI enforces: ban predicate-hiding phrasing; ban unconditional fake DAGs; require direct router ownership of every node; ban ref-to-ref continuations; cap declared branch bytes against v10.

## dag (conditional load — predicates live in SKILL.md)

| Skill | Cheap keys (must be readable in router) | Nodes |
|-------|-------------------------------------------|-------|
| analyze | level, play_level/epic count, phase, lens id | core scope, one reviewer lens, late report template |
| adjust | promise blast radius | exactly one story/epic/project branch + template |
| story-validate | archetype, claimed_state, UI, visual host | spine, backend-skip, larp, states/*, axes/*, … |
| epic-validate | archetype, claimed_state, UI | rollup/matrix/graph + states + axes |
| project-validate | claimed_state, PROFILE, commercial | states/*, profile, coverage, gate-liveness, … |
| visual-testing | platform host | common workflow inline + exactly one real host ref |
| speck-larp | archetype, Job A/B/C, auth blocked? | spine, backend-skip, sandbox, jobs/*, recording |
| speck | first-actions hit; status vs new work | first-actions, spine, gap-routes, scale-route, triage |
| speck-audit | UI story? | spine, multi-lens, fidelity, sweeps, chain |
| project-evidence-contract | play_level, archetype | spine, tiers/*, archetype/* |
| project-promote | from→to play_level | spine, transitions/* |
| story-implement | UI-bearing vs API/backend | spine, ui, backend |
| story-tasks | UI-bearing vs API/backend | spine, ui-tasks, api-tasks |
| project-clarify | workflow phase (start→Q&A→research→close) | load-rules, question-sets, research-flags, output |
| story-clarify | workflow phase | same shape |
| speck-debug | debug phase (triage→…→fix) | triage, hypotheses, evidence, fix-loop |
| speck-skeptical-review | exploring vs locking | alternatives, tradeoffs, lock |
| epic-architecture | crosses seams?; locking? | decisions, seams, alternatives |
| parallel-execution | before spawn / worktrees / at merge | wave-safety, worktrees, verify-skills |

## inline (honest always-path)

Including former “domain-refs” that had no cheap skip: `epic-experience-chain`, `epic-breakdown`, `epic-clarify`, `epic-constitution`, `project-constitution`, `epic`, `story`, `harden`, `visual-quality`, `speck-learn`, `speck-recheck`, `speck-reprove`, `speck-migrate`, `speck-catch-up`, `speck-frontier-scan`, `project-plan`, `story-ui-spec`, plus all other always-path process skills (specify/plan/import/…).

## shim / user router

- Analyze compatibility: `project-analyze`, `epic-analyze`, `story-analyze`
- Adjust compatibility: `project-adjust`, `epic-adjust`, `story-adjust`
- Scan compatibility: `project-scan`, `epic-scan`, `story-scan`
- Retired compatibility: `epic-outline`, `story-outline`
- Convenience routers over genuinely different specialists: `validate`, `retrospective`

## Frontmatter

- `disable-model-invocation: true`: exact entries in `.speck/reference/skill-catalog-policy.json`
- Families: analyze/adjust/scan each expose one canonical auto entry; validate/retrospective expose level specialists and keep their generic router user-only
- Cursor `paths:` (auto-surface scoping):
  - `story-*` → `specs/projects/**/S*/**`, `specs/projects/**/stories/**`
  - `epic-*` → `specs/projects/**/E*/**`, `specs/projects/**/epics/**`
  - `project-*` → `specs/projects/**`
  - `visual-testing`, `visual-quality`, `story-ui-spec` → `**/*.{tsx,jsx,vue,svelte,css}` plus specs UI paths
