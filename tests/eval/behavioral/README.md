# Speck v10-v11 behavioral tournament

This benchmark tests whether v11's subtraction and just-in-time architecture improves agent behavior, rather than merely shrinking the repository.

## Frozen comparison

| Condition | Revision | Version |
|---|---|---|
| v10 | `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` | 10.5.0 |
| v11 | `8ff081f1436024e5315fd68a3c2af505bd09ab83` | 11.0.0 |

The harness is added after the v11 revision and always exports methodology files from these commits. Subject workspaces do not contain the harness or hidden scorers. Before a run starts, the runner requires `README.md`, `cases.py`, `runner.py`, the transcript validator, and its context loader to be clean in Git; records their commit plus a content hash in the manifest; and snapshots the evaluator pair for the lifetime of the run.

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
- wall time and valid subject-execution rate.

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
python3 tests/eval/behavioral/runner.py self-test

# Pilot pairs; these results are resumed into the full run.
python3 tests/eval/behavioral/runner.py run \
  --cases implement-backend,validate-fake-green \
  --workers 2

# Complete remaining pairs without overwriting the pilot.
python3 tests/eval/behavioral/runner.py run --cases all --workers 2

# Re-test a committed candidate without changing the frozen defaults.
python3 tests/eval/behavioral/runner.py run \
  --run-id <new-run-id> \
  --v11-revision <candidate-commit> \
  --cases all --workers 2

# Discover the installed Cursor model slug first, then judge and report.
cursor-agent status --format json
cursor-agent --list-models
python3 tests/eval/behavioral/runner.py judge --model <different-family-model-slug>
python3 tests/eval/behavioral/runner.py report
```

Raw event streams and workspaces are ignored under `.runs/`. Checked-in evidence lives under `reports/<run-id>/`: result JSON, subject patches, final responses, blinded judge output, summary JSON, and report Markdown. Result JSON records event hashes, model/effort, token usage, wall time, completion signals, and artifact changes.

For revisions with executable JIT profiles, inspect methodology conformance
separately from output quality:

```bash
python3 .speck/scripts/validation/validators/validate-context-transcript.py \
  --transcript <subject.events.jsonl> \
  --profile story-validate-ui \
  --select claimed_state=ux-rc \
  --select visual_host=web \
  --root <subject-workspace> --json
```

The non-collapsible axes are REACH, SELECTIVITY, TIMING, and GATE_USE.
The exact loader argv, explicit zero exit, emitted context bodies, receipt
order, hashes, byte counts, gate lists, and gate policy are checked. Gate use is
a direct, single-command event, not a substring: the gate is the primary
command and owns the recorded tool exit. Selected states may require multiple
gates. A direct nonzero gate is preserved as `conformant_red`: the agent used
the method and the artifact remains red. Passing these axes proves context-path
conformance only; hidden scoring, blind judgment, audit, and LARP still own
semantic use and quality. Subject execution validity, artifact mutation, and
context conformance are reported separately. A red
conformance report is a methodology-adherence finding; it neither invalidates
the experiment nor changes the artifact-quality score.
The runner applies the declared profile automatically to the eight relevant
v11 cases using a repository-trusted validator and a contract snapshotted from
the pinned revision outside the subject workspace. It records the report
alongside each result; methodology-contaminated or otherwise invalid subjects
remain visible but cannot contribute a green conformance aggregate. Controlled
quality aggregates keep only pairs where both subjects are experimentally
valid; excluded pairs remain visible in the case table.

## Harness validity

`self-test` checks that the corpus has 12 unique five-item rubrics, deletion-mutation-tests all 12 scorer families to zero, behavior-mutation-tests the backend and UI scorers, isolates project artifacts from exported methodology fixtures, distinguishes project-owned feedback and learned output from methodology edits, excludes invalid pairs from quality aggregation, and recognizes canonical `lifecycle_state`, `Draft (Placeholder)`, bounded Gherkin/EARS acceptance scenarios, zero-open summaries, real-principal wording, verified-readiness precedence over quoted inherited claims, and missing image-path classifications. The UI behavior test executes the browser entry path against a fake DOM with five randomly named items in a hidden random target order. It walks select, deselect, maximum-cardinality approval, a fresh remount, partial approval, retained state, and final approval across every item while checking labels, status, ARIA, and control state at every transition. Instrumented call counters bind those runtime changes to `initialState`, `toggleSelection`, and `approveSelected`. It rejects unmounted, initially enabled, state-clobbering, always-disabled dummy, disconnected dual-path, counter-bumping facade, and capped-approval renderers. A conforming backend implementation must pass all behavior checks; an always-green mutant must score lower. Subject execution validity requires exit 0, a runtime `turn.completed` event, and at least one tool event. Whether an artifact changed and whether a v11 context contract passed are independent endpoints.

After the isolated run, audit found that the UI scorer assumed an unrequired `{items}` state shape and document scorers searched exported `tests/eval/fixtures` as if they were subject artifacts. The reusable harness now mutation-tests the UI state/status boundary and browser entry path, scopes project documents to `specs/**`, accepts canonical `lifecycle_state`, and seeds contamination plus real-project mutants. Frozen subjects were explicitly rescored without rerunning transcripts or the blind judge; the manifest and report record the exact committed evaluator revision and content hash used for each rescore.

The first run id, `2026-08-10-v10-v11-terra`, is retained as invalid evidence. Its audit found parent-repository ESM contamination, incomplete judge scrubbing/order blinding, and an unverifiable post-run scorer freeze. It must not be used for a branch decision. The corrected decision run uses the `-isolated` suffix.
