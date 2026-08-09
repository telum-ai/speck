# harden / behavior-rules

## Behavior Rules

- NEVER just patch the bug without documenting why the gates missed it.
- NEVER cite a guardrail as evidence without a mutation record produced by `mutate-guard.sh`.
- NEVER close a fire on an OBSERVATION without answering what its green licenses (step 3b). An observation that closes a fire, exits a shadow period, or re-stamps a readiness state licenses something irreversible: it needs `OBSERVATION_EXPOSED`, and `OBSERVATION_UNEXPOSED_BLOCKING.P1` means the run does not count toward that claim. An observation that licenses only *waiting* needs nothing — record `OBSERVATION_UNEXPOSED.P2` and move on.
- NEVER tune an observation until it is exposed, and never adjust a mutation until it reddens — both manufacture exactly the evidence the field exists to prevent. Record the honest verdict and write the scope down.
- NEVER close a harden without §2b answered — including the zero-red sentence.
- NEVER delete a pre-existing test to get green. Classify it; a `DEFECT-PINNING` test is its own finding.
- ALWAYS add a systemic guardrail (linter, regression test, or primitive check) to ensure it can never recur.
- ALWAYS re-assess the readiness state of the affected stories.
- BLOCK subsequent releases if the defect is a P0 blocker until the `/harden` flow report is stamped and green.
