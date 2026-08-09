# Verify + report

## Verify

- Different verifier per finding. `confirmed` | `refuted`. Quote text to refute.
- CRITICAL-by-rule: refute only by showing rule does not apply.
- Non-CRITICAL disagreement → majority-refute (N = tier lens count).
- Keep `refuted` rows. Write Verifier + Verdict.

## Report

Path: `[PROJECT_DIR]/project-analysis-report.md`.

```yaml
---
artifact_type: project-analysis-report
speck_version: 11.0.0
analyzed_sha: <40-char HEAD>
play_level: build
epic_count: <int>
lenses:
  - id: L3
    name: promise-coverage
    reviewer: <id>
    authored_corpus: false
---
```

Required: Lens Roster; Issues Found; Promise Coverage; `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN`.
Commit after corpus. Edit PRD/epics/product-contract after → `ANALYSIS_STALE.P1`.

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | ≥1 CRITICAL open | Fix / waive / refute; re-run |
| NEEDS_FIXES | Open non-CRITICAL | Owner decides; epic work may start |
| CLEAN | All resolved / waived / refuted | `/epic-specify` |

```bash
bash .speck/scripts/validation/validate-template.sh --strict [PROJECT_DIR]/project-analysis-report.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate specs/projects/[PROJECT_ID]
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID]
```
