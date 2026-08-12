# Invalid proof examples (JIT)

## 3. Invalid Proof Sources (anti-proof)

*What runtime evidence DOES NOT count for THIS product. Validation reports that rely on these MUST mark themselves as "surrogate proof" and cannot claim UX-RC or higher.*

### Platform: [e.g., iOS]
- ❌ Browser localhost — not the iOS runtime
- ❌ Expo Go — not the standalone build
- ❌ Safari — not native
- ❌ Dev client launcher screenshots
- ❌ Stale production bundle (>1 week old build)
- ❌ Static screenshots not captured from the target runtime
- ❌ Mock data screenshots when feature requires real data
- ❌ Pro-unlocked LARP for paid validation (must be real purchase flow)

### Platform: [e.g., Web]
- ❌ Dev server (`vite dev` / `next dev`) screenshots for SHIP-RC claims
- ❌ Storybook-only screenshots for full-flow validation
- ❌ Mocked auth screenshots for auth flow claims
- ❌ Localhost screenshots for production-like behavior validation

- ❌ **A client-bundle secret scan whose scope is static chunks only** (`.next/static/**`, `dist/assets/**`) cited as proof no secret reaches the browser. On App Router that omits prerendered HTML and the RSC flight payload — both browser-delivered — so a CLEAN result is silent about the paths a Server Component actually leaks through. Enumerate the surfaces (§2c) in the gate's Scope cell.
- ❌ **A single liveness self-test cited as proof a multi-surface leak gate covers all its surfaces.** One direction proves the machinery runs; it says nothing about the surfaces it did not plant a canary in. One observed-biting direction per enumerated surface, or the uncovered surfaces are undeclared residual.

### Platform: [e.g., CLI]
- ❌ `cargo run` output for shipping claims (must be release binary)
- ❌ Tests-pass-locally for cross-platform binary claims

### Universal Test Hygiene & Form-UX Anti-Proof (All Platforms)
- ❌ Tautological assertions: using empty/unconditional `expect(true).toBe(true)` checks to inflate passing test counts.
- ❌ Silent skips: collect-time skips (e.g. `describe.skipIf` evaluated before runtime setup) that hide unrun tests. Skips must be runtime skip-with-reason logs. **A skipped standing/guarded regression suite is not a gate** — verify guarded suites report as RUN (not skipped) in the target CI. A conditionally-skipped suite is worse than a failing one: invisibly green (#76.2).
- ❌ API-bypassed forms: using direct API/programmatic client calls to audit or validate user stories that primarily focus on interactive forms/inputs. If a human touches the UI, the audit/LARP must drive it through the real UI.
- ❌ Static mocks for async close: using synchronous/immediate mocks that do not model async callback latency or late-firing close events. Mocks must accurately simulate teardown delays.
- ❌ **Un-adjudicated capture (P1)**: a screenshot/recording stored as evidence of *quality* with no substantive per-screen critique. Twenty un-judged screenshots are surrogate proof of felt quality, not proof (#78).
- ❌ **Claim without mechanism (P2)**: any product/AI-surface claim of an action or completed state (built, generated, scheduled, "done") with no observed mechanism behind it (endpoint hit, row written, state change). A first-person action claim on a no-tools LLM surface is an automatic FELT-GOOD fail + P0 (#75-G1).
- ❌ **Bypass-role / dead-guard tests (P2)**: a negative test asserting an authz/RLS/tenant-isolation guard while running as a bypass-capable role (e.g. `service_role`/superuser) or behind a silent collect-time skip — it stays green even if the guard clause is deleted. Guard tests MUST run as a real least-privileged principal and actually attempt the forbidden op (#77.2).

### Universal Substrate-Mismatch Anti-Proof (All Platforms)
*The §2a claim-type axis restated as anti-proof. Each bullet is a **real** instrument producing a **real** green — the defect is the claim it is attached to, not the instrument. Cite one of these for the named claim type and the claim is surrogate proof (§13), capped at NO-SHIP for that AC until re-collected on an admissible substrate.*
- ❌ **A green suite cited for a visibility claim** ("this principal can/cannot see X"), however mutation-verified — including a read performed by a bypass-capable or mocked client. Only a live read as the real principal, both directions, can observe it.
- ❌ **A mock cited for what the deployment ACCEPTS.** A mock confirms the belief it was written from; it cannot contradict it. Same for a vendor payload fixture carrying no provenance (needs the vendor's field-reference URL + retrieval date on the fixture).
- ❌ **A post-walk read with no pre-walk baseline** cited as proof the walk wrote something — stale rows from an earlier seed are indistinguishable from a fresh write. Likewise a screenshot of a success state.
- ❌ **A rule-engine pass or a props-level assertion cited for fit / reachability / announcement.** The engine has no model of containment or overflow; props are not the platform accessibility tree; jsdom performs no layout, so its geometry numbers are zeros and its geometric claims are arithmetic models of the CSS, not the CSS's behaviour. An axe count with no tag scope stated is silent about every rule outside that scope.
- ❌ **A source-text assertion that a prompt rule string is present**, cited as proof the prompt changed behaviour. Behaviour is control-vs-treatment on the composed prompt with the shipped model, n reported.
- ❌ **A magnitude inherited from a report rather than measured** (a number quoted from a fire log, retro, or prior audit and then acted on). Re-measure before fixing; the naive fix to a mis-measured defect is routinely a worse defect.

### Universal Evidence-Integrity Anti-Proof — Reward Hacking (All Platforms)
*A green check is proof ONLY if the agent under test could not have manufactured it. The implementer/validator MUST be isolated from the evaluator. Any green gate produced through the channels below is anti-proof and caps the claim at NO-SHIP until re-run under isolation. (Industry audits found EVERY major coding benchmark could be driven to near-100% without solving a single task — Berkeley RDI, 2026.)*
- ❌ Implementer-authored/-modified verification logic in the graded change: test-harness hooks (`conftest.py`, `pytest_*` hooks, `jest`/`vitest` global setup/teardown), grader scripts, or CI config touched in the same diff that is being graded. (SWE-bench Verified was driven to 100% via a `conftest.py` pytest hook that rewrote every result to PASSED.)
- ❌ Force-passing constructs: monkeypatched assertions, module-load/`init()` side-effects that mutate results, or env flags that short-circuit checks.
- ❌ Answer/fix retrieval instead of derivation: mining git history for the reference fix, fetching the patch/solution from the web or issue tracker, or copying a known-good diff. (Solution-artifact retrieval showed a 72% resolved rate vs. ~40% baseline — *The Verification Horizon*, arXiv 2606.26300, 2026.)
- ❌ Visible-test overfitting: hard-coding outputs to satisfy the named tests rather than implementing the behavior.
- ❌ Self-graded "done": the agent declaring its own success criteria met without a runtime / exit-code / artifact check it did not control. ("Gate progress with facts, not vibes" — Thread AI, 2026.)

---
