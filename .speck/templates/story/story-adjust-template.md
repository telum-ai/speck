---
speck_version: 7.15
template_version: "7.15.0"
artifact_type: story-adjust-report
---

# Post-Validation Story Adjustment Report: [Adjust Name]

**Adjustment ID**: `ADJUST-S###-[short-description]`  
**Date**: [YYYY-MM-DD HH:MM]  
**Branch**: [branch name]  
**Related Story**: [S###]

---

## 1. Change Intent (The Why)

*Describe exactly what deliberate change is being introduced and why. What new product understanding or customer feedback drove this redesign?*

- **Observed Need / Feedback**: [e.g., "Founder walkthrough requested an axis-grouped layout rather than a flat list for the signature view."]
- **Deliberate Shift**: [e.g., "We are splitting the flat list into two visual sections: Active and Inactive."]
- **Impact Severity**: [P1 - High | P2 - Medium | P3 - Low]

---

## 2. Delta Re-specification (The What)

*Specify only the delta — what requirements, acceptance criteria, or wireframe sections are modified.*

- **Affected Specification**: `stories/S###-[name]/spec.md`
- **FR / AC Changes**:
  - [e.g., "Modified FR-1: Flat list replaced with grouped list."]
  - [e.g., "Added AC-4: Axis header must display item counts."]
- **UI Elements Changed**: [e.g., "Removed flat list view; added Segmented Control and two Section headers."]

---

## 3. Promise Conservation (The Contract)

*Every deliberate redesign must conserve promises. Which PRM-NNN rows were retired (via a DEC) and what new PRM-NNN rows were added?*

- **Retired Promises (via DEC)**:
  - [e.g., "PRM-002 (flat list UI element) retired via DEC-0208."]
- **New Promises Added**:
  - [e.g., "PRM-015 (segmented control element) added."]
  - [e.g., "PRM-016 (axis header counts) added."]
- **Traceability Matrix Path**: `epics/E###-[name]/traceability-matrix.md`

---

## 4. Decision-Log & Audit Status

*Every major adjustment phase requires a recorded decision lock and a re-audit.*

- **Decision Log Reference**: [e.g., `DEC-0208` in `project-decisions-log.md`]
- **Re-Audit Performed**: [e.g., "Yes, ran /audit to verify no styling leaks or performance issues on the new double list view."]
- **New Test Guardrail**: [e.g., "Updated Playwright test to click Segmented Control tabs and verify items filtered correctly."]

---

## 5. Readiness Re-assessment (The Status)

*An un-validated adjustment downgrades the story's readiness state until delta-validation passes.*

- **Prior State**: [e.g., `UX-RC`]
- **Downgrade State**: `NO-SHIP` (during implementation and audit)
- **Re-assessed State**: [e.g., `UX-RC` (fully restored after delta-validation passed with fresh LARP evidence)]
- **Verification Proof**: [Link to fresh tests run / new screenshots / larp findings]

---

*[as of SHA <git_sha_short> | verified <date> | speck]*
