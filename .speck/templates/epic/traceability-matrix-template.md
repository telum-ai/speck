---
speck_version: 7.14
template_version: "7.14.0"
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
                                                      └→ descoped (a DEC drops it)

Enforced by .speck/scripts/validation/validators/validate-traceability-matrix.sh:
  • default mode (epic-analyze, pre-commit): once epic-breakdown.md exists, NO row may be open —
    every row needs a discharge (story+AC) or a DEC.
  • --require-evidence (epic-validate): every row must be `discharged` or `descoped`.
-->

## 1. Promise Sources

Enumerate EVERY promise this epic owns, from each source below, then give each a PRM id in §2.

- **product-contract.md** — sections routed to this epic: §1 paid promise, §3 differentiator pillars, §3a anti-differentiators, §4 JTBD / operational invariants, §5 magic moments, §10 trust moments.
- **epic.md** — every `FR-[EPIC]-###` and every `NFR-###`.
- **wireframes.md** — every screen in the screen-inventory, AND every element/state drawn per screen (Default / Loading / Empty / Error / Success).
- **experience-chain.md** — every seam rule: §2 single-job-per-screen, §4 no-repetition, §5 first-viewport "why now", §6 magic-moment placement, §7 continuity threads, §8 backtracking, §9 cross-epic adjacency.

> If a source is absent for this epic (e.g. backend-only epic with no wireframes), note "N/A — no UI surface" here. Absence must be stated, not assumed.

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | [differentiator pillar text] | S012 / AC-3 | — | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | [screen element + its job] | S018 / AC-1 | — | mapped |
| PRM-003 | experience-chain §6 / magic-moment placement | [seam rule text] | — | DEC-0207 | descoped |
| PRM-004 | epic.md FR-E0NN-014 | [requirement text] | — | — | open |

## 3. Coverage Summary

- **Total promises**: [N]
- **Discharged** (story validated w/ evidence): [N]
- **Mapped** (assigned, pending validation): [N]
- **Descoped** (via DEC): [N]
- **Open / unmapped**: [N] ← **MUST be 0 after `/epic-breakdown`**

Any open/undischarged row blocks `/epic-analyze` (P1) and bars the epic from claiming ANY readiness state at `/epic-validate`. Descope deliberately (with a DEC) or discharge it — never let it evaporate.

---

*[as of SHA `<hash>` | generated `<date>` | speck v7.14.0]*
