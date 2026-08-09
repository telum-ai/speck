# project-analyze — spine

## Role separation (P4)

1. Lens reviewer did **not** author the corpus.
2. Lenses do not share findings until verification.
3. Verifier ≠ lens; verifier ≠ corpus author.
4. Lens Roster: `Reviewer` + honest `Authored any corpus artifact?`.
5. Solo agent only if disclosed in Reviewer column.

## Severity (by rule)

CRITICAL by construction:
- cross-artifact `contradictory`
- unaddressed MM-N or JOB-N in coverage matrix
- gate precondition contradicts evidence contract

Else: HIGH | MEDIUM | LOW. Only CRITICAL + `open` blocks.
Vocab: `CRITICAL|HIGH|MEDIUM|LOW` · `confirmed|refuted` · `open|resolved|waived DEC-####`.
Waiver → `/speck-decision-log`.

## Corpus load

Load whichever exist: `project.md`, `PRD.md`, `epics.md`, `product-contract.md`, `context.md`, `architecture.md`, `evidence-contract.md`, `project-roadmap.md`, `project-landscape-overview.md`, `project-decisions-log.md`.
`git rev-parse HEAD` → `analyzed_sha`.

## NEVER / ALWAYS

- NEVER judge severity where mapping assigns CRITICAL
- NEVER self-verify; NEVER delete `refuted` rows
- NEVER hand-grep MM/JOB; NEVER CLEAN with uncovered MM/JOB
- NEVER claim decorrelation Reviewer contradicts
- ALWAYS frontmatter + full `analyzed_sha`; commit report after corpus
