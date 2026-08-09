# speck-audit / fidelity

## 4. Spec-to-implementation traceability

Per AC / FR in `spec.md`:
- Supporting code + test exist
- Test asserts behavior, not buggy current state
- Flag `expect().toBe(<wrong>)`, BUG/TODO/fix-later comments
- Flag `test.skip` without reason

## 5. Promise↔Source fidelity sweep (opt-in semantic)

Run before epic close, when `--check-fidelity` WARN, or on demand.
Scope: mandatory on differentiator (product-contract §3) + magic-moment (§5) rows; widen on request.

Structural pre-pass:

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --check-fidelity specs/projects/[PROJECT_ID]/epics/[EPIC_ID]
```

Per in-scope `discharged` row: adversarial subagent gets Source clause (verbatim), row `Promise`, discharged predicate.
Verdict: `faithful` | `drift` (P2) | `contradictory` (P1 — false discharge).
Log Source, Promise, predicate location. Never auto-resolve subjective faithfulness.
