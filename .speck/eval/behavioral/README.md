# Speck v10-v11 behavioral tournament

This benchmark tests whether v11's subtraction and just-in-time architecture improves agent behavior, rather than merely shrinking the repository.

## Frozen comparison

| Condition | Revision | Version |
|---|---|---|
| v10 | `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` | 10.5.0 |
| v11 | `8ff081f1436024e5315fd68a3c2af505bd09ab83` | 11.0.0 |

The harness is added after the v11 revision and always exports methodology files from these commits. Subject workspaces do not contain the harness or hidden scorers. Before a run starts, the runner requires `README.md`, `cases.py`, and `runner.py` to be clean in Git and records their commit plus a content hash in the manifest.

## Design

The corpus contains 12 paired tasks spanning project, epic, and story work; PROMISE, BUILD, and PROVE; documents, backend code, UI state, audit, and false-green validation traps. Every pair receives the same task prompt, seed product files, model, reasoning effort, sandbox, and time limit. Only the exported Speck revision differs.

Run order and A/B labels are deterministic but randomized from seed `127110`. Subjects are not told which label they occupy. Because the methodology contains its own version, subject blinding cannot be guaranteed. The external quality judge receives A then B in label order after version strings, version fields, revision hashes, and version stamps are scrubbed. Judge construction fails if any forbidden identity pattern survives, and a checked blinding manifest records prompt hashes and zero hits.

Subject workspaces live under the operating system temporary directory, outside the Speck repository tree. The runner fails if the workspace root inherits any ancestor `package.json`; this prevents the live Speck package type, Git state, or JavaScript module resolution from contaminating a subject. Product patches and raw event streams are copied back to the evidence directory.

The default subject cell is `gpt-5.6-terra` at medium effort through `codex exec --ignore-user-config --ephemeral`. It is a high-volume implementation/evaluation cell, not a claim about every host or model. The external judge runs through Cursor with a different model family.

## Predeclared endpoints

Primary endpoint: paired deterministic hidden-check quality, 0-100 per task.

Secondary endpoints:

- false-green count on adversarial audit/validation tasks;
- required corrections, defined as failed hidden checks;
- blinded judge quality, 0-100;
- total, cached, and uncached input tokens reported by the subject runtime;
- wall time and valid-run rate.

The summary also reports a predeclared composite of 70% deterministic score and 30% blinded-judge score. Axes remain visible; the composite cannot hide a false-green regression.

Interpretation thresholds fixed before subjects run:

- regression: v11 loses more than 5 mean hidden-score points or produces more false greens;
- behavioral parity: the paired hidden-score CI includes zero but its lower bound stays above -5, with no false-green increase;
- improvement: positive mean hidden score, no false-green increase, and the blinded judge does not contradict the direction;
- drastic improvement: at least +15 hidden-score points, at least 25% fewer input tokens, and no false-green increase;
- a literal 300% improvement would require a 4.0x composite quality ratio. The colloquial product judgment should instead use the visible quality, safety, and efficiency axes.

Twelve pairs can find regressions and estimate direction. They cannot prove universal superiority across all models, repositories, or long-running projects.

## Reproduction

```bash
python3 .speck/eval/behavioral/runner.py self-test

# Pilot pairs; these results are resumed into the full run.
python3 .speck/eval/behavioral/runner.py run \
  --cases implement-backend,validate-fake-green \
  --workers 2

# Complete remaining pairs without overwriting the pilot.
python3 .speck/eval/behavioral/runner.py run --cases all --workers 2

# Discover the installed Cursor model slug first, then judge and report.
cursor-agent status --format json
cursor-agent --list-models
python3 .speck/eval/behavioral/runner.py judge --model <different-family-model-slug>
python3 .speck/eval/behavioral/runner.py report
```

Raw event streams and workspaces are ignored under `.runs/`. Checked-in evidence lives under `reports/<run-id>/`: result JSON, subject patches, final responses, blinded judge output, summary JSON, and report Markdown. Result JSON records event hashes, model/effort, token usage, wall time, completion signals, and artifact changes.

## Harness validity

`self-test` checks that the corpus has 12 unique five-item rubrics, deletion-mutation-tests all 12 scorer families, and behavior-mutation-tests the backend scorer. A conforming backend implementation must score 8/8 behavior checks; an always-green mutant must score lower. Every case family must turn red when its artifact is deleted. Subject validity additionally requires exit 0, a runtime `turn.completed` event, at least one tool event, and a changed artifact.

After the isolated run, audit found that the frozen UI scorer assumed an unrequired `{items}` state shape. The reusable harness now mutation-tests a conforming array-state implementation and a status-clobbering mutant, accepts array or object state, and requires already-confirmed unselected items to remain confirmed. The completed isolated run is not silently rescored; its `decision.md` excludes/sensitivity-tests that invalid primary pair.

The first run id, `2026-08-10-v10-v11-terra`, is retained as invalid evidence. Its audit found parent-repository ESM contamination, incomplete judge scrubbing/order blinding, and an unverifiable post-run scorer freeze. It must not be used for a branch decision. The corrected decision run uses the `-isolated` suffix.
