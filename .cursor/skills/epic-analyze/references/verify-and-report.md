# Verify + report

## Verify findings

- Hand each finding to a different verifier. Verdict: `confirmed` | `refuted`.
- Refutation must quote artifact text. Unrefuted → `confirmed`.
- CRITICAL-by-rule refutation must show the rule does not apply.
- Keep `refuted` rows. Write `Verifier` + `Verdict` on every Issues Found row.

## Write report

Path: `[EPIC_DIR]/epic-analysis-report.md`. Match template.

```yaml
---
artifact_type: epic-analysis-report
speck_version: 11.0.0
analyzed_sha: <40-char HEAD>
lenses:
  - id: L3
    name: promise-coverage
    reviewer: <id>
    authored_corpus: false
---
```

Required: Lens Roster; Issues Found (Verifier+Verdict+Status); Promise Coverage matrix; `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN`.
Commit report after corpus. Corpus edit after report → `ANALYSIS_STALE.P1`.

## Verdict

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | ≥1 CRITICAL open | Fix / waive / refute; re-run |
| NEEDS_FIXES | Open non-CRITICAL | Owner decides; stories may start |
| CLEAN | All resolved / waived / refuted | `/story-specify` |

```bash
bash .speck/scripts/validation/validate-template.sh --strict [EPIC_DIR]/epic-analysis-report.md
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID] --epic [EPIC_ID]
```
