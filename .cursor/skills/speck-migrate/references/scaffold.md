# Migration-scaffold repair

Turn mechanically created compatibility scaffolds into honest current artifacts. Preserve all pre-migration files and block new feature work until the marker is cleared.

Optional `$ARGUMENTS`: `--phase=triage|contracts|decisions|epic-artifacts|honesty|state|plan|profile|refresh|finalize|all`. Default `all`; large projects begin with `triage` and commit phases separately.

## 0. Triage

Require `migration-report.md`, git history, `project.md`, and either `PRD.md` or `sprint-log.md`. Inventory truth artifacts, epics/stories, validation reports, screenshots, ship docs, scaffold banners, and replacement markers. Choose the honesty mode:

- 5a: story validation reports exist.
- 5b: only ship/release docs carry readiness claims.
- 5c: no historical readiness claim; record the no-op explicitly.

Write and stamp `migration-estimate.md` with the mode, artifact state, effort, and remediation preview. `--phase=triage` stops here.

## 1. Contracts

Fill `product-contract.md` from existing project, PRD, UX, domain, constitution, and pricing truth. Fill `evidence-contract.md` from the active recipe's merged evidence block and current project constraints. Use current project skills/templates, preserve unknowns as `[NEEDS USER REVIEW]`, remove scaffold banners only after real content replaces them, and stamp both artifacts.

For a missing PROFILE registry or gate criteria, run the same contracts phase with `--phase=profile`, then `project-profile`. For template drift, `--phase=refresh` appends required current sections without overwriting existing truth.

## 2. Decisions and epic artifacts

Reconstruct `project-decisions-log.md` from git with `Reconstructed: true`, source SHA/date, plausible alternatives, and locked status. Use `speck-decision-log` for each recovered decision.

For each UI epic missing experience truth, create a populated `experience-chain-historical.md` with the brownfield exemption. Create a full current experience chain only when journey and wireframes already exist. Note missing optional architecture; do not manufacture it.

## 3. Honesty pass

- Mode 5a: for each historical story PASS, require target-build runtime LARP, correct evidence platform, separate audit, reachability, and clean user-facing language. Missing runtime/platform/audit proof floors the effective result at `IMPL-GREEN` and adds `## Catch-Up Downgrade` with the reason.
- Mode 5b: map ship-doc claims to feature areas and floor them at `IMPL-GREEN` unless the document cites checked-in evidence satisfying the current evidence contract. Write `catch-up-honesty-pass.md`.
- Mode 5c: record that no historical claim required downgrade.

Do not silently lower a historical claim or invent a magic moment/differentiator. Keep the original claim visible and record the current effective state.

## 4. State and plan

Regenerate `project-state.md` from post-honesty truth. Write and stamp `project-catch-up-plan.md` with P0–P3 work, downgraded claims, pending reviews, replacement markers, LARP gaps, and deferred historical-to-current conversions. The plan exists even when empty.

## 5. Finalize

Run strict template/artifact validators, `project-profile`, and `speck-recheck`. Remove this project from `.speck/.migration-needs-catchup` only when no scaffold banner or unresolved replacement marker remains, contracts are truthful, honesty findings are represented in project state, and the catch-up plan exists. Delete the marker file only when every listed project is complete.
