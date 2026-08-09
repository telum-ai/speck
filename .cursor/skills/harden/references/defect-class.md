# harden / defect-class

## The Harden Flow (/harden scope)

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

3b. **Observation licensing — when an OBSERVATION is what closes the fire** (record in §3, cite in §4):
   - Step 3 mutation-proves a **test**. This step is its counterpart for an **observation** — a grep of a log, a CI verdict, a dashboard, a quiet inbox, a count that did not move. Those close fires and justify REFUTED in exactly the same way, and they carry a defect tests do not: **a green reports its verdict and never its exposure** — whether the occasion it ran on contained the failing case at all. A hard-won pass and a pass that *could not have failed* are byte-identical in the report, so confidence accumulates on **run count** rather than on **chances to fail**.
   - **This is not the shadowed/vacuous/forged class.** The check is correct, executed, and truthful about itself. What is missing is the occasion. Keep them apart mechanically: re-run the check against a **real failing case** — RED means the guard is broken (that is the other class, and it is a §2b finding); GREEN means nothing is broken and this run simply had nothing to catch (this class).
   - **Ask the two questions, in order:**
     1. **Can the failing case be manufactured cheaply?** Yes → manufacture it before the green counts. Two legs, and neither substitutes for the other. *The instrument:* confirm it can show the thing AT ALL before believing it showed nothing (a positive control). *The invocation:* run the **shipped** one. Diff the local flags and env against the `Dockerfile` CMD / `Procfile` / deploy command — the canonical instance is a secret in a URL path segment that was invisible locally under `uvicorn --log-level warning` and reproduced in one request under the container's own invocation, which defaults to INFO. **The observation was real; the configuration it was made under was the lie.**
     2. **If it cannot be exposed, what does this green license?** Only *waiting* → the unexposed run is harmless and chasing exposure is waste. Something **accumulating or irreversible** — closing this fire, exiting a shadow period, re-stamping a readiness state, writing REFUTED on a live credential → **the unexposed run must not count toward it.**
   - Run it, and **transcribe the `SPECK_OBSERVATION_*` block; never type a verdict by hand**:
     ```
     .speck/scripts/validation/observe-guard.sh \
       --subject '<what is being watched>' \
       --observe '<the exact command whose output you read>' \
       --expect-absent '<the needle you claim is not there>' \
       --licenses waiting|accumulating|irreversible \
       [--positive-control '<a command that MUST make the needle appear>'] [--no-lever] \
       [--shipped-from Dockerfile|Procfile] [--shipped-cmd '<deploy command>'] \
       [--env <KEY>] [--accept-divergence <flag>]
     ```
     `--licenses` is **required and has no default** — it is question 2, and nothing else in the toolchain expresses it. Verdicts: `OBSERVATION_EXPOSED` (the green counts) · `OBSERVATION_UNEXPOSED.P2` (waiting-only; honest, non-blocking) · `OBSERVATION_UNEXPOSED_BLOCKING.P1` (the run does not count toward what it was cited for) · `OBSERVATION_NOT_GREEN.P1` (the observation did not hold — that is the real finding, route it to §1) · `OBSERVATION_UNMEASURED.P2`.
   - **The three bounds — they are what keep this from being tyrannical:**
     - **Some subjects have no lever.** A guard reconciling inbound mail cannot make mail arrive. Declare `--no-lever`; it does not excuse the run, it routes straight to question 2. *Two static passes in a row prove only that neither number moved* — the guard's per-subject ledger reports `SPECK_OBSERVATION_STATIC=true` when it sees exactly that.
     - **Exposure is bought, not free.** Buy it where the green authorises something that cannot be walked back, not everywhere. `--accept-divergence <flag>` is that dial, and it is **counted in the record**, so a purchase decision is auditable rather than invisible.
     - **A disclosed gap beats a fabricated proof.** If no shipped-invocation source exists, the tool says `SHIPPED_SOURCE=none` and names `--shipped-cmd` as the repair. Leave that sentence in the report.

4. **Document the Hardening**:
   - Create a dated hardening report using the template:
     `specs/projects/<PROJECT_ID>/project-harden-report-<YYYYMMDD>.md`
   - Fill in all sections (Defect, Root Cause, Guardrails, Readiness Re-assessment).

5. **Re-Stamp & Re-Assess State**:
   - If the bug affected an already-validated story/epic, update its `validation-report.md` with the new re-assessed readiness state.
   - Run `.speck/scripts/stamp-truth.sh` against the report and the updated validation reports.
   - Trigger `/project-state` to regenerate and update active status.

---
