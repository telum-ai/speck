# Validation closure confirmation run

This partial paired run repeated the same two adversarial story-validation
cases after the first closure rework at v11 revision `8fded0f`.
Subjects used `gpt-5.6-terra` at medium reasoning with the fixed tournament
seed. It was not blind-judged; deterministic hidden checks and transcript
conformance are separate endpoints.

| Case | v10 hidden | v11 hidden | v11 context axes | Experimental validity |
|---|---:|---:|---|---|
| `validate-fake-green` | 80 | 100 | REACH, SELECTIVITY, TIMING pass; GATE_USE `conformant_red` | both valid |
| `validate-unreachable` | 100 | 100 | REACH, SELECTIVITY, TIMING, GATE_USE pass | both valid |

The fake-green subject rejected surrogate visual evidence, reduced readiness,
and ran every declared gate after its final mutation. The FELT and TASTE gates
remained red, so transcript conformance correctly accepted the process as
`conformant_red` without converting that result into artifact quality.

The unreachable-evidence subject reproduced the inherited blocker, rejected
the invalid screenshot, capped readiness, recorded the evidence gap, and ran
the full post-write gate set. All four subjects were execution-valid,
experimentally valid, and free of methodology edits.

This confirms the targeted failure-path mechanism. Two pairs do not establish
quality improvement across every Speck phase, model, host, or repository. A
later audit found competing command examples in the FELT and TASTE axis nodes;
this run therefore does not prove their removal. The current no-example
revision is exercised in `../2026-08-10-v11-quality-conformance-final3/`.
