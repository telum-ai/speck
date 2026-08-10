# Analyze spine

## Role separation (P4)

1. Lens reviewer did not author the corpus.
2. Lenses do not share findings before verification.
3. Verifier differs from the lens that raised the finding and from corpus authors.
4. Every Lens Roster row names the reviewer and honestly states whether they authored any corpus artifact.
5. A solo run discloses that limitation; never claim stronger decorrelation.

## Severity

CRITICAL by construction:

- two artifacts cannot both be satisfied
- an in-scope MM-N or JOB-N has no valid coverage row
- a gate precondition contradicts the evidence contract

Else use HIGH | MEDIUM | LOW by judgment. Only CRITICAL + `open` blocks.

Vocabulary: Severity `CRITICAL|HIGH|MEDIUM|LOW`; Verdict `confirmed|refuted`; Status `open|resolved|waived DEC-####`. A waiver requires a real `/speck-decision-log` entry.

## Invariants

- Never let the finding author self-verify.
- Never delete refuted rows.
- Never hand-grep MM/JOB instead of using the witness graph.
- Never write CLEAN with uncovered MM/JOB.
- Always record full `analyzed_sha` and commit the report after the corpus.
