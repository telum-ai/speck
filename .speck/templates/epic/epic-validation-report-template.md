---
template_version: "7.11.0"
artifact_type: epic-validation-report
---

# Epic Validation Report: [Epic Name]

**Epic**: [EPIC_ID]  
**Project**: [PROJECT_ID]  
**Validation Date**: [DATE]  
**Epic Duration**: [Start] to [End]  
**Overall Status**: [COMPLETE/PARTIAL/FAILED]

---

## Executive Summary

[Summary of epic outcome vs original vision and success criteria. Include what’s complete, what’s partial, and what blocks closure.]

---

## Story Completion Status

| User Story | Story ID | Status | Tests | Notes |
|------------|----------|--------|-------|-------|
| 1.1 | S004 | ✅ Complete | Pass | |
| 1.2 | S005 | ⚠️ Partial | 90% | Missing edge case |

**Total**: [X of Y] stories complete ([Z]%)

---

## Acceptance Criteria Validation

### User Story 1.1
- **Criteria**: Given X, when Y, then Z
- **Status**: ✅ PASS
- **Evidence**: [Test results, screenshots]

### User Story 1.2
- **Criteria**: Given A, when B, then C
- **Status**: ❌ FAIL
- **Issue**: [What failed and why]
- **Fix**: [Required changes]

---

## Technical Validation

### Architecture Compliance
- Implemented as designed: ✅/❌
- Deviations: [List with justification]
- Technical debt incurred: [Estimate]

### API Implementation
| API | Spec Match | Tests | Docs |
|-----|------------|-------|------|
| /api/v1/[endpoint] | ✅ | ✅ | ✅ |

### Performance Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| API Response | <200ms | 145ms | ✅ PASS |
| Page Load | <1s | 1.2s | ❌ FAIL |

---

## Integration Testing

### With Epic [X]
- Integration points tested: ✅/❌
- Data flow verified: ✅/❌
- No breaking changes: ✅/❌

### End-to-End Scenarios
| Scenario | Result | Notes |
|----------|--------|-------|
| [User journey] | PASS | |

---

## Quality Metrics

### Test Coverage
- Unit: [X]% (target: [Y]%)
- Integration: [A]% (target: [B]%)
- E2E: [C] scenarios passing

### Code Quality
- Linting: [Pass/Fail]
- Type Safety: [Coverage]
- Complexity: [Score]
- Duplication: [Percentage]

### Documentation
- [ ] API documentation complete
- [ ] User guides written
- [ ] Developer docs updated
- [ ] Architecture diagrams current

### Cursor Rules Compliance

**Skills Directory**: `.cursor/skills/` [exists/not found]  
**Total Rules Evaluated**: [X]  
**Epic-Wide Rules Applied**: [Y]

| Rule File | Stories Checked | Pass Rate | Issues Found |
|-----------|-----------------|-----------|--------------|
| [rule.mdc] | 8/8 stories | 100% (8/8) | None |
| [rule.mdc] | 5/8 stories | 60% (3/5) | Violations in S002, S005, S007 |

**Epic-Level Compliance**:
- Cross-story consistency: [✅/⚠️/❌] [details]
- Integration patterns: [✅/⚠️/❌] [details]
- Architectural rules: [✅/⚠️/❌] [details]

**Patterns & Recommendations**:
- [Patterns of rule violations that should be addressed]
- [Recommendations for improving compliance in future epics]

---

## Security Validation

- Authentication: ✅/❌ [Notes]
- Authorization: ✅/❌ [Notes]
- Input Validation: ✅/⚠️/❌ [Notes]
- Security Scan: [Results]

---

## Visual Design Validation

*Aggregated visual validation from story-level reports*

### Wireframe Adherence

| Screen/Flow | Wireframe Reference | Implementation | Status | Notes |
|-------------|---------------------|----------------|--------|-------|
| [Screen name] | `wireframes.md#section` | ✅ Matches | ✅ PASS | |
| [Screen name] | `wireframes.md#section` | ⚠️ Deviates | ⚠️ PARTIAL | [Justified deviation] |
| [Flow name] | `wireframes.md#section` | ❌ Missing | ❌ FAIL | Not implemented |

**Wireframe Coverage**: [X/Y] screens match wireframes ([Z]%)

### User Journey Completion

*From user-journey.md touchpoints*

| Journey Stage | Touchpoint | Screen | Status | Emotional Goal Met? |
|---------------|------------|--------|--------|---------------------|
| [Stage] | [Touchpoint] | [Screen path] | ✅ Complete | ✅ Yes |
| [Stage] | [Touchpoint] | [Screen path] | ⚠️ Partial | ⚠️ Needs polish |
| [Stage] | [Touchpoint] | [Screen path] | ❌ Missing | ❌ No |

**Journey Completion**: [X/Y] touchpoints complete ([Z]%)

### Cross-Story Visual Consistency

| Aspect | Status | Details |
|--------|--------|---------|
| Component consistency | ✅/⚠️/❌ | [Same components look identical across stories] |
| Typography consistency | ✅/⚠️/❌ | [Same text styles everywhere] |
| Color usage | ✅/⚠️/❌ | [No one-off colors outside design system] |
| Spacing consistency | ✅/⚠️/❌ | [Consistent margins/padding] |
| Animation consistency | ✅/⚠️/❌ | [Same interaction patterns] |

**Inconsistencies Found**:
1. [Story X uses different button style than Story Y]
2. [Story Z has custom shadow not in design system]

### Design System Adoption

**Epic-Wide Token Compliance**: [X]% (aggregated from stories)

| Story | Token Compliance | Accessibility Score | Voice/Tone |
|-------|------------------|---------------------|------------|
| S001 | 95% | 92/100 | ✅ PASS |
| S002 | 78% | 85/100 | ⚠️ PARTIAL |
| S003 | 100% | 95/100 | ✅ PASS |

**Design System Gaps** (patterns needed but not defined):
1. [Pattern needed] - Used in [X] stories - Recommend adding to design-system.md
2. [Pattern needed] - Used in [Y] stories - Recommend adding to design-system.md

### Screenshot Gallery

| Story | Screen | Screenshot | Notes |
|-------|--------|------------|-------|
| S001 | Dashboard | `stories/S001/screenshots/dashboard-desktop.png` | |
| S002 | Login | `stories/S002/screenshots/login-mobile.png` | |
| [etc] | | | |

### Epic Visual Summary

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Wireframe adherence | 100% | [X]% | ✅/⚠️/❌ |
| Journey completion | 100% | [X]% | ✅/⚠️/❌ |
| Cross-story consistency | High | [Rating] | ✅/⚠️/❌ |
| Token compliance (avg) | >90% | [X]% | ✅/⚠️/❌ |
| Accessibility (avg) | >85/100 | [X]/100 | ✅/⚠️/❌ |

**Overall Visual Status**: [✅ PASS / ⚠️ PARTIAL / ❌ FAIL]

---

## 📊 Epic JTBD Quality Scorecard

*Aggregated quality scorecard across all stories in this epic. Subject to the Quality Judgment & Scoring Protocol in `evidence-contract.md` §5.*

| Dimension | Score (0-10) | Evidence Path | Distinct Skeptical Note (Required for >=9) | Cap Reason (if any) |
|-----------|--------------|---------------|--------------------------------------------|---------------------|
| **Functional** | [0-10] | [path] | [Distinct note] | [e.g. Capped at 8 due to active P2 finding] |
| **Emotional** | [0-10] | [path] | [Distinct note] | |
| **Social** | [0-10] | [path] | [Distinct note] | |
| **Trust** | [0-10] | [path] | [Distinct note] | |
| **Commercial** | [0-10] | [path] | [Distinct note] | |

**Aggregate Epic Quality Score**: [Average of scores]/10

---

## JTBD Walkthrough & First-Time Comprehension

*This section is the top-down validation proof of user experience. Bottom-up validation (tests passing) is necessary but insufficient. We must walk the core JTBD of this epic end-to-end to verify that it composes into a coherent product and that a first-time user can immediately comprehend it.*

* **WHEN: infra_service / backend_api**: Replace this with an **Operational Scenario stress-test Walkthrough** (how the API handles a full client workflow under network disconnect / concurrent client disruptions).

### Option A: Human JTBD Walkthrough (for UI/Human-facing epics)

**Core Job**: [What the user is trying to accomplish — from epic.md]
**Entry Point**: [Where the user starts in the app]
**Path**: [Step-by-step screens/views traversed]

| Step | User Action | Expected Result | Actual Result | Comprehension PASS/FAIL | Status (✅/❌) |
|------|-------------|-----------------|---------------|-------------------------|----------------|
| 1 | [e.g. Open App] | [Sees screen X] | [Matches] | [Yes/No] | [✅] |
| 2 | [e.g. Press button Y] | [Navigates to Z] | [Matches] | [Yes/No] | [✅] |

**First-Time User Comprehension Rubric (Aggregated)**:
1. **What am I seeing?** (Understand screen context within 2 seconds of landing) -> [PASS / FAIL]
2. **Why does it matter?** (Value matches user's active JTBD) -> [PASS / FAIL]
3. **What do I do next?** (Primary continuation action is obvious with zero hunting) -> [PASS / FAIL]

*Overall First-Time Comprehension Verdict*: [PASS / FAIL] (If FAIL, epic validation is FAIL regardless of story-level results, and maximum verified state is capped at IMPL-GREEN).

### Option B: System Operational Scenario Walkthrough (for Infra/Backend epics)

**Core System Operation**: [The transactional/data flow being validated]
**Entry Point**: [The calling client endpoint / queue trigger]
**Expected Guarantees**: [Latency, throughput, durability bounds]

| Step | Disruption / Load Trigger | Expected System Behavior | Actual Behavior | Invariants Preserved (Yes/No) | Status (✅/❌) |
|------|---------------------------|--------------------------|-----------------|-------------------------------|----------------|
| 1 | [e.g. 500 rps write burst] | [Sub-50ms latency] | [Matches] | [Yes] | [✅] |
| 2 | [e.g. DB container restart]| [ROLLBACK completed] | [Matches] | [Yes] | [✅] |

---

## 🗣️ Human Language Pass

*Review of user-visible copy and AI-generated outputs against the voice principles in `product-contract.md` §6.*

- [ ] **No Cringe:** Could the target user read this aloud without cringing?
- [ ] **No Jargon Leak:** No internal methodology or technical jargon leaks into the UI.
- [ ] **AI Output Governed:** AI-generated text is governed by the same voice contract as static UI (no generic AI cheerleading).

---

## Evaluative Change Explanation (If applicable)

*If this evaluation changes a previous rating, state, or recommendation (or overrides a previous assessment), you MUST detail exactly what changed in the codebase or context, and the logical reasons for the new verdict.*

---

## Deviations from Plan

| Area | Planned | Actual | Reason |
|------|---------|--------|--------|
| [Area] | [Original] | [What changed] | [Why] |

---

## Lessons Learned

### What Went Well
1. [Success factor]
2. [Success factor]

### What Could Improve
1. [Issue encountered]
2. [Process improvement]

---

## Outstanding Items

### Must Fix
1. [Critical issue]
2. [Critical issue]

### Should Fix
1. [Important issue]

### Nice to Have
1. [Enhancement]

---

## Epic Closure Checklist

- [ ] All stories implemented
- [ ] Acceptance criteria verified
- [ ] Integration tested
- [ ] Performance validated
- [ ] Security reviewed
- [ ] Documentation complete
- [ ] Stakeholder sign-off

---

## Recommendation

**Status**: [APPROVED/CONDITIONAL/REJECTED]

If CONDITIONAL, complete these items before epic closure:
1. [Item]
2. [Item]

---
*Generated by /epic-validate command*  
*Template Version: 1.0.0*

