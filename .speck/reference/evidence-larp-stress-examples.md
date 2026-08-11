# LARP / stress test examples (JIT)

## 4. Required Runtime LARP / Integration Stress Tests

* **WHEN: consumer_product / b2b_saas / internal_tool**: Persona-based LARP flows recorded as evidence at each readiness state.
* **WHEN: infra_service / backend_api**: Integration / Stress-test scenarios under concurrent simulated load.

> **P1 — the two-job LARP**: every UI LARP is two non-collapsible jobs — **DOES-IT-WORK** (functional: the flow completes, gates enforced) and **IS-IT-GOOD** (experiential: per-screen, pixel-grounded adversarial critique of how it looks and feels). IS-IT-GOOD has its own pass/fail and can block ship independently of functional green. A captured screen with no substantive critique is an incomplete LARP (surrogate proof), not a pass. See `/speck-larp`.

### Option A: Human Persona-Based LARP (for UI/Human-facing products)

### Longitudinal Proof Mode (for adaptive products)
*Distinguishes "snapshot state coverage" from "same-user longitudinal proof" to verify continuity across weeks/months of use.*

- **Requirement:** For products with learning, adaptation, or progress over time, the validation suite **MUST** record same-user timeline continuity.
- **Evidence:** A `timeline.jsonl` containing state mutations and invariants across the longitudinal chapters (Day 0 -> Week 12+).
- **Rule:** Disconnected seeded states are valid for debugging, but **NOT** sufficient for claiming longitudinal product excellence.

### LARP Required for UX-RC

| Persona | Flow | Evidence required |
|---------|------|-------------------|
| [Anxious beginner] | Onboarding → first session → completion | Screenshots, AX tree, taste notes per screen, timings |
| [Returning user] | Cold-open → resume context → action | Screenshots showing no re-onboarding, timings |
| [Skeptical buyer] | Landing → trust check → first signal of value | Screenshots, taste notes, "would I pay?" judgment |
| [Naive first-timer (context-stripped)] | Onboarding → first screen → value-producing screen | Screenshots, First-Viewport Reaction rubric, taste notes, revulsion check (Required for consumer archetypes) |
| **Second actor, same install** *(REQUIRED — Speck-owned, not a placeholder)* | A signs in → writes → teardown → **B signs in on the same install, offline** | Per persistence layer, B observes nothing of A's: server row, cache, queue/outbox, local DB, notification schedule, draft, store receipt, billing SDK identity, analytics. `signOut` vs `deleteAccount` compared field-for-field. Discharges `PROBE:second-actor` in §11a |

*Every other row above is a placeholder for this product to name. **The second-actor row is not.** A persona set can be arbitrarily broad and still be one identity in many states — day-0, paused, muted-counterpart, solo, serial-decliner are all the same actor — so identity and tenancy defects are as invisible to a wide persona army as to a single-user suite. The scars: an offline queue that survived sign-out and replayed under the current token, landing A's unsynced work in B's account; a sign-out that forgot the push token instead of revoking it, so a stranger's handset keeps receiving A's notifications with neither person holding a control that can stop it; one local DB per device, so B read A's sessions offline while the account-delete path already knew the difference.*

### LARP Required for SHIP-RC

All UX-RC LARPs **plus**:

| Persona | Flow | Evidence required |
|---------|------|-------------------|
| [Each named persona] | Full primary JTBD walkthrough | Full recording (video or step-by-step), AX trees, timings, transcripts |
| [Privacy-conscious user] | Account / data review | Screenshots showing data residency, deletion paths |

LARP scripts live in: `specs/projects/<PROJECT_ID>/personas/<persona-id>.md`

### Option B: Integration / Stress-Test Scenarios (for Infra/Backend)

### Stress Tests Required for API-RC (equivalent to UX-RC)

| Consumer Profile | Simulated Flow | Metrics / Evidence Required |
|------------------|----------------|-----------------------------|
| [Peak Concurrent Caller] | 500 concurrent requests over 1 min | Latency histogram (P95/P99), total successful ops, zero DB lock timeouts |
| [Malformed Operator] | Send 100 random malformed payloads | Confirm stable error codes (e.g. 400), zero database exception leaks, zero 500 crashes |

### Stress Tests Required for OPERATIONAL-RC (equivalent to SHIP-RC)

| Scenario | Simulated Disruptions | Integrity / Failover Evidence Required |
|----------|-----------------------|----------------------------------------|
| [Database Disconnect] | Restart DB container during active writes | Connection pooled retry success, zero partial writes (rollback complete), graceful 503 response |
| [Unresponsive Auth Provider] | Mock auth provider response latency >= 5s | Request timeout trigger within 1s, fail-closed/cached response validity, client receives expected timeout error |

---
