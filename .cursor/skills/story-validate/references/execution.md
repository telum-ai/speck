# Execution checks

| Check | Action |
|-------|--------|
| Tasks | Parse `tasks.md`; incomplete → WARN (`--allow-incomplete`) |
| Tests | Run suite from `plan.md`; failures → HALT unless `--force` |
| Mutation | `mutate-guard.sh` per Evidence guard; transcribe `SPECK_MUTATION_*`; never hand-type |
| Quickstart | Run if present (`--skip-quickstart`) |
| Perf | Only if targets in spec (`--skip-perf`) |
| Constitution / rules / lint/types | Per plan.md |

Mutation: throwaway worktree; pattern matches once; guard calls shipped code; never tune until red.

```bash
.speck/scripts/validation/mutate-guard.sh --verify-receipt [STORY_DIR]/validation-report.md
```
`RECEIPT_MISMATCH.P1` blocks.
