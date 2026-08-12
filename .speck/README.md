# Speck runtime guide

Speck turns explicit product promises into excellent, proven products. The marked block in root `AGENTS.md` is the only always-loaded operating doctrine and the only canonical flow. This guide is an index for humans and agents who need more context; selected skills own procedures and templates own artifact shape.

## Operating model

- PROMISE defines the product contract and what good means.
- BUILD turns that promise into traceable specs, plans, tasks, and implementation.
- PROVE independently searches for defects and evaluates the real outcome.
- PROFILE keeps every declared public surface aligned with the promise and evidence.

Green checks and complete-looking files are evidence, not the objective. Readiness is judged independently on CORRECT, ON-CONTRACT, FELT-GOOD, and TASTE.

## Start and routing

Always begin with `AGENTS.md` → **Start every engagement**. It owns compatibility repair, project resolution, `project-state.md`, play level, recheck triggers, witness-graph checks, scope analysis, and status continuation.

The canonical Project, Epic, Story, decision, and post-validation order lives only inside the marked `SPECK:FLOW` block in `AGENTS.md`. `.speck/reference/command-phases.md` explains conditional gates without copying the order. Artifact writes consult `.speck/reference/canonical-routing.md`.

Play level lives in `.speck/project.json`. Absence is treated as Platform for backward-compatible, fail-safe rigor.

| Play level | Intended use | Planning and proof depth |
|---|---|---|
| Sprint | Small, time-bounded bet | Smallest artifacts; audit and runtime LARP at validation |
| Build | Meaningful users, revenue, or multiple epics | Product/context/evidence contracts; project architecture, UX, and analysis become required at four or more epics |
| Platform | Regulated, enterprise, marketplace, or cross-system work | Full foundation, seven-lens project analysis, and full PROVE gates |

## Core artifacts

Project truth lives under `specs/projects/<id>/`:

- `project.md` — vision, boundaries, and binding PROFILE surface registry
- `product-contract.md` — promises, jobs, differentiators, magic moments, and language constraints
- `evidence-contract.md` — valid proof, readiness gates, and platform evidence rules
- `context.md`, plus conditional `domain-model.md`, `ux-strategy.md`, `constitution.md`, `architecture.md`, and `design-system.md`
- `PRD.md`, `epics.md`, and `project-analysis-report.md`
- `project-state.md` — current readiness, drift, blockers, and next action
- `project-decisions-log.md`, `project-validation-report.md`, and `project-retro.md`

Epic truth lives in `epics/E###-name/` and includes `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`, the traceability matrix, conditional `user-journey.md`, `wireframes.md`, and `experience-chain.md`, `epic-analysis-report.md`, `audit-report.md`, validation evidence, and retrospective.

Story truth lives in `stories/S###-name/` and includes `spec.md`, `plan.md`, conditional `ui-spec.md`, `tasks.md`, `story-analysis-report.md` when required, implementation evidence, `audit-report.md`, `validation-report.md`, and `story-retro.md`.

Never invent another filename under `specs/`; use `.speck/reference/canonical-routing.md`.

## Analysis and conditional steps

Planning analysis runs after planning and before downstream build work. It loads one compact common core, one level-specific lens per independent reviewer, and the selected report contract only after findings return.

Every reached conditional flow slot gets a Flow Fit verdict:

- `included` with its artifact;
- `not-applicable` with trigger evidence and rationale; or
- `missing`, which blocks downstream work.

Absence is not an implicit skip. `validate-project-analysis.sh` enforces this for v11 reports.

## PROVE roles

- `speck-audit` attacks the implementation, negative paths, mechanisms, and test authenticity. It creates findings and does not declare readiness.
- `speck-larp` exercises the real user job and judges function, feel, and taste. Backend-only work takes the explicit non-UI branch.
- `visual-testing` runs inside UI LARP and supplies recipe-selected host evidence: screenshots, accessibility inspection, runtime logs, states, and interaction coverage.
- Project, epic, or story validation adjudicates all applicable evidence and alone declares the highest readiness earned.

The order and role boundaries are pinned in `AGENTS.md` and the routing/semantic-conservation tests.

## Recipes and host evidence

`.speck/recipes/<name>/recipe.yaml` is a stack starting point, not current vendor documentation. Every recipe declares one recognized `visual_testing.platform`; `api` and `cli` are explicit nonvisual routes. Current APIs and standards are researched just in time from official sources.

Visual host procedures live under `.cursor/skills/visual-testing/references/`. The active recipe selects exactly one. Capacitor-wrapped web uses its own native-shell host rather than borrowing Flutter or React Native instructions.

## Learning and feedback

`speck-learn` captures an observation immediately in current work. Story retrospective keeps the first occurrence local. Epic/project retrospective may promote repeated, evidence-backed rules with named consumers into the project's own `.speck/patterns/learned/`.

Vanilla Speck seeds no project-learned patterns, and upgrades preserve project-owned ones. A defect in Speck templates, scripts, routing, or methodology goes to `speck-feedback`, not the project pattern library. See `docs/methodology/project-learning.md` in the Speck source repository.

## Compatibility migration

`speck-migrate` is the single migration entry. It selects one procedure for explicit upgrade or the oldest active scaffold, proof, or graph repair marker. Historical version tokens remain only where existing repositories need them. See `docs/history/migrations.md` in the Speck source repository.

## Runtime locations

| Need | Location |
|---|---|
| Canonical flow and engagement ladder | `AGENTS.md` |
| Skill procedure | `.cursor/skills/<skill>/SKILL.md` |
| Artifact templates | `.speck/templates/{project,epic,story}/` |
| Artifact homes | `.speck/reference/canonical-routing.md` |
| Gate explanations | `.speck/reference/command-phases.md` |
| Host/model capabilities | `.speck/reference/host-capabilities.md` |
| Stack starting points | `.speck/recipes/` |
| Witness graph | `.speck/scripts/graph/speck_graph.py` |
| Planning analysis gate | `.speck/scripts/validation/validators/validate-project-analysis.sh` |
| PROFILE drift | `.speck/scripts/profile-surface-check.py` |
| Corpus/JIT budgets | `.speck/scripts/validation/validators/validate-corpus-budget.sh` |

Methodology development records, ADRs, history, evaluation harnesses, and release evidence belong only in the Speck source repository. They are not product-development context or exported runtime output.
