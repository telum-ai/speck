<!-- SPECK:START -->

# Speck — Promise → Build → Prove

Speck turns product promises into implemented work and checked runtime evidence. Optimize for finding what is wrong, not for producing documents that look complete or checks that look green.

## Operating model

PROMISE defines the product contract. BUILD turns it into traceable work. PROVE evaluates the real result. PROFILE keeps the public face aligned with what is promised and proven.

Primary artifacts: `product-contract.md` for PROMISE; story specs, plans, tasks, and experience artifacts for BUILD; `project-state.md`, `evidence-contract.md`, audit reports, and runtime evidence for PROVE; root `README.md` for PROFILE.

## Non-negotiable principles

- P1 — Evaluate the outcome, not the evidence format. Runtime agent role-play (LARP) must answer both “does it work?” and “is it good?”
- P2 — Every claim needs a real mechanism or execution path. No mechanism means the claim fails.
- P3 — Inability to reach or test something is a finding. Record the reproduced attempt before naming a blocker.
- P4 — The author does not certify their own work. Use a separate, independently motivated evaluator; probe lists inspire attacks but never define done.

## Start every engagement

Stop at the first action that applies:

1. Handle compatibility markers before new work: `.speck/.v9-graph-needed` → `/speck-graph-up`; `.speck/.v8-reprove-needed` → `/speck-reprove`; `.speck/.migration-needs-catchup` or `<!-- v7 MIGRATION SCAFFOLD -->` → `/speck-catch-up`.
2. Resolve the active project under `specs/projects/`. If none exists, use `project-brainstorm` for a fuzzy idea or `project-specify` for clear scope; do not build a graph at repository root.
3. Read the active project's `project-state.md` when present. On “status”, “continue”, or “next”, follow its Next action.
4. Read `.speck/project.json` for `play_level`; if absent, use Platform until the project is classified.
5. Run `/speck-recheck` before feature work when project state or runtime evidence is missing, runtime verification is older than two weeks, ownership changed, or the agent is new to the project.
6. For an existing project, run `python3 .speck/scripts/graph/speck_graph.py build <project-dir>` then `check <project-dir>`. Repair hard graph findings labeled `.P1` before continuing. The graph's printed `GRAPH_CAP` value only limits the highest claim; it never grants readiness. If Python is unavailable, warn and continue with the remaining gates.
7. Route the user's request through the canonical flow below.

For long autonomous runs, encourage native `/goal` when the host offers it. It is optional. Without it, use the same manual `check` → `gap` → repair loop. Load `.cursor/skills/speck/references/gap-routes.md` only for status, goal, or gap work.

## Play levels

| Level | Use for | Required depth |
|-------|---------|----------------|
| Sprint | Small, time-bounded bets | Sprint PRD + log; audit and runtime LARP at validation |
| Build | Products with meaningful users, revenue, or multiple epics | Product/context/evidence contracts; audit, LARP, decisions, readiness; architecture, UX, and project analysis at 4+ epics |
| Platform | Regulated, enterprise, marketplace, or cross-system work | Full foundation and PROVE flow; seven-lens project analysis after planning |

Build with 4+ epics and Platform require `/analyze --level project` after `project-plan` and before `epic-specify`; `check-epic-prereqs.sh` enforces it. A legacy `.analysis-gate-grandfathered` marker is advisory only until an analysis report exists, then remove it.

## Readiness

Judge four independent axes: CORRECT (works), ON-CONTRACT (delivers the promise), FELT-GOOD (works well for a real user), and TASTE (coherent quality). One axis cannot compensate for another.

Readiness climbs from NO-SHIP → IMPL-GREEN (implementation checks) → INTEGRATION-GREEN (integrated runtime) → UX-RC or API-RC (target experience or contract proven) → COMMERCIAL-RC when applicable → SHIP-RC (production-grade evidence complete) → SHIP (deployed). Never claim SHIP-RC from dev-server evidence.

## Canonical flow

What/order only — how is in skills. Brackets are conditional slots; evaluate them when reached. `.speck/reference/command-phases.md` explains gates but never redefines this order.

<!-- SPECK:FLOW:START -->
Entry: brownfield `project-import → speck-scan(project) → project-specify`; fuzzy greenfield `project-brainstorm → project-specify`.
Sprint: `project-specify → ship → [project-promote if outgrown]`.
Build foundation: `project-specify → project-clarify → [project-domain if specialized] → project-product-contract → project-readme → project-evidence-contract → project-context → [project-ux if UI/4+] → [project-constitution if governance-heavy] → [project-architecture if cross-system/4+] → [project-design-system if shared UI] → project-plan → [analyze(project), required 4+]`.
Platform foundation: `project-specify → project-clarify → [project-domain if specialized] → project-ux → project-context → project-constitution → project-architecture → [project-design-system if UI] → project-product-contract → project-readme → project-evidence-contract → project-plan → analyze(project) → project-roadmap`.
Epic: `[epic-discover if brownfield has no map] → epic-specify → epic-clarify → [epic-constitution if local principles] → [epic-architecture if cross-cutting] → [epic-journey → epic-wireframes if UX-heavy] → [epic-experience-chain if UI] → epic-plan → epic-breakdown → analyze(epic) → story loop → speck-audit(epic) → [speck-larp if UI] → epic-validate → epic-retrospective`.
Story: `[story-extract if code exists without artifacts | story-specify] → story-clarify → [speck-scan(story) for code facts] → story-plan → [story-ui-spec if complex UI] → story-tasks → story-implement(+ visual-quality if UI) → speck-audit → [speck-premise-challenge if high-impact UI seeks UX-RC+] → [speck-larp if UI] → story-validate(+ visual-testing if UI) → story-retrospective`.
Project close: completed epics `→ project-validate → project-retrospective`; after truth gates on main `→ project-state`.
Decision boundary: `[just-in-time-research if external facts] → speck-skeptical-review → lock → speck-decision-log`. Parallel dispatch: `project-roadmap → parallel-execution → worktrees`.
Post-validation input: defect `→ harden`; deliberate redesign `→ adjust`; engagement gap `→ speck-recheck`; rigor outgrowth `→ project-promote`; new scope `→ [project-specify | epic-specify | story-specify]`.
<!-- SPECK:FLOW:END -->

## Always-on gates

- Read the selected `SKILL.md` and its required template before writing. Never invent filenames under `specs/`; read `.speck/reference/canonical-routing.md` when writing an artifact.
- Compare at least three alternatives before a non-trivial lock, then record the decision at the phase boundary.
- Run `/speck-audit` after implementation and before validation. For UI, run naive-user and hostile-user runtime LARP before validation. Checked-in evidence is required for a passing validation report.
- Verify delegated work from its transcript and tool evidence; do not accept a self-reported pass or readiness state.
- Keep every enumerable promise traced through the matrix and witness graph. Never hand-edit `witness.json`.
- Stamp truth artifacts with the current commit SHA, run banned-language checks, recheck market claims before COMMERCIAL-RC, and check PROFILE drift during recheck.
- Declare the exact readiness state. Do not hide premise or taste failures behind implementation green, and do not turn an unreproduced access problem into a blocker.

## When user says

| Say | Do |
|-----|-----|
| `/speck …` | Read `.cursor/skills/speck/SKILL.md` |
| Build or change a feature | Enter at the appropriate `*-specify`; never skip straight to implementation |
| “Is this done?” | Audit, run applicable LARP, validate, and declare readiness with evidence |
| Status / continue | Read `project-state.md` and follow Next action |
| Run epics in parallel | Load `parallel-execution`; validate the wave before creating worktrees |
| Fix a defect in validated work | Run `harden` |
| Deliberately redesign validated work | Run `adjust` after classifying story, epic, or project blast radius |
| Change the product contract or direction | Run `adjust --level project`, compute the cascade, and revalidate affected work |

## Load only when needed

- Artifact locations: `.speck/reference/canonical-routing.md`
- Gate explanations and host differences: `.speck/reference/command-phases.md` and `.speck/reference/host-capabilities.md`
- Parallel dispatch and merge mechanics: `.cursor/skills/parallel-execution/SKILL.md`
- Stack starting points: `.speck/recipes/`; current vendor behavior: official docs at decision or implementation time
- Speck methodology development only: `docs/decisions/`, `docs/methodology/`, and `docs/history/`

<!-- SPECK:END -->
