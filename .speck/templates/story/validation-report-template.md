# Validation Report: [STORY NAME]

**Date**: [YYYY-MM-DD HH:MM:SS]  
**Branch** (optional): `S###-story-name`  
**Status**: [PASS / CONDITIONAL_PASS / FAIL]  
**Validator**: [/story-validate command v1.0]

---

## Executive Summary

### Overall Metrics
- **Task Completion**: [X/Y] tasks complete ([Z]%)
- **Test Results**: [X/Y] tests passing ([Z]%)
- **Requirements Coverage**: [X/Y] requirements verified ([Z]%)
- **Performance**: [PASS / FAIL] ([X/Y] targets met)
- **Constitution Compliance**: [PASS / CONDITIONAL / FAIL]
- **Code Quality**: [PASS / FAIL]

### Quick Status
| Category | Status | Notes |
|----------|--------|-------|
| 📋 Tasks | [✅/⚠️/❌] | [summary] |
| 🧪 Tests | [✅/⚠️/❌] | [summary] |
| 📊 Performance | [✅/⚠️/❌] | [summary] |
| 📜 Constitution | [✅/⚠️/❌] | [summary] |
| 🔍 Code Quality | [✅/⚠️/❌] | [summary] |

---

## Specification Deviations (Delta Tracking)

> **Purpose**: Document how implementation differed from spec using OpenSpec-inspired delta format  
> **Usage**: Feeds retrospectives and guides spec updates  
> **Action**: Review each deviation and decide whether to update spec or revert implementation

### MODIFIED Requirements
[For requirements that changed during implementation]

**Requirement**: [Original requirement name from spec.md]
- **From Spec**: [What spec originally said]
- **Actual Implementation**: [What was actually built]
- **Reason**: [Why it changed - technical limitation, better approach discovered, performance optimization, etc.]
- **Evidence**: [Code location, commit, or test demonstrating the change]
- **Validation**: ✅ Improvement | ⚠️ Acceptable deviation | ❌ Should revert to spec
- **Action**: □ Update spec.md | □ Revert implementation | □ Document as approved exception

[Repeat for each modified requirement]

### ADDED Requirements
[For requirements discovered during implementation that weren't in original spec]

**Requirement**: [New requirement name]
- **Why Needed**: [What necessitated this - edge case found, integration requirement, user feedback]
- **Implementation**: [What was added]
- **Evidence**: [Code location or test coverage]
- **Validation**: ✅ Necessary addition | ⚠️ Scope creep | ❌ Should be separate story
- **Action**: □ Add to spec.md | □ Create follow-up story | □ Remove if scope creep

[Repeat for each added requirement]

### REMOVED Requirements
[For requirements from spec that couldn't be implemented or were deprioritized]

**Requirement**: [What from spec wasn't implemented]
- **Why Not Implemented**: [Technical blocker, timeline constraint, deprioritized, discovered infeasible]
- **Impact**: [What functionality is missing, user impact]
- **Validation**: ✅ Acceptable deferral to v2 | ⚠️ Partial implementation acceptable | ❌ Must implement
- **Action**: □ Update spec.md to defer | □ Create follow-up story | □ Escalate blocker

[Repeat for each removed requirement]

**Summary**: [X] modified, [Y] added, [Z] removed

---

## Requirements Traceability Matrix

*Mapping specification requirements to verification evidence*

| Req ID | Description | Verification Method | Status | Evidence | Notes |
|--------|-------------|---------------------|--------|----------|-------|
| FR-001 | [requirement text] | Contract test | ✅ PASS | `tests/contract/test_x.py` | All assertions pass |
| FR-002 | [requirement text] | Integration test | ✅ PASS | `tests/integration/test_y.py` | Scenario validated |
| FR-003 | [requirement text] | Quickstart scenario | ⚠️ MANUAL | Scenario #2 in quickstart.md | Needs user confirmation |
| FR-004 | [requirement text] | Unit test | ❌ FAIL | `tests/unit/test_z.py` | Expected X, got Y |
| FR-005 | [requirement text] | - | ❌ UNTESTED | No test coverage found | Critical gap |

**Coverage Summary**:
- ✅ Verified: [X] requirements ([Y]%)
- ⚠️ Manual validation: [X] requirements ([Y]%)
- ❌ Failed: [X] requirements ([Y]%)
- ❌ Untested: [X] requirements ([Y]%)

---

## Test Suite Results

### Summary by Test Type
```
Contract Tests:    [X passed] / [Y total] ([Z]%)
Integration Tests: [X passed] / [Y total] ([Z]%)
Unit Tests:        [X passed] / [Y total] ([Z]%)
Performance Tests: [X passed] / [Y total] ([Z]%)
---
Total:            [X passed] / [Y total] ([Z]%)
Coverage:         [Z]% (lines/statements/branches)
```

### Failed Tests Detail
[If any tests failed, list them here with error details]

**Example**:
```
❌ tests/integration/test_auth.py::test_login_invalid_credentials
   AssertionError: Expected 401 status code, got 500
   Line 45: assert response.status_code == 401
   
   Full traceback:
   [error output]
```

### Skipped/Pending Tests
[List any tests marked as skip or pending with reasons]

### Test Execution Logs
[Link to full test output or attach test report file]

---

## Quickstart Scenario Execution

*Integration test scenarios from quickstart.md*

| Scenario | Steps | Status | Duration | Details |
|----------|-------|--------|----------|---------|
| User Registration Flow | 5 | ✅ PASS | 2.3s | All steps successful |
| Data Import | 3 | ❌ FAIL | - | Step 2 timeout after 30s |
| API Authentication | 4 | ✅ PASS | 1.1s | Token validated |
| Error Handling | 6 | ⚠️ PARTIAL | 3.5s | Step 5 needs manual check |

### Failed Scenario Details
[For each failed scenario, provide step-by-step breakdown]

**Example**:
```
❌ Data Import Scenario (quickstart.md lines 45-62)

Steps:
1. ✅ Prepare test data file → success (data.csv created)
2. ❌ Upload via API → FAILED
   Expected: 201 Created
   Actual: 500 Internal Server Error
   Error: "Database connection timeout"
3. ⏭️ Verify import → skipped (step 2 failed)

Root Cause: Database connection pool exhausted during large file upload
Recommendation: Increase pool size or implement streaming upload
```

### Manual Scenarios Checklist
[For scenarios requiring manual validation, provide checklist]

- [ ] **Scenario**: [name]
  - [ ] Step 1: [description]
  - [ ] Step 2: [description]
  - [ ] Expected outcome: [description]

---

## Performance Validation

*Comparing actual metrics against spec.md targets*

| Metric | Target | Actual | Status | Gap | Notes |
|--------|--------|--------|--------|-----|-------|
| API latency (p50) | <100ms | 78ms | ✅ PASS | -22ms | Well within target |
| API latency (p95) | <200ms | 245ms | ❌ FAIL | +45ms | Optimization needed |
| API latency (p99) | <500ms | 890ms | ❌ FAIL | +390ms | Severe outliers |
| Throughput | >1000 req/s | 1250 req/s | ✅ PASS | +250 req/s | Good headroom |
| Memory usage (avg) | <512MB | 380MB | ✅ PASS | -132MB | Efficient |
| Memory usage (peak) | <1GB | 1.2GB | ❌ FAIL | +200MB | Memory leak suspected |
| Cold start time | <3s | 1.8s | ✅ PASS | -1.2s | Fast startup |

**Performance Summary**:
- ✅ Met: [X/Y] targets ([Z]%)
- ❌ Failed: [X/Y] targets ([Z]%)

**Performance Issues**:
1. **P95 latency exceeded**: Likely caused by database query N+1 problem in user listing endpoint
2. **Peak memory high**: Potential memory leak in WebSocket connection handler
3. **P99 latency critical**: Investigate timeout handling and connection pooling

**Performance Test Logs**: [link to detailed performance report]

---

## Constitution Compliance

*Verifying constitutional principles are implemented, not just claimed*

### Gates from plan.md Constitution Check

| Principle/Gate | Required | Claimed in Plan | Actually Implemented | Status | Evidence |
|----------------|----------|-----------------|---------------------|--------|----------|
| Library-First | Feature as library | Yes | ✅ Yes | ✅ PASS | `src/lib/` structure exists |
| CLI Interface | Text I/O commands | Yes | ⚠️ Partial | ⚠️ WARN | CLI exists but no JSON output |
| Test-First | Tests before code | Yes | ✅ Yes | ✅ PASS | Git history shows tests committed first |
| Feature Flags | Gradual rollout | Yes | ❌ No | ❌ FAIL | No feature flag configuration found |
| [Custom Gate] | [requirement] | [claim] | [actual] | [status] | [evidence/location] |

### Complexity Deviations Check

*From plan.md Complexity Tracking table*

| Declared Violation | Justification in Plan | Actually Needed? | Status | Notes |
|--------------------|----------------------|------------------|--------|-------|
| 4th project added | "Mobile app requires separate project" | ✅ Yes | ✅ VALID | Complexity justified |
| Repository pattern | "Multiple DB backends needed" | ❌ No | ⚠️ REVIEW | Only 1 DB in use, reconsider |

**Constitution Issues**:
- ❌ **Feature flags missing**: Plan claimed feature flags for gradual rollout, but no configuration found
  - **Impact**: Cannot do phased deployment
  - **Recommendation**: Add feature flag infrastructure before merge
  
- ⚠️ **Repository pattern questionable**: Complexity justified for "multiple DB backends" but only PostgreSQL is used
  - **Impact**: Unnecessary abstraction layer
  - **Recommendation**: Simplify to direct DB access or document second DB usage

### Constitutional Principles Adherence

✅ **Aligned**:
- Modular library structure (`src/lib/[feature]/`)
- CLI interface present (`src/cli/commands/`)
- Test-first approach (git log confirms)

⚠️ **Partially Aligned**:
- CLI JSON output missing (only human-readable text)

❌ **Not Aligned**:
- Feature flags infrastructure missing

---

## Research Alignment Validation

*Comparing implementation against research recommendations embedded in plan.md*

### Research Decision Implementation

| Research Area | Recommendation | Implementation Status | Evidence | Notes |
|---------------|----------------|----------------------|----------|-------|
| [Topic from plan.md research] | [Recommended approach] | ✅ Implemented | [File/code location] | Matches recommendation |
| [Topic from plan.md research] | [Recommended approach] | ⚠️ Partial | [File/code location] | Alternative approach used |
| [Topic from plan.md research] | [Recommended approach] | ❌ Not implemented | N/A | Missing from codebase |

**Research Alignment Issues**:
- ❌ **[Topic]**: Research recommended [X] but implementation uses [Y]
  - **Impact**: [Performance/security/maintainability concern]
  - **Recommendation**: [Align with research or document justification]

---

## Codebase Pattern Adherence Validation

*Comparing implementation against existing patterns (if codebase-scan-*.md exists)*

### File Organization Compliance

| Aspect | Expected (from scans) | Actual | Status | Notes |
|--------|----------------------|--------|--------|-------|
| File naming | [snake_case/kebab-case/PascalCase] | [actual convention used] | ✅ PASS | Consistent |
| Directory structure | [expected path] | [actual path] | ✅ PASS | Follows convention |
| Test organization | [expected structure] | [actual structure] | ❌ FAIL | Tests misplaced |
| Import style | [expected pattern] | [actual pattern] | ✅ PASS | Matches codebase |

### Component Reuse Validation

| Component/Pattern | Available in Codebase | Reused? | Status | Notes |
|-------------------|----------------------|---------|--------|-------|
| [Existing component from scan] | Yes (`path/to/component`) | ✅ Yes | ✅ PASS | Properly reused |
| [Existing pattern from scan] | Yes (`path/to/pattern`) | ⚠️ Partial | ⚠️ WARN | Custom variant created |
| [Existing service from scan] | Yes (`path/to/service`) | ❌ No | ❌ FAIL | Duplicated functionality |

**Pattern Adherence Issues**:
- ❌ **Duplicated functionality**: New [component] created when [existing component] was available
  - **Impact**: Code duplication, inconsistency
  - **Recommendation**: Refactor to use existing [component] from `[path]`
  
- ⚠️ **File naming inconsistency**: New files use [X] naming when codebase uses [Y]
  - **Impact**: Inconsistent codebase navigation
  - **Recommendation**: Rename files to match existing convention

### Pattern Reuse Metrics

- **Reuse Rate**: [X]% ([Y] reused / [Z] available)
- **Convention Compliance**: [X]% ([Y] compliant / [Z] total files)
- **Directory Structure Match**: ✅ PASS / ❌ FAIL

---

## Visual/UX Validation

*Validating implementation against design specifications*

### Platform & Strategy

| Property | Value |
|----------|-------|
| **Platform** | [web / mobile-flutter / mobile-rn / desktop-electron / desktop-tauri / extension / N/A] |
| **Strategy** | [browser-mcp / golden-tests / maestro / playwright / webdriverio / puppeteer / N/A] |
| **Pattern Reference** | `.speck/patterns/visual-testing/[platform]-visual-testing.md` |

*If Platform = N/A: Story has no UI components, skip this section*

### Screenshots Captured

| Screen | Breakpoint/Device | Screenshot | Status | Notes |
|--------|-------------------|------------|--------|-------|
| [Screen name] | mobile (375px) | `screenshots/[name]-mobile.png` | ✅ | |
| [Screen name] | tablet (768px) | `screenshots/[name]-tablet.png` | ✅ | |
| [Screen name] | desktop (1024px) | `screenshots/[name]-desktop.png` | ⚠️ | Minor layout shift |
| [Component] | hover state | `screenshots/[name]-hover.png` | ✅ | |
| [Component] | error state | `screenshots/[name]-error.png` | ✅ | |

**Screenshot Directory**: `{STORY_DIR}/screenshots/`

### Design Token Compliance

| Property | Expected Token | Actual Implementation | Status |
|----------|---------------|----------------------|--------|
| Primary color | `var(--primary-500)` | ✅ Token used | ✅ PASS |
| Text color | `var(--gray-900)` | ✅ Token used | ✅ PASS |
| Button padding | `var(--space-4)` | ❌ Hardcoded `16px` | ❌ FAIL |
| Border radius | `var(--radius-md)` | ✅ Token used | ✅ PASS |
| Shadow | `var(--shadow-sm)` | ❌ Hardcoded `box-shadow` | ❌ FAIL |

**Token Compliance**: [X/Y] properties use design tokens ([Z]%)

**Hardcoded Values Found**:
```
[File path:line] - [hardcoded value] → should use [token]
```

### Responsive Behavior

| Breakpoint | Expected Layout | Actual Layout | Status |
|------------|----------------|---------------|--------|
| Mobile (375px) | Single column, stacked | ✅ Matches | ✅ PASS |
| Tablet (768px) | 2-column grid | ✅ Matches | ✅ PASS |
| Desktop (1024px) | 3-column with sidebar | ⚠️ 2-column only | ⚠️ PARTIAL |
| Wide (1280px) | Max-width container | ✅ Matches | ✅ PASS |

### Accessibility Audit

*From `runAccessibilityAudit()` or equivalent*

| Category | Issues | Severity | Status |
|----------|--------|----------|--------|
| Color contrast | 0 | - | ✅ PASS |
| Touch targets | 2 | Medium | ⚠️ WARN |
| ARIA labels | 0 | - | ✅ PASS |
| Heading structure | 1 | Low | ⚠️ WARN |
| Keyboard navigation | 0 | - | ✅ PASS |
| Focus indicators | 0 | - | ✅ PASS |

**Accessibility Score**: [X]/100

**Issues to Address**:
1. [Issue description] - [Severity] - [Fix suggestion]

### Voice/Tone Compliance

*Comparing UI copy against ux-strategy.md voice attributes*

| Voice Attribute | Expected | UI Copy Example | Status |
|-----------------|----------|-----------------|--------|
| Friendly | Approachable language | "Oops! That didn't work" | ✅ PASS |
| Professional | Clear and concise | "Save changes" | ✅ PASS |
| Encouraging | Positive reinforcement | "Error" → should be "Let's try again" | ⚠️ WARN |

**Voice/Tone Notes**:
- [Specific copy that doesn't match voice]
- [Suggestions for improvement]

### ui-spec.md Testing Checklist

*Copy from ui-spec.md and check off during validation*

**Visual Testing**:
- [✅/❌] All states render correctly
- [✅/❌] Responsive at all breakpoints
- [✅/❌] Animations perform smoothly
- [✅/❌] Design tokens applied correctly

**Functional Testing**:
- [✅/❌] All interactions work as specified
- [✅/❌] Keyboard navigation complete
- [✅/❌] Screen reader announcements correct
- [✅/❌] Error states handle gracefully

**Checklist Completion**: [X/Y] items checked ([Z]%)

### Visual Validation Summary

| Aspect | Status | Score |
|--------|--------|-------|
| Screenshots | ✅ PASS | [X/Y] captured |
| Design Tokens | ⚠️ PARTIAL | [Z]% compliant |
| Responsive | ✅ PASS | All breakpoints |
| Accessibility | ⚠️ PARTIAL | [X]/100 |
| Voice/Tone | ✅ PASS | Matches strategy |
| ui-spec Checklist | ⚠️ PARTIAL | [Z]% complete |

**Overall Visual Status**: [✅ PASS / ⚠️ PARTIAL / ❌ FAIL]

---

## Code Quality Gates

### Linting Results

**Python (flake8)**:
```
✅ PASS - 0 violations found
All files conform to PEP 8
```

**Python (mypy)**:
```
❌ FAIL - 12 type errors found

src/services/user.py:45: error: Argument 1 has incompatible type "str"; expected "int"
src/models/account.py:23: error: Missing return statement
[...additional errors...]

Summary: 12 errors, 3 files
```

**JavaScript/TypeScript (eslint)**:
```
⚠️ WARN - 5 warnings found

src/components/Dashboard.tsx:12:3 - warning: 'useState' is not defined (react-hooks/rules-of-hooks)
[...additional warnings...]

Summary: 0 errors, 5 warnings
```

### Type Checking Results

**TypeScript (tsc --noEmit)**:
```
✅ PASS - No type errors found
```

### Security Scanning Results

**Python (bandit)**:
```
⚠️ WARN - 2 medium severity issues

Issue: [B105:hardcoded_password_string] Possible hardcoded password: 'test123'
   Location: tests/fixtures/auth.py:15
   Severity: Medium
   Confidence: Medium

Issue: [B201:flask_debug_true] Flask app run with debug=True
   Location: src/main.py:45
   Severity: Medium
   Confidence: High
```

**JavaScript (npm audit)**:
```
✅ PASS - 0 vulnerabilities found
```

### Code Quality Summary

| Tool | Result | Errors | Warnings | Blockers |
|------|--------|--------|----------|----------|
| flake8 | ✅ PASS | 0 | 0 | No |
| mypy | ❌ FAIL | 12 | 0 | Yes |
| eslint | ⚠️ WARN | 0 | 5 | No |
| tsc | ✅ PASS | 0 | 0 | No |
| bandit | ⚠️ WARN | 0 | 2 | No |
| npm audit | ✅ PASS | 0 | 0 | No |

**Critical Issues**:
1. **mypy type errors**: Must fix before merge (see details above)

**Non-blocking Warnings**:
1. **eslint warnings**: Should fix but don't block merge
2. **bandit warnings**: Test fixtures only, acceptable

---

## Documentation Completeness

### Required Documentation

- [✅/❌] **API Documentation**: [status and location]
  - OpenAPI schema: `contracts/api.yaml` ✅
  - Endpoint descriptions: ⚠️ Partial (3/10 endpoints documented)
  
- [✅/❌] **Model/Entity Documentation**: [status]
  - Docstrings: ✅ All models have docstrings
  - Field descriptions: ⚠️ 60% coverage
  
- [✅/❌] **CLI Help Text**: [status]
  - Commands: ✅ All commands have --help
  - Examples: ❌ No usage examples
  
- [✅/❌] **Migration Guide**: [status]
  - Breaking changes: ✅ N/A (no breaking changes)
  
- [✅/❌] **Agent Context Files**: [status]
  - Updated: ✅ `.cursor/rules/specify-rules.mdc` includes this feature
  - Recent changes: ✅ Feature listed in recent changes

### Documentation Gaps

1. **API endpoint documentation incomplete**: Only 3/10 endpoints have descriptions in OpenAPI schema
2. **CLI usage examples missing**: Add examples to README or CLI --help output

---

## Blockers & Critical Issues

*Issues that MUST be resolved before merge/deploy*

### 🚨 Critical Blockers

1. **Type errors (mypy)**: 12 type errors must be fixed
   - **Files affected**: `src/services/user.py`, `src/models/account.py`
   - **Effort**: ~1 hour
   - **Fix by**: [developer name]

2. **Feature flags missing**: Constitutional requirement not implemented
   - **Impact**: Cannot do gradual rollout
   - **Effort**: ~3 hours
   - **Fix by**: [developer name]

3. **Performance p95 latency failed**: Exceeds 200ms target by 45ms
   - **Root cause**: Database N+1 queries
   - **Effort**: ~2 hours
   - **Fix by**: [developer name]

### ⚠️ Non-Critical Issues (Fix before or after merge)

1. **eslint warnings**: 5 warnings in frontend code
2. **Documentation gaps**: API documentation only 30% complete
3. **CLI JSON output missing**: Constitutional guideline suggests JSON output

---

## Recommendations

### Before Merge
1. **Fix mypy type errors**: Critical for type safety
2. **Implement feature flags**: Required by constitution
3. **Optimize p95 latency**: Add database query caching or fix N+1 problem
4. **Document remaining API endpoints**: Complete OpenAPI schema

### After Merge (Technical Debt)
1. **Add CLI JSON output**: Improve automation capabilities
2. **Fix eslint warnings**: Code quality improvement
3. **Review repository pattern usage**: May be over-engineered

### Performance Optimization
1. **Investigate p99 latency spikes**: Profile slow requests
2. **Monitor memory usage**: Potential leak in WebSocket handler
3. **Add database indexes**: User listing endpoint is slow

---

## Next Steps

### If Status = PASS ✅
- ✅ **Ready for code review**
- ✅ **Ready for PR** (use details from this report)
- ✅ **Deploy to staging** after review approval
- 📋 **Create tickets** for non-critical technical debt

### If Status = CONDITIONAL_PASS ⚠️
- ⚠️ **Address warnings** (optional before merge)
- ✅ **Ready for PR** with noted caveats
- 📋 **Document known issues** in PR description
- 🔄 **Re-run /story-validate** after fixes (optional)

### If Status = FAIL ❌
- ❌ **Fix critical blockers** before review
- 🔄 **Re-run /story-validate** after fixes
- 📋 **Update tasks.md** with fix tasks
- ⏸️ **Hold PR** until validation passes

---

## Validation Metadata

**Command**: `/story-validate`  
**Version**: 1.0  
**Duration**: [X.Xs]  
**Artifacts Generated**:
- `validation-report.md` (this file)

**Validation Flags Used**: [list any flags like --allow-incomplete, --skip-perf]

**Re-run Command**:
```bash
/story-validate [same flags if needed]
```

---

*Generated by /story-validate on [YYYY-MM-DD HH:MM:SS]*

