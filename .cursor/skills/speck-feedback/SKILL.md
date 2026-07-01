---
name: speck-feedback
description: Continuous feedback capture mechanism. Maintains a running feedback file, dedup-checks issues on telum-ai/speck via gh, and drafts comments/issues for one-tap confirmation.
disable-model-invocation: false
---

## Purpose

When developers or agents encounter a bug, a workaround, or a confusing Speck instruction, they often patch it locally or work around it without capturing the feedback. This skill defines the **Continuous Feedback Capture Mechanism** to ensure these learnings are captured and fed back upstream to the Speck methodology.

---

## 🛠️ Core Process

### 1. Maintain Running Feedback File
- Write feedback immediately to a running file: `.speck/feedback/<date>-<session>.md` (using `.speck/templates/feedback/template.md`).
- Fill out the TL;DR, Gap / Observation, Symptom, Root Cause, Severity, and Diff sections.

### 2. Upstream Deduplication & Check
- Before filing a new issue, use `gh` to search for similar issues on the `telum-ai/speck` repository:
  ```bash
  gh issue list --repo telum-ai/speck --search "[keywords]"
  ```
- **Guardrails**:
  - **Dedup First**: Always search existing issues first.
  - **Prefer Comment**: If a similar issue exists, draft a comment to append to that issue instead of creating a new one.
  - **Human Confirmation**: Always present the drafted issue/comment to the user for one-tap confirmation before running `gh issue create` or `gh issue comment`.

### 3. Draft Comment or Issue
- **If similar issue exists (e.g. #123)**:
  - Draft a comment:
    ```markdown
    I encountered this issue in my workspace during [session].
    Here is my observation:
    - **Symptom**: [symptom]
    - **Root cause**: [root cause]
    - **Patch applied**: [patch]
    ```
- **If no similar issue exists**:
  - Draft a new issue using the feedback template.

---

## 🚦 Inline Capture Triggers

Always-on discipline demands that the moment a gate is worked around, a skill is ambiguous, or a Speck behavior is patched locally, you MUST trigger `/speck-feedback`:

| Skill | Trigger Condition | Action |
|-------|-------------------|--------|
| `story-validate` | Any gate is bypassed, skipped, or marked `⚠️ Skipped` due to environment/tooling limitations | Run `/speck-feedback` to document the limitation and propose a sandbox-friendly setup or mock. |
| `epic-validate` | Any story-level validation is bypassed or the JTBD LARP is blocked by infrastructure | Run `/speck-feedback` to document the block and propose an upstream fix. |
| `speck-audit` | Any adversarial probe is skipped or false-green theater is detected | Run `/speck-feedback` to document the probe gap. |
| `speck-learn` | You capture a `GOTCHA` or `DEBT` that stems from a Speck template or script limitation | Run `/speck-feedback` to propose a template or script enhancement. |
