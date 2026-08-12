# project-validate / coverage-matrix

## 8. Coverage matrix (breadth)

Always-on (cheap):
```bash
.speck/scripts/validation/generate-coverage-matrix.sh --level project specs/projects/<PROJECT_ID>
bash .speck/scripts/validation/validators/validate-coverage-matrix.sh specs/projects/<PROJECT_ID>
```

`--exhaustive` (opt-in, expensive): adjudicate prior `speck-larp <persona> --tier=torture` evidence per cell (persona × route × {happy,error,empty,loading} × viewport × theme + input-variety on §8 AI surfaces). Missing cells STOP and route back to the producer; validation never fans out LARP. Require the recorded Job A/B/C verdict and real `larp-recordings/…` path per cell.

Breadth verdict caps (never raises) claimable state. `validate-coverage-matrix.sh --strict` before SHIP-RC when §8 declares matrix required.
