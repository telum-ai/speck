---
name: story-adjust
description: Deliberate re-engineering of already-validated story work. Run when you deliberately modify what you previously specified and validated (redesign, visual-system overhaul, content shift) — distinguished from /harden which is for defect/bug fixing. FIRST ACTION after loading is to read template at .speck/templates/story/story-adjust-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now:
```
.speck/templates/story/story-adjust-template.md
```

---

## 🎯 The Story-Adjust Flow (/story-adjust scope)

When validated story work is intentionally changed because of new understanding, redesign, visual overhauls, or scoping changes, do NOT wing it and do NOT use `/harden` (which is reserved exclusively for post-validation/post-ship defect fixes). Instead, use the **Story-Adjust Flow**:

1. **Understand Change Intent**:
   - Determine what deliberate redesign or pivot has been decided and why.
   - Outline the specific scope of the changes.

2. **Re-Spec the Delta**:
   - Do NOT rebuild the spec from scratch. Spec only the **delta**.
   - Update the affected Functional Requirements (FRs), Acceptance Criteria (AC), or wireframe components in `spec.md`.
   - Update any elements in `ui-spec.md` or `contracts/` affected by the shift.

3. **Conserve Promises**:
   - Ensure the `traceability-matrix.md` still balances (conservation law).
   - Any removed/superseded promises MUST be explicitly retired using a Decision Log entry (`DEC-NNNN`).
   - Add new `PRM-NNN` rows for any net-new elements, actions, or seams introduced.

4. **Force a Decision Log Entry**:
   - Append a clear decision lock detailing the redesign and the alternatives considered to `project-decisions-log.md` via `/speck-decision-log`.

5. **Re-run Audit and Validation (on the Delta only)**:
   - Run `/audit` to verify the delta.
   - Run `/story-validate` focusing on the delta, capturing new screenshots or visual evidence.

6. **Re-Stamp and Downgrade Readiness**:
   - Downgrade the story's readiness state to `NO-SHIP` (or a lower validated state) until delta-validation is complete.
   - Once validated, claim the re-assessed readiness state.
   - Write theDated story adjustment report: `specs/projects/<PROJECT_ID>/epics/E###/stories/S###/story-adjust-report-<YYYYMMDD>.md`.
   - Run `.speck/scripts/stamp-truth.sh` against the report and updated specs.
   - Run `/project-state` to regenerate the workspace first-read state.

---

## Behavior Rules

- NEVER leave validated specification docs, experience chains, or wireframes stale after a deliberate change — that is promise evaporation by silence, which Speck's methodology exists to prevent.
- ALWAYS conserve promises: retire old promises with a DEC ref and add new promises for the redesigned elements.
- ALWAYS downgrade the story's readiness state during implementation and delta-validation; do not sit at a green claim when the validated code has been altered.
