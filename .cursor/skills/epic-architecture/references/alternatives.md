# epic-architecture / alternatives

Use this node only before locking a non-trivial architecture choice.

1. State the decision, the promises it serves, and the constraints that make it necessary.
2. Compare at least three viable alternatives. Include the smallest/no-new-component option when viable.
3. Evaluate each alternative on contract fidelity, seam and failure behavior, operability, reversibility, and how it can be proved.
4. Use just-in-time research for unstable external facts; cite the sources that actually changed the choice.
5. Choose one alternative and record why it wins, what was rejected, and which assumptions would reopen the decision.
6. Check alignment with project architecture, constitution, security boundaries, and integration contracts.
7. Put the lock in `epic-architecture.md` and append the decision log entry.

Keep story-local implementation choices open. Resume at the first incomplete applicable slot in the canonical Epic flow in root `AGENTS.md`.
