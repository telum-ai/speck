# Gap routing (`/goal` companion)

Run `python3 .speck/scripts/graph/speck_graph.py check <project-dir>` and `gap <project-dir>`. Surface their stdout. Stop on literal `SPECK-GAP: none`; otherwise route the highest-priority gap:

`/story` and `/epic` are user-only entry points, so a driving loop cannot invoke them. It routes to
the granular skills directly and carries the orchestrator's own obligations itself: read
`.speck/reference/lifecycle-state.md` for the state ladder and the stop-gates, and execute each
step by loading its `SKILL.md` rather than reproducing it from the flow line.

| Gap | Route |
|-----|-------|
| Promise has no trace, delivery, or real discharge | Resume the story flow at its first missing step — detect which step that is with `.speck/reference/lifecycle-state.md`, and apply its stop-gates |
| Audit has an open P0/P1 | `harden` |
| User experience is untested or a magic moment is unjudged | `speck-larp` |
| Taste fork, product-contract pivot, price, deploy, or other owner gesture | Stop for the owner decision |
| Graph is stale | `python3 .speck/scripts/graph/speck_graph.py build <project-dir>` |
