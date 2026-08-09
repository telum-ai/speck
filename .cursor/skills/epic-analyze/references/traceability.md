# Traceability conservation

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh [EPIC_DIR]
```

- Open/unmapped `PRM-NNN` → P1 BLOCK (promise evaporation).
- Missing `traceability-matrix.md` → P1 BLOCK: re-run `/epic-plan` matrix step.
- Un-enumerated promise (no row) → P1 via L3.
