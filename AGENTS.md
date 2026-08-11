<!-- SPECK:START -->

# Speck — Promise → Build → Prove

Speck turns explicit product promises into excellent, proven products. PROMISE defines what good means; BUILD realizes it; PROVE independently searches for anything preventing the real result from passing its applicable quality axes. Artifacts and green checks are evidence, never the objective.

## Operating model

PROMISE defines the product contract and quality bar. BUILD turns it into traceable work. PROVE evaluates the real result. PROFILE keeps every declared public surface aligned with what is promised and proven.

Primary artifacts: `product-contract.md` for PROMISE; story specs, plans, tasks, and experience artifacts for BUILD; `project-state.md`, `evidence-contract.md`, audit reports, and runtime evidence for PROVE; the `project.md` PROFILE registry plus its declared surfaces, centered on root `README.md`, for PROFILE.

## Non-negotiable principles

- P1 — Evaluate the outcome, not the evidence format. Runtime agent role-play (LARP) must answer both “does it work?” and “is it good?”
- P2 — Every claim needs a real mechanism or execution path. No mechanism means the claim fails.
- P3 — Inability to reach or test something is a finding. Record the reproduced attempt before naming a blocker.
- P4 — The author does not certify their own work. Use a separate, independently motivated evaluator; probe lists inspire attacks but never define done.

## Start every engagement

Perform these steps in order. Reading context never completes the ladder. If a step routes to a repair or skill, complete it before continuing to later steps:

1. Handle compatibility state before new work through `speck-migrate`, oldest repair first: migration scaffold/banner → legacy proof → witness graph. Re-enter it until `.speck/.migration-needs-catchup`, `.speck/.v8-reprove-needed`, and `.speck/.v9-graph-needed` are cleared honestly.
2. Resolve the active project under `specs/projects/`. If none exists: existing code or docs enter through `project-import → speck-scan(project) → project-specify`; fuzzy greenfield enters through `project-brainstorm`; clear greenfield enters through `project-specify`. Do not build a graph at repository root.
3. Read the active project's `project-state.md` when present and capture its Next action; do not execute that action until the remaining entry gates below are clear.
4. Read `.speck/project.json` for `play_level`; if absent, use Platform until the project is classified.
5. Run `/speck-recheck` before acting on project work when project state or runtime evidence is missing, runtime verification is older than two weeks, ownership changed, or the agent is new to the project. Fresh state, an explicit Next action, and defect work do not waive a new-agent recheck. If required recheck commands cannot run, record the reproduced P3 finding and do not continue to the captured Next action.
6. For an existing project, run `python3 .speck/scripts/graph/speck_graph.py build <project-dir>` then `check <project-dir>`. Repair hard graph findings labeled `.P1` before continuing to any captured Next action; project-state prose or an accepted-deferral label cannot waive a live `.P1`. The graph's printed `GRAPH_CAP` value only limits the highest claim; it never grants readiness. If Python is unavailable, warn and continue with the remaining gates.
7. For unscoped new work, run `bash .speck/scripts/bash/analyze-scale.sh --json "<request>"` and inspect its `routing` signals. Complexity 0–1 routes to story scope, 2 to epic scope, and 3–4 to project scope; explicit user scope overrides the suggestion. Complexity chooses scope, never play level.
8. On “status”, “continue”, or “next”, follow the captured Next action after steps 1–7 are clear. Otherwise route the user's request through the canonical flow below.

For long autonomous runs, encourage native `/goal` when the host offers it. It is optional. Without it, use the same manual `check` → `gap` → repair loop. Load `.speck/reference/gap-routes.md` only for status, goal, or gap work.

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

The PROVE roles are distinct and ordered. Audit attacks the implementation for defects and missed mechanisms. LARP exercises the real user job and judges function, feel, and taste. Visual testing supplies host-specific visual and accessibility evidence inside UI LARP. Validation adjudicates all applicable evidence and alone declares readiness.

## Canonical flow

What/order only — how is in skills. Brackets are conditional slots; evaluate them when reached. `.speck/reference/command-phases.md` explains gates but never redefines this order.

<!-- SPECK:FLOW:START -->
Entry: brownfield `project-import → speck-scan(project) → project-specify`; fuzzy greenfield `project-brainstorm → project-specify`.
Sprint: `project-specify → ship → [project-promote if outgrown]`.
Build foundation: `project-specify → project-clarify → [project-domain if specialized] → project-product-contract → project-profile → project-evidence-contract → project-context → [project-ux if UI/4+] → [project-constitution if governance-heavy] → [project-architecture if cross-system/4+] → [project-design-system if shared UI] → project-plan → [analyze(project), required 4+]`.
Platform foundation: `project-specify → project-clarify → [project-domain if specialized] → project-ux → project-context → project-constitution → project-architecture → [project-design-system if UI] → project-product-contract → project-profile → project-evidence-contract → project-plan → analyze(project) → project-roadmap`.
Epic: `[epic-discover if brownfield has no map] → epic-specify → epic-clarify → [epic-constitution if local principles] → [epic-architecture if cross-cutting] → [epic-journey → epic-wireframes if UX-heavy] → [epic-experience-chain if UI] → epic-plan → epic-breakdown → analyze(epic) → story loop → speck-audit(epic) → speck-larp(+ visual-testing if UI) → epic-validate → epic-retrospective`.
Story: `[story-extract if code exists without artifacts | story-specify] → story-clarify → [speck-scan(story) for code facts] → story-plan → [story-ui-spec if complex UI] → story-tasks → [analyze(story), required Build/Platform] → story-implement(+ visual-quality if UI) → speck-audit → speck-larp(+ visual-testing if UI) → story-validate → story-retrospective`.
Project close: completed epics `→ speck-larp(+ visual-testing if UI) → project-validate → project-retrospective`; after truth gates on main `→ project-state`.
Decision boundary: `[just-in-time-research if external facts] → speck-premise-challenge → speck-skeptical-review → lock → speck-decision-log`. Parallel dispatch: `project-roadmap → parallel-execution → worktrees`.
Post-validation input: defect `→ harden`; deliberate redesign `→ adjust`; engagement gap `→ speck-recheck`; rigor outgrowth `→ project-promote`; new scope `→ [project-specify | epic-specify | story-specify]`.
<!-- SPECK:FLOW:END -->

## Always-on gates

- Read the selected `SKILL.md` and its required template before writing. Never invent filenames under `specs/`; read `.speck/reference/canonical-routing.md` when writing an artifact.
- Compare at least three alternatives before a non-trivial lock, then record the decision at the phase boundary.
- Run `speck-audit` after implementation, then exercise the real user or operator job with `speck-larp`; UI LARP includes naive/hostile passes and host-specific visual testing. Validation follows and only adjudicates checked-in evidence.
- Verify delegated work from its transcript and tool evidence; do not accept a self-reported pass or readiness state.
- Before dispatch, read `.speck/reference/agent-dispatch.json`. A custom agent supplies role separation and model tier, then enters the mapped canonical skill; it never replaces the skill.
- Keep every enumerable promise traced through the matrix and witness graph. Never hand-edit `witness.json`.
- Before price locks or COMMERCIAL-RC, compare free, DIY, and substitute options and require a value-defensibility artifact. Recheck market claims before COMMERCIAL-RC.
- Stamp truth artifacts with the current commit SHA, run banned-language checks, and check PROFILE drift during recheck.
- Capture a methodology workaround, ambiguous skill, or patched Speck behavior through `speck-feedback` while the evidence is fresh.
- Declare the exact readiness state. Do not hide premise or taste failures behind implementation green, and do not turn an unreproduced access problem into a blocker.

## When user says

| Say | Do |
|-----|-----|
| `/speck …` | Read the compatibility skill, then apply this engagement ladder and canonical flow |
| Build or change a feature | Enter at the appropriate `*-specify`; never skip straight to implementation |
| “Is this done?” | Audit, run applicable LARP, validate, and declare readiness with evidence |
| Status / continue | Clear the engagement gates, then follow the `project-state.md` Next action |
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
