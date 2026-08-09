# speck-catch-up / profile-refresh

## Phase 8 — Finalize

1. Remove project from `.speck/.migration-needs-catchup` (delete file if empty).
2. Run `/project-readme`.
3. Re-run `/recheck`.
4. Update project-state: "Catch-up complete. Resume normal workflow."

## Phase PROFILE (v7.7+, idempotent)

If missing: append `## PROFILE surfaces` to project.md, `PROFILE Gate Criteria` to evidence-contract.md (from templates, marked `[FROM PROFILE CATCH-UP]`). Log decision. Run `regenerate-project-readme.sh`, `validate-readme.sh`, `profile-drift-check.sh`. Skip steps where section exists.
