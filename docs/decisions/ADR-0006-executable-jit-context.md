# ADR-0006: Executable JIT context contracts

- **Date**: 2026-08-10
- **Status**: accepted
- **Class**: jit
- **Amends**: ADR-0005

## Context

ADR-0005 made conditional load paths explicit in prose. The isolated v10/v11
behavioral tournament showed that this is insufficient as an execution
mechanism:

- one backend task loaded both the backend and UI branch;
- one validation task skipped mandatory execution and post-write references;
- one validation task loaded unrelated states and both UI/backend branches;
- several runs loaded the right reference yet missed a load-bearing obligation
  in the artifact.

The transcripts contain enough evidence to measure reach and timing after the
fact, but ordinary shell reads are host-specific and easy to misclassify. A
stable execution path and a machine-readable receipt are required before
transcript conformance can become a dependable leading signal.

Transcript conformance remains narrower than quality. It can prove that the
declared context was reached selectively and on time; it cannot prove that the
agent understood or used it correctly.

## Alternatives considered

| Mechanism | JIT fidelity | Quality leverage | Auditability | Context cost | Decision |
|---|---|---|---|---|---|
| Reinforce the existing router prose | Medium | Low | Low | Lowest | Reject: the failed runs already ignored exact MUST/Do-not-Read language. |
| Add only a post-hoc transcript parser | Low | Low | Medium | None | Reject: it observes inconsistent host commands without giving agents one dependable loading path. |
| Always inject every skill reference | High reach, no selectivity | Medium | High | Highest | Reject: it reverses v11 subtraction and recreates branch pollution. |
| Manifest-backed loader, receipt, and independent transcript validator | High | Medium | High | Only the selected path | Accept. |

## Decision

1. Canonical high-risk JIT paths are declared in
   `.speck/reference/skill-load-contracts.json`. Each profile names its exact
   required files, forbidden sibling branches, and at least one post-write gate
   when the skill mutates artifacts. Dynamic routers declare required selectors
   such as claimed readiness state and visual host; the selected value is part
   of the receipt and unselected values become forbidden branches.
2. `.speck/scripts/context/speck_context.py PROFILE` is the only receipt-bearing
   load path. It fails closed, reads only contract-declared files, and emits a
   deterministic receipt containing selectors, ordered paths, byte counts, and
   hashes. The transcript validator binds the exact loader argv, requires an
   explicit zero exit code, and byte-compares every emitted BEGIN/END body with
   the isolated workspace; a receipt without its bodies fails REACH.
3. Skills with a declared profile route through the loader before their first
   write. Cheap branch keys are still computed before loading; selection does
   not require preloading a branch.
4. The transcript validator scores four independent axes:
   `REACH`, `SELECTIVITY`, `TIMING`, and `GATE_USE`. It fails when any applicable
   axis fails and explicitly disclaims semantic-use and output-quality proof.
   Gate checks match executable argv and exact repository script paths, not
   substrings or basenames. Selector-specific `all` gates preserve state
   obligations such as FELT and TASTE at UI UX-RC+. Shell redirects and known
   write-capable interpreter forms count as mutations when host events are thin.
5. Load-bearing output obligations remain at their JIT point of use. The
   manifest and receipt do not replace templates, artifact validators,
   adversarial audit, LARP, or behavioral evaluation.
6. The contract, loader, analyzer, and behavioral scorer receive mutation-backed
   self-tests. A green test must demonstrate that seeded violations redden the
   relevant verdict.

## Lock

- **Owner**: Speck v11 methodology
- **Locked mechanism**: manifest-backed selected loading plus receipts and
  independent transcript validation
- **Revisit trigger**: a supported host cannot expose completed command and
  file-mutation events, or a paired behavioral run shows a material quality or
  efficiency regression attributable to receipt loading
- **Acceptance evidence**: corpus-budget check, loader/analyzer mutation suite,
  behavioral scorer contamination mutants, full repository suite, self-eval,
  and a fresh isolated paired run

## Budget delta

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| AGENTS bytes | unchanged | unchanged | 0 |
| Desc sum | unchanged | unchanged | 0 |
| Skill count | unchanged | unchanged | 0 |
| Backend validate path | pre-v11 59,953 B ceiling | 22,682 B worst backend path | -62.2% before receipt overhead |
| UI validate path | pre-v11 59,953 B ceiling | 26,782 B worst state/host path | -55.3% before receipt overhead |

This is a JIT mechanism expansion. It adds no always-on prose, catalog entry, or
unselected reference content.

## Evidence

- Isolated v11 transcripts: 9/12 strict or near-conforming; three concrete
  reach/selectivity failures listed above.
- Mutation-backed loader and transcript tests (required by this ADR).
- A1-lite self-eval and paired behavioral replication (required before release).

## Consequences

Agents have one portable way to load a selected context path, and later review
can distinguish missing context, branch pollution, late loading, and skipped
post-write gates. A contracted behavioral subject is invalid when context
conformance fails; process evidence cannot be laundered into a quality verdict.
Receipts add small command/output overhead. Profiles must be kept aligned with
router DAGs and tight post-subtraction load budgets; corpus validation owns that
drift check.
