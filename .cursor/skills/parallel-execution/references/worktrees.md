# parallel-execution / worktrees

Use exact, validated paths. Never use a broad directory, unresolved variable, or forced removal for worktree cleanup.

1. Fetch the chosen base and confirm the planning/spec paths exist at that SHA.
2. Create one branch and worktree per approved chunk:

   ```bash
   git worktree add ../<repo>-eNNN -b epic/eNNN origin/main
   ```

3. In each worktree, confirm the assigned spec and seam contract before editing. Commit verified slices and rebase onto the current integration branch before handoff.
4. If a worker stops, inspect and commit recoverable WIP in its existing worktree. Do not delete and restart by default.
5. Merge with preserved history. Do not bypass hooks. If lint-staged's stash handling corrupts a conflicted merge, abort the commit, restore and re-stage the resolution, configure that hook to run lint-staged with `--no-stash` during merge commits, run the complete gate, and commit normally.
6. A conflict-free merge still needs semantic proof. Before push:
   - require one migration head and apply migrations to a throwaway database carrying representative dirty-state shapes;
   - perform a frozen dependency install so the lockfile is proven resolvable;
   - rebuild and check the witness graph at the merge commit;
   - run the complete project test/build/lint gate;
   - state deploy order when schema and code ride different release paths.
7. Verify the merge commit contains all expected files and parents, then regenerate `project-state.md` on the integration branch.
8. Remove the clean worktree without `--force`:

   ```bash
   git worktree remove ../<repo>-eNNN
   ```

If normal removal refuses, inspect the reported WIP. Preserve or explicitly resolve it before retrying.
