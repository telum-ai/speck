# Matrix and witness graph

Run the traceability matrix with evidence required:

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --require-evidence [EPIC_DIR]
```

- Every `PRM-NNN` is `discharged`, `descoped` by a decision, or
  `pilot-gated`. Open promises cap readiness.
- Apply `MATRIX_GRAIN_CAP`; an ungraded matrix caps at `INTEGRATION-GREEN`.
- Evidence grain cannot exceed the effective story state. `UX-RC+` rows need
  real walkthrough evidence.
- Search the shipped code for dead seams: an enum never set, an uncalled
  feature path, or an orphan route requires a decision or a P1 fix.

For UX-RC+ transitions, run strict gate liveness and its probe. A disarmed gate
is P1; unmeasured liveness lowers the maximum claim.

Build and check the witness graph:

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/<PROJECT_ID>
python3 .speck/scripts/graph/speck_graph.py check specs/projects/<PROJECT_ID>
```

`DANGLING_REF.P1`, `DUP_ID.P1`, and `PHANTOM_PROMISE.P1` block. A stale or
unmigrated graph caps at `INTEGRATION-GREEN`. `UNJUDGED_SURFACE.P2` blocks a
quality claim until the separate LARP evidence is adjudicated. `ORPHAN_CODE`
remains not evaluated until joined to runtime/test evidence.
