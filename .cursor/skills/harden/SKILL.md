---
name: harden
description: Lightweight skill for post-validation hardening. Run when a defect is found in already validated/shipped work. Captures the defect, technical root cause, gate defect (why gates missed it), systemic guardrail (tests/lint/checks), and readiness re-assessment — bypassing the heavy spec -> plan -> tasks lifecycle. FIRST ACTION after loading is read template at .speck/templates/project/harden-template.md.
disable-model-invocation: false
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now:
```
.speck/templates/project/harden-template.md
```

---

## 🎯 The Harden Flow (/harden scope)

When a bug is found post-validate or post-ship, do NOT spin up a full-ceremony story with spec, plan, and tasks unless the feature requires brand-new functionality. Instead, use the **Harden Flow**:

1. **Investigate & Diagnose**:
   - Determine what broke, how it was discovered (e.g. founder walkthrough, user report), and identify the technical root cause.
   - Run `/speck-debug` or equivalent debugging scripts if necessary.

2. **Root Cause Analysis (RCA)**:
   - Critically evaluate why the existing safety nets (tests, linters, audit, validation) missed this bug.
   - Do NOT just patch the code — find the systemic testing or specification gap.

3. **Implement Fix & Systemic Guardrail**:
   - Write the fix for the bug.
   - **Crucial**: Implement a regression guardrail. If it was a mock issue, fix the mock; if it was a UI-bypass issue, add a test that drives the real UI DOM.
   - If applicable, add a lint check, template check, or prime utility to prevent recurrence across the codebase.

4. **Document the Hardening**:
   - Create a dated hardening report using the template:
     `specs/projects/<PROJECT_ID>/project-harden-report-<YYYYMMDD>.md`
   - Fill in all sections (Defect, Root Cause, Guardrails, Readiness Re-assessment).

5. **Re-Stamp & Re-Assess State**:
   - If the bug affected an already-validated story/epic, update its `validation-report.md` with the new re-assessed readiness state.
   - Run `.speck/scripts/stamp-truth.sh` against the report and the updated validation reports.
   - Trigger `/project-state` to regenerate and update active status.

---

## Behavior Rules

- NEVER just patch the bug without documenting why the gates missed it.
- ALWAYS add a systemic guardrail (linter, regression test, or primitive check) to ensure it can never recur.
- ALWAYS re-assess the readiness state of the affected stories.
- BLOCK subsequent releases if the defect is a P0 blocker until the `/harden` flow report is stamped and green.
