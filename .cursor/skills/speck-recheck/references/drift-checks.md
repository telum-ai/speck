# speck-recheck / drift-checks

## 2. Parallel drift detection

Run in parallel where host supports subagents; else sequential:

```bash
bash .speck/scripts/staleness-check.sh
bash .speck/scripts/check-replace-markers.sh specs/projects/<id>/
bash .speck/scripts/banned-language-lint.sh
bash .speck/scripts/profile-drift-check.sh          # when PROFILE integrated
bash .speck/scripts/settings-drift-check.sh         # when .claude/settings.json exists
bash .speck/scripts/asset-drift-check.sh            # when UI/brand assets exist
bash .speck/scripts/validation/validators/validate-schema-drift.sh   # DB-backed
bash .speck/scripts/validation/validators/compute-cascade.sh --strict  # superseded DECs
bash .speck/scripts/validation/validators/compute-eval-signals.sh --strict
bash .speck/scripts/market-staleness-check.sh       # when product-contract.md exists
bash .speck/scripts/market-reconcile-check.sh
bash .speck/scripts/validation/validators/validate-gate-liveness.sh specs/projects/<id>/evidence-contract.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate specs/projects/<id>
python3 .speck/scripts/graph/speck_graph.py build specs/projects/<id> && python3 .speck/scripts/graph/speck_graph.py check specs/projects/<id>
grep -rln "\[NEEDS USER REVIEW\]" specs/projects/<id>/
```

Subagent scans (when available):
- Spec-vs-code reconciliation (product-contract / PRD / architecture assertions vs code)
- Third-party integration risk (auth model, ToS, data residency) — vendor docs via Context7 / official docs JIT
- Constitution principle compliance

Each check returns: FRESH | STALE | DRIFTED | MISSING with evidence.

### REPLACE_BEFORE_SHIP markers

Token present → artifact incomplete; cannot support readiness above IMPL-GREEN.
- Referenced by active UX-RC+ claim → P0
- Otherwise → P1
- Remediation: `/speck-catch-up`

### Graph drift codes

`DANGLING_REF.P1`, `DUP_ID.P1`, `UNMAPPED_PROMISE.P1`, `PHANTOM_PROMISE.P1`, `DEP_CYCLE.P1`. `GRAPH_CAP` / `GRAPH_UNMIGRATED.P3` advisory.

### Analysis gate codes

`UNANALYZED_CORPUS.P1`, `ANALYSIS_STALE.P1`, `ANALYSIS_CRITICAL_OPEN.P1`, `PROMISE_UNCOVERED.P1`, `ANALYSIS_DECORRELATION_UNVERIFIED.P2`, `ANALYSIS_COVERAGE_UNCOMPUTED.P2`, `ANALYSIS_GRANDFATHERED.P2`.

Grandfather marker: surface uncollapsed every recheck; one `/project-analyze` spends it (`check-epic-prereqs.sh` prints `rm` command).

### Mutation codes (`GUARD_*`)

From `mutate-guard.sh` → `SPECK_MUTATION_VERDICT=<code>`:

| Code | Meaning |
|------|---------|
| `GUARD_MUTATION_PROVEN` | Not a finding; carry as evidence |
| `GUARD_MUTATION_GREEN.P2` | Mutation happened; suite missed it — honest, non-blocking |
| `GUARD_MUTATION_UNOBSERVABLE.P2` | Subject needs `--applier`; test could not see mutation |
| `GUARD_UNMUTATED.P2` | Nothing measured; AC not discharged |
| `GUARD_UNMUTATED_HARNESS.P2` | Harness could not run probe |

### Observation codes (`OBSERVATION_*`)

From `observe-guard.sh` → `SPECK_OBSERVATION_VERDICT=<code>`:

| Code | Meaning |
|------|---------|
| `OBSERVATION_EXPOSED` | Not a finding; instrument shown able to display thing |
| `OBSERVATION_UNEXPOSED.P2` | Green licenses only waiting — non-blocking |
| `OBSERVATION_UNEXPOSED_BLOCKING.P1` | Green licenses accumulating/irreversible act — run does not count |
| `OBSERVATION_NOT_GREEN.P1` | Observation failed; cancelled CI ≠ pass |
| `OBSERVATION_UNMEASURED.P2` | Nothing measured; destructive invocation refused |

## 3. Persona LARP cold-start

**consumer_product / b2b_saas / internal_tool**: per persona in `personas/<id>.md`, cold-start app (clean storage), execute LARP script, capture evidence vs product-contract magic moments. Use `/larp`.

**infra_service / backend_api**: run integration/stress scenarios from evidence-contract Option B.

Any failure → P0 drift.

## 4. Synthesize drift report

Per finding: severity (P0–P3), type code, location, evidence, recommended fix.

Finding types include: SPEC_VS_CODE, TRUTH_STALE, TEMPLATE_DRIFT.P1/P2, LARP_FAIL, INTEGRATION_RISK, PRINCIPLE_VIOLATION, BANNED_LANGUAGE, PROFILE_DRIFT.P1/P2/P3, SETTINGS_DRIFT.P0, SCHEMA_DRIFT.P0, CASCADE_STALE.P1, MARKET_DRIFT.P1/P2, WEDGE_DRIFT.P1/P2, GATE_WIRING_DRIFT.P1, V8_REPROVE.P1, plus GUARD_* and OBSERVATION_* above.

## NEVER / ALWAYS

- NEVER skip persona LARP cold-start (when product type requires it)
- NEVER claim "no drift" without running staleness-check, banned-language-lint, check-replace-markers, and applicable drift scripts listed in §2
- NEVER mark artifact fresh while `REPLACE_BEFORE_SHIP:` or `[NEEDS USER REVIEW]` remain
- NEVER let OBSERVATION close P0 or re-stamp without checking what green licenses
- NEVER treat cancelled/skipped CI as pass (`OBSERVATION_NOT_GREEN.P1`)
- NEVER report `ANALYSIS_COVERAGE_UNCOMPUTED.P2` as coverage pass
- NEVER collapse `ANALYSIS_GRANDFATHERED.P2` across sessions
- NEVER hand-write `*[market-verified …]*` stamp (only `stamp-market.sh`)
- ALWAYS write dated report
- ALWAYS update `project-state.md` regardless of verdict
- ALWAYS route `/speck-reprove` when v8-reprove marker or V8_STALE present
- BLOCK feature work on P0
