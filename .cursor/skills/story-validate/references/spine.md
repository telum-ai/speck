# story-validate — spine

## Pre-validate STOP

1. Missing `audit-report.md` → STOP: run `/speck-audit`. Any P0 → STOP.
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

## Inherited-claim challenge

Cross-examine every evidence claim already present in the report before
replacing it. Classify each cited artifact `PRESENT`, `MISSING`, or
`UNREACHABLE-ATTEMPTED`, then state whether its instrument can observe the
claimed axis. For an inherited blocker, record the exact attempt and verdict
`REPRODUCED` or `NOT REPRODUCED`; explicitly reject an invalid blocker.
Explicitly reject unsupported or surrogate claims; omission is not
adjudication.

## Readiness enum

`NO-SHIP` | `IMPL-GREEN` | `INTEGRATION-GREEN` | `UX-RC` | `API-RC` | `COMMERCIAL-RC` | `SHIP-RC` | `SHIP`

Frontmatter: `readiness_state_claimed`, `readiness_state_verified`, `build_sha`, `build_artifact`, `audit_report`, `larp_evidence`, `clean_build`.

## Flags

`--allow-incomplete`, `--force`, `--skip-perf`, `--skip-quickstart`, `--skip-truth-update`, `--claim <state>`.
