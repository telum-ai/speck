# Post-write

Lower `readiness_state_verified` to highest state where all gates pass.
Banned-phrase self-check.

This is a closure loop, not a one-shot check. Run every gate selected by the
receipt individually. First SHA-stamp the report, then run the complete set. A
red gate means edit or lower the report, re-stamp it, and rerun every selected
gate. Finish only when all selected gates exit 0 after the most recent stamp,
with no later report edit; a different green validator cannot substitute for a
required red one.

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
