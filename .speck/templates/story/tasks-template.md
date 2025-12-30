---
# Implementation status for orchestrator
# Values: pending | in_progress | completed
status: pending
---

# Tasks: [STORY NAME]

**Input**: Design documents from `{STORY_DIR}/`
**Prerequisites**: spec.md (required), plan.md (required), data-model.md, contracts/

## Execution Flow (main)
```
1. Load spec.md and plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure (research is embedded in plan.md)
2. From spec.md:
   → Extract: all FR-XXX requirements, scenarios, NFRs (performance/security/privacy/accessibility)
3. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → codebase-scan-*.md: Extract conventions → enforce in tasks
4. Generate tasks by category:
   → Setup: project init, dependencies, linting, feature flags
   → Tests: contract tests, social scenario tests, AI behavior tests
   → Core: models, services, availability matching, AI integration
   → Real-time: WebSocket, push notifications, presence
   → Privacy: availability encryption, data protection
   → Polish: performance validation, dogfooding, brand voice
5. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
6. Number tasks sequentially (T001, T002...)
7. Generate dependency graph
8. Create parallel execution examples
9. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
10. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- **NEW**: Each task includes inline context card (see examples below)

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

---

## Implementation Context

### FR → Task Mapping

**This table shows which tasks implement which functional requirements from spec.md**

| FR ID | Requirement Summary | Implementing Tasks | Test Coverage |
|-------|---------------------|-------------------|---------------|
| FR-001 | [Summary from spec] | T001, T012 | contract/test_xxx.py |
| FR-002 | [Summary from spec] | T003, T015 | integration/test_yyy.py |
| ... | ... | ... | ... |

**Coverage Check**: Every FR MUST have at least one implementing task. Every task SHOULD reference at least one FR.

### Research Decisions Reference

**Key technical decisions from plan.md (with embedded research) that affect implementation**:

1. **[Decision Name]** (affects T005, T014, T027)
   - **Why**: [Rationale from research]
   - **How**: [Implementation pattern/code example]
   - **Performance**: [Benchmark or target]

2. **[Decision Name]** (affects T012, T023)
   - **Why**: [Rationale]
   - **How**: [Pattern]
   - **Security**: [Requirement]

(List 3-5 critical research decisions with implementation implications)

### Codebase Patterns to Reuse

**Components and patterns that ALREADY EXIST - do NOT recreate**:

| Pattern/Component | Location | Reuse in Tasks | DON'T Do |
|-------------------|----------|----------------|----------|
| PhoneInput | design-system/PhoneInput.tsx:589-694 | T019 | Create custom phone input |
| SMSOTPForm | components/auth/SMSOTPForm.tsx | T019 | Recreate OTP form |
| Debounced search | pages/onboarding/UserInfoEntry.tsx:198-252 | T023 | Custom debounce logic |

### Performance Targets

| Target | Technique | Tasks | Validation |
|--------|-----------|-------|------------|
| <100ms search | Use existing GIN index | T012, T023 | Performance test |
| <2s matching | Batch processing | T005, T014 | Integration test |

### Security Requirements

| Requirement | Implementation | Tasks | Checklist |
|-------------|----------------|-------|-----------|
| Client hashing | crypto.subtle.digest | T005 | [ ] No CryptoJS, [ ] Pepper included |
| Rate limiting | 100/minute limit | T004, T014 | [ ] Uses rate_limit.py |

### Design System Components

| Component | Use For | Tasks |
|-----------|---------|-------|
| Button | CTAs | T018, T023, T031 |
| PhoneInput | Phone entry | T019 |
| Dialog | Modals | T019, T020 |
| InfoBox | Progress | T019, T023 |

### Brand Voice Examples

**Copy to use in this feature**:
- "Find friends" (not "Add users")
- "Finding your friends..." (not "Loading...")
- "Connection request sent! 🎉" (not "Request submitted")

---

### Phase 1: Setup
- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

## Enhanced Task Description Format

**OLD FORMAT** (context-less):
```markdown
- [ ] T014 Implement contact matching service in backend/src/services/contact_matching.py
```

**NEW FORMAT** (context-rich):
```markdown
- [ ] T014 Implement privacy-preserving contact matching service

**Implements**: FR-006 (display phone contacts), FR-010 (display email contacts)

**Pattern**: Two-layer async session management (codebase-scan-user.md:206-268)
  - Public: `match_contacts(hashes, contact_type, db=None)`
  - Internal: `_match_contacts_with_session(hashes, contact_type, db)`

**Research** (research-report-privacy-contact-matching.md):
  - Use SHA-256 hashes (client already peppered)
  - Query: `SELECT user_id FROM user_contact_hashes WHERE hash = ANY(?)`
  - Rate limit: 100 contacts/minute (use rate_limit.py)
  - NO plaintext storage

**Performance** (spec.md NFR):
  - Target: <500ms for 1000 contacts
  - Optimization: Batch SELECT with ANY(?)
  - Validation: Integration test with mock 1000 contacts

**Testing**: Contract test (test_connections_discover_contacts.py)
  - Validates schema from contracts/connections-discovery.yaml
  - Checks privacy: returns user IDs only
  - Validates rate limiting: 429 after limit

**File**: `backend/src/services/contact_matching.py`
```

**Use this format for ALL tasks** (minimum: Implements, Pattern/Research note, File path)

---

### Phase 2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE Phase 3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Contract Tests (Example Format)

- [ ] T004 [P] Contract test: POST /availability endpoint

**Implements**: FR-002 (availability input), validates contract

**Pattern**: Contract test pattern from codebase-scan-auth.md:544-626
```python
@pytest.mark.asyncio
async def test_endpoint_schema(client):
    response = await client.post("/v1/availability", json={...})
    assert response.status_code in [200, 201]
    assert "id" in response.json()
```

**File**: `tests/contract/test_availability.py`

---

### Integration Tests (Example Format)

- [ ] T006 [P] Integration test: Phone contact discovery with inline verification

**Implements**: FR-004 (phone verification), FR-006 (display contacts)  
**Scenario**: From quickstart.md Scenario 1

**Test Flow**:
1. User with no phone_verified attempts phone discovery
2. System shows inline verification modal (not navigation)
3. User completes verification
4. Contact list appears with matches

**File**: `tests/integration/test_phone_discovery_flow.py`

---

### Performance Tests (Example Format)

- [ ] T009 [P] Performance test: Username search <100ms

**Implements**: NFR from spec.md:139  
**Constitutional Mandate**: Real-time Performance principle

**Test**:
```python
def test_username_search_performance():
    # Create 10,000 test users
    # Search with prefix
    start = time.time()
    results = search_username("test")
    duration = time.time() - start
    assert duration < 0.1  # <100ms
```

**Validates**: GIN index usage, LIMIT optimization

**File**: `tests/performance/test_username_search.py`

### Phase 3: Core Implementation (ONLY after tests are failing)

### Backend Implementation (Example Format)

- [ ] T010 [P] Create ConnectionRequest model with normalized user pairs

**Implements**: FR-014 (connection requests), FR-015 (pending state)

**Pattern**: Single-table schema from research-report-connection-schema.md
```python
# Use LEAST/GREATEST for bidirectional normalization
user_low = Column(UUID, Computed("LEAST(user_a_id, user_b_id)"))
user_high = Column(UUID, Computed("GREATEST(user_a_id, user_b_id)"))

# Unique constraint prevents duplicates in either direction
__table_args__ = (
    UniqueConstraint("user_low", "user_high", name="unique_user_pair"),
    CheckConstraint("user_a_id <> user_b_id", name="no_self_connection"),
)
```

**Research**: Prevents duplicate requests even under race conditions (ON CONFLICT DO NOTHING)

**Testing**: Contract test validates unique constraint, integration test validates race condition handling

**File**: `backend/src/models/connection_request.py`

---

- [ ] T012 Implement username search endpoint with <100ms response

**Implements**: FR-012 (real-time search), FR-013 (public discovery)

**Pattern**: Use existing GIN index (codebase-scan-user.md:344-348)
```python
# DON'T create new index - it already exists!
stmt = select(User).where(
    func.lower(User.username).like(func.lower(search) + '%')
).limit(20)  # Important: LIMIT prevents over-fetch
```

**Performance** (spec.md:139, Constitutional mandate):
  - Target: <100ms response time
  - Technique: GIN trigram index on username_lower (ALREADY EXISTS!)
  - Optimization: LIMIT 20, check discoverable_by_username privacy toggle

**Research** (research-report-postgresql-search.md):
  - B-tree index achieves <100ms for millions of users
  - No need for Redis caching at current scale
  - Debounce client-side (500ms) to reduce load

**Testing**: 
  - Contract test: validates schema
  - Performance test: validates <100ms with 10k users

**File**: `backend/src/api/v1/connections.py` (endpoint: GET /discover/username)

---

### Frontend Implementation (Example Format)

- [ ] T019 Create inline phone verification component

**Implements**: FR-004 (phone verification required), FR-017 (inline verification)

**Pattern**: Reuse existing components (DON'T recreate!)
  - Import PhoneInput from design-system (scan-design-system.md:589-694)
  - Import SMSOTPForm from components/auth (scan-auth.md:798-833)
  - Wrap in Dialog modal (from design system)

**Implementation**:
```typescript
import { PhoneInput, getE164PhoneNumber } from '@/design-system';
import { SMSOTPForm } from '@/components/auth/SMSOTPForm';
import { Dialog } from '@/design-system';

// State-driven UI (send → verify) - NO navigation!
const [step, setStep] = useState<'input' | 'verify'>('input');

<Dialog open={showVerify} title="Verify your phone">
  {step === 'input' ? (
    <PhoneInput
      value={phone}
      onChange={setPhone}
      countryCode="NO"
    />
  ) : (
    <SMSOTPForm 
      onSuccess={() => {
        setShowVerify(false);  // Close modal
        refreshUser();  // Update phone_verified
      }}
    />
  )}
</Dialog>
```

**Brand Voice** (scan-design-system.md:386-433):
  - Title: "Verify your phone" (not "Phone Verification Required")
  - Progress: Use InfoBox with "This usually arrives in a few seconds..."
  - Success: "You're all set! 🎉"

**Testing**: Component test validates PhoneInput integration, modal behavior, no navigation

**File**: `frontend/src/components/connections/PhoneVerification.tsx`

---

- [ ] T023 Create real-time username search component with <100ms UX

**Implements**: FR-012 (real-time search)

**Pattern**: Debounced search with AbortController (scan-user.md:198-252)
```typescript
useEffect(() => {
  const controller = new AbortController();
  const timer = setTimeout(async () => {
    if (query.length >= 3) {
      const results = await searchUsername(query, controller.signal);
      if (!controller.signal.aborted) setResults(results);
    }
  }, 500);  // 500ms debounce (tested optimal)
  
  return () => {
    clearTimeout(timer);
    controller.abort();  // Cancel in-flight requests
  };
}, [query]);
```

**Design System**:
  - Use Input for search field
  - Use Button intent="primary" for "Send Request"
  - Show InfoBox variant="accent" during search

**Performance** (spec.md:139):
  - Target: <100ms backend response
  - Debounce: 500ms to reduce API calls
  - Loading state: Show during search

**Brand Voice**: Helper text: "Search by username..." (encouraging)

**File**: `frontend/src/components/connections/UsernameSearch.tsx`

### Phase 4: Integration & External Services
- [ ] T018 [CUSTOMIZE: External service integration task]
- [ ] T019 [CUSTOMIZE: Third-party API integration task]
- [ ] T020 [CUSTOMIZE: Data sync/import task]
- [ ] T021 [CUSTOMIZE: Additional integration task]

### Phase 5: Polish & Validation
- [ ] T022 [P] Brand voice audit: copy matches design-system.md guidelines
- [ ] T023 [P] UX validation: matches ux-strategy.md principles
- [ ] T024 Performance validation: all targets from context.md met
- [ ] T025 [P] Accessibility audit: WCAG 2.1 AA compliance
- [ ] T026 [P] Security audit: privacy requirements verified

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T015
- Implementation before polish (T022-T026)

## Parallel Example
```
# Launch T004-T007 together:
Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
Task: "Integration test registration in tests/integration/test_registration.py"
Task: "Integration test auth in tests/integration/test_auth.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks with privacy considerations
- [ ] Social scenario tests defined for core user journeys
- [ ] AI behavior tests included for suggestion quality
- [ ] Performance tests validate project targets (e.g., <100ms, <2s, <3s if defined)
- [ ] Privacy tests ensure availability never exposed
- [ ] Real-time components have WebSocket/notification tasks
- [ ] Dogfooding tasks included for social validation
- [ ] Brand voice and frictionless UX tasks present
- [ ] Feature flag tasks for gradual rollout
- [ ] All tests come before implementation (TDD)
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task