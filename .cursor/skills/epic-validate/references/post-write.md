# epic-validate / post-write

# epic-validate

Prereq: all stories ≥ `IMPL-GREEN`; `/audit --epic <id>` → epic `audit-report.md`.
Output: `[EPIC_DIR]/epic-validation-report.md`, `[EPIC_DIR]/epic-punch-list.md`.
Templates: `.speck/templates/epic/epic-validation-report-template.md`, `.speck/templates/epic/epic-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state — never PASS/FAIL.

## 12. Write outputs

1. `epic-validation-report.md` — match template; evaluative drift section if state changed.
2. `epic-punch-list.md` — match template.
3. Update `epic.md` status + link report.

Post-write:
```bash
bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict epic-validation-report.md
bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict epic-validation-report.md
```

Readiness ≥ UX-RC: `.speck/scripts/regenerate-project-readme.sh --epic-validated <E###>`.
Trigger `/project-state`. Bypass/blocked LARP → `/speck-feedback`.

Audit subagent stall: degrade gracefully, complete scope sequentially, disclose fallback in audit + epic reports.
