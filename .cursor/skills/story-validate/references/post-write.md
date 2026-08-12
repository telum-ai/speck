# Post-write

Set `readiness_state_verified` to the highest state every gate allows. Run the
banned-phrase self-check.

The receipt's gate arrays are exact. Closure cycle:

1. SHA-stamp the report.
2. Run every gate, even after downgrade. Each gets its own shell event as the
   primary command; lists, pipes, backgrounding, substitution, or collected
   `$?` do not bind the event exit to the gate.
3. Correctable red → edit/lower, re-stamp, rerun all. Otherwise name the blocker
   and still run the remaining gates.

`conformant_red` may finish NO-SHIP only after all gates ran after the latest
stamp, every red is named, and no later report edit occurred. Green = all zero.

Gate argv comes only from the receipt arrays; never reconstruct it from nodes,
examples, or state.

SHIP-RC/SHIP+ uses the literal receipt entries for README and PROFILE checks.
`PROFILE_DRIFT.P1` blocks SHIP-RC+.

UI touching PROFILE: `regenerate-project-readme.sh --check` before UX-RC+.
Trigger `/project-state`. Prompt project truth updates unless `--skip-truth-update`.
Bypass → `/speck-feedback`.
