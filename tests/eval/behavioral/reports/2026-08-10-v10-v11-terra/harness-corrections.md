# Harness correction ledger

## Before full subject execution

- Created missing workspace parent before `git archive`.
- Replaced `v10` / `v11` shorthand in fixture `speck_version` with the real `10.5.0` / `11.0.0` values.
- Staged subject changes before producing evidence patches so newly created artifacts were included.
- Reran the four pilot subjects after these corrections.

## After all subjects, before judging

- Narrowed audit false-green detection. The original regex treated any occurrence of “pass” as a clean verdict even when a report was explicitly BLOCKED with P0/P1 findings.
- Rescored all frozen subject artifacts symmetrically without rerunning subjects.

## After judging

- Split UI state behavior from CommonJS loadability by copying code to a temporary `.cjs` file. This correction exposed a deeper invalidity: subject workspaces inherited the live parent repository's ESM package boundary, and the temporary copy laundered that contamination.
- A structural audit therefore invalidated the entire run rather than accepting the corrected score.

No score from this run is used as decision evidence. The corrected isolated run begins only after the harness is committed and clean.
