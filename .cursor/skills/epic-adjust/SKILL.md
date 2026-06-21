---
name: epic-adjust
description: Deliberate re-engineering of already-validated epic-level work. Run when you deliberately modify what you previously specified and validated at the epic level (IA redesign, cross-cutting visual-system overhaul, multi-story structural pivot) — distinguished from /harden which is for defect/bug fixing. FIRST ACTION after loading is to read template at .speck/templates/epic/epic-adjust-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now:
```
.speck/templates/epic/epic-adjust-template.md
```

---

## 🎯 The Epic-Adjust Flow (/epic-adjust scope)

When validated epic-level work (such as Information Architecture, screen-flows, cross-story design systems) is intentionally changed because of new understanding or pivots, do NOT wing it and do NOT use `/harden` (which is reserved exclusively for post-validation defect fixes). Instead, use the **Epic-Adjust Flow**:

1. **Understand Cross-Cutting Pivot**:
   - Identify the product redesign or cross-cutting pivot.
   - Map out which stories and shared components within the epic are affected.

2. **Re-Spec the Delta**:
   - Spec only the epic-level deltas in `epic.md` (FRs/NFRs), `wireframes.md` (screen layout or inventory), and `experience-chain.md` (cross-screen seam rules).

3. **Conserve Promises**:
   - Re-walk and update the epic's `traceability-matrix.md`.
   - Retire superseded cross-story promises using a Decision Log entry (`DEC-NNNN`).
   - Add new `PRM-NNN` rows for any redesigned elements, screens, or seam rules.

4. **Force a Decision Log Entry**:
   - Append a clear decision lock detailing the epic-level redesign and alternatives to `project-decisions-log.md` via `/speck-decision-log`.

5. **Re-run Audit and Validation (on the Delta only)**:
   - Run `/audit` (epic-level) to examine the cross-story structural impacts.
   - Run `/epic-validate` (JTBD walkthrough) on the delta, capturing new multi-screen visual flow evidence.

6. **Re-Stamp and Downgrade Readiness**:
   - Downgrade the epic's overall readiness state to `NO-SHIP` (or a lower validated state) until delta-validation is complete.
   - Once validated, claim the re-assessed readiness state.
   - Write the dated epic adjustment report: `specs/projects/<PROJECT_ID>/epics/E###/epic-adjust-report-<YYYYMMDD>.md`.
   - Run `.speck/scripts/stamp-truth.sh` against the report and updated specs.
   - Run `/project-state` to regenerate the workspace first-read state.

---

## Behavior Rules

- NEVER leave epic specification docs, experience chains, or wireframes stale after a deliberate cross-story redesign — keep the truth honest.
- ALWAYS conserve promises: retire old promises with a DEC ref and add new promises for the redesigned elements.
- ALWAYS downgrade the epic's readiness state during implementation and delta-validation; do not let stale validation claims mislead the team.
