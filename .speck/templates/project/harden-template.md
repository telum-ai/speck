---
speck_version: 10.0
template_version: "10.0.0"
artifact_type: harden-report
mutation_record: required
---

# Post-Validation Hardening Report: [Harden Name]

**Defect ID**: `HARDEN-###-description`  
**Date**: [YYYY-MM-DD HH:MM]  
**Branch**: [branch name]  
**Related Story/Epic**: [S### / E### / none]

---

## 1. Defect Description (The Truth)

*Describe exactly what broke and how it was discovered. What did the user/founder live or experience?*

- **Observed Behavior**: [e.g., "Pressing 'Submit' on the studio creation form did not block double-submits, causing duplicate DB rows when double-clicked."]
- **Impact Severity**: [P0 - Blocker | P1 - High | P2 - Medium | P3 - Low]
- **Found by**: [e.g., Founder post-ship walkthrough / User bug report]

---

## 2. Root Cause Analysis (The Gap)

*Identify the deep technical gap. Why did the existing validation gates (unit tests, linter, story-validate, /audit) miss it — and did one of them **require** the defect?*

- **Technical Root Cause**: [e.g., "The `useActionState` `isPending` state was destructured from the hook but never bound to the button's `disabled` prop, leaving the button interactive during submit."]
- **Gate Defect (Why did gates miss it?)**: [e.g., "The `/audit` executed via direct API tests and bypassed the UI DOM entirely, and unit tests didn't simulate consecutive click events during pending network transactions."]

---

## 2b. Counter-Tests (The Suite's Shadow)

*Every defect has a shadow: the tests written against the buggy code. They name the defect as the
expected value, so they are green forever and the truthful change is the failing one. The cheapest
misreading of a red suite is "my fix broke a test" rather than "the suite agreed with the bug".*

**Classify, do not delete.** A pre-existing test asserting the old behaviour is not automatically a
defect. Exactly one of the three classes is a finding:

- `DEFECT-PINNING` — the assertion encodes the bug. It is its own remediation line in §3 with its
  own severity, and it inherits the severity of the defect it pinned on a safety, authorization or
  disclosure surface.
- `DECISION-RECORD` — the assertion encodes a deliberate choice the fix now reverses. Cite the
  decision-log entry and re-decide there. Deleting it to get green is not a repair.
- `SCOPE-NARROWING` — the assertion was true of a narrower case and the fix narrows it. Rewrite.

- **Pre-Fix Grep**: [SEARCH_QUERY RUN OVER THE SUITE BEFORE WRITING THE FIX]
- **Pre-Existing Tests That Went Red**: [TEST_PATH AND NAME AND CLASS PER ENTRY]
- **If None Went Red**: [NO_PRE_EXISTING TEST WENT RED BECAUSE THE HONEST REASON]

*A fix that turns nothing red is suspect. The two causes look identical in a report: the path was
genuinely uncovered, or the fix does not do what its author thinks it does. The honest exception is
the first — and an uncovered path is a coverage finding of its own, carried into §3. The requirement
here is the SENTENCE, never a hunt for something to break.*

---

## 3. Remediations & Hardening Guardrails (The Fix)

*What did you fix, and what systemic guardrail (tests, linter rules, template check) is now in place to prevent this bug from ever recurring?*

- **Implementation Fix**: [e.g., "Bound `isPending` to the submit button's `disabled` state and disabled form fields during submission."]
- **Regression Test**: [e.g., "Added a Playwright test simulating double-click and asserting that only one API request is dispatched."]
- **Systemic Guardrail Added**: [e.g., "Updated `ui-spec-template.md` to require Double-Submit Protection and Form-Level states in all UI specifications."]
- **Guardrail Mutation-Proof**: [MUTATION_SITE PATH AND LINE] · [MATCH_COUNT] · [RED_TESTS NAMES AND COUNTS] · [GREEN_CONTROL THAT STAYED GREEN] · [VERDICT_CODE FROM MUTATE GUARD]
- **Class Recurrence Check**: [SECOND_INSTANCE OF THIS SHAPE FOUND OR NOT AND THE SHAPE GREP USED]

*Produce the Mutation-Proof line by running `.speck/scripts/validation/mutate-guard.sh` and
transcribing its `SPECK_MUTATION_*` output — the verdict cell is the code the script printed, never
a judgement typed by hand. The script mutates inside a throwaway worktree, so there is nothing to
revert and an interrupted run cannot leave a mutated production file behind.*

*Verdicts: `GUARD_MUTATION_PROVEN` · `GUARD_MUTATION_GREEN.P2` (report it green, write the honest
scope onto the test, and never tune the mutation until it reddens) · `GUARD_UNMUTATED.P2` (nothing
was measured — the guardrail does not discharge this defect yet).*

*Class recurrence: if this is the SECOND instance of a shape, the required deliverable stops being
another instance fix and becomes a gate at the chokepoint every reader routes through — with
inverted polarity, so the registry enumerates exceptions rather than instances. Declining a shape in
writing beats flagging correct code: `>=2 instances AND a syntactically decidable shape`.*

---

## 4. Readiness Re-assessment

*Do these changes alter or restore any previously verified readiness states?*

- **Affected Artifacts**: [e.g., `stories/S008-signup/validation-report.md`]
- **Prior State**: [e.g., `SHIP-RC`]
- **Re-assessed State**: [e.g., `SHIP` (after fixing double-submit and verifying against the launch build)]
- **Verification Proof**: [Link to tests run / new screenshots / larp findings]

---

*[as of SHA <git_sha_short> | verified <date> | speck]*
