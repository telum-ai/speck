# Epic report

Verify every finding with a reviewer other than its author, keep refuted rows, and write `[EPIC_DIR]/epic-analysis-report.md` from the loaded template. `BLOCKED` means an open CRITICAL or missing applicable flow slot; `NEEDS_FIXES` means another finding remains open; `CLEAN` means all findings are resolved, waived by decision, or refuted.

Run:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [EPIC_DIR]/epic-analysis-report.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh [EPIC_DIR]/epic-analysis-report.md --strict
bash .speck/scripts/validation/check-epic-prereqs.sh [PROJECT_DIR]
```

Commit the report after the analyzed corpus so `analyzed_sha` proves ordering.
