# parallel-execution / wave-safety

Decide whether the work is genuinely parallel before creating branches or workers.

1. Read the active wave in `epics.md`. Every requested epic must be in that wave, with all upstream dependencies already merged. An integrator with two or more unfinished upstreams runs later.
2. Assign exclusive file and schema ownership. If two chunks touch the same file, shared table, migration head, or truth artifact, serialize them or lock the interface in `.speck/templates/project/seam-contract-template.md` first.
3. For shared databases, prefer a solo foundation wave that creates shared tables and columns. Parallel downstream epics consume that frozen schema; a later shared migration gets a solo wave.
4. Confirm the complete planning corpus and every seam contract are committed and pushed to the branch from which worktrees will start. Each worker brief names its owned files, forbidden shared files, spec path, base SHA, and verification command.
5. Assign one branch/worktree and one decision-log number band per epic. Only the integrator regenerates `project-state.md`.
6. Record the wave, base SHA, ownership, branches, worktrees, open gates, and merge order in the orchestration ledger.

Stop instead of dispatching when ownership overlaps, a dependency is unmerged, the planning corpus is not visible at the base SHA, or available disk cannot support the wave.
