# Gap routing (`/goal` companion)

Run `python3 .speck/scripts/graph/speck_graph.py check <project-dir>` and `gap <project-dir>`. Surface their stdout. Stop on literal `SPECK-GAP: none`; otherwise route the highest-priority gap:

| Gap | Route |
|-----|-------|
| Promise has no trace, delivery, or real discharge | Resume the story flow at its first missing step |
| Audit has an open P0/P1 | `harden` |
| User experience is untested or a magic moment is unjudged | `speck-larp` |
| Taste fork, product-contract pivot, price, deploy, or other owner gesture | Stop for the owner decision |
| Graph is stale | `python3 .speck/scripts/graph/speck_graph.py build <project-dir>` |
