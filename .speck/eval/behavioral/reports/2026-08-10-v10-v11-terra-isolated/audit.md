# Structural audit

Auditor: fresh Cursor Grok 4.5 High context, separate from the GPT-5.6 harness author. Opus 5 and Gemini 3.1 Pro audit attempts were blocked by exhausted premium usage. Grok also supplied the blinded artifact judge, so the structural audit is fresh-context and cross-family from the author, but not model-family-independent from the judge.

## Verdict

The corrected run is not decision-grade for a v11 quality win, quality parity proof, or “much better” product claim. Its isolation, Git freeze, judge blinding, arithmetic, valid-run evidence, and anti-300% conclusion survived. The primary hidden-score mean is contaminated by one invalid UI oracle.

## P0 — UI oracle assumed an unrequired representation

The task required behavior from `initialState`, `toggleSelection`, and `approveSelected`; it did not require an `{items, selectedIds}` state object. The frozen probe called `s0.items.every(...)`.

- v10 returned an array. The probe threw before evaluating behavior and recorded all six behavior checks as failed, producing 25/100.
- v11 returned `{items, selectedIds}` and produced 100/100.
- A shape-agnostic replay showed that v10 passed the six originally intended checks.
- v10 preserved an already-confirmed unselected item during a later approval. V11 reset every unselected item to `pending`. The blinded judge identified this and preferred v10 83 to 72.

The 75-point UI swing was the only large v11 hidden-score win and drove the reported +2.5 mean. That primary pair is invalid.

## Sensitivity

| Treatment | Hidden mean change, v11−v10 | Approximate 95% CI | Interpretation |
|---|---:|---|---|
| Frozen report | +2.5 | −8.8 to +17.9 | Invalid due UI oracle |
| Drop UI pair | −4.1 | −10.5 to +0.9 | Inconclusive, v10-leaning |
| Fair-score both UI outputs 100 | −3.8 | −10.0 to +1.3 | Inconclusive, v10-leaning |
| V10 100; v11 87.5 for status clobber | −4.8 | −10.8 to +0.4 | Inconclusive, v10-leaning |

The reported required-corrections advantage is also contaminated. Excluding the UI shape failures changes v10→v11 from 13→9 to 7→9.

## Evidence that survived

- Workspaces were outside the repository tree with no ancestor `package.json`.
- Harness commit `c23561e` and content fingerprint `245a7850…` match the frozen files.
- Judge prompts were A-then-B with zero forbidden version/revision hits.
- All 24 subject runs were valid and every event/patch hash verified.
- False greens were 0/0; audit was 100/100; backend implementation was 100/100.
- The blinded judge favored v10 by 4.7 points overall.
- Total input fell 41.8%, uncached input 33.6%, and observed wall time 22.5% in v11 in this model cell.
- Nothing supports a 4x or colloquial “300%” quality claim.

## Remaining limits

Twelve pairs, one model/effort cell, toy fixtures, ceiling-heavy endpoints, and keyword-oriented document checks are suitable for regression hunting, not a universal quality proof. Subject agents also necessarily saw their methodology version even though the external judge did not.

