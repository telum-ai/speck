# Post-write

Set `readiness_state_verified` to the highest state every gate allows. Run the
banned-phrase self-check.

The receipt's gate arrays are exact. Closure cycle:

1. SHA-stamp the report.
2. Run each gate in its own shell tool event, as the primary command. Lists,
   pipelines, background jobs, substitutions, and collected `$?` fail
   conformance because the event exit no longer belongs to the gate.
3. On red, edit or lower, re-stamp, and rerun the full set.

A direct red remains visible as `conformant_red`, but closure stays open. Finish
only after every gate is zero after the latest stamp and no later report edit.

```bash
bash .speck/scripts/validation/validate-template.sh validation-report.md --strict
```

UI axis gates come from the selected FELT/TASTE nodes. Backend skips them.

SHIP-RC/SHIP+:
```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
bash .speck/scripts/profile-drift-check.sh
```
`PROFILE_DRIFT.P1` blocks SHIP-RC+.

UI touching PROFILE: `regenerate-project-readme.sh --check` before UX-RC+.
Trigger `/project-state`. Prompt project truth updates unless `--skip-truth-update`.
Bypass → `/speck-feedback`.
