# v11 release decision

## Decision

Advance methodology revision `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea` as the v11 release candidate.

This is a decision to ship a substantially leaner, more observable methodology with strong evidence of correct just-in-time behavior. It is not a claim that one benchmark proved a universal quality increase, and it does not support describing v11 as 300% better.

## What the evidence supports

- All 24 subject runs were experimentally valid and changed their assigned artifacts.
- All 8 v11 runs with executable context profiles passed REACH, SELECTIVITY, TIMING, and GATE_USE.
- Mean input tokens fell 15.6%; mean uncached input tokens fell 31.7%; mean wall time fell 21.9%.
- The independent blinded judge preferred v11 by 9.8 points on average.
- Both versions produced zero false greens on the designated false-green cases.
- Real-project entry canaries preserved hard graph and migration precedence in Streb, Odd, and Speilet snapshots.

## What remains uncertain

- The predeclared deterministic endpoint moved 4.7 points against v11, with two losses: epic breakdown completeness and UI runtime integration.
- The predeclared 70/30 composite moved 0.4 points against v11; its confidence interval crosses zero.
- V11 required five hidden-check corrections versus one for v10.
- This is one 12-pair task set, one subject model/effort cell, and one external judge family.

The quality conclusion is therefore directional: v11 appears to improve judgment quality while making context use cheaper and more disciplined, but average outcome quality is not yet statistically established.

## Release posture

Merge is justified because the primary design claim for v11 is subtraction plus just-in-time loading without a demonstrated collapse in overall quality. The combined score remained near parity, the independent judge improved materially, context conformance was perfect in applicable runs, and the efficiency gain was large. The two concrete outcome misses are now visible rather than hidden by the evaluator.

Confidence should be raised after release with replication across a second model/host cell and a longitudinal trial in a real product repository. Those trials should retain the frozen transcript checks and add end-to-end runtime probes for implementation tasks.

## Evidence identity

- Subject methodology: `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea`
- Original run harness: `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea` / `51fb7e0110bd68b54a73435b55fb942afb5f812b1de73ec8e7fe6184fe00718b`
- Frozen-artifact rescore evaluator: `332e168f30ffac35aac22bf97264b3d2a485e034` / `63dc4bc3c14980e82757e81d23b950b212216ace476535d75e25b970bbc36385`
- Rescore evaluator audit: `cursor-grok-4.5-high` PASS; no reproducible P0/P1 false-green or evidence-integrity defect
- Blind judge: `cursor-grok-4.5-high`
- Aggregate report: `report.md`
