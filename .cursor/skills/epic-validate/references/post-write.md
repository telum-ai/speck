# epic-validate / post-write

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
