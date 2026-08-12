# ADR-0011: Positive quality objective, declared PROFILE surfaces, and AGENTS-owned entry routing

- **Date**: 2026-08-11
- **Status**: accepted
- **Class**: spine + skill-catalog + jit + gate
- **Amends**: ADR-0002, ADR-0008, ADR-0009, ADR-0010

## Decision question

How should Speck preserve its positive product-quality objective, enforce PROFILE beyond README, and remove `/speck` as a competing orchestrator without expanding always-on context back into a procedure manual?

Constraints: PROMISE must define what good means; the four readiness axes remain non-collapsible; every declared PROFILE surface needs a real drift mechanism; AGENTS remains below its hard budget; existing `/speck` and `/project-readme` invocations remain additive migrations; automatic routing must work without either alias.

## Alternatives

1. **Patch the status quo.** Improve the opening sentence and add more README-script branches while keeping `/speck` and `project-readme` as orchestrators. Lowest migration cost; likely failure is continued conceptual and routing drift because broad concepts retain narrow names and duplicate owners. Falsifier: a non-README declared surface can drift while the PROFILE gate stays green.
2. **One canonical PROFILE router plus compatibility aliases.** Put the positive objective and unscoped-work rule in AGENTS; make `project-profile` the sole automatic PROFILE skill; keep `/project-readme` and `/speck` as reference-free user aliases; enforce the `project.md` registry through deterministic adapters. Moderate migration cost; likely failure is an adapter vocabulary that becomes another fixed checklist. Falsifier: a declared generic file surface cannot be checked without changing the skill catalog.
3. **AGENTS and scripts only.** Delete the three router skills and place scope resolution, PROFILE procedure, and compatibility behavior in AGENTS/scripts. Fewest skill files; likely failure is always-on procedure growth and weaker explicit-command compatibility. Falsifier: the complete behavior fits the always-on budget and routes equally well without adding selection ambiguity.

## Comparison and lock

Option 2 best fits quality, enforcement, compatibility, and context constraints. The registry is open through a generic `file` adapter while fragile behavior remains deterministic. Option 1 fails P2 because the pillar can still overclaim its mechanism. Option 3 spends always-on context on procedure rather than sequence.

Locked choice: **Option 2**.

## Decision

1. Speck optimizes for realizing the promised good. PROMISE defines the quality bar; BUILD realizes it; PROVE independently searches for anything preventing the real result from passing the applicable axes. Green artifacts are evidence, not the objective.
2. `project.md` owns a binding PROFILE registry. Every retained row declares an adapter, target, source of truth, and readiness boundary. README is the center of gravity, not the pillar's extent.
3. `project-profile` is the only automatic PROFILE entrypoint. It refreshes safely managed local surfaces and runs the all-surface drift gate. `project-readme` is a user-only compatibility shim.
4. `/speck` is a user-only compatibility shim that reapplies AGENTS routing. Scope resolution for unscoped work lives once in the engagement ladder. Router-local copies are deleted.
5. Semantic conservation is a separately guarded evaluation surface. Every load-bearing pre-v11 obligation is classified as spine, JIT, executable gate, compatibility, or deliberate retirement and mapped to reachable current carriers. Deleting a carrier or anchor must turn the harness red.
6. PROFILE gates fail closed for required local surfaces. Remote surfaces use a real provider read or produce an explicit unreachable finding; a manual assertion cannot silently count as alignment.

## Budget delta

Measured at the commit boundary (`git archive` of the parent commit vs. the commit that lands this ADR), via `validate-corpus-budget.sh`:

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| AGENTS bytes | 9121 | 10048 | +927 |
| AGENTS lines | 97 | 100 | +3 |
| Desc sum | 6902 | 6904 | +2 |
| Auto-invoked skill count | 63 | 63 | 0 |
| Skill dirs (total) | 79 | 80 | +1 |

Equal retirement: `project-profile` is added as the sole automatic PROFILE entrypoint (+1 auto-invoked skill); `project-readme` is demoted to `disable-model-invocation: true` in the same change (-1 auto-invoked skill), holding the auto-invoked skill count at 63. The new skill dir (`project-profile`) is the only net addition to the catalog.

## Evidence

- Gate change (PROFILE fail-closed, Decision item 6): fail-closed A1-lite candidate-corpus score against the immutable baseline, `bash tests/eval/score.sh --root . --check` — 12/12 fixtures correct, `catch_rate_pct` 100.0, `clean_rate_pct` 100.0, 0 regressions against `tests/eval/reports/baseline.json`.
- Catalog expansion (`project-profile` added, `project-readme` demoted): `bash .speck/scripts/validation/validators/validate-corpus-budget.sh` passes at the commit boundary, and the equal-retirement arithmetic above holds the auto-invoked skill count flat.

## Consequences

- Existing explicit commands keep working without owning sequence.
- PROFILE can grow by declaring surfaces rather than adding automatic skills.
- Flow and semantic-baseline changes require the repository's external approval label.
- Context conformance still proves loading and gate use, not semantic understanding or output quality; paired behavioral evaluation remains a separate release signal.

## Revisit triggers

- AGENTS-only routing loses more than 5 percentage points on either intended model family.
- A common PROFILE surface cannot be represented by the generic adapter contract.
- The compatibility aliases receive meaningful procedure again.
- A paired current-HEAD run shows a material quality or false-green regression attributable to this decision.
