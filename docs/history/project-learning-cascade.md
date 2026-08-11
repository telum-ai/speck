# Historical project-learning cascade

Speck originally shipped a populated `.speck/patterns/learned/` library and described this promotion path:

1. A story records a concrete learning.
2. An epic retrospective confirms recurrence across stories.
3. A project retrospective confirms recurrence across epics.
4. A generalized, evidence-backed pattern is proposed for broader use.

The promotion idea remains useful, but the storage ownership was wrong. Vanilla Speck cannot honestly ship “project-learned” files, and wholesale framework sync must not overwrite a project's own memory.

Current boundary:

- Project-local learnings stay with the project and may create `.speck/patterns/learned/` when needed.
- Speck upgrades preserve that project-owned directory.
- Generalized methodology findings for Speck itself live in `docs/methodology/patterns/`.
- Nothing in `.speck/patterns/learned/` is seeded by vanilla Speck.
