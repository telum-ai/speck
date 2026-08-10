# Project adjustment branch

Update the directional delta in `product-contract.md` and/or `project.md`; reconcile `PRD.md`, `architecture.md`, `context.md`, and `evidence-contract.md` when touched. Run `/speck-skeptical-review` before locking the new direction.

The DEC must supersede the replaced decision. Then compute the reverse cascade:

```bash
bash .speck/scripts/validation/validators/compute-cascade.sh --dec DEC-XXXX
```

Declare every affected epic, story, and promise in the report. Route each through `/adjust --level epic` or `/adjust --level story`. Keep the project at `NO-SHIP` or the minimum supported downstream state while `CASCADE_STALE.P1` remains.

Write `specs/projects/<PROJECT_ID>/project-adjust-report-<YYYYMMDD>.md` from `.speck/templates/project/project-adjust-template.md`.

After downstream adjustment and validation, require this to pass before restoring readiness:

```bash
bash .speck/scripts/validation/validators/compute-cascade.sh --dec DEC-XXXX --strict
bash .speck/scripts/validation/validate-template.sh --strict [PROJECT_ADJUST_REPORT]
bash .speck/scripts/stamp-truth.sh [PROJECT_ADJUST_REPORT]
```
