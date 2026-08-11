# Story report

Verify every finding with a reviewer other than its author, keep refuted rows, and write `[STORY_DIR]/story-analysis-report.md` from the loaded template. `BLOCKED` means an open CRITICAL or missing applicable flow slot; `NEEDS_FIXES` means another finding remains open; `CLEAN` means all findings are resolved, waived by decision, or refuted.

Run:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [STORY_DIR]/story-analysis-report.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh [STORY_DIR]/story-analysis-report.md --strict
```

Commit the report after the analyzed corpus so `analyzed_sha` proves ordering.
