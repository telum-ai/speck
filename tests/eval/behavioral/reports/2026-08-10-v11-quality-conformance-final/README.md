# Validation closure falsification run

This partial paired run tested the two adversarial story-validation cases after
receipt enforcement landed at v11 revision `8607aa4`. Subjects used
`gpt-5.6-terra` at medium reasoning with the fixed tournament seed. It was not
blind-judged and is retained because it falsified the first closure design.

| Case | v10 hidden | v11 hidden | v11 context axes | Experimental validity |
|---|---:|---:|---|---|
| `validate-fake-green` | 80 | 80 | REACH, SELECTIVITY, TIMING pass; GATE_USE fail | both valid |
| `validate-unreachable` | 100 | 80 | REACH, SELECTIVITY, TIMING pass; GATE_USE fail | v11 valid; v10 invalid due to a methodology edit |

The v11 agents loaded the selected context before mutation and avoided
forbidden branch context. Both then copied the post-write reference's partial
gate pattern instead of executing every receipt-declared gate. They also missed
one case-specific evidence disposition each. The result rejected the first
design: exact receipts alone were insufficient while the prose still contained
a competing command example.

The first follow-up removed the post-write command examples, made receipt arrays
the declared gate argv interface, and defined honest red closure. A later audit
found that two axis nodes still carried competing examples; the fully corrected
current revision is exercised in
`../2026-08-10-v11-quality-conformance-final3/`.
