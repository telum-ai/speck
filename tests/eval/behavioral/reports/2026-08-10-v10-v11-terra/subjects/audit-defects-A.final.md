S008 audit is BLOCKED; validation must not proceed.

I wrote the stamped canonical report: [audit-report.md](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/audit-defects-A/specs/projects/001-pulseboard/epics/E002-reminders/stories/S008-send-service/audit-report.md).

Evidence found:

- P0: callback input can inject SQL (`x' OR '1'='1` rewrites the query).
- P1: unconfirmed actions send; failed sends consume retry credit; cache crosses workspace boundaries; product copy falsely promises fully automatic sending.
- P2: no S008 tests/acceptance scenarios; required project proof artifacts are missing, so graph, liveness, and banned-language gates cannot run.

`py_compile` passed, but direct behavioral probes reproduced all four service failures. No implementation was changed and no commit was made.