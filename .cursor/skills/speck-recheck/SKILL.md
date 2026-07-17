---
name: speck-recheck
description: Mandatory engagement-gap drift detector for Speck. Compares truth-doc assertions to current HEAD via SHA stamps, runs persona LARP cold-start, scans for third-party integration risk + ToS posture, checks constitution principle compliance, updates project-state.md, and blocks new feature work if drift is found. Load when reengagement gap is >2 weeks since last verified-against-runtime, when a new agent picks up a project, or when user says "audit", "make ship-ready", "is this still working".
disable-model-invocation: false
---

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
├── [Parallel] shell: PROMISE drift — for each epic dir with a `traceability-matrix.md`, run `.speck/scripts/validation/validators/validate-traceability-matrix.sh <EPIC_DIR>` (and `--require-evidence` for epics whose validation claims ≥ UX-RC); classify any unresolved promise as `PROMISE_DRIFT.P1` (evaporated promise — a drawn/stated commitment with no story and no DEC)
├── [Parallel] shell: MARKET drift — run `.speck/scripts/market-staleness-check.sh` (no-web, age/stamp only); classify `MARKET_DRIFT.P1` (an absolute "no competitor does X" claim in §3/§3a that is unverified/stale past the tight clock, an honest `verdict: eroded|false`, or a cited scan report that is missing — phantom evidence) or `MARKET_DRIFT.P2` (generic differentiator past its archetype cadence, provisional/unverified baseline, or under-sourced). Route findings to `/speck-frontier-scan --product`
├── [Parallel] shell: WEDGE reconciliation — run `.speck/scripts/market-reconcile-check.sh`; classify `WEDGE_DRIFT.P1` (§3 differentiator empty while §2a states a defensible wedge, OR §2a self-flags §3 as thin/copyable — the Brightstance case) or `WEDGE_DRIFT.P2` (§3↔§2a token overlap < 25% — auditor confirms §3 is at least as defensible as the wedge)
├── [Parallel] shell: GATE-WIRING drift — run `.speck/scripts/validation/validators/validate-gate-liveness.sh specs/projects/<id>/evidence-contract.md`; classify `GATE_WIRING_DRIFT.P1` (a §6a gate declared pre-commit/pre-push but wired stages:[manual] or nowhere), `CI_TRUNK_EXCLUDED.P1` (a ci: gate whose workflow ignores trunk), `SCRIPT_UNREFERENCED.P1` (a §6a-named script never called on the commit path), or `GATE_WAIVER_UNBACKED.P2` (a waiver citing a missing DEC). A dark gate manufactures clean-looking evidence — this is P2 (no claim without a mechanism) applied to the GATES themselves. Unrecognized CI/hook system → `GATE_WIRING_UNVERIFIED` (never false-green)
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
- Type: SPEC_VS_CODE | TRUTH_STALE | TEMPLATE_DRIFT.P1 | TEMPLATE_DRIFT.P2 | LARP_FAIL | INTEGRATION_RISK | PRINCIPLE_VIOLATION | BANNED_LANGUAGE | ASSET_DRIFT.P1 | PROFILE_DRIFT.P1 | PROFILE_DRIFT.P2 | PROFILE_DRIFT.P3 | SETTINGS_DRIFT.P0 | SCHEMA_DRIFT.P0 | MIGRATION_REPAIR_WARNING.P1 | CASCADE_STALE.P1 | EVAL_SIGNAL_DRIFT.P2 | MARKET_DRIFT.P1 | MARKET_DRIFT.P2 | WEDGE_DRIFT.P1 | WEDGE_DRIFT.P2 | GATE_WIRING_DRIFT.P1 | CI_TRUNK_EXCLUDED.P1 | SCRIPT_UNREFERENCED.P1 | GATE_WAIVER_UNBACKED.P2 | V8_REPROVE.P1
- Where (file:line or surface)
- Evidence (link to artifact)
- Recommended fix

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

If only P1-P3:
- Surface findings; allow user to proceed at their discretion
- Add follow-up stories to the active epic's backlog

If no drift:
- Re-stamp all checked truth artifacts with fresh `verified` date
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
- NEVER claim "no drift" without running `staleness-check.sh` AND `banned-language-lint.sh` AND `check-replace-markers.sh` AND `asset-drift-check.sh` (when UI/brand assets exist) AND `settings-drift-check.sh` (when `.claude/settings.json` exists) AND `validate-schema-drift.sh` (when DB-backed) AND `compute-cascade.sh --strict` (if superseded DECs exist) AND `compute-eval-signals.sh --strict` AND `market-staleness-check.sh` AND `market-reconcile-check.sh` (when `product-contract.md` exists)
- NEVER mark a truth artifact "fresh" while it still contains `REPLACE_BEFORE_SHIP:` or `[NEEDS USER REVIEW]` tokens
- ALWAYS write a dated report (even if green)
- ALWAYS re-stamp truth artifacts on green (with fresh `verified` date)
- ALWAYS update `project-state.md` regardless of verdict (including the new "Sections Awaiting User Review" and "Outstanding REPLACE_BEFORE_SHIP markers" appendices)
- BLOCK new feature work on P0 findings
- ALWAYS route to `/speck-reprove` (and block feature work) when `.speck/.v8-reprove-needed` exists or any `V8_STALE` (pre-v8 stamp) artifact is found — v7-era green is not trusted under v8 until re-proven
- NEVER hand-write or hand-edit the `*[market-verified …]*` stamp; only `stamp-market.sh` writes it, and only when a real sourced scan report backs it (P2). On `MARKET_DRIFT.P1`, block `COMMERCIAL-RC`/`SHIP-RC` and spec-derived marketing copy until re-scanned

## Integration Points

- Reads: all truth artifacts, all `personas/*.md` LARP scripts, `.speck/scripts/staleness-check.sh`, `.speck/scripts/banned-language-lint.sh`
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
