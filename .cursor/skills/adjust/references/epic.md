# Epic adjustment branch

Map affected stories and shared components. Update only epic-level deltas in `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`, `wireframes.md`, `journey.md`, and `experience-chain.md` as applicable.

Reconcile `traceability-matrix.md`. Retire superseded cross-story promises with a DEC and add PRM rows for new screens, elements, and seam rules. Route each affected story through `/adjust --level story`.

Run a decorrelated epic audit, then `/epic-validate` on the changed JTBD and cross-story composition.

Write `specs/projects/<PROJECT_ID>/epics/E###/epic-adjust-report-<YYYYMMDD>.md` from `.speck/templates/epic/epic-adjust-template.md`.

After the last mutation, run separately:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [EPIC_ADJUST_REPORT]
bash .speck/scripts/stamp-truth.sh [EPIC_ADJUST_REPORT]
```
