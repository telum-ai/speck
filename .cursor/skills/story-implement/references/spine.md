# story-implement / spine

1. Locate `STORY_DIR` by walking up to `spec.md`. STOP if absent or `Draft (Placeholder)`.
2. Run `bash .speck/scripts/validation/check-story-prereqs.sh "$STORY_DIR"`. Require spec, plan, tasks, and the story-analysis gate when `tasks.md` declares `analysis_required: true`.
3. Read plan/tasks, their optional design artifacts, and every existing file they name. Preserve its public data shape, entry points, and wired surfaces unless the plan changes them; never invent a replacement API.
4. Run `python3 .speck/scripts/graph/speck_graph.py context specs/projects/<id> <story-id>` and hold PRM/MM/JOB/FR/AC, dependencies, and constraining DECs.
5. Set tasks `status: in_progress`. Do not normalize `spec.md`/`plan.md` labels to satisfy a gate. A requirement or design change routes through adjust.
6. Before coding, map each normative clause to a test. Cover every specified input invariant, success/failure, equality and adjacent boundaries, blank/malformed input, unknown/duplicate identity, and unaffected state. A compound bullet remains uncovered until every clause has a test. Work in dependency order; tests precede code; implement every affected surface, including wiring.
7. Delegation names task id, owned files, acceptance predicate, scan patterns, and test command. Verify returned work before integration.
8. Before `[X]`, re-read clauses against test names. Before/after/strictly/only/unless/exactly require equality plus adjacent controls; a nearby happy path is not coverage. Run and inspect the narrow test. Failed sequential work blocks dependants.
9. Run repo gates: lint, typecheck, tests, build, and banned-language lint for changed product copy. After the final mutation, run the primary test gate as its own command event; do not chain, pipe, or wrap it—the recorded event exit must be the gate exit.
10. Confirm every task is `[X]`; set `status: completed`. Report files changed plus exact gate verdicts. Never infer PASS from a command merely running.
11. Next route is `/speck-audit` by a separate auditor, then `/story-validate`. Do not start another story and do not claim a readiness state here.
