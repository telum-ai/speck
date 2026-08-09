The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`/recheck` is the **engagement-gap drift detector** that prevents Speck's #1 failure mode: an agent (or human) picks up a project after time has passed and starts new feature work on top of stale assumptions.

Six v6 projects independently described this pattern:
- Odd: B0 ToS violation shipped through 7 epics of validation; would have surfaced via persona LARP cold-start
- Pust: validation docs said GO-SHIP while real app had broken fresh-user flow
- Splang: R12 was "no more hand-waving" but worktree backend had never booted
- Brightstance: old PASS docs disagreed with current HEAD's runtime

The fix is structural: every engagement above a threshold gap runs `/recheck` BEFORE any new work.

## When to Run

`/recheck` is **mandatory** when any of:
- More than 14 days since the latest truth artifact's `verified` stamp
- A new agent picks up the project (no record of prior session continuity)
- User explicitly requests audit / "make ship-ready" / "is this still working"
- The "Next action" in `project-state.md` is unknown or empty
- **v8 re-prove**: `.speck/.v8-reprove-needed` exists OR `staleness-check.sh` reports any `V8_STALE` artifact (stamped `< speck 8`). The project's green is verification-shaped (`[pre-v8-proof]`); this raises `V8_REPROVE.P1` and routes to `/speck-reprove` **before** any other drift work.

`/recheck` is **optional but recommended** when:
- Major dependency updates (framework, language, lib) since last validation
- Multiple parallel branches merged since last validation

## Prerequisites

- Inside a Speck project (find `specs/projects/<id>/` by walking up)
- Git repository (for SHA comparison)

## Execution Steps

### 1. Locate project and prerequisites

Find `specs/projects/<PROJECT_ID>/`. Determine play level from `.speck/project.json`.

Required artifacts to check:
- `project-state.md` (if exists; if not, that's already drift)
- All truth artifacts per play level (per `staleness-check.sh`)
- `product-contract.md` (banned language, magic moments)
- `evidence-contract.md` (proof requirements)

### 2. Run subagent-parallel drift detection

```
├── [Parallel] shell: Run .speck/scripts/staleness-check.sh
├── [Parallel] shell: Run .speck/scripts/check-replace-markers.sh specs/projects/<id>/
├── [Parallel] speck-scanner: Spec-vs-code reconciliation — for each truth assertion in product-contract.md / PRD.md / architecture.md, find supporting code or flag as ungrounded
├── [Parallel] speck-auditor: Third-party integration risk surface scan — for each external service in context.md/architecture.md, verify auth model, ToS posture, data residency, worst-case story
├── [Parallel] speck-auditor: Constitution principle compliance scan — for each principle in constitution.md (or product-contract.md principles section), verify enforcement mechanism is current
├── [Parallel] speck-auditor: Banned-language scan via .speck/scripts/banned-language-lint.sh
├── [Parallel] shell: PROFILE drift — run .speck/scripts/profile-drift-check.sh; classify P1/P2/P3; refresh placeholders via regenerate-project-readme.sh if P3 only
├── [Parallel] shell: SETTINGS drift — run .speck/scripts/settings-drift-check.sh; classify SETTINGS_DRIFT.P0; suggest `npx github:telum-ai/speck reconcile-settings`
├── [Parallel] shell: ASSET drift — run `.speck/scripts/asset-drift-check.sh`; classify `ASSET_DRIFT.P1` when duplicate SVG path geometry appears in 2+ source files (brand dual-encoding)
├── [Parallel] shell: SCHEMA drift — run `.speck/scripts/validation/validators/validate-schema-drift.sh` (for DB-backed projects, or if migration directories exist); classify `SCHEMA_DRIFT.P0` or `MIGRATION_REPAIR_WARNING.P1`
├── [Parallel] shell: CASCADE drift — run `.speck/scripts/validation/validators/compute-cascade.sh --strict` (if project-level adjustments, superseded project DECs, or contract section changes exist); classify `CASCADE_STALE.P1` (superseded decisions whose downstream promises are still active as discharged under old state)
├── [Parallel] shell: EVAL signal drift — run `.speck/scripts/validation/validators/compute-eval-signals.sh --strict` to analyze VCS-as-eval metrics (override-rate, survival); classify any threshold breaches as `EVAL_SIGNAL_DRIFT.P2`
├── [Parallel] shell: GRAPH drift + conservation — run `python3 .speck/scripts/graph/speck_graph.py build specs/projects/<id> && python3 .speck/scripts/graph/speck_graph.py check specs/projects/<id>`. This single call now covers BOTH structural link rot AND promise conservation (folded from the old per-epic `validate-traceability-matrix.sh` default-mode run, v9.3): `DANGLING_REF.P1` / `DUP_ID.P1` (link rot), `UNMAPPED_PROMISE.P1` (the evaporated-promise / `PROMISE_DRIFT` check — an open row after epic-breakdown with no story and no DEC), `PHANTOM_PROMISE.P1` (a promised `MM-N`/`JOB-N` no story delivers), `DEP_CYCLE.P1` (circular depends_on). `GRAPH_CAP` / `GRAPH_UNMIGRATED.P3` are advisory caps; route un-adopted schemes to `speck_graph.py migrate`. The `--require-evidence` grain teeth still run at `/epic-validate` (that gate is unchanged — the graph does not yet own grain enforcement).
├── [Parallel] shell: MARKET drift — run `.speck/scripts/market-staleness-check.sh` (no-web, age/stamp only); classify `MARKET_DRIFT.P1` (an absolute "no competitor does X" claim in §3/§3a that is unverified/stale past the tight clock, an honest `verdict: eroded|false`, or a cited scan report that is missing — phantom evidence) or `MARKET_DRIFT.P2` (generic differentiator past its archetype cadence, provisional/unverified baseline, or under-sourced). Route findings to `/speck-frontier-scan --product`
├── [Parallel] shell: WEDGE reconciliation — run `.speck/scripts/market-reconcile-check.sh`; classify `WEDGE_DRIFT.P1` (§3 differentiator empty while §2a states a defensible wedge, OR §2a self-flags §3 as thin/copyable — the Brightstance case) or `WEDGE_DRIFT.P2` (§3↔§2a token overlap < 25% — auditor confirms §3 is at least as defensible as the wedge)
├── [Parallel] shell: GATE-WIRING drift — run `.speck/scripts/validation/validators/validate-gate-liveness.sh specs/projects/<id>/evidence-contract.md`; classify `GATE_WIRING_DRIFT.P1` (a §6a gate declared pre-commit/pre-push but wired stages:[manual] or nowhere), `CI_TRUNK_EXCLUDED.P1` (a ci: gate whose workflow ignores trunk), `SCRIPT_UNREFERENCED.P1` (a §6a-named script never called on the commit path), or `GATE_WAIVER_UNBACKED.P2` (a waiver citing a missing DEC). A dark gate manufactures clean-looking evidence — this is P2 (no claim without a mechanism) applied to the GATES themselves. Unrecognized CI/hook system → `GATE_WIRING_UNVERIFIED` (never false-green). NOTE: only the cheap WIRING check runs here in the always-on recheck shell; the heavier gate-liveness CANARY probe (mutation runs, `gate-liveness-probe.sh` → `GATE_DISARMED.P1` / `GATE_LIVENESS_UNVERIFIED.P2`, #88 Phase 2) is opt-in at `/epic-validate` / `/project-validate` / `/audit`, never on the recheck fast path.
├── [Parallel] shell: PLANNING-ANALYSIS gate — run `.speck/scripts/validation/validators/validate-project-analysis.sh --gate specs/projects/<id>`. It exits 1 on any P1 by default (no `--strict` needed — that is what makes it a gate, not a report). Classify `UNANALYZED_CORPUS.P1` (the gate applies at this play level / epic count and no analysis report exists — the corpus was never read by a lens that did not write it), `ANALYSIS_STALE.P1` (`PRD.md` / `epics.md` / `product-contract.md` has a commit AFTER the report's last commit — CONTENT freshness, never `stamped SHA == HEAD`; no git history ⇒ `unknown`, never `fresh`), `ANALYSIS_CRITICAL_OPEN.P1` (a findings row at Severity CRITICAL with Status `open`), `PROMISE_UNCOVERED.P1` (an `MM-N`/`JOB-N` the witness graph knows about is absent from the promise-coverage matrix, or present unresolved), `ANALYSIS_DECORRELATION_UNVERIFIED.P2` (fewer lenses than the tier requires, or a CRITICAL/HIGH row whose Verifier equals its Lens — the author certifying their own work), `ANALYSIS_COVERAGE_UNCOMPUTED.P2` (the graph could not be read, so matrix completeness was NOT computed — an honest unknown, never a green), and `ANALYSIS_GRANDFATHERED.P2` (a pre-v10.3 project exempted by `<PROJECT_DIR>/.analysis-gate-grandfathered`). The grandfather code is the **disclosed asymmetry**: the gate is real forward and advisory backward, so surface it on every recheck — loudly, never collapsed — for as long as the marker sits on disk.
├── [Parallel] shell: grep -rln "\[NEEDS USER REVIEW\]" specs/projects/<id>/   (surface to project-state.md)
└── [Wait] → Synthesize drift report
```

Each subagent returns: FRESH | STALE | DRIFTED | MISSING with evidence.

**REPLACE_BEFORE_SHIP markers** (added in Speck v7.2+):
- Any truth artifact carrying a `REPLACE_BEFORE_SHIP:` token is **incomplete**
- The artifact CANNOT support a readiness state claim above `IMPL-GREEN` while tokens remain
- Treat as **P0 drift** if the artifact is referenced by an active `UX-RC` or higher claim
- Treat as **P1 drift** otherwise (a scaffolded artifact that hasn't been filled)
- The catch-up flow (`/speck-catch-up`) is the standard remediation path

### 3. Run persona LARP cold-start / Integration stress-test sanity check

- **WHEN: consumer_product / b2b_saas / internal_tool**:
  - For each persona in `personas/<id>.md`, run persona LARP cold-start.
  - Cold-start the app from a fresh state (no logged-in user, clean storage, etc.).
  - Execute the LARP script for the persona's primary JTBD; capture screenshots, AX trees, timings, and compare against `product-contract.md` magic moments.
  - Use the `/larp` skill for the actual execution; `/recheck` orchestrates and aggregates.
- **WHEN: infra_service / backend_api**:
  - Run the integration / stress-test scenarios (from Option B in `evidence-contract.md`).
  - Warm up the system, send concurrent mock client requests, and verify latency histograms, error-code stability, connection pooling recovery, and DB-isolation invariants.

If any check fails: drift detected (P0).

### 4. Compute the drift report

For each finding:
- Severity (P0-P3)
- Type: SPEC_VS_CODE | TRUTH_STALE | TEMPLATE_DRIFT.P1 | TEMPLATE_DRIFT.P2 | LARP_FAIL | INTEGRATION_RISK | PRINCIPLE_VIOLATION | BANNED_LANGUAGE | ASSET_DRIFT.P1 | PROFILE_DRIFT.P1 | PROFILE_DRIFT.P2 | PROFILE_DRIFT.P3 | SETTINGS_DRIFT.P0 | SCHEMA_DRIFT.P0 | MIGRATION_REPAIR_WARNING.P1 | CASCADE_STALE.P1 | EVAL_SIGNAL_DRIFT.P2 | MARKET_DRIFT.P1 | MARKET_DRIFT.P2 | WEDGE_DRIFT.P1 | WEDGE_DRIFT.P2 | GATE_WIRING_DRIFT.P1 | CI_TRUNK_EXCLUDED.P1 | SCRIPT_UNREFERENCED.P1 | GATE_WAIVER_UNBACKED.P2 | GATE_DISARMED.P1 | GATE_LIVENESS_UNVERIFIED.P2 | GUARD_MUTATION_PROVEN | GUARD_MUTATION_GREEN.P2 | GUARD_MUTATION_UNOBSERVABLE.P2 | GUARD_UNMUTATED.P2 | GUARD_UNMUTATED_HARNESS.P2 | OBSERVATION_EXPOSED | OBSERVATION_UNEXPOSED.P2 | OBSERVATION_UNEXPOSED_BLOCKING.P1 | OBSERVATION_NOT_GREEN.P1 | OBSERVATION_UNMEASURED.P2 | UNANALYZED_CORPUS.P1 | ANALYSIS_STALE.P1 | ANALYSIS_CRITICAL_OPEN.P1 | PROMISE_UNCOVERED.P1 | ANALYSIS_DECORRELATION_UNVERIFIED.P2 | ANALYSIS_COVERAGE_UNCOMPUTED.P2 | ANALYSIS_GRANDFATHERED.P2 | V8_REPROVE.P1
- Where (file:line or surface)
- Evidence (link to artifact)
- Recommended fix

**Mutation codes (`GUARD_*`) — the one registered set.** They are emitted by
`.speck/scripts/validation/mutate-guard.sh` as `SPECK_MUTATION_VERDICT=<code>` and consumed here,
so a mutation record is a value a pipeline can read rather than a markdown cell it cannot. They are
registered alongside the other finding codes on purpose: the cap mechanism reads codes, and a
mutation claim that lives only in prose is invisible to it.

- `GUARD_MUTATION_PROVEN` — not a finding. The guard was watched failing at a real, executable
  production line, with a control that stayed green. Carry it as the evidence for the AC.
- `GUARD_MUTATION_GREEN.P2` — the mutation provably happened and the suite did not notice. **Honest
  and non-blocking by design**: making it blocking is what creates the incentive to tune a mutation
  until it reddens. Record it green, write the scope onto the test, and do not adjust the mutation.
  Same ethos as `GATE_LIVENESS_UNVERIFIED.P2` — degrade-to-honest on applicability, fail-closed on
  claims.
- `GUARD_MUTATION_UNOBSERVABLE.P2` (v10.5) — the mutation provably happened and the cited test
  **structurally could not see it**: the subject is a file that must be APPLIED to a system before
  anything can observe it (a migration, a schema, an infra manifest) and no `--applier` was supplied,
  so the test inspected a system the mutation never reached. Split out from `GUARD_MUTATION_GREEN.P2`
  because that code's own wording — "write the honest scope onto the test" — invites the reader to
  conclude the guard is blind, and here it is not blind at all. Re-run with `--applier`.
- `GUARD_UNMUTATED.P2` — nothing was measured (no match, a comment or docstring line, a test or
  fixture path, an already-red target, or a control that reddened too). The guard does **not**
  discharge its AC at this state; a validation report citing it as proven is drift.
- `GUARD_UNMUTATED_HARNESS.P2` (v10.5) — nothing was measured, **and the harness is why**: the probe
  worktree could not run the guard at all (a build tool that rejects the linked `node_modules`, a
  missing binary). Same non-discharge as `GUARD_UNMUTATED.P2`, different cause and different remedy —
  it is not a statement about the guard, and an author who reads it as one deletes a working gate.

A validation report or harden report whose cited guard carries no `GUARD_*` verdict at all is the
same class one level up — the claim exists and the measurement does not.

**Observation codes (`OBSERVATION_*`) — the counterpart set, for evidence that is WATCHED rather
than RUN.** Emitted by `.speck/scripts/validation/observe-guard.sh` as
`SPECK_OBSERVATION_VERDICT=<code>`. The `GUARD_*` codes above install mutation-as-evidence for
**tests**; these do the same work for **observations** — a grep of a log, a CI verdict, a
dashboard, a quiet inbox, a count that did not move. They are load-bearing in the same way: they
get written into findings, they close fires, they justify REFUTED.

The mechanism they exist to break: **a green reports its verdict and never its exposure** —
whether the occasion it ran on contained the failing case at all. A hard-won pass and a pass that
*could not have failed* are byte-identical in the artifact, so confidence accumulates on **run
count** rather than on **chances to fail**. Note this is NOT the shadowed / vacuous / forgeable
class: the check was correct, executed, and truthful about itself. What was missing was the
occasion. Re-run against a real failing case to tell them apart — RED means the guard is broken
(that is the other class); GREEN means nothing is broken and this run had nothing to catch.

- `OBSERVATION_EXPOSED` — not a finding. The instrument was shown able to display the thing, and
  the occasion ran under the **shipped** invocation (flags and env diffed against the `Dockerfile`
  CMD / `Procfile` / deploy command). Carry it as the evidence.
- `OBSERVATION_UNEXPOSED.P2` — exposure was not established, and this green licenses only
  **waiting**. Honest and non-blocking by design: an unexposed run is harmless here and buying
  exposure would be waste. Same degrade-to-honest ethos as `GUARD_MUTATION_GREEN.P2`.
- `OBSERVATION_UNEXPOSED_BLOCKING.P1` — exposure was not established and this green licenses
  something **accumulating or irreversible**: closing a fire, exiting a shadow period, re-stamping
  a readiness state, writing REFUTED on a live credential. **The run does not count toward it.**
  Either buy exposure or stop citing the observation as the thing that closes it.
- `OBSERVATION_NOT_GREEN.P1` — the observation did not hold. The needle was present where absence
  was asserted, or the result never arrived where presence was asserted (**a gate you never saw is
  not a gate that passed** — a `cancelled` CI run is a missing result, not a pass). This is a real
  finding, not an exposure problem.
- `OBSERVATION_UNMEASURED.P2` — nothing was measured; a destructive invocation was refused.

**The bounds, so this stays proportionate.** Some subjects have **no lever** — a guard reconciling
inbound mail cannot make mail arrive. Its correct move is not to manufacture but to refuse to let
an unexposed run count (`--no-lever`), because *two static passes in a row prove only that neither
number moved* (`SPECK_OBSERVATION_STATIC=true` reports exactly that). And **exposure is bought,
not free** — buy it where the green authorises something that cannot be walked back, not
everywhere; `--accept-divergence` records the purchase instead of hiding it.

### 5. Update project-state.md

Trigger `/project-state` to regenerate with drift findings in:
- Blocking issues section (P0/P1 drift)
- Truth staleness report (all stale artifacts)
- Next action: "Resolve drift before new feature work"

### 6. Decision gate

If `V8_REPROVE.P1` (marker `.speck/.v8-reprove-needed` present, or any `V8_STALE` artifact stamped `< speck 8`):
- **BLOCK new feature work**
- Route to `/speck-reprove` **before** resolving other drift — it builds the suspect-green worklist (mapped to P1-P4), caps effective shippable state at `INTEGRATION-GREEN`, reverts consumer FELT-GOOD to `uncovered`, preserves each historical claim stamped `[pre-v8-proof]`, and (Phase 1.5, #87) runs `reconcile-matrix-grain.sh` so the traceability matrices stop asserting a readiness the report cap removed. A `V8_STALE` line naming a `traceability-matrix.md` ("report capped but matrix un-graded") is this exact un-reconciled contradiction.

If P0 drift found:
- **BLOCK new feature work**
- Surface P0 findings to user with proposed remediations
- Recommend running `/audit` for affected stories
- Refuse to proceed with any `/story-implement`, `/epic-plan` until P0 resolved

If `MARKET_DRIFT.P1` or `WEDGE_DRIFT.P1` found:
- Do NOT block `/story-implement` — a stale or over-strong market claim is not a runtime defect
- **BLOCK claiming `COMMERCIAL-RC` / `SHIP-RC`** and **BLOCK generating marketing / positioning copy from the spec** until the claim is re-validated (`/speck-frontier-scan --product` → re-stamp) or §3 is reconciled with the §2a wedge (`/project-adjust`). This is the precise "don't ship a false 'no competitor does X'" save.

If `UNANALYZED_CORPUS.P1` / `ANALYSIS_STALE.P1` / `ANALYSIS_CRITICAL_OPEN.P1` / `PROMISE_UNCOVERED.P1` found:
- Do NOT block `/story-implement` inside an epic already underway — the defect is in the plan, and halting mid-story does not repair it
- **BLOCK the next `/epic-specify`** until `/project-analyze` clears. `check-epic-prereqs.sh` is the enforcing call site; `/recheck`'s job is to surface the block early instead of at the moment someone tries to start an epic
- Route to `/project-analyze` with lenses decorrelated from whoever authored the corpus

If `ANALYSIS_GRANDFATHERED.P2` found:
- Never block — this project was planned before the gate existed, and the decision was that the gate is real forward and advisory backward
- Surface it in the report AND in `project-state.md`, uncollapsed, on **every** recheck. The repeated notice is the entire mechanism for backward-facing projects; a notice that fades is a gate that quietly turned off
- State plainly what it means: no decorrelated lens has read this planning corpus. One `/project-analyze` run makes the exemption **spent** — `check-epic-prereqs.sh` then names it and prints the `rm` command that retires `<PROJECT_DIR>/.analysis-gate-grandfathered`. Carry that instruction into the report; a spent marker left on disk goes on exempting the project for reasons that no longer exist

If only P1-P3:
- Surface findings; allow user to proceed at their discretion
- Add follow-up stories to the active epic's backlog

If no drift:
- **First ask what the green licenses.** Re-stamping every truth artifact with a fresh `verified`
  date is not *waiting* — it is an **accumulating** act, and it is the single place in this skill
  where confidence is written down on the strength of things not having happened. So before
  re-stamping, for every finding that rests on an OBSERVATION rather than on a test — a quiet log,
  a green CI verdict, a count that did not move, a `staleness-check.sh` that reported nothing —
  run `.speck/scripts/validation/observe-guard.sh --licenses accumulating` over it and transcribe
  the verdict. `OBSERVATION_UNEXPOSED_BLOCKING.P1` means that observation does not count toward
  the re-stamp; re-stamp the artifacts it does not carry and say why the rest were held.
- Otherwise re-stamp all checked truth artifacts with fresh `verified` date
- Proceed normally

### 7. Write the recheck report

Write to `specs/projects/<PROJECT_ID>/project-recheck-report-<YYYYMMDD>.md`. See claude skill for the full report template.

### 8. Apply stamp + report to user

```
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/project-recheck-report-<YYYYMMDD>.md
```

Report summary fields per claude skill.

## Behavior Rules

- NEVER skip persona LARP cold-start
- NEVER claim "no drift" without running `staleness-check.sh` AND `banned-language-lint.sh` AND `check-replace-markers.sh` AND `asset-drift-check.sh` (when UI/brand assets exist) AND `settings-drift-check.sh` (when `.claude/settings.json` exists) AND `validate-schema-drift.sh` (when DB-backed) AND `compute-cascade.sh --strict` (if superseded DECs exist) AND `compute-eval-signals.sh --strict` AND `market-staleness-check.sh` AND `market-reconcile-check.sh` (when `product-contract.md` exists) AND `validate-project-analysis.sh --gate` (when a planning corpus exists)
- NEVER mark a truth artifact "fresh" while it still contains `REPLACE_BEFORE_SHIP:` or `[NEEDS USER REVIEW]` tokens
- NEVER let an OBSERVATION close a P0 or re-stamp a truth artifact without answering what its green licenses. A green that closes a fire or refreshes a `verified` date is accumulating or irreversible, so it needs `OBSERVATION_EXPOSED`; a green that licenses only *waiting* needs nothing, and `OBSERVATION_UNEXPOSED.P2` is the correct, non-blocking record for it. **Two static passes in a row prove only that neither number moved** — a repeat drift-check with byte-identical output is not a second datapoint
- NEVER treat a `cancelled`, skipped, or never-triggered CI run as a pass. A gate you never saw is not a gate that passed — that is `OBSERVATION_NOT_GREEN.P1`, and it is a finding
- ALWAYS surface `ANALYSIS_GRANDFATHERED.P2` in full on every recheck, never collapsed and never de-duplicated across sessions. It is the only signal a pre-v10.3 project gets, and it is deliberately advisory — quieting it converts a disclosed asymmetry into a silent exemption
- NEVER report `ANALYSIS_COVERAGE_UNCOMPUTED.P2` as a coverage pass. It means the witness graph could not be read, so matrix completeness was not computed — an honest unknown, and the `PROMISE_UNCOVERED.P1` check did not run
- ALWAYS write a dated report (even if green)
- ALWAYS re-stamp truth artifacts on green (with fresh `verified` date)
- ALWAYS update `project-state.md` regardless of verdict (including the new "Sections Awaiting User Review" and "Outstanding REPLACE_BEFORE_SHIP markers" appendices)
- BLOCK new feature work on P0 findings
- ALWAYS route to `/speck-reprove` (and block feature work) when `.speck/.v8-reprove-needed` exists or any `V8_STALE` (pre-v8 stamp) artifact is found — v7-era green is not trusted under v8 until re-proven
- NEVER hand-write or hand-edit the `*[market-verified …]*` stamp; only `stamp-market.sh` writes it, and only when a real sourced scan report backs it (P2). On `MARKET_DRIFT.P1`, block `COMMERCIAL-RC`/`SHIP-RC` and spec-derived marketing copy until re-scanned

## Integration Points

- Reads: all truth artifacts, all `personas/*.md` LARP scripts, `.speck/scripts/staleness-check.sh`, `.speck/scripts/banned-language-lint.sh`, `.speck/scripts/validation/validators/validate-project-analysis.sh`
- Invokes: `/larp` (for persona cold-start), `/project-state` (regeneration)
- Writes: `project-recheck-report-<date>.md`, re-stamps truth artifacts on green
- Updates: `project-state.md` blocking issues, next action

## Context: $ARGUMENTS

### Live Workspace Gaps (Claude-Only Pre-Injection)
```!
bash .speck/scripts/staleness-check.sh 2>/dev/null || true
bash .speck/scripts/check-replace-markers.sh specs/projects/ 2>/dev/null || true
```


## Cross-Host Portability & Compatibility

This process skill is fully supported across all primary AI runtimes (Claude, Cursor, Codex) with identical evidence requirements.

| Capability | Claude Code | Cursor | Codex |
|------------|-------------|--------|-------|
| **Execution** | Interactive skill command | Interactive skill command | Interactive skill command |
| **Automation** | /loop scheduling, background monitors | manual or scheduled CI run | manual or scheduled CI run |
| **Parallelization** | Spawns parallel `speck-scanner` & `speck-auditor` | Fallback to sequential main context | Fallback to sequential main context |

### Fallbacks & Adaptations
- **Subagents**: Spawning subagents (`speck-scanner` / `speck-auditor`) is a Claude-only feature. If running on Cursor or Codex, execute the staleness-check, replace-markers-check, and banned-language-lint checks sequentially using the core scripts in your main context.
