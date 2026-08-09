# story-validate — spine

## Pre-validate STOP

1. Missing `audit-report.md` → STOP: run `/audit`. Any P0 → STOP.
2. Missing project `evidence-contract.md` → STOP: run `/project-evidence-contract`.
3. Missing `spec.md`/`plan.md`/`tasks.md` → ERROR: specify/plan/tasks first.

## Axes (non-collapsible)

| Axis | Owner |
|------|-------|
| CORRECT | Tests, mutation, traceability, audit |
| ON-CONTRACT | evidence-contract gates at claimed + lower |
| FELT-GOOD | Naive-hostile LARP (consumer UX-RC+) |
| TASTE | Connoisseur pass (consumer UX-RC+) |

LARP = DOES-IT-WORK + IS-IT-GOOD.

## Readiness enum

`NO-SHIP` | `IMPL-GREEN` | `INTEGRATION-GREEN` | `UX-RC` | `API-RC` | `COMMERCIAL-RC` | `SHIP-RC` | `SHIP`

Frontmatter: `readiness_state_claimed`, `readiness_state_verified`, `build_sha`, `build_artifact`, `audit_report`, `larp_evidence`, `clean_build`.

## Flags

`--allow-incomplete`, `--force`, `--skip-perf`, `--skip-quickstart`, `--skip-truth-update`, `--claim <state>`.

## NEVER / ALWAYS

- NEVER skip failing tests unless `--force`
- NEVER verify without evidence; NEVER UX-RC+ from code-read alone
- NEVER defer browser cold-start LARP for UI archetypes
- NEVER mark device-walk ✅ without human attestation
- NEVER hand-type mutation verdicts; NEVER PASS/FAIL instead of state
- ALWAYS `/audit` before validate; ALWAYS deferrals with Cap Status
- ALWAYS honest PRM grain; ALWAYS SHA-stamp
