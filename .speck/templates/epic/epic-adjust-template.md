---
speck_version: 8.0
template_version: "7.15.0"
artifact_type: epic-adjust-report
---

# Post-Validation Epic Adjustment Report: [Adjust Name]

**Adjustment ID**: `ADJUST-E###-[short-description]`  
**Date**: [YYYY-MM-DD HH:MM]  
**Branch**: [branch name]  
**Related Epic**: [E###]

---

## 1. Change Intent (The Why)

*Describe exactly what deliberate change is being introduced across this epic and why. What high-level product redesign or cross-cutting pivot occurred?*

- **Observed Need / Feedback**: [e.g., "Overhaul the visual system of the Flyt dashboard to match the new neutral-only treatment requested by users."]
- **Deliberate Shift**: [e.g., "Removing all categorical color treatments across all screens in the dashboard in favor of a single neutral-treatment scale."]
- **Impact Severity**: [P1 - High | P2 - Medium | P3 - Low]

---

## 2. Delta Re-specification (The What)

*Specify the epic-level deltas across your epic.md, wireframes.md, or experience-chain.md.*

- **Affected Specification**: `epics/E###-[name]/epic.md`
- **Seam / Flow Changes**: [e.g., "experience-chain.md §6 updated to remove colored notification badges on transitions."]
- **Wireframe Screens / Elements Updated**: [e.g., "wireframes.md Screen S05 updated: removed colored badges, replaced with standard text pill."]

---

## 3. Promise Conservation (The Contract)

*Every deliberate redesign must conserve promises. Re-walk the traceability matrix to retire superseded promises and register the deltas.*

- **Retired Promises (via DEC)**:
  - [e.g., "PRM-104 (categorical color styling) retired via DEC-0209."]
- **New Promises Added**:
  - [e.g., "PRM-152 (neutral visual scale element) added."]
- **Traceability Matrix Path**: `epics/E###-[name]/traceability-matrix.md`

---

## 4. Decision-Log & Audit Status

*Every major adjustment phase requires a recorded decision lock and a re-audit.*

- **Decision Log Reference**: [e.g., `DEC-0209` in `project-decisions-log.md`]
- **Re-Audit Performed**: [e.g., "Yes, ran /audit on E### scope to verify accessibility color-contrast ratios on the neutral scale."]
- **New Test Guardrail**: [e.g., "Added a baseline visual regression test for S05 dashboard to lock the neutral treatment."]

---

## 5. Readiness Re-assessment (The Status)

*An un-validated adjustment downgrades the epic's readiness state until delta-validation passes.*

- **Prior State**: [e.g., `UX-RC`]
- **Downgrade State**: `NO-SHIP` (during implementation and audit)
- **Re-assessed State**: [e.g., `UX-RC` (fully restored after delta-validation passed with fresh LARP walkthrough evidence)]
- **Verification Proof**: [Link to fresh tests run / new screenshots / larp findings]

---

*[as of SHA <git_sha_short> | verified <date> | speck]*
