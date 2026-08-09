# Promise inventory (graph only)

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/[PROJECT_ID] --stdout \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every printed id → coverage matrix row.
Graph unavailable → `NOT COMPUTED` (`ANALYSIS_COVERAGE_UNCOMPUTED.P2`). Never hand-grep `### MM-`.
