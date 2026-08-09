# story-validate — procedure

Prereq: `spec.md`, `plan.md`, `tasks.md`, `audit-report.md` (from `/audit`).
Output: `[STORY_DIR]/validation-report.md` (template: `.speck/templates/story/validation-report-template.md`).
Verdict: readiness state — never PASS/FAIL.

## 0. Template

Read `.speck/templates/story/validation-report-template.md` before writing.
Frontmatter: `readiness_state_claimed`, `readiness_state_verified`, `build_sha`, `build_artifact`, `audit_report`, `larp_evidence`, `clean_build`.

## 1. Readiness states

| State | Meaning |
|-------|---------|
| `NO-SHIP` | Blockers remain |
| `IMPL-GREEN` | Tests/lint/types pass |
| `INTEGRATION-GREEN` | Real round-trip per evidence-contract §7 service; live schema when DB-backed |
| `UX-RC` | Primary UI flows pass in target runtime + LARP evidence |
| `API-RC` | Backend operational walkthrough + contract/schema gates (no rendered surface) |
| `COMMERCIAL-RC` | Billing/entitlements/legal (paid products) |
| `SHIP-RC` | All gates pass against launch build |
| `SHIP` | Post-deploy proof complete |

Claim highest state evidence supports; caller may pass `--claim <state>`.

## 2. Pre-validate gates (STOP on fail)

1. **`/audit` → `audit-report.md`** in story dir. Missing → STOP: run `/audit` first. Any P0 → STOP.
2. **`evidence-contract.md`** at project root. Missing → STOP: run `/project-evidence-contract`.
3. **Archetype** — read `.speck/project.json` → `project_archetype`, `play_level`.
   - `infra_service` / `backend_api` / backend-only story → skip LARP + Premise-Challenge.
   - UI-facing (`consumer_product`, `b2b_saas`, `internal_tool` with UI):
     - `/larp` → `larp-recordings/<sha>-<persona>-findings.md`. Missing → STOP.
     - High-impact surfaces (onboarding, empty, paywall, error, celebration) → `/speck-premise-challenge` documented. Missing/failed → cap at `IMPL-GREEN`/`INTEGRATION-GREEN`.
4. **Claimed state** declared (default: highest supported).

## 3. Four axes (non-collapsible)

| Axis | Owner at story validate |
|------|-------------------------|
| CORRECT | Tests, mutation, traceability, audit input |
| ON-CONTRACT | evidence-contract gates at claimed + lower states |
| FELT-GOOD | AI naive-hostile LARP for consumer UX-RC+ (`felt_axis: ai-verified`) |
| TASTE | Connoisseur-hostile pass (`/speck-larp` Job C) for consumer UX-RC+ |

LARP split: **DOES-IT-WORK** (functional walkthrough) + **IS-IT-GOOD** (FELT + TASTE).
Optional stronger signals: `larp-recordings/<sha>-felt-attestation.md`, `larp-recordings/<sha>-human-attestation.md` — never required for SHIP-RC.

## 4. Locate story

Walk up to `spec.md` → `STORY_DIR`. Missing `spec.md`/`plan.md`/`tasks.md` → ERROR: run specify/plan/tasks first.
Record `git rev-parse HEAD` → `build_sha`.

## 5. Validation algorithm

1. Read `audit-report.md` — P0 blocks claimed state.
2. Read `evidence-contract.md` gate criteria for claimed state + all lower states; mark ✅/⚠️/❌ per criterion with evidence paths.
3. **Device-walk tier**: criteria marked `device-walk`/`always-manual` → ⚠️ Manual or ❌ Ungrounded unless `larp-recordings/<sha>-human-attestation.md` exists. Missing attestation → cap at `UX-RC`; refuse `SHIP-RC+`.
4. **Keystone deps**: founder secrets in evidence-contract/spec. Missing active keystone → require explicit `skip-with-reason` in test/CI log. Silent skip → fail. Logged skip → ⚠️ `Skipped (Awaiting Keystone)`, cap at `UX-RC`.
5. **Deferrals** — populate `## What this validation did NOT verify / Deferrals`; blank/boilerplate → fail validation.
   - Every row: `Cap Status` = `evidence-pending` | `implementation-pending`.
   - `implementation-pending` → cap `NO-SHIP`.
   - `autonomous-not-done` on browser cold-start LARP → forbidden (UI archetypes).
   - Other `autonomous-not-done` → cap `IMPL-GREEN`/`INTEGRATION-GREEN`.
   - INTEGRATION-GREEN cap via named infra blocker → logged reproduced LARP failure required (P3).
6. **INTEGRATION-GREEN** (when §7 services or DB-backed):
   - One real round-trip per §7 service (not mock-only); capture logs/traces.
   - DB-backed + reachable `DATABASE_URL`: `validate-schema-drift.sh --live --strict --target "$DATABASE_URL"` + real write path.
   - No `DATABASE_URL` → do NOT ✅ schema row; record ⚠️ deferral `evidence-pending`.
   - No §7 services and not DB-backed → auto-pass INTEGRATION-GREEN.
7. **Clean-build** (UX-RC+): frontmatter `clean_build: yes` required; else cap at `INTEGRATION-GREEN`.
8. **FELT-GOOD**: consumer archetype at UX-RC+ → naive-hostile LARP (`larp-recordings/<sha>-naive-hostile-findings.md`). Not run → `felt_axis: uncovered`, cap below UX-RC, run pass. Confusion/disorientation/revulsion → block + lower state.
9. **TASTE**: consumer UX-RC+ → connoisseur pass or `validate-taste-axis.sh` green.
10. Lower `readiness_state_verified` to highest state where all gates pass.
11. Banned-phrase self-check on report language.
12. SHA-stamp report.

## 6. Spec coverage + promise discharge

- RTM: every FR-XXX → verification method; untested → flag.
- Epic `traceability-matrix.md`: confirm assigned `PRM-NNN` rows discharged with evidence in this validation; cite in `## Spec Coverage`.
- Set each discharged row `Grain (proven-at)` to evidence grain — NOT headline verified state. Unit test = `impl-green`; live DB = `integration-green`; build-LARP = `ux-rc+`.

## 7. Execution checks

| Check | Action |
|-------|--------|
| Tasks | Parse `tasks.md` checkboxes; incomplete → WARN (override `--allow-incomplete`) |
| Tests | Run suite from `plan.md`; failures → HALT unless `--force` |
| Mutation | One row per guard cited in Evidence column — run `mutate-guard.sh`; transcribe `SPECK_MUTATION_*`; never hand-type verdict |
| Quickstart | Execute `quickstart.md` scenarios if present |
| Perf | Only if targets in spec |
| Constitution | Re-check plan.md gates vs code |
| Cursor rules | Scan `.cursor/rules/` for applicable rules on changed files |
| Lint/types | Run from repo root per plan.md stack |

Mutation rules: throwaway worktree; pattern must match once; guard must call shipped code; `GUARD_MUTATION_GREEN.P2` = honest scope; never tune until red; `GUARD_UNMUTATED.P2` does not discharge AC.

Receipt verify after report:
```bash
.speck/scripts/validation/mutate-guard.sh --verify-receipt [STORY_DIR]/validation-report.md
```
`RECEIPT_MISMATCH.P1` blocks. `RECEIPT_VERIFIED` = citation real at SHA — not proof mutation ran.

## 8. Visual / UX (UI stories)

SKIP when `visual_testing.platform` is `api` or `cli`.

Load recipe from `project.md` `_active_recipe:` → `.speck/recipes/[recipe]/recipe.yaml` → `visual_testing:` section.
Platform procedure: `.cursor/skills/visual-testing/references/<host>.md` (e.g. `web.md`, `mobile-flutter.md`) — NOT legacy `visual-testing-web` paths.
Also load: `design-system.md`, `ux-strategy.md`, `ui-spec.md`, epic `wireframes.md` if present.

Scope: 1–3 most impacted screens from diff + ui-spec; default + loading + empty + error + one interaction state.
Execute per recipe `agent_commands`; use breakpoints/devices from recipe.
Multimodal agents: `Read` on `larp-recordings/*.png` — judge from rendered pixels, not code alone.

Gates in report:
- Design token compliance (grep hardcoded hex/px)
- Voice/tone vs ux-strategy
- ui-spec Testing Checklist
- Aesthetic Quality + First-Time Comprehension rubrics
- `NEEDS_WORK`/`UGLY` → cap at `IMPL-GREEN`

## 9. User reachability (any UI)

| Check | FAIL if |
|-------|---------|
| Discoverability | No nav path from entry |
| Auth | Dev headers, hardcoded tokens |
| Scaffolding | UUID fields, debug panels in UI |
| End-to-end | Workflow needs dev knowledge |
| Feedback | Silent failures, missing states |

`UNREACHABLE` → validation fails. `PARTIAL` → conditional.

## 10. Code audit (manual, required)

Change surface: `git diff --name-only`, entrypoints, 1–3 call-site traces.
Checklist: correctness/edge cases, maintainability, security/privacy, performance, operability, frontend a11y, test quality.
High-severity (security, data loss, broken authz, missing critical tests) → fail even if tests green.

## 11. Post-write validators

```bash
bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict validation-report.md
bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict validation-report.md
```

SHIP-RC/SHIP+:
```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
bash .speck/scripts/profile-drift-check.sh
```
`PROFILE_DRIFT.P1` blocks SHIP-RC+.

UI touching PROFILE surfaces (landing, marketing, package.json): `regenerate-project-readme.sh --check` before UX-RC+.
Trigger `/project-state` regeneration.
Green → prompt project truth updates (`project.md`, `PRD.md`, `architecture.md`, etc.) unless `--skip-truth-update`.
Bypass/skipped gate → run `/speck-feedback`.

## 12. Parallelization

Independent checks (FR traceability, tests, perf, constitution, rules, lint, security, docs) may run in parallel via subagents when host supports; synthesize into one report. Cursor/Codex: sequential in main context.

## 13. Flags

`--allow-incomplete`, `--force`, `--skip-perf`, `--skip-quickstart`, `--skip-truth-update`, `--claim <state>`.

## NEVER / ALWAYS

- NEVER skip test execution on failure (unless `--force`)
- NEVER verify requirement without evidence
- NEVER claim UX-RC+ from code reading alone
- NEVER defer browser cold-start LARP for UI archetypes
- NEVER mark device-walk ✅ without human attestation
- NEVER hand-type mutation verdicts
- NEVER substitute PASS/FAIL for readiness state
- ALWAYS run `/audit` before validate
- ALWAYS populate deferrals with Cap Status
- ALWAYS grade PRM discharge grain honestly
- ALWAYS SHA-stamp report
