# Speck skill load map (complete)

**Status: implemented** in `.cursor/skills/**` (routers + contentful `references/` nodes; anti-theater CI). Not a paper inventory.

Canonical inventory for ADR-0005. Every skill is exactly one class:

| Class | Rule |
|-------|------|
| `inline` | Always-path → dense `SKILL.md` only (0 refs) |
| `dag` | Branch keys → router ≤80 lines + ≥2 refs, conditional Reads |
| `shim` | Thin alias → other skill (keep short) |

Updated whenever skills are added/removed. CI anti-theater enforces: refs empty OR ≥2 nodes (never single `procedure.md`).

## dag (must have load DAG)

| Skill | Branch keys | Nodes (shape) |
|-------|-------------|----------------|
| epic-analyze | play_level, epic count, lens id | spine, tiers/*, lenses/L*, promise-inventory, traceability, verify-and-report, gate-codes |
| project-analyze | play_level, epic count, lens id | same shape (project-scoped lenses) |
| story-validate | archetype, claimed_state, UI, visual host | spine, backend-skip, larp, execution, states/*, axes/*, integration-green, commercial, visual, spec-coverage, reachability, code-audit, post-write |
| epic-validate | archetype, claimed_state, UI | mirror story-validate + rollup/matrix/graph nodes |
| project-validate | play_level, claimed_state, PROFILE | spine, states/*, profile, coverage-matrix, gate-liveness, recheck, post-write |
| visual-testing | platform host | procedure + one host ref |
| speck-larp | archetype, Job A/B/C, UI | spine, jobs/*, backend-skip, recording |
| speck | first-actions hit, gap type, triage | spine, first-actions, gap-routes, triage, scale-route |
| speck-catch-up | migration phase, PROFILE | spine, phases/*, profile-refresh |
| speck-recheck | drift class, archetype | spine, drift-checks/*, gates |
| speck-audit | risk tier, multi-lens | spine, fidelity, sweeps/*, multi-lens |
| project-evidence-contract | play_level, archetype, UI | spine, tiers/*, archetype/*, probes |
| epic | play_level, next phase | spine, phases/* (orchestrator) |
| story | next phase | spine, phases/* (orchestrator) |
| project-promote | from→to play_level | spine, transitions/* |
| speck-reprove | archetype | spine, caps/*, felt-reearn |
| story-implement | archetype, UI | spine, stack/*, ui-branch |
| story-tasks | UI vs api | spine, ui-tasks, api-tasks |
| story-ui-spec | host/recipe | spine, hosts/* or point visual-testing |
| project-plan | play_level, complexity | spine, build-gate, e000 |
| speck-migrate | version crossing | spine, crossings/* |

## domain-refs (fat / weakly branched — Claude multi-domain pattern)

Router lists domains; load only needed domain file.

| Skill | Domains |
|-------|---------|
| project-clarify | load-rules, question-sets, research-flags, output |
| story-clarify | load-rules, question-sets, research-flags, output |
| epic-clarify | load-rules, question-sets, output |
| speck-debug | triage, hypotheses, evidence, fix-loop |
| speck-learn | capture, classify, register |
| epic-constitution | principles, enforcement |
| project-constitution | principles, enforcement |
| epic-architecture | decisions, seams, alternatives |
| epic-breakdown | story-map, deps, estimates |
| epic-experience-chain | seams, emotion, coverage |
| project-constitution | (see above) |
| speck-frontier-scan | lenses, sources, output |
| speck-skeptical-review | alternatives, tradeoffs, lock |
| parallel-execution | wave-safety, worktrees, verify-skills |
| harden | defect-class, reprove, report |
| visual-quality | rubrics, caps |

## inline (honest always-path — keep single SKILL.md)

All remaining process skills not listed above (specify/plan/import/ux/domain/design-system/adjust shims/scan aliases/self-eval/outline aliases/feedback/decision-log/graph-up/premise-challenge/retrospective routers that only dispatch, etc.) unless they later gain a real branch key.

## Frontmatter

- `disable-model-invocation: true` only: speck, story, epic
- Cursor `paths:` (auto-surface scoping):
  - `story-*` → `specs/projects/**/S*/**`, `specs/projects/**/stories/**`
  - `epic-*` → `specs/projects/**/E*/**`, `specs/projects/**/epics/**`
  - `project-*` → `specs/projects/**`
  - `visual-testing`, `visual-quality`, `story-ui-spec` → `**/*.{tsx,jsx,vue,svelte,css}` plus specs UI paths
