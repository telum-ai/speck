# Promise inventory before L3

Run the witness graph and enumerate MM/JOB nodes. Restrict coverage to the selected project or epic scope.

```bash
python3 .speck/scripts/speck_graph.py build --root . --json \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every printed in-scope id needs a coverage row. If the graph is unavailable, report `NOT COMPUTED` (`ANALYSIS_COVERAGE_UNCOMPUTED.P2`); never substitute hand-grep. An epic may defer a UI-only MM on a backend scope only by naming the carrying epic.
