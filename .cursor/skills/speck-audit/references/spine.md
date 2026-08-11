# speck-audit

Mandatory after implementation and before validation. This behavioral audit is separate from the pre-implementation `/analyze --level story` planning challenge.
Output: `<story-or-epic-dir>/audit-report.md`.
P4: auditor ≠ implementer; judged by defects found, not green. P2: every claim resolves to a mechanism.

## 12. Decision-lock application

Scan `project-decisions-log.md` for decisions locked in scope or last 14 days. Multi-file reconciliation specified but not applied → **P1** drift.

## 13. Banned language + gate liveness

```bash
bash .speck/scripts/banned-language-lint.sh <changed-files>
bash .speck/scripts/validation/validators/validate-product-contract.sh --strict specs/projects/[PROJECT_ID]/product-contract.md
bash .speck/scripts/validation/validators/validate-gate-liveness.sh --strict specs/projects/[PROJECT_ID]/evidence-contract.md
```

Opt-in canary (on-demand, throwaway worktree):

```bash
bash .speck/scripts/validation/validators/gate-liveness-probe.sh --require-liveness specs/projects/[PROJECT_ID]/evidence-contract.md
```

`GATE_DISARMED.P1` → P0-adjacent (gate green on injected defect). `GATE_LIVENESS_UNVERIFIED.P2` → cap ship claim, never blocks.

Search implementer summary for banned phrases; require enumeration if found.

## 15. Verdict + continuation

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | Any P0 | Validate refuses PASS |
| NEEDS_FIXES | P1–P3 only | Surface; owner choice |
| CLEAN | No open P0 | Chain to `/story-validate` or `/epic-validate` |

Orchestrated/delegated run: on CLEAN (or NEEDS_FIXES without P0) → **immediately proceed to validate** — audit is mid-lifecycle, not turn boundary.
Stop only on P0 or when user must choose P1–P3 handling.
