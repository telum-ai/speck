# story-implement / spine

1. Locate `STORY_DIR` by walking up to `spec.md`. STOP if absent or `Draft (Placeholder)`.
2. Run `bash .speck/scripts/validation/check-story-prereqs.sh "$STORY_DIR"`. Require `spec.md`, `plan.md`, `tasks.md`, and the story-analysis gate when `tasks.md` declares `analysis_required: true`.
3. Read `tasks.md`, `plan.md`, optional `data-model.md`, `contracts/`, `quickstart.md`, `codebase-scan-*.md`.
4. Prefer one connected context read:
   ```bash
   python3 .speck/scripts/graph/speck_graph.py context specs/projects/<id> <story-id>
   ```
   Hold PRM/MM/JOB/FR/AC, dependencies, and constraining DECs while implementing.
5. Set `tasks.md` frontmatter `status: in_progress`.
6. Execute phases in dependency order. Same-file work is sequential; `[P]` work may run concurrently only when files/runtime are independent. Tests precede corresponding implementation.
7. Give each delegated task its task id, owned files, acceptance predicate, relevant scan patterns, and test command. Verify returned work yourself before integration.
8. After each task: run its narrow test, inspect output, then mark `[X]`. A failed sequential task stops dependants; a failed parallel task does not erase successful siblings.
9. Run the full project gates named by `plan.md`/repo conventions: lint, typecheck, tests, build, and `bash .speck/scripts/banned-language-lint.sh` for changed product copy. After the final mutation, run the primary test gate as its own command event; do not chain, pipe, or wrap it, because the recorded event exit must be the gate exit.
10. Confirm every task is `[X]`; set `status: completed`. Report files changed plus exact gate verdicts. Never infer PASS from a command merely running.
11. Next route is `/audit` by a separate auditor, then `/story-validate`. Do not start another story and do not claim a readiness state here.
