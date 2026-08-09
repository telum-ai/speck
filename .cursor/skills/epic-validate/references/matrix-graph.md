# Promise conservation + graph + gate liveness

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --require-evidence [EPIC_DIR]
bash .speck/scripts/validation/validators/validate-gate-liveness.sh --strict
bash .speck/scripts/validation/validators/gate-liveness-probe.sh --require-liveness specs/projects/<PROJECT_ID>/evidence-contract.md
python3 .speck/scripts/graph/speck_graph.py build specs/projects/<PROJECT_ID>
python3 .speck/scripts/graph/speck_graph.py check specs/projects/<PROJECT_ID>
```

PRM rows: discharged|descoped|pilot-gated. Open → cap.
MATRIX_GRAIN_CAP / GRAIN FLOOR. Evaporation audit → DEC or P1.
GATE_DISARMED.P1 → P1. GATE_LIVENESS_UNVERIFIED.P2 folds into MAX.
DANGLING_REF/DUP_ID/PHANTOM_PROMISE.P1; GRAPH_CAP; UNJUDGED_SURFACE.P2. ORPHAN_CODE not a pass.
