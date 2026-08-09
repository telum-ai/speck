# project-validate / post-write

## 10. Write outputs

1. `project-validation-report.md`
2. `project-validation-summary.md`
3. `project-punch-list.md`

Post-write axis validators (consumer UX-RC+ claims):
```bash
bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict project-validation-report.md
bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict project-validation-report.md
```
