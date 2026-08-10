# Post-write

Lower `readiness_state_verified` to highest state where all gates pass.
Banned-phrase self-check. SHA-stamp report.

```bash
bash .speck/scripts/validation/validate-template.sh validation-report.md --strict
```

UI axis validators live in the selected `axes/felt.md` and `axes/taste.md`
nodes. Backend runs never load or execute them.

SHIP-RC/SHIP+:
```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
bash .speck/scripts/profile-drift-check.sh
```
`PROFILE_DRIFT.P1` blocks SHIP-RC+.

UI touching PROFILE: `regenerate-project-readme.sh --check` before UX-RC+.
Trigger `/project-state`. Prompt project truth updates unless `--skip-truth-update`.
Bypass → `/speck-feedback`.
