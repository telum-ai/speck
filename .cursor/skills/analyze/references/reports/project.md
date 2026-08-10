# Project analysis report

Hand each finding to a different verifier. A refutation quotes artifact text; a CRITICAL-by-rule refutation shows the rule does not apply. Keep every refuted row and record Verifier + Verdict.

Write `[PROJECT_DIR]/project-analysis-report.md` matching the loaded template with `artifact_type: project-analysis-report`, full SHA, play level, epic count, Lens Roster, Issues Found, Promise Coverage, and `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN`.

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | ≥1 CRITICAL open | Fix, waive, or refute; re-run |
| NEEDS_FIXES | Open non-CRITICAL | Owner decides; epic work may start |
| CLEAN | All resolved, waived, or refuted | `/epic-specify` |

Run as separate direct commands after the last report mutation:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [PROJECT_DIR]/project-analysis-report.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate specs/projects/[PROJECT_ID]
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID]
```

Any analyzed-corpus commit after the report is `ANALYSIS_STALE.P1`.
