# Story analysis report

Hand each finding to a verifier who did not author the corpus or raise that finding. Keep refuted rows and record Verifier + Verdict.

Write `[STORY_DIR]/story-analysis-report.md` from the loaded template. Use `BLOCKED` for any open CRITICAL, `NEEDS_FIXES` for open non-CRITICAL findings, and `CLEAN` when every finding is resolved, waived, or refuted.

Run as separate direct commands after the last report mutation:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [STORY_DIR]/story-analysis-report.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh --strict --gate [STORY_DIR]
```

Any committed change to `spec.md`, `plan.md`, or `tasks.md` after the report is `ANALYSIS_STALE.P1`.
