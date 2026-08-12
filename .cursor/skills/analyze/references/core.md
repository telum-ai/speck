# Analyze core

## Scope

- Project reads the planning corpus: `project.md`, `PRD.md`, `epics.md`, product/context/evidence contracts, and any architecture, UX, domain, constitution, design-system, roadmap, or decision artifacts that exist.
- Epic reads `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`, traceability and experience artifacts, plus inherited project promises and constraints.
- Story reads `spec.md`, `plan.md`, `tasks.md`, optional UI/data/contracts/scans, inherited constraints, epic breakdown, and its traceability rows.

Record `git rev-parse HEAD` as `analyzed_sha`. Judge planning truth only; post-implementation truth belongs to `speck-audit` and validation.

## Flow fit

Before accepting the corpus, evaluate every conditional slot already reached in the canonical AGENTS flow. Do not infer that absence means “not applicable.” Record one Flow Fit row per slot with trigger evidence, the artifact or explicit not-applicable rationale, and `included | not-applicable | missing`.

- Project: entry choice (`project-import` + project `speck-scan`, `project-brainstorm`, or clear greenfield) plus `project-domain`, `project-ux`, `project-constitution`, `project-architecture`, `project-design-system`.
- Epic: `epic-discover`, `epic-constitution`, `epic-architecture`, `epic-journey`, `epic-wireframes`, `epic-experience-chain`.
- Story: `story-extract`, `speck-scan`, `story-ui-spec`.

If the condition is true and its work is absent, verdict `missing`; do not manufacture a rationale after the fact. A missing applicable slot is `FLOW_OPTIONAL_MISSING.P1` and blocks downstream work until it is completed or a real decision changes the condition.

Play-level requirements outrank authored applicability. Platform must mark `project-ux`, `project-constitution`, and `project-architecture` `included`; Build with four or more epics must mark `project-ux` and `project-architecture` `included`. Any other verdict is `FLOW_REQUIRED_MISSING.P1`.

## Promise and traceability checks

For project and epic scope, build the witness graph and enumerate its `magic-moment`, `job`, and `differentiator` nodes. Every in-scope id needs a coverage row. If the graph cannot be read, record `ANALYSIS_COVERAGE_UNCOMPUTED.P2`; never substitute hand-grep.

```bash
python3 .speck/scripts/graph/speck_graph.py build "$PROJECT_DIR" --stdout
```

At epic scope also run:

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh "$EPIC_DIR"
```

An open/unmapped promise or missing matrix is P1. Story scope inventories every FR, acceptance scenario, inherited promise, and explicit gate against plan sections and task ids.

## Role separation and verdicts

Reviewers did not author the corpus and do not share findings before verification. A verifier differs from the lens that raised a CRITICAL or HIGH finding. Keep refuted rows.

CRITICAL by construction: two artifacts cannot both be satisfied; an in-scope promise has no valid coverage; a gate precondition contradicts the evidence contract. Everything else uses HIGH, MEDIUM, or LOW by judgment. Status is `open | resolved | waived DEC-####`; verdict is `confirmed | refuted`. Any open CRITICAL or missing applicable flow slot makes the report `BLOCKED`.
