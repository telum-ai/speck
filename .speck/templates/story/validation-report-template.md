---
speck_version: 8.0
template_version: "7.11.0"
artifact_type: validation-report
readiness_state_claimed: [NO-SHIP | IMPL-GREEN | INTEGRATION-GREEN | UX-RC | API-RC | COMMERCIAL-RC | SHIP-RC | SHIP]
readiness_state_verified: [NO-SHIP | IMPL-GREEN | INTEGRATION-GREEN | UX-RC | API-RC | COMMERCIAL-RC | SHIP-RC | SHIP]
felt_axis: [uncovered | ai-verified | human-verified]
taste_axis: [uncovered | ai-critiqued | forks-open | human-verified]
taste_anchor: [product+universal | universal-only]
build_sha: [hash]
build_artifact: [iOS sim / web prod bundle / etc.]
audit_report: [path or "not-run"]
larp_evidence: [path or "not-run"]
clean_build: [yes/no]
---

# Validation Report — [STORY/EPIC NAME]

**Subject**: [Story / Epic ID]
**Date**: [YYYY-MM-DD HH:MM]
**Build SHA**: [hash]
**Build Artifact**: [per evidence-contract.md valid proof source]
**Clean Build (caches cleared)**: [yes/no]
**Claimed Readiness State**: [state]
**Verified Readiness State**: [state — may be lower than claimed if gates fail]

---

## 🎯 Readiness State Claim

**Claiming**: `[STATE]`

**Why this state and not higher**:
[1-2 sentences. E.g., "Claiming UX-RC, not COMMERCIAL-RC, because billing flow is not implemented in this story."]

**Why this state and not lower**:
[1-2 sentences. E.g., "Above IMPL-GREEN because LARP evidence captured from launch build, not dev server."]

---

## 🧭 Four-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD / TASTE)

*Every readiness claim decomposes into four independent, non-substitutable axes:*
- **CORRECT**: [How correctness was verified, e.g. tests pass, /audit clean]
- **ON-CONTRACT**: [How conformance to specs & magic moments was verified, e.g. larp-recordings/<sha>-<persona>-findings.md]
- **FELT-GOOD** *(legibility — not broken / not confusing)*: [AI naive-hostile taste verdict + First-Viewport Reaction, e.g. larp-recordings/<sha>-naive-hostile-findings.md → `ai-verified`. `uncovered` only if the naive-hostile pass has not run. A human review is an optional stronger signal → `human-verified`.]
- **TASTE** *(connoisseur craft — crafted / premium / it sings)*: [AI connoisseur-hostile verdict, **dual-anchored** against §6b Aesthetic Contract + design-system.md (product-relative) AND the `visual-quality` universal principles, e.g. larp-recordings/<sha>-connoisseur-findings.md → `ai-critiqued`. `forks-open` if aesthetic forks await your decision (below). `taste_anchor: universal-only` if §6b/design-system was absent. A **severe BAD** (≥2 pixel-grounded craft violations on a flagship/magic-moment surface) caps the claimable state.]

### 🎨 Aesthetic Forks — Owner Decision
*Populated when `taste_axis: forks-open`. Each fork the AI surfaces for you — aesthetics are an owner call; the AI never resolves subjective taste unilaterally.*
- [Fork: the decision · Option A vs Option B · pixel reasoning · which anchor is silent/conflicting · AI recommendation]

---

## ✅ Gate Criteria Check

*Verify against `evidence-contract.md` gate criteria for the claimed state. Each gate criterion in the contract maps to a row here.*

| Gate | Required at this state? | Evidence | Status |
|------|------------------------|----------|--------|
| Unit tests pass | Yes (IMPL-GREEN+) | `test-output.txt` | ✅ |
| Integration tests pass | Yes (IMPL-GREEN+) | [evidence] | ✅ |
| Lint passes | Yes (IMPL-GREEN+) | [evidence] | ✅ |
| Type check passes | Yes (IMPL-GREEN+) | [evidence] | ✅ |
| Build succeeds | Yes (IMPL-GREEN+) | [evidence] | ✅ |
| Real-integration round-trips succeed | Yes (INTEGRATION-GREEN+, if external §7 deps exist) | [real completion logs / traces] | ✅/⚠️/❌ |
| Live DB schema matches migrations & write path verified | Yes (INTEGRATION-GREEN+, if DB-backed) | `validate-schema-drift.sh output` | ✅/⚠️/❌ |
| Clean build compiled (caches cleared) | Yes (UX-RC+) | [production compile logs] | ✅/⚠️/❌ |
| Persona LARP recorded against built artifact | Yes (UX-RC+) | `larp-recordings/<sha>-<persona>-findings.md` | ✅/⚠️/❌ |
| Reachability: user can complete primary JTBD without dev shortcuts | Yes (UX-RC+) | [LARP evidence] | ✅/⚠️/❌ |
| No UI scaffolding (UUID inputs, debug headers) | Yes (UX-RC+) | [audit-report.md check] | ✅/⚠️/❌ |
| Automation language invisible to users | Yes (UX-RC+) | [LARP transcripts + banned-language scan] | ✅/⚠️/❌ |
| Banned-language lint passes | Yes (UX-RC+) | `banned-language-lint.sh output` | ✅/⚠️/❌ |
| Magic moments validated in LARP | Yes (UX-RC+) | [LARP findings] | ✅/⚠️/❌ |
| Real sandbox purchase + restore + manage + entitlement state in DB | Yes (COMMERCIAL-RC+, paid products only) | [evidence] | ✅/⚠️/❌ |
| Fallback states tested | Yes (COMMERCIAL-RC+) | [evidence] | ✅/⚠️/❌ |
| Support / Privacy / Terms accessible before purchase | Yes (COMMERCIAL-RC+) | [LARP evidence] | ✅/⚠️/❌ |
| Analytics events fire for purchase funnel | Yes (COMMERCIAL-RC+) | [dashboard screenshot] | ✅/⚠️/❌ |
| Runtime LARP against LAUNCH build (not dev/preview) | Yes (SHIP-RC+) | [LARP evidence with launch build SHA] | ✅/⚠️/❌ |
| Device-walk manual attestation recorded | Yes (SHIP-RC+, if device-walk criteria exist) | `larp-recordings/<sha>-human-attestation.md` | ✅/⚠️/❌ |
| Keystone dependencies bypassed/verified | Yes (SHIP-RC+, if keystone keys listed) | [CI logs showing skip-with-reason or active keys] | ✅/⚠️/❌ |
| Full JTBD walkthrough per persona | Yes (SHIP-RC+) | [LARP evidence per persona] | ✅/⚠️/❌ |
| Cross-epic integration tested | Yes (SHIP-RC+, epic-level only) | [evidence] | ✅/⚠️/❌ |
| Production env config verified | Yes (SHIP-RC+) | [evidence] | ✅/⚠️/❌ |
| Environment separation verified | Yes (SHIP-RC+) | [evidence] | ✅/⚠️/❌ |
| Adversarial probe passes | Yes (SHIP-RC+) | `audit-report.md` | ✅/⚠️/❌ |
| Deployment ran without errors | Yes (SHIP) | [evidence] | ✅/⚠️/❌ |
| Post-deploy healthcheck returns ok | Yes (SHIP) | [evidence] | ✅/⚠️/❌ |

If any required-at-this-state gate is ❌: **Verified state = lower** (drop to highest state where all gates pass).

---

## 📊 JTBD Quality Scorecard

*Scorecard based on the 5 dimensions from `product-contract.md` §4. Subject to the Quality Judgment & Scoring Protocol in `evidence-contract.md` §5.*

| Dimension | Score (0-10) | Evidence Path | Distinct Skeptical Note (Required for >=9) | Cap Reason (if any) |
|-----------|--------------|---------------|--------------------------------------------|---------------------|
| **Functional** | [0-10] | [path] | [Distinct note] | [e.g. Capped at 8 due to active P2 finding] |
| **Emotional** | [0-10] | [path] | [Distinct note] | |
| **Social** | [0-10] | [path] | [Distinct note] | |
| **Trust** | [0-10] | [path] | [Distinct note] | |
| **Commercial** | [0-10] | [path] | [Distinct note] | |

**Aggregate Quality Score**: [Average of scores]/10

---

## 📋 Spec Coverage (Requirements Traceability)

*Maps each FR in spec.md to evidence.*

| FR | Description | Verifiable by | Code | Test | LARP | Status |
|----|-------------|---------------|------|------|------|--------|
| FR-001 | [text] | agent-LARP | `<file:line>` | `<test>` | `<larp-step>` | ✅ |
| FR-002 | [text] | device-walk | `<file:line>` | `<test>` | `<larp-step>` | ⚠️ Manual |
| FR-003 | [text] | agent-LARP | — | — | — | ❌ Ungrounded |

**Coverage**: [X/Y] grounded, [A/B] tested, [C/D] LARP-validated

---

## 🛑 Blocking Issues (from audit-report.md)

*P0 findings from `/audit` that block higher readiness states.*

| ID | From | Severity | Description | Required for state |
|----|------|----------|-------------|---------------------|
| - | audit-report.md | - | None | - |

If any P0 exists: claimed state must be lowered.

---

## 🎭 LARP Summary

*Per `evidence-contract.md` LARP requirements.*

| Persona | Flow | Verdict | Evidence path |
|---------|------|---------|---------------|
| [persona-id] | [flow name] | PASS / CONDITIONAL / FAIL | `larp-recordings/<sha>-<persona>-findings.md` |

**Magic moments validated**: [X / Y]
**Taste-judgment dimensions failed**: [list]

---

## 🗣️ Human Language Pass

*Review of user-visible copy and AI-generated outputs against the voice principles in `product-contract.md` §6.*

- [ ] **No Cringe:** Could the target user read this aloud without cringing?
- [ ] **No Jargon Leak:** No internal methodology or technical jargon leaks into the UI.
- [ ] **AI Output Governed:** AI-generated text is governed by the same voice contract as static UI (no generic AI cheerleading).

---

## 🔬 What this validation did NOT verify / Deferrals (Mandatory)

*To establish high trust and avoid theater, you MUST explicitly disclose what this validation did NOT check or prove. Do not leave blank.*

**Classify EVERY deferral.** `autonomous-not-done` deferrals are BLOCKERS — an agent with a build + browser tool could have done them, so they must be completed, not deferred (they cap the state at IMPL-GREEN). Only `human/creds-gated` deferrals are legitimate.

| Deferred item | Class (`autonomous-not-done` / `human/creds-gated`) | Cap Status (`evidence-pending` / `implementation-pending`) | Why deferred | Resolve by |
|---------------|------------------------------------------------------|-----------------------------------------------------------|--------------|-----------|
| [e.g. browser LARP on prod build + stored axe JSON] | autonomous-not-done → MUST complete | evidence-pending | [reason] | [before claiming UX-RC] |
| [e.g. Batch API path for FR-E002-004] | human/creds-gated | implementation-pending → BLOCKER | [code never built] | [implement or DEC descope] |
| [e.g. live SMS send to a real phone] | human/creds-gated | evidence-pending | [creds not provisioned] | [human/keystone] |

- **Untested / Unchecked Aspects**: [e.g., "Did not test native Apple Pay callbacks, verified mock flow only. Deferred to physical device walk (human/creds-gated, evidence-pending)."]
- **Deferred / Stale Proofs**: [e.g., "Sentry logging was not verified against active staging event streams because the API keys are not provisioned yet (human/creds-gated, evidence-pending)."]
- **Assumptions Untested**: [e.g., "Assumed the Stripe webhook responds under 1s; did not stress test webhook latency bounds."]

> Any `implementation-pending` row present → verified readiness state MUST cap at `NO-SHIP`. Unbuilt code cannot pass as IMPL-GREEN or higher.
> Any `autonomous-not-done` row present → this validation may NOT claim UX-RC/API-RC; cap at IMPL-GREEN/INTEGRATION-GREEN and complete the autonomous portion first.

---

## ⚠️ Specification Deviations (Delta Tracking)

*Optional. Document only if implementation differed materially from spec.*

### MODIFIED
- [FR / requirement]: [from → to, reason, evidence]

### ADDED
- [What was discovered + added]

### REMOVED / DEFERRED
- [What from spec wasn't done, why, follow-up]

---

## 🔬 Banned-Phrase Detection (Self-Audit)

*This validation report MUST NOT contain banned phrases that hide gaps. Run this self-check before claiming a state.*

- [ ] No "ready for launch" without launch-build evidence
- [ ] No "outside autonomous reach" without enumerating what CAN be done
- [ ] No "premium polish complete" without taste-judgment rubric pass
- [ ] No "should work in production" — replace with "verified in [build]" or "not yet verified"
- [ ] No "tests pass therefore done" — runtime evidence required at UX-RC+
- [ ] No "the AI agent confirmed" — must link to evidence file

If any check fails: **re-audit and tighten language before publishing this report**.

---

## 📊 Next Steps

### If verified state matches claimed:
- ✅ Ready for the next stage
- 📋 If this is a story: epic-level work can include this
- 📋 If SHIP-RC: deployment can proceed (human approval per evidence-contract section 9)

### If verified state is lower than claimed:
- ❌ Fix the failing gate(s)
- 🔄 Re-run `/audit` + `/larp` + `/story-validate`

### If P0 audit findings remain:
- 🛑 Resolve P0s before resubmitting

---

## 🧭 Project Documentation Updates

*Complete after this validation passes to update project-level truth.*

After verified-state PASS, the following project-level docs may need updates:

- [ ] `project.md` → If this changed project scope or vision
- [ ] `PRD.md` → If this delivered new features
- [ ] `product-contract.md` → If a new magic moment was validated or banned-term added
- [ ] `architecture.md` → If new patterns introduced
- [ ] `evidence-contract.md` → If new platform-specific proof learned
- [ ] `context.md` → If new constraints discovered

For each updated doc, re-stamp with `.speck/scripts/stamp-truth.sh <path>`.

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck vX.Y.Z]*
