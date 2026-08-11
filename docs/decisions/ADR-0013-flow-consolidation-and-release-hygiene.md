# ADR-0013: Flow consolidation and release hygiene

- **Date**: 2026-08-11
- **Status**: accepted
- **Class**: always-on-contract + JIT + delete
- **Amends**: ADR-0005, ADR-0007, ADR-0009, ADR-0012

## Context

Conditional canonical steps could disappear without an analysis finding. Audit, LARP, visual testing, and validation overlapped in wording and order. Migration repair had three one-version skill entries, audit split one mandatory procedure across five files, and generated evaluation transcripts dominated the release diff.

## Decision

1. Analysis uses one compact common core plus per-reviewer lenses and a late report contract. Every reached conditional project, epic, or story slot is recorded as `included`, evidence-backed `not-applicable`, or `missing`; missing or unreviewed slots block downstream work.
2. PROVE has one role sequence: audit attacks implementation, UI LARP exercises the real job, visual testing supplies host evidence inside LARP, and validation adjudicates evidence and declares readiness.
3. `speck-audit` keeps its common adversarial procedure inline and loads one UI reference only for UI-bearing work.
4. `speck-migrate` owns explicit upgrades and scaffold, proof, and graph repair through one selected-stage load contract. The older skill directories are retired.
5. Premise challenge applies to any high-impact commitment at the decision boundary. Project learning stays local until recurrence justifies promotion; methodology defects route to `speck-feedback`.
6. Skill frontmatter drops unused `paths:` metadata. Generated tournament and routing reports are ignored local evidence; the release retains harnesses, negative controls, and concise decision summaries.

## Enforcement

Analysis validation has positive and negative Flow Fit controls. Recipe validation requires a recognized visual/nonvisual host for every recipe and mutation-tests missing and unknown hosts. Routing and semantic-conservation baselines pin the PROVE order, unified migration, alias absence, learning boundary, and new executable carriers.

## Consequences

The agent sees less fragmented procedure, conditional steps can no longer vanish silently, every PROVE tool has one job, migration has one discoverable entrance, and reproducible code replaces megabytes of checked-in run output.
