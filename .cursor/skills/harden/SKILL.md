---
name: harden
description: Lightweight skill for post-validation hardening. Run when a defect is found in already validated/shipped work. Captures the defect, technical root cause, gate defect (why gates missed it), systemic guardrail (tests/lint/checks), and readiness re-assessment — bypassing the heavy spec -> plan -> tasks lifecycle. FIRST ACTION after loading is read template at .speck/templates/project/harden-template.md.
disable-model-invocation: false
---

> 🚦 **METHODOLOGY INTENT SPLIT**: 
> - Use `/harden` when something you previously validated/shipped is **broken** (defect, bug, incident).
> - Use `/story-adjust` or `/epic-adjust` when you have **deliberately changed** what you specified/shipped (redesign, visual overhaul, scope pivot) at the story or epic level.
> - Use `/project-adjust` when you have a **deliberate directional or strategic intent change** (such as pivoting a product contract or strategic vision) at the project level.

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
   - Critically evaluate why the existing safety nets (tests, linters, audit, validation) missed this bug — **and whether one of them REQUIRED it.**
   - Do NOT just patch the code — find the systemic testing or specification gap.

2b. **Counter-test sweep — BEFORE you write the fix** (fills §2b of the template):
   - Every defect has a shadow: the tests written against the buggy code. They name the defect as the *expected value*, so they are honest, well-named and green forever — and the truthful change is the failing one. The cheapest misreading of a red suite is "my fix broke a test" rather than "the suite agreed with the bug".
   - **Grep the suite for assertions naming the OLD behaviour** and record the query verbatim. Search the behaviour, not the identifier (`rg -n 'fail-open|renders ONLY|deliberate claim' --glob '**/__tests__/**'`).
   - **After the fix, list every PRE-EXISTING test that went red**, and classify each — never delete one to get green:
     - `DEFECT-PINNING` — the assertion encodes the bug. It is **its own finding**, with its own remediation line in §3 and its own severity; on a safety, authorization or disclosure surface it inherits the severity of the defect it pinned.
     - `DECISION-RECORD` — the assertion encodes a deliberate choice the fix reverses. Cite the decision-log entry and re-decide there.
     - `SCOPE-NARROWING` — it was true of a narrower case. Rewrite it.
   - **If nothing went red, say why.** A fix that turns nothing red is suspect: "the path was genuinely uncovered" and "the fix does not do what I think it does" look identical in a report. The honest exception is the first — and an uncovered path is a coverage finding of its own. If no reason can be given, the fix is unproven: mutate it (step 3) before claiming anything. The requirement is the **sentence**, never a hunt for something to break.
   - For a copy / disclosure / claims defect, also check the guard's DIRECTION: a blacklist of phrasings is never complete and does not cross locales. The load-bearing assertion must be **positive** (the required fact is PRESENT), parametrized over **every** locale bundle. A blacklist-only guard is secondary evidence.

3. **Implement Fix & Systemic Guardrail**:
   - Write the fix for the bug.
   - **Crucial**: Implement a regression guardrail. If it was a mock issue, fix the mock; if it was a UI-bypass issue, add a test that drives the real UI DOM.
   - If applicable, add a lint check, template check, or prime utility to prevent recurrence across the codebase.
   - **Then mutation-prove the guardrail** — a guard is not evidence until someone watched it fail, and the highest-yield suspect is the guard authored in the *same increment* as the fix, because it was designed against the same model of the defect that produced a wrong fix once:
     ```
     .speck/scripts/validation/mutate-guard.sh \
       --file <production path> --pattern '<the shipped line>' --replacement '<the defect>' \
       --red '<the guardrail invocation>' --green '<a control that must STAY green>' \
       [--expect-count N]
     ```
     It runs inside a **throwaway worktree**, so there is nothing to revert and an interrupted run cannot leave a mutated production file behind. It refuses a pattern that does not match exactly once, a comment or docstring line, and a test or fixture path — the three ways a mutation is silently a no-op. **Transcribe its `SPECK_MUTATION_*` output into §3; never type a verdict by hand.**
   - A guard cited as evidence must **import and call the shipped function or the shipped SQL literal**, not a transcription of it — a guard that re-derives its own predicate cannot observe its own removal. For a **drop / filter / redact** guardrail the required control is that **legitimate content survives**; proving bad content is caught is satisfied by a guard that drops everything, and over-removal is the bug that actually ships.
   - If the mutation comes back **`GUARD_MUTATION_GREEN.P2`, record it green** and write the honest scope onto the test ("this guard does not observe X"). **Never tune the mutation until it reddens** — that manufactures exactly the evidence the field exists to prevent.
   - **Class recurrence (§3, required).** Ask "is this an instance of a class?" and answer it by searching for the syntactic **shape**, not for the identifier that happened to be wrong. On the **second** instance the required deliverable stops being another instance fix and becomes a **gate at the chokepoint** every reader routes through — with inverted polarity, so the registry enumerates *exceptions* rather than instances. The bound: `>=2 instances AND a syntactically decidable shape`. Where the shape is not decidable, a named in-file declination plus the chokepoint refactor beats a scanner that flags correct code.

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
- NEVER cite a guardrail as evidence without a mutation record produced by `mutate-guard.sh`.
- NEVER close a harden without §2b answered — including the zero-red sentence.
- NEVER delete a pre-existing test to get green. Classify it; a `DEFECT-PINNING` test is its own finding.
- ALWAYS add a systemic guardrail (linter, regression test, or primitive check) to ensure it can never recur.
- ALWAYS re-assess the readiness state of the affected stories.
- BLOCK subsequent releases if the defect is a P0 blocker until the `/harden` flow report is stamped and green.
