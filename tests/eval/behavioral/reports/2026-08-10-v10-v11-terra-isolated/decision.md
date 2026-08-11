# Branch decision from the behavioral tournament

## Direct answer

No: this run does not show that v11 delivers “300%” on the subtraction/JIT brief. It shows a large and credible efficiency gain. It does not show a quality gain.

## What the evidence supports

- Total input tokens: **−41.8%**.
- Uncached input tokens: **−33.6%**.
- Observed wall time: **−22.5%**.
- False greens: **0 vs 0**.
- Audit defect detection: **100 vs 100**.
- Backend hidden behavior: **100 vs 100**.
- Blinded artifact quality: **v11 −4.7 points**.
- Hidden quality after invalidating the UI oracle: approximately **v11 −4.1 points**, with a wide interval crossing zero.

The strongest honest quality label is **inconclusive, v10-leaning**. The strongest efficiency label is **drastic context reduction in this GPT-5.6 Terra/medium cell**.

## Where v11 specifically lost this sample

- Epic breakdown mis-mapped PRM-002/PRM-004 traceability and scored 60 vs 90; the judge scored it 42 vs 85.
- Story specification was thinner and scored 55 vs 65; the judge scored it 73 vs 82.
- Evidence contract omitted or weakened promise coverage and scored 65 vs 80; the judge scored it 72 vs 88.
- The v11 UI artifact reset previously confirmed unselected items to pending. The frozen hidden scorer missed that defect, but the blinded judge caught it.

These are not proof that the methodology causes those misses. They are concrete regression candidates that block a quality-superiority claim and should drive the next rework pass.

## Release implication

V11 has demonstrated the subtraction half of the brief. It has not yet demonstrated “improve the methodology without reducing performance and accuracy.” Do not market or merge it as a proven behavioral upgrade on this evidence alone. The next decision-grade step is targeted rework of epic traceability, story-spec depth, and evidence-contract promise conservation, followed by a fresh frozen replication across at least one additional model cell.
