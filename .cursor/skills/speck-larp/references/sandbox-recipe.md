# speck-larp / sandbox-recipe

- Built artifact exists (per evidence-contract — NOT dev server)
- **Clean Build for UX-RC+:** Build cache cleared (e.g. `rm -rf .next` / `trash .next` or build tool cache equivalents) and a fresh compilation run of the production built artifact.
- **REQUIRED and non-deferrable:** For all UI-facing stories/epics, the browser cold-start LARP is **REQUIRED and non-deferrable**. You may NOT defer the LARP or use `autonomous-not-done` to bypass it. A cap at `INTEGRATION-GREEN` for a "named infrastructure blocker" is valid ONLY with a **logged, reproduced failure of the actual LARP recipe** (the attempted run + the specific error captured) — never an assertion, memory, or a prior epic's precedent (P3, #76.1). First try the Sandbox-Friendly setup recipe below. Otherwise report a hard blocker (`NO-SHIP`).

If launch-build doesn't exist: STOP and report. Tell user "LARP requires the target build. Run [build command] first."

### UI LARP Setup Recipe (Sandbox-Friendly)

To execute browser LARPs successfully in sandboxed or restricted environments without real production databases/credentials:
1. **Throwaway/Local DB**: Seed a local/SQLite or Docker-based database with minimal test fixtures.
2. **Loopback/Review-Session Backdoor**: Implement a secure backdoor route or environment flag (e.g. `VITE_DEV_HTTP=true` or `process.env.PLAYWRIGHT_TEST=true`) that bypasses external OAuth/Clerk redirects and logs in a test user.
3. **localStorage Token Re-injection**: Pre-populate `localStorage` or cookies with mock JWTs or session tokens before navigating, to simulate an authenticated state.
4. **Loopback/Mock Server**: Run a lightweight local mock server (e.g., MSW or wiremock) to intercept and mock third-party API calls (e.g., Stripe, Resend) during the browser run.

## Execution Steps

### 1. Locate project, persona, and tooling

Find `specs/projects/<PROJECT_ID>/`.

Read inputs:
- `personas/<persona-id>.md` — LARP script
- `evidence-contract.md` — valid proof sources
- `product-contract.md` — magic moments + banned language
- `.speck/recipes/<active>/recipe.yaml` → `visual_testing:` section

If persona-id not specified, ask user which persona or run all per evidence-contract requirements.

### 2. Verify the target build exists

Map the evidence-contract's valid proof source to a concrete artifact:
