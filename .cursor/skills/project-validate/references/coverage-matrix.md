# project-validate / coverage-matrix

## 8. Coverage matrix (breadth)

Always-on (cheap):
```bash
.speck/scripts/validation/generate-coverage-matrix.sh --level project specs/projects/<PROJECT_ID>
bash .speck/scripts/validation/validators/validate-coverage-matrix.sh specs/projects/<PROJECT_ID>
```

`--exhaustive` (opt-in, expensive): fan-out `/speck-larp <persona> --tier=torture` per cell (persona × route × {happy,error,empty,loading} × viewport × theme + input-variety on §8 AI surfaces). Deterministic `banned-language-lint.sh` across N samples; full-page axe + Lighthouse; evidence-contract §11 resilience cells. Record Job A/B/C verdict + real `larp-recordings/…` path per cell.

Breadth verdict caps (never raises) claimable state. `validate-coverage-matrix.sh --strict` before SHIP-RC when §8 declares matrix required.
