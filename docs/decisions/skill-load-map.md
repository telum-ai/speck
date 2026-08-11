# Speck skill load map

**Status: implemented.** Canonical inventory for ADR-0005.

Three structures are valid:

- `inline`: one always-path procedure in `SKILL.md`; no references created merely to look JIT.
- `dag`: the router names cheap branch keys, loads only the selected procedure, and forbids siblings.
- `shim`: a thin compatibility alias retained only when a real user-facing command needs it.

The agent must be able to choose a reference from the router alone. CI rejects hidden predicates, unconditional multi-reference chains, reference-to-reference continuations, and branches exceeding their context budget.

## Conditional DAGs

| Skill | Cheap branch key | Loaded branch |
|---|---|---|
| analyze | level, play level, lens, report phase | one common core, one reviewer lens at a time, then one late report contract |
| adjust | affected promise level | one story, epic, or project procedure |
| speck-migrate | oldest active marker or explicit upgrade | scaffold, proof, graph, or upgrade |
| story-validate | claimed state, UI/backend, visual host | applicable states and exactly one visual host |
| epic-validate | claimed state, UI/backend | applicable states, axes, and rollup |
| project-validate | claimed state, PROFILE/commercial reach | applicable states and project gates |
| visual-testing | recipe visual host | exactly one host procedure |
| speck-larp | UI/backend, jobs claimed, reachability | applicable jobs and unlock procedure |
| project-evidence-contract | play level and archetype | applicable tier and archetype |
| project-promote | source and target play level | one transition |
| story-implement, story-tasks | UI or backend | one implementation/task branch |
| clarify/debug/skeptical-review | current phase | one phase procedure |
| parallel-execution | dispatch or merge phase | wave, worktree, or verification procedure |

## Honest inline or hybrid skills

Always-path procedures stay inline. `speck-audit` is hybrid: its common adversarial procedure is inline and only UI-specific checks load `references/ui.md`. `speck-learn`, retrospectives, constitutions, plans, and the remaining direct artifact skills are inline because splitting their mandatory sequence would save no context.

## Retained shims

The only shims are compatibility surfaces that users may plausibly name: `speck`, `epic-outline`, `story-outline`, the scan aliases, and `project-readme`. Analyze and retrospective use their canonical auto-selected entries directly; their unused level aliases and generic retrospective router were removed.

Catalog policy and model-invocation flags are enforced by `.speck/reference/skill-catalog-policy.json`. Skill frontmatter contains only the name, effective description, and a model-invocation flag when policy requires it.
