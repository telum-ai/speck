---
speck_version: 8.0
template_version: "8.4.0"
artifact_type: traceability-matrix
---

# Promise Traceability Matrix: [Epic Name]

**Epic**: [EPIC_ID]
**Project**: [PROJECT_ID]
**Lifecycle**: rows enumerated by `/epic-plan` → assigned by `/epic-breakdown` + `/story-specify` → discharged by `/story-validate` → re-walked by `/epic-validate`
**Status**: [Open (pre-breakdown) / Mapped / Discharged]

<!--
THE CONSERVATION LAW (Speck v7.14): every enumerable upstream promise gets a PRM-NNN id and MUST
resolve to exactly one of:
  • a story + acceptance criterion that DISCHARGES it, or
  • a DEC entry that explicitly DESCOPES it, or
  • a visibly-OPEN row (allowed ONLY before /epic-breakdown).
Nothing evaporates silently. "Wireframes are just inspiration" is BANNED — if a wireframe draws it
or an experience-chain seam states it, it is a PROMISE and gets a row, or it gets a DEC.

Status lifecycle:  open → mapped (assigned story+AC) → discharged (story validated with evidence)
                                                      ├→ descoped (a DEC drops it)
                                                      └→ pilot-gated (deferred to live pilot, with backing reference)

GRAIN (Speck v8.4, #87) — a SECOND, ORTHOGONAL axis. Status answers "resolved?"; Grain answers
"at what grain was the discharging evidence collected?". Value = the readiness-ladder enum
(no-ship | impl-green | integration-green | ux-rc | api-rc | operational-rc | commercial-rc |
ship-rc | ship), optionally suffixed ` [pre-v8-proof]`. Descoped / pilot-gated rows = `—`.
  • helper-importing unit test = impl-green · live DB round-trip = integration-green
  • cold-start build-LARP on the shipped artifact = ux-rc (and up)
A `[pre-v8-proof]` row is STILL `discharged` — nothing evaporates, conservation math is unchanged.
Grain is per-(row × evidence): one story can discharge PRM-A via a unit test (impl-green) and PRM-B
via a build-LARP (ux-rc). The story's single `readiness_state_verified` is only the CEILING, not
the value. An un-graded discharged row is treated as story-grain (integration-green) — so an
un-graded matrix cannot back a product-grain (≥ ux-rc) claim: the honest, humble default.

Enforced by .speck/scripts/validation/validators/validate-traceability-matrix.sh:
  • default mode (epic-analyze, pre-commit): once epic-breakdown.md exists, NO row may be open —
    every row needs a discharge (story+AC) or a DEC/pilot-gated status. Grain is OPTIONAL here.
  • --require-evidence (epic-validate): every row must be `discharged`, `descoped`, or `pilot-gated`.
    Absent grain is never a conservation violation. As of v8.5.0 the grain teeth BLOCK here (at the
    /epic-validate gate): grain ≤ the discharging story's effective state; a ≥ ux-rc row must cite
    walk-evidence; an invalid grain token is rejected. On the fast path (default mode) grain findings
    stay surfaced-only (WARN). The gate emits MATRIX_GRAIN_CAP = MIN grain over ALL discharged rows;
    /epic-validate folds it into MAX claimable = MIN(story states, MATRIX_GRAIN_CAP).
  • --check-fidelity (opt-in, WARN-only, #86): checks each row's Promise shares vocabulary with the
    Source clause it names, and that the named Source artifact/anchor exists. PRESENCE + OVERLAP only —
    it does NOT judge whether the shipped product keeps the promise (that is /audit's semantic sweep).

## RETROFIT / FINALIZATION MODE (Speck v7.15)
If you are retrofitting this matrix on an already-built epic (e.g. following a large audit of existing promises), do NOT start from scratch:
1. **Seed from Existing Audit/Scan**: Import existing promises directly from your audit-report.md or codebase scan.
2. **Consolidation Rule**: Consolidate multiple fine-grained promises (e.g., individual form fields or styling rules) into high-level, load-bearing PRM rows to maintain readability.
3. **Backing Column**: List the fine-grained backing promise/audit IDs in the 'Backing' column. NEVER truncate or merge promises silently without backing references.
4. **Pilot-Gated Status**: For promises restricted to the pilot program, set Status to 'pilot-gated' and cite the specific pilot boundary/reference (e.g. PILOT-GATED-01) in the DEC/Discharge columns.
-->

## 1. Promise Sources

Enumerate EVERY promise this epic owns, from each source below, then give each a PRM id in §2.

- **product-contract.md** — sections routed to this epic: §1 paid promise, §3 differentiator pillars, §3a anti-differentiators, §4 JTBD / operational invariants, §5 magic moments, §10 trust moments.
- **epic.md** — every `FR-[EPIC]-###` and every `NFR-###`.
- **wireframes.md** — every screen in the screen-inventory, AND every element/state drawn per screen (Default / Loading / Empty / Error / Success).
- **experience-chain.md** — every seam rule: §2 single-job-per-screen, §4 no-repetition, §5 first-viewport "why now", §6 magic-moment placement, §7 continuity threads, §8 backtracking, §9 cross-epic adjacency.

> If a source is absent for this epic (e.g. backend-only epic with no wireframes), note "N/A — no UI surface" here. Absence must be stated, not assumed.

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Grain (proven-at) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | [differentiator pillar text] | S012 / AC-3 | — | — | ux-rc | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | [screen element + its job] | S018 / AC-1 | — | — | — | mapped |
| PRM-003 | experience-chain §6 / magic-moment placement | [seam rule text] | — | DEC-0207 | — | — | descoped |
| PRM-004 | epic.md FR-E0NN-014 | [requirement text] | — | — | — | — | open |
| PRM-005 | wireframes S05 / dashboard | [consolidated complex visual flow] | — | — | AUDIT-E002-42, E002/PRM-054 | — | pilot-gated |
| PRM-006 | epic.md NFR-003 | [backend invariant text] | S021 / AC-2 | — | — | integration-green | discharged |

## 3. Coverage Summary

- **Total promises**: [N]
- **Discharged** (story validated w/ evidence): [N]
- **Mapped** (assigned, pending validation): [N]
- **Descoped** (via DEC): [N]
- **Pilot-gated** (deferred to pilot): [N]
- **Open / unmapped**: [N] ← **MUST be 0 after `/epic-breakdown`**

### Grain floor (Speck v8.4, #87)

- **Discharged at product grain** (≥ ux-rc): [N]
- **Discharged at story grain** (< ux-rc, or un-graded): [N]
- **MATRIX_GRAIN_CAP** (MIN grain over ALL discharged rows): [enum] ← the ceiling this matrix can back at `/epic-validate`

An un-graded discharged row counts as story-grain (integration-green): an un-graded matrix cannot back a product-grain (≥ ux-rc) claim. Grade discharged rows at the grain their evidence was collected — a helper-importing unit test is `impl-green`, not the story's headline state.

Any open/undischarged row blocks `/epic-analyze` (P1) and bars the epic from claiming ANY readiness state at `/epic-validate`. Descope deliberately (with a DEC), defer (with pilot-gated and a backing reference), or discharge it — never let it evaporate.

---

*[as of SHA `<hash>` | generated `<date>` | speck vX.Y.Z]*
