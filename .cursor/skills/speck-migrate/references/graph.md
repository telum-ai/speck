# Witness-graph repair

Establish a trustworthy witness graph after scaffold and legacy-proof repair. The graph proves traceability, completeness, and freshness; it never proves fidelity or quality.

## 1. Preflight and migrate identities

Confirm older migration markers are already cleared. Run the graph migration in dry-run mode, inspect identity collisions and unresolved references, then apply:

```bash
python3 .speck/scripts/graph/speck_graph.py migrate
python3 .speck/scripts/graph/speck_graph.py migrate --apply
python3 .speck/scripts/graph/speck_graph.py lint-refs
```

Harden missing MM/JOB/DIF, epic, story, and decision identifiers in their canonical artifacts. Resolve collisions deliberately; do not invent mappings where the product truth is ambiguous.

## 2. Compile from source truth

Run `speck_graph.py build`, then `check` and `gap`. Never hand-edit generated `witness.json`; fix its source artifacts and rebuild.

Repair hard `.P1` findings first: duplicate identities, dangling references, phantom witnesses, untraced promises, and stale graph state. A real product gap stays open; graph migration must not launder it into a witness.

## 3. Reconcile the road already walked

- Preserve pre-v9 proof history and its effective cap; run `reconcile-matrix-grain.sh` when capped story evidence and matrix grain disagree.
- Move witness-bearing prose into the canonical ledger/matrix fields the compiler reads rather than keeping a second authored graph.
- Grade ungraded discharge rows and repair dangling references.
- Treat orphan removal as a product decision requiring human confirmation when scope is not already locked.
- Generate `road`; then regenerate `project-state.md` from the compiled graph rather than copying a stale state claim forward.

## 4. Finish

Delete `.speck/.v9-graph-needed` only after build, `road`, `check`, and `gap` all run, the witness is fresh, and no hard graph finding remains. Real promise gaps may remain only when project state names their route and readiness cap.
