# speck / first-actions

## 0. First-actions ladder (stop at first hit)

0. `.speck/.v9-graph-needed` → `/speck-graph-up`. Else `python3 .speck/scripts/graph/speck_graph.py build` + `check`. Hard `.P1` blocks; repair first. `GRAPH_CAP` caps claims. python3 absent → WARN + proceed.
1. `.speck/.v8-reprove-needed` → `/speck-reprove`. Cap INTEGRATION-GREEN; FELT uncovered until re-earned.
2. `.speck/.migration-needs-catchup` OR `<!-- v7 MIGRATION SCAFFOLD -->` in truth docs → `/speck-catch-up`.
3. Read `specs/projects/<id>/project-state.md` if present.
4. Play level from `.speck/project.json` (`play_level`; missing = platform).
5. Engagement gap (missing/stale>2w/`< speck 8`/new agent) → `/recheck`.
6. Then route user request.

## NEVER / ALWAYS

- NEVER skip first-actions ladder
- NEVER route to `/story-implement` on engagement gap without `/recheck`
- NEVER set Platform play level solely from complexity 3–4
- NEVER invent filenames under `specs/` (see `.speck/reference/canonical-routing.md`)
- NEVER skip `/project-analyze` before `/epic-specify` when gate applies
- ALWAYS read `project-state.md` Next action on continuation
- ALWAYS run scale analysis when no context provided
- ALWAYS respect user override of routing recommendation
- ALWAYS block feature work when catch-up or v8-reprove markers present
