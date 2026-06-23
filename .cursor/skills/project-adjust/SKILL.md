---
name: project-adjust
description: Deliberate directional or strategic intent change of already-validated/shipped project work. Run when you deliberately modify high-level contracts, strategic promises, or decisions (e.g., revising product-contract.md or project.md) — distinguished from /harden (defect fixing) and /story-adjust or /epic-adjust (story/epic redesign). FIRST ACTION after loading is to read template at .speck/templates/project/project-adjust-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/project/project-adjust-template.md
```

---

## 🎯 The Project-Adjust Flow (/project-adjust scope)

When validated project-level work (such as strategic promises in `product-contract.md`, core design vision in `project.md`, or central system design in `architecture.md`) is intentionally pivoted or changed, do NOT wing it and do NOT use `/harden`. Instead, use the **Project-Adjust Flow**:

1. **Re-Spec the Contract Delta**:
   - Update `specs/projects/<PROJECT_ID>/product-contract.md` (§1 Paid Promise, §3 Differentiators / Banned Language) and/or `project.md` (Vision / scope) to match the new directional intent.
   - Update `PRD.md`, `architecture.md`, or `evidence-contract.md` if touched.
   - *Caution*: Do NOT just overwrite these documents; use the normative language guidelines of Speck and run `/project-product-contract` or similar to keep them crisp.

2. **Conduct Skeptical Review**:
   - Run `/speck-skeptical-review` to analyze the new direction, explore at least N>=3 alternative approaches, score trade-offs, and document the architectural rationale.

3. **Force a Superseding Decision Log Entry**:
   - Appending a clear decision lock (using project-level DEC bands `DEC-0001`–`DEC-0099`) to `project-decisions-log.md` via `/speck-decision-log`.
   - The new log entry MUST carry a `Supersedes: DEC-XXXX` field linking to the superseded decision.

4. **Compute Cascade & Blast Radius**:
   - Run the reverse change-cascade script to find all downstream epics, stories, and promises affected by the changed contract section or superseded decision:
     ```bash
     bash .speck/scripts/validation/validators/compute-cascade.sh --dec DEC-XXXX
     ```
   - Declare the blast radius in your adjustment report. The cascade script will flag downstream items as stale (`CASCADE_STALE.P1`) on `/recheck`.

5. **Route Downstream Adjustments**:
   - Instruct the workspace (or deploy subagents) to run `/epic-adjust` or `/story-adjust` on all affected downstream epics and stories identified in the blast radius.

6. **Re-Stamp and Downgrade Readiness**:
   - Downgrade the overall project readiness state to `NO-SHIP` (due to active stale cascade flags) or down to the minimum validated state of affected downstream epics.
   - Create the dated project adjustment report: `specs/projects/<PROJECT_ID>/project-adjust-report-<YYYYMMDD>.md` based on the template.
   - Once all downstream epics/stories are updated and re-validated, recheck the cascade (`compute-cascade.sh --dec DEC-XXXX --strict` returns 0) and restore the project's validated readiness state.
   - Run `.speck/scripts/stamp-truth.sh` against the report and updated specs.
   - Run `/project-state` to regenerate the workspace first-read state.

---

## Behavior Rules

- NEVER revise a validated product contract or make directional project changes by silently editing files. Always run `/project-adjust` to compute the cascade and maintain a clean audit trail.
- ALWAYS force a new DEC entry that explicitly lists which prior decision it `Supersedes`.
- ALWAYS run `compute-cascade.sh` to determine the precise blast radius of dependent epics/stories, and downgrade project readiness state until the cascade is fully re-validated and resolved.
