# epic-validate / composition

## 8. Cross-epic + composition

- Test seams to dependent epics (data/auth/navigation).
- JTBD walkthrough section in report: core job, entry point, journey steps, composition assessment, cross-epic integration.
- JTBD `BLOCKED`/`PARTIAL` → epic fails regardless of story greens.

## 11. Legacy rollup checks

Epic vision vs `epic.md`; architecture vs `epic-tech-spec.md`; story completion from `epic-breakdown.md`; aggregate tests; Cursor rules compliance across stories; performance/security/docs.

Parallel subagents when host supports; else sequential.

## NEVER / ALWAYS

- NEVER claim epic UX-RC from story greens alone (composition fallacy)
- NEVER defer browser cold-start LARP for UI epics
- NEVER discharge PRM from JTBD sample alone (long tail must exist)
- NEVER hand-wave phantom/dead seams
- NEVER substitute PASS/FAIL for readiness state
- ALWAYS run `/audit --epic` first
- ALWAYS apply MIN(story, MATRIX_GRAIN_CAP, GRAPH_CAP)
- ALWAYS SHA-stamp report
