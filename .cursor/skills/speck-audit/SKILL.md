---
name: speck-audit
description: Audits implemented work adversarially. Use after implementation and before any story or epic validation.
---

# speck-audit

Audit searches for defects in implemented work. It does not declare readiness; validation does that after audit and applicable runtime evaluation.

## Scope and independence

1. Resolve the active story or epic. Story prerequisites are `spec.md`, `plan.md`, `tasks.md`, completed implementation, and the project evidence contract. Epic audit requires completed story audits and validations.
2. Use a separate auditor that did not implement the target. For security, privacy, billing, or another P0/P1-sensitive surface, use at least three independent lenses appropriate to the risk. Reviewers do not share findings before synthesis.
3. Read the target corpus, inherited product/evidence contracts, changed files, relevant decisions, and implementer handoff evidence. Treat summaries as leads, never proof.

## Attack the implementation

1. Trace every in-scope requirement and acceptance criterion to the exact implementation path and a behavior assertion. Flag skipped, tautological, state-mirroring, or bypass-role tests.
2. Derive break attempts from the evidence contract and changed mechanisms. Exercise failure paths, boundary attribution, async teardown, external dependency failure, and rollback where applicable.
3. For authorization, tenant, or RLS claims, use a real least-privileged principal and attempt the forbidden operation. For sensitive data, enumerate all readers and writers across the codebase before trusting a seam-local guard.
4. Run the relevant suite in its normal configuration and in changed order when the harness supports it. Record unavailable probes as reproduced limits, not passes.
5. At epic close, and for differentiators or magic moments, run:

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --check-fidelity specs/projects/[PROJECT_ID]/epics/[EPIC_ID]
```

Adjudicate each discharged promise as `faithful`, `drift` (P2), or `contradictory` (P1). Subjective fidelity never auto-resolves.
6. Reconcile recent decision locks against every file they require. A declared multi-file decision applied only partly is P1 drift.
7. Run applicable contract checks as separate commands:

```bash
bash .speck/scripts/banned-language-lint.sh <changed-files>
bash .speck/scripts/validation/validators/validate-product-contract.sh --strict specs/projects/[PROJECT_ID]/product-contract.md
bash .speck/scripts/validation/validators/validate-gate-liveness.sh --strict specs/projects/[PROJECT_ID]/evidence-contract.md
```

Use `gate-liveness-probe.sh --require-liveness` in a throwaway worktree when gate behavior itself is in doubt. A gate that stays green on its injected defect is P0-adjacent.

## UI branch

If the target has a user interface, MUST Read `references/ui.md` and execute it. Otherwise do not load that file. UI evidence remains the later LARP/visual-testing job; audit only identifies implementation defects and unreachable paths.

## Close

Write `<target>/audit-report.md` with the auditor roster, real probes and exits, findings by P0-P3, and any untested boundary. Stamp it:

```bash
bash .speck/scripts/stamp-truth.sh <target>/audit-report.md
```

Any P0 is `BLOCKED`; validation must not advance. Open P1-P3 is `NEEDS_FIXES` and must remain visible to validation. With no open P0, continue directly to applicable LARP and validation; an audit report is not a turn boundary or a readiness claim.
