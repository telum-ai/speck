# speck-catch-up

Reconstruct v7 truth artifacts from v6 brownfield state. Downgrade over-optimistic readiness to what runtime actually proves.

Input: `$ARGUMENTS`. Parse `--phase=<name>`. Default: `--phase=all`.

**Block feature work** (`/story-implement`, `/epic-plan`, etc.) until catch-up complete. Refuse: *"v7 truth artifacts are still scaffolds. Run `/speck-catch-up` first."*

## Phase REFRESH (idempotent)

For each file with template drift (`check-artifact-template-drift.sh`): append missing sections from template; preserve existing content. Log decision. Regenerate project-state.

## Idempotency

Safe to re-run. Skip phases where scaffold banner already removed. `--phase=<name>` targets one phase explicitly.
