# Current-revision validation confirmation

This partial paired run exercised the two adversarial story-validation cases
against v11 revision `09fd353`, which includes receipt-only gate argv,
truth-stamp ordering enforcement, honest-red closure, and invalid-pair
exclusion. Subjects used `gpt-5.6-terra` at medium reasoning with the fixed
tournament seed. It was not blind-judged.

| Case | v10 hidden | v11 hidden | v11 context axes | Experimental validity |
|---|---:|---:|---|---|
| `validate-fake-green` | 80 | 100 | REACH, SELECTIVITY, TIMING, GATE_USE pass | both valid |
| `validate-unreachable` | 85 | 100 | REACH, SELECTIVITY, TIMING pass; GATE_USE `conformant_red` | both valid |

Both v11 subjects loaded exactly the selected context before mutation, avoided
forbidden branches, truth-stamped before every non-stamp gate, and executed the
complete receipt-declared closure set. The unreachable-evidence gates remained
partly red, so conformance stayed separate from artifact quality.

The first score pass reported v11 as 80 and 75. Inspection found two evaluator
false negatives: an explicitly rejected inherited `Readiness: UX-RC` table row
was mistaken for the current verdict, and `evidence/review.png | MISSING` was
not recognized as a missing screenshot. Mutation tests now pin verified-state
precedence and missing image-path classification. The frozen artifacts and
transcripts were rescored without rerunning subjects; their final v11 scores
are 100 and 100.

This is direct evidence for the corrected validation failure path and its
methodology adherence. Two pairs do not establish universal quality gains.
