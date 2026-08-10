# INVALID — do not use for a branch decision

This first tournament run completed 24 valid subject processes, but its comparison is not internally valid.

The post-run structural audit found four decisive defects:

1. Subject workspaces were nested below the live Speck repository and inherited its `package.json` with `type: module`. That contaminated the UI module behavior and drove the only non-tied hidden-score pair.
2. The judge scrubber left condition versions and version fields in saved prompts, while artifact presentation order followed condition order rather than A/B label order. The judge was not actually blind.
3. The harness and scorer were untracked when subjects ran, so the claimed pre-run freeze was not Git-verifiable. Two legitimate scorer corrections also overwrote results without preserving a score-delta ledger.
4. Removing the contaminated UI case reduced the deterministic comparison to eleven ties.

The logged efficiency data and subject artifacts remain useful diagnostic evidence, but the aggregate result is invalid. The corrected harness freezes itself in Git, runs workspaces outside the repository tree, fails on ancestor package metadata, uses same-path UI probes, asserts complete judge scrubbing, presents A then B, reports cached and uncached tokens, and mutation-tests every scorer family.

Independent audit attempts with Opus 5 and Gemini 3.1 Pro were blocked by exhausted premium usage. A fresh Grok 4.5 High context completed the structural audit; this is decorrelated from the GPT-5.6 harness author but shares the model family used for artifact judging.

