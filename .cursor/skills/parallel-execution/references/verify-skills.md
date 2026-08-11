# parallel-execution / verify-skills

Before accepting or merging a delegated unit:

1. Confirm every required artifact exists and passes `bash .speck/scripts/validation/validate-template.sh --strict <path>`.
2. Inspect the host transcript for real skill invocations. Stories require `speck-audit` and `story-validate`; epics require `analyze` at epic level, `speck-audit`, and `epic-validate` when the canonical flow reaches them.
3. For contract-backed JIT paths, run the context-transcript validator and require REACH, SELECTIVITY, TIMING, and GATE_USE. A skill call without its required context receipt is incomplete.
4. Require an audit by a separate evaluator that did not implement the unit. High-risk work uses multiple decorrelated lenses as required by its evidence contract.
5. Read the test, lint, type, build, and banned-language outputs themselves. Missing commands, skipped checks, empty logs, or self-reported green are not proof.
6. Check that the implementation diff did not weaken the tests, graders, hooks, or CI that certify it. Verification changes need separate review.
7. Reject the unit when any required invocation, report, gate output, or independent audit is absent. Record the rejection in the orchestration ledger and rerun from the first missing gate.
