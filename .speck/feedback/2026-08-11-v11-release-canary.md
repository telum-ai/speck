# Speck Feedback — v11 release canary

**Date**: 2026-08-11
**Speck version (workspace)**: v11.0.0
**Methodology candidate**: `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea` on branch `feat/v11-subtraction`
**Workspace**: Speck source (Platform; v11 release validation)

---

## TL;DR

A read-only canary over a real Build project exposed an entry-order ambiguity: the agent treated reading `project-state.md` as a stopping action and skipped the mandatory new-agent recheck. It then exposed a targetless command in the recheck recipe. A separate CLI probe showed that `speck upgrade --help` performed a real upgrade. All were reproduced and patched inline with focused regression evidence.

---

## Gap / Observation C1: Context read bypasses later engagement gates

**Symptom**: On a “what is next?” request, the agent stopped at the `project-state.md` Next action and described `/speck-recheck` as advisory even though it was new to the project.

**Reproduction**: Install the v11 candidate into an isolated snapshot of a real project, ask a fresh agent for the exact next autonomous action, and inspect its transcript and routing rationale.

**Root cause**: `AGENTS.md` said both “Stop at the first action that applies” and “On status/continue/next, follow its Next action” before the new-agent recheck step. A context read therefore looked like a higher-priority terminal route.

**Severity**: P1

**Patch applied**: The ladder now distinguishes context reads from routing actions, captures Next action without executing it, requires recheck before project work, and follows Next action only after entry gates clear. The recheck skill and command-phase explanation use the same trigger.

**Proposed upstream fix**: Shipped in this branch; retain a real-repo transcript canary for this precedence rule.

**Impact**: Prevents fresh agents from acting on stale or un-reconciled project truth.

## Gap / Observation C1b: Project-state prose waives a live graph P1

**Symptom**: After correctly naming recheck first, the agent called six `PHANTOM_PROMISE.P1` findings “accepted structural deferrals” and queued formatting even though the graph artifact said “cannot advance until fixed.”

**Reproduction**: Repeat the status canary against a project whose checked graph carries hard P1 findings and whose project-state names unrelated hygiene work first.

**Root cause**: The ladder required P1 repair but did not explicitly resolve conflict with project-state prose that described the cap as accepted debt.

**Severity**: P1

**Patch applied**: The graph step now states that project-state prose and accepted-deferral labels cannot waive a live P1 before any captured Next action.

**Proposed upstream fix**: Shipped in this branch and conserved in the semantic baseline.

**Impact**: Prevents agents from laundering blocking traceability failures into background debt.

---

## Gap / Observation C2: Help flag dispatches a destructive command

**Symptom**: `node packages/cli/bin/speck.js upgrade --help` fetched the published release and modified the working tree instead of printing help.

**Reproduction**: Run `speck upgrade --help` in a disposable directory and compare the directory before and after.

**Root cause**: Help handling existed only as command cases, so a help flag after `upgrade` reached upgrade dispatch.

**Severity**: P1

**Patch applied**: Global help now returns before option parsing or dispatch. Integration tests assert both `upgrade --help` and `upgrade -h` exit zero, print usage, omit upgrade output, and preserve directory contents.

**Proposed upstream fix**: Shipped in this branch; keep the integration test in the root suite.

**Impact**: Makes command help reliably read-only and prevents accidental methodology downgrades.

## Gap / Observation C3: Recheck invokes a targetless cascade computation

**Symptom**: The recheck transcript ran `compute-cascade.sh --strict`; the command exited 2 because cascade computation requires `--dec` or `--contract-section`.

**Reproduction**: Follow the command literally from `speck-recheck/SKILL.md` in any project.

**Root cause**: A targeted adjustment validator was listed as an unconditional whole-project drift check.

**Severity**: P1

**Patch applied**: Recheck now invokes the validator only for each decision superseded since the last verified recheck and supplies the required `--dec DEC-NNNN` target.

**Proposed upstream fix**: Shipped in this branch; the existing validator invocation tests remain authoritative for its CLI contract.

**Impact**: Removes a guaranteed false blocker while retaining cascade validation exactly when a changed decision makes it relevant.

## Gap / Observation C4: Correct JIT load, unbound closure gate

**Symptom**: Exact-head tournament subjects loaded the correct story branch before mutation, but `story-tasks` and backend implementation failed transcript `GATE_USE` because their final validator/test was bundled with unrelated commands.

**Reproduction**: Inspect the post-hoc context reports for `story-tasks` and `implement-backend`: REACH, SELECTIVITY, and TIMING pass; GATE_USE reports no exit-bound gate after the last mutation.

**Root cause**: The receipted contract declared `direct-event-exit-bound`, but the JIT procedural spine only said to run the gate and did not translate that policy into an explicit shell boundary.

**Severity**: P1

**Patch applied**: Both spines now require the final validator or primary test gate as a standalone command after the final mutation, with no chain, pipe, or wrapper.

**Proposed upstream fix**: Shipped in this branch; the final frozen tournament passed GATE_USE for all 8 applicable v11 transcripts.

**Impact**: A green transcript now proves the recorded process exit belongs to the named closure gate instead of a later command in a compound shell expression.

## Gap / Observation C5: Framework commits blocked by an inapplicable product gate

**Symptom**: The Speck source pre-commit hook rejected the release-canary commit because staged banned-language lint could not locate a project `product-contract.md`.

**Reproduction**: Run `banned-language-lint.sh --staged` in a framework or Sprint repository with no product contract.

**Root cause**: The staged gate treated an absent term producer as an invocation error instead of an explicit not-applicable state.

**Severity**: P1

**Patch applied**: Staged mode now exits green with `SPECK_GATE_SCOPE=not-applicable:no-product-contract`; full-scan mode remains fail-closed. A regression test pins both the explicit verdict and telemetry.

**Proposed upstream fix**: Shipped in this branch and exercised through the real pre-commit hook.

**Impact**: Framework and Sprint commits remain possible without bypassing hooks, while projects that declare banned terms retain the blocking scan.

---

## Round-trip status

| Feedback ID | Filed | Shipped in | Status |
|-------------|-------|------------|--------|
| C1 | 2026-08-11 | v11.0.0 candidate | fixed, cross-host canary green |
| C1b | 2026-08-11 | v11.0.0 candidate | fixed, cross-host canary green |
| C2 | 2026-08-11 | v11.0.0 candidate | fixed, regression test green |
| C3 | 2026-08-11 | v11.0.0 candidate | fixed, targeted invocation restored |
| C4 | 2026-08-11 | v11.0.0 candidate | fixed, final transcript tournament 8/8 green |
| C5 | 2026-08-11 | v11.0.0 candidate | fixed, hook regression green |

---

## Concrete proposals summary (prioritized)

| # | Proposal | Effort | Impact |
|---|----------|--------|--------|
| **P1** | Preserve entry-gate precedence in transcript canaries | Small | High |
| **P1** | Keep all help paths pre-dispatch and read-only | Trivial | High |
| **P1** | Keep targeted validators conditional and fully parameterized | Trivial | Medium |
| **P1** | Bind closure evidence to a standalone gate event | Small | High |
| **P1** | Emit explicit non-applicability when a gate has no producer | Small | High |

## Later release hardening

The same release arc also closed false-green paths found by independent audits:

- Semantic conservation now protects its evaluator, workflow wiring, package entrypoint, and load-bearing regions instead of trusting anchor presence alone.
- PROFILE validation fails closed on malformed rows, unknown readiness requirements, targeted-surface parsing errors, and claim-specific drift.
- Template export and CLI sync exclude generated Python and operating-system cache files without excluding runtime Python.
- Epic architecture, project planning, evidence-contract, and story flows load artifact-writing detail only when the relevant branch is selected.
- Story specification and task closure reject mutations after their final validators, including wrapped, reordered, and synonym-bearing false-green variants.
- The behavioral UI scorer now requires the wired browser entry path, exercises select and deselect for every randomized item before and after remount, proves full-batch and partial approvals, and rejects disconnected, truncated, stale, capped, and counter-facade renderers.

Each correction has a focused negative control. A decorrelated closure audit of the exact rescore evaluator found no reproducible P0/P1 false-green or evidence-integrity defect. The final release report records all subject artifacts, context receipts, the blinded judge, and the exact post-run evaluator revision used for disclosed rescoring.

---

## Context (auto-collected)

### Projects in this workspace

- **Speck source**: recipe=`n/a`, play_level=`platform`, archetype=`methodology`, speck_version=`v11.0.0`
- **001-odd snapshot**: play_level=`build`, real-project status-routing canary

### Friction signals detected

- **ENTRY_PRECEDENCE**: a read step was interpreted as a terminal route.
- **HELP_SIDE_EFFECT**: a documentation flag reached command dispatch.

---

*Generated by Speck feedback channel; no issue submitted because the upstream fix is this branch.*
