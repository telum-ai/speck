# story-tasks / spine

1. Use the receipted task template bytes already loaded with this spine; preserve its fields, task ids, `[P]` markers, context cards, mapping table, and checklist. Set `analysis_required: false` for Sprint and `true` for Build/Platform. Do not reload a contract file directly.
2. Locate `STORY_DIR` by walking up to `spec.md`. STOP if `plan.md` is missing. Read `spec.md` and `plan.md` fully.
3. Extract every FR, acceptance scenario, edge case, NFR, security/privacy rule, architecture decision, file path, pattern, constitution gate, and research result.
4. Read when present: `data-model.md`, `contracts/`, `quickstart.md`, `codebase-scan-*.md`, epic `epic-breakdown.md`, project/epic constitution.
5. Reconcile story `depends_on`/`blocks` with epic breakdown. Keep dependency metadata in `spec.md`; `tasks.md` frontmatter carries only `status`, Speck/artifact identity, and the play-level analysis marker.
6. Generate immediately executable tasks with owned file paths, test command, acceptance predicate, input context, dependencies, and parallel safety. Research cannot be deferred into implementation tasks.
7. Order phases: setup → failing tests/probes → core → integration/failure paths → polish/docs → full verification. Mark `[P]` only for tasks with no shared files, schema head, or mutable runtime.
8. Build FR→task mapping. Every requirement maps to at least one task; every task maps back to a requirement, gate, or explicit enabling need.
9. Cross-check spec↔plan↔tasks: coverage, plan/constitution alignment, dependency order, failure symmetry, and no orphan work. Resolve conflicts or leave a named CRITICAL; do not call the checklist ready with one open.
10. After the final `tasks.md` mutation, run the validator as its own command event. Do not chain, pipe, wrap, or append another command; the recorded event exit must be the validator exit:
   ```bash
   bash .speck/scripts/validation/validators/validate-story-tasks.sh "$STORY_DIR/tasks.md"
   ```
11. Resume the canonical flow at `/analyze --level story`; Sprint skips there, while Build and Platform require decorrelated story analysis before implementation.
