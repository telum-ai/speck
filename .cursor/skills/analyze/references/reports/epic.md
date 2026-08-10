# Epic analysis report

Hand each finding to a different verifier. A refutation quotes artifact text; a CRITICAL-by-rule refutation shows the rule does not apply. Keep every refuted row and record Verifier + Verdict.

Write `[EPIC_DIR]/epic-analysis-report.md` matching the loaded template with `artifact_type: epic-analysis-report`, full SHA, Lens Roster, Issues Found, Promise Coverage, and `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN`.

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | ≥1 CRITICAL open | Fix, waive, or refute; re-run |
| NEEDS_FIXES | Open non-CRITICAL | Owner decides; stories may start |
| CLEAN | All resolved, waived, or refuted | `/story-specify` |

Run as separate direct commands after the last report mutation:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [EPIC_DIR]/epic-analysis-report.md
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID] --epic [EPIC_ID]
```

Any analyzed-corpus commit after the report is `ANALYSIS_STALE.P1`.
