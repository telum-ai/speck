# epic-analyze — spine

Always on this skill's critical path.

## Role separation (P4)

1. Lens reviewer did **not** author the corpus (subagent / other session / other model).
2. Lenses do not share findings until verification.
3. Verifier ≠ lens that raised finding; verifier ≠ corpus author.
4. Every Lens Roster row: `Reviewer` + honest `Authored any corpus artifact?`.
5. Solo agent only if Reviewer discloses it — do not claim stronger decorrelation.

## Severity (by rule)

CRITICAL by construction:
- cross-artifact `contradictory` (two artifacts cannot both be satisfied)
- unaddressed MM-N or JOB-N in coverage matrix
- gate precondition contradicts evidence contract

Else: HIGH | MEDIUM | LOW by judgment.
Only CRITICAL + Status `open` blocks.
Vocab: Severity `CRITICAL|HIGH|MEDIUM|LOW` · Verdict `confirmed|refuted` · Status `open|resolved|waived DEC-####`.
Waiver → real `/speck-decision-log` entry.

## Corpus load

Load epic corpus + project `PRD.md`, `architecture.md`, `context.md`, `product-contract.md`, constitutions if present.
Record `git rev-parse HEAD` → `analyzed_sha`.

## NEVER / ALWAYS

- NEVER judge severity where mapping assigns CRITICAL
- NEVER self-verify a finding
- NEVER delete `refuted` rows
- NEVER hand-grep MM/JOB instead of the graph
- NEVER write CLEAN with uncovered MM/JOB
- NEVER claim decorrelation Reviewer column contradicts
- ALWAYS write frontmatter + full `analyzed_sha`
- ALWAYS commit report after corpus; re-run after corpus edits
