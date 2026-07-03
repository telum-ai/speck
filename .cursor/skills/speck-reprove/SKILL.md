---
name: speck-reprove
description: Drive a v7→v8-migrated project to v8-honest reality (the catch-up analog for the v8 thesis "Evaluation Over Verification"). v7-era "green" was optimized for the letter of v7 gates, not evaluation-proven — this skill triages that suspect green against the four v8 principles (P1-P4), caps effective shippable state at INTEGRATION-GREEN, reverts consumer FELT-GOOD to uncovered, preserves each historical claim but stamps it [pre-v8-proof], and builds a prioritized re-prove worklist in project-v8-reprove-report.md. Load when .speck/.v8-reprove-needed exists, when /recheck raises V8_REPROVE.P1 (pre-v8 stamps), or when the user says "reprove", "bring this up to v8", "/speck-reprove".
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

**The problem this solves.** A v7 project has weeks of `PASS` / `UX-RC` / `SHIP-RC` claims produced under v7's verification-shaped gates. v8's thesis is that you cannot out-enumerate an agent optimizing for green, so **that green is suspect until re-established under evaluation**. Bumping the version does not make old claims true.

`/speck-reprove` is the migration analog of `/speck-catch-up`: it does NOT reconstruct artifacts (they already exist and are structurally fine) — it **re-proves the truth**. It refuses to inherit v7 green, caps the project honestly, maps each suspect claim to the v8 principle it is suspect under, and hands back a prioritized climb.

This is **not** a reset to zero. Nothing suspect is deleted; the historical claim is preserved and stamped `[pre-v8-proof]`. States climb back to `verified` only as real v8 evidence lands.

## When to Run

Run automatically when ANY of these is true (detect on engagement — this is First Action #1a, before feature work):

1. `.speck/.v8-reprove-needed` marker exists at workspace root (written by `speck upgrade` on the v7→v8 crossing).
2. `/recheck` / `staleness-check.sh` reports `V8_STALE` / `V8_REPROVE.P1` — a truth artifact stamped `speck v<7 or lower`.
3. User says "reprove", "bring this up to v8", "/speck-reprove".

**Block new feature work** until reprove is complete (no `/story-implement`, `/epic-plan`, or ship claim). Refuse with: *"This project was upgraded to Speck v8 but its truth is still v7-shaped green. Run `/speck-reprove` first."*

## Prerequisites

- Project at `specs/projects/<id>/` exists with v7 truth artifacts.
- Git history available (for stamp/claim archaeology).

## The cap-and-worklist model (the core doctrine)

On engagement, the effective shippable state is **capped** — old claims do not carry over as ship-ready:

| v7 claim | v8 effective state (until re-proven) | Why |
|----------|--------------------------------------|-----|
| Any claim ≥ `UX-RC` | Capped at **`INTEGRATION-GREEN`** | UX-RC+ requires evaluation evidence (P1) that v7 green may only have verified |
| Consumer archetype **FELT-GOOD** | Reverts to **`uncovered`** | The axis most likely to be fake green (#78) — needs the naive-hostile IS-IT-GOOD pass |
| `IMPL-GREEN` / `INTEGRATION-GREEN` | Unchanged | Correctness/integration claims are the least suspect; re-verify opportunistically |

The historical claim is **preserved** in place and stamped `[pre-v8-proof]` (never overwritten to a lower number silently). It climbs back only when a real v8 evaluation lands.

## Execution

### Phase 0 — Triage: inventory + suspect-green classification

Inventory truth artifacts, validation reports, LARP evidence, and traceability matrices. For each existing readiness claim, classify the principle it is suspect under:

| Suspect signal | Principle | What to look for |
|----------------|-----------|------------------|
| Screenshots/recordings present but no per-screen adversarial adjudication; no DOES-IT-WORK vs IS-IT-GOOD split; FELT-GOOD asserted from correctness evidence | **P1** | `validation-report.md` / `persona-larp` with captures but no IS-IT-GOOD verdict or Common-Sense Defect Sweep |
| AI action-claim, price/paywall, or authz/RLS test with no exhibited mechanism (no fired endpoint/row/real-principal-forbidden-op; price with no value-defensibility artifact) | **P2** | claims in specs/reports and negative tests that assert a guard without attempting the forbidden op as a least-privileged principal |
| Readiness cap justified by "unreachable"/"named infra blocker"/"tooling limitation" with no logged, reproduced real attempt | **P3** | `INTEGRATION-GREEN` caps and skipped LARPs citing a blocker without the recipe run + specific error |
| Self-audited (implementer == auditor); no independent/N-skeptic audit | **P4** | `audit-report.md` authored by the implementer, or missing |

Run `.speck/scripts/staleness-check.sh <PROJECT_DIR>` to enumerate `V8_STALE` artifacts. Detect consumer archetypes from `product-contract.md` / `personas/`.

### Phase 1 — Apply the cap

For each artifact/claim:
- Where a v7 claim is ≥ `UX-RC`, set the **effective** state to `INTEGRATION-GREEN` in `project-state.md` while **preserving** the historical claim in the artifact, appended with `[pre-v8-proof]`.
- For consumer archetypes, render **FELT-GOOD → `uncovered`** in the readiness map (the AI must re-run the naive-hostile IS-IT-GOOD LARP to re-cover it — a human sign-off is an optional stronger override, never a prerequisite).
- Do NOT rewrite the numeric history to a lower value; add the `[pre-v8-proof]` marker + a one-line "capped pending v8 re-prove" note.

### Phase 2 — Build the re-prove worklist

Map every suspect claim to its concrete re-prove action, prioritized P0→P3:

- **P1 (evaluate):** re-run `/larp` with the DOES-IT-WORK vs IS-IT-GOOD split + per-screen pixel-grounded critique + Common-Sense Defect Sweep. Cover consumer FELT-GOOD with the AI's own naive-hostile pass.
- **P2 (mechanism):** exhibit the mechanism for each claim — fired endpoint / written row / real forbidden-op attempted as a least-privileged principal / value-defensibility artifact vs the free substitute.
- **P3 (reach):** for each cap citing a blocker, run the actual recipe and either reach the control or log the reproduced failure (recipe + specific error).
- **P4 (adversary):** ensure a genuinely independent `/audit` (separate auditor) exists for anything climbing back to ≥ `UX-RC`.

### Phase 3 — Write `project-v8-reprove-report.md`

Read the template at `.speck/templates/project/project-v8-reprove-report-template.md` and follow it exactly. It captures: the suspect-green triage table, the cap applied (per artifact), the prioritized worklist mapped to P1-P4, and the climb-back criteria. SHA-stamp it (the stamp will read `speck v8.x`, clearing V8_STALE for the report itself).

### Phase 4 — Finalize

1. Regenerate `project-state.md` via `/project-state`: effective (capped) states, FELT-GOOD `uncovered` for consumer archetypes, blocking issues = the P0/P1 worklist, Next action = "Work through project-v8-reprove-report.md".
2. Remove the `.speck/.v8-reprove-needed` marker **only after** the report exists and the worklist is tracked in `project-state.md`.
3. Re-run `/recheck` to confirm no remaining `V8_STALE` beyond the tracked worklist.

## Behavior Rules

- **NEVER** carry a v7 `UX-RC`+ claim into v8 as ship-ready without a fresh v8 evaluation — cap at `INTEGRATION-GREEN` first.
- **NEVER** silently lower a historical numeric claim — preserve it and append `[pre-v8-proof]` with a capped note.
- **NEVER** re-cover consumer FELT-GOOD from correctness/conformance evidence — it requires the naive-hostile IS-IT-GOOD LARP (P1).
- **NEVER** accept a `[pre-v8-proof]` cap justified by a "named blocker" without a logged, reproduced real attempt (P3).
- **ALWAYS** map each suspect claim to the specific principle (P1-P4) and a concrete re-prove action.
- **ALWAYS** SHA-stamp the report (v8) and remove the marker only after the worklist is tracked.
- **ALWAYS** write the report even if nothing is suspect — state "No pre-v8 claims required re-proving; project shipped clean v8 from upgrade."

## Idempotency

Safe to re-run. Artifacts already stamped `speck v8.x` and claims already re-proven are skipped; only remaining `V8_STALE` / `[pre-v8-proof]` items are processed. Removing the marker is the terminal step.

## Context: $ARGUMENTS
