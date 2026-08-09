# Promise inventory (graph only)

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/[PROJECT_ID] --stdout \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every printed id in this epic's scope → coverage matrix row.
Graph unavailable → report `NOT COMPUTED` (`ANALYSIS_COVERAGE_UNCOMPUTED.P2`). Never hand-grep `### MM-`.
UI-only MM on backend epic → deferral naming carrying epic; never silent pass.
