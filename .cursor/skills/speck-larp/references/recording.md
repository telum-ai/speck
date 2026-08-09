# speck-larp / recording

## Prerequisites

- `personas/<persona-id>.md` exists (LARP script)
- `evidence-contract.md` exists (defines valid proof sources)
- Active recipe with `visual_testing:` config (defines tooling)
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

## Integration Points

- Reads: `personas/<persona-id>.md`, `evidence-contract.md`, `product-contract.md`, recipe.yaml, platform visual-testing skill
- Writes: `<dir>/larp-recordings/<sha>-<persona>-*` evidence files, findings note
- Invokes: `banned-language-lint.sh`, `stamp-truth.sh`
- Feeds into: `/story-validate`, `/epic-validate`, `/project-validate`, `/recheck`

## Cross-Host Portability & Compatibility

This process skill is fully supported across all primary AI runtimes (Claude, Cursor, Codex) with identical evidence requirements.

| Capability | Claude Code | Cursor | Codex |
|------------|-------------|--------|-------|
| **Execution** | Interactive skill command | Interactive skill command | Interactive skill command |
| **Tooling** | Native Browser MCP or Playwright | Playwright or manual capture | Playwright or manual capture |

### Fallbacks & Adaptations
- **Visual Testing / Browser MCP**: Spawning dynamic browser actions via Playwright/Browser MCP is highly streamlined in Claude/Cursor (using the browser tools or MCP integration). On Codex or other hosts, if automation tools are unavailable, execute the persona steps manually against the target build, take screenshots, save them to `<story-or-epic-dir>/larp-recordings/`, and write the findings note manually.
