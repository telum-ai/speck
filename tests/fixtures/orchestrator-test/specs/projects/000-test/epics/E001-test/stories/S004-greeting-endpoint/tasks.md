---
# Story dependency declaration for autonomous orchestration
# The orchestrator reads this to determine execution order
depends_on: [S001-project-setup, S002-express-config, S003-greeting-service]
blocks: [S005-input-validation]
---

# Tasks: S004 Create /greet Endpoint

**Input**: Design documents from `tests/fixtures/orchestrator-test/specs/projects/000-test/epics/E001-test/stories/S004-greeting-endpoint/`
**Prerequisites**: spec.md (required), plan.md (required)

## Execution Flow (main)
```
1. Load spec.md and plan.md from story directory
   → Extract: tech stack (Express, TypeScript), structure
2. From spec.md:
   → Extract: FR-001 to FR-004 (endpoint, params, response, service integration)
   → Extract: NFR-001 (response time <100ms), NFR-002 (HTTP status codes)
3. Generate tasks by category:
   → Setup: N/A (covered by dependencies)
   → Tests: contract tests for endpoint scenarios
   → Core: route handler, service integration
   → Integration: register route in Express app
   → Polish: N/A (validation covered in acceptance criteria)
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Validate task completeness:
   → All acceptance scenarios have tests? ✓
   → All endpoints implemented? ✓
   → Service integration? ✓
7. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- Single project structure: `src/`, `tests/` at repository root
- Test paths are relative to story directory for this test fixture

---

## Implementation Context

### FR → Task Mapping

**This table shows which tasks implement which functional requirements from spec.md**

| FR ID | Requirement Summary | Implementing Tasks | Test Coverage |
|-------|---------------------|-------------------|---------------|
| FR-001 | Endpoint at GET /greet | T002, T003 | T001 |
| FR-002 | Accept name query parameter | T002 | T001 |
| FR-003 | Return JSON with message field | T002 | T001 |
| FR-004 | Use greeting service for message | T002 | T001 |

**Coverage Check**: All FRs have implementing tasks and test coverage ✓

### Research Decisions Reference

**Key technical decisions from plan.md that affect implementation**:

1. **Express Router Pattern** (affects T002)
   - **Why**: Separation of concerns, modularity
   - **How**: Create dedicated route handler in `src/routes/greet.ts`
   - **Pattern**: Import Router, define route, export router

2. **Greeting Service Integration** (affects T002)
   - **Why**: Business logic separation (from S003-greeting-service)
   - **How**: Import greet function from `../services/greeting`
   - **Pattern**: Service provides pure function, route handles HTTP

3. **Query Parameter Handling** (affects T002)
   - **Why**: Express query parsing, default handling
   - **How**: `req.query.name as string || ''` provides fallback
   - **Pattern**: Type cast and default value for optional params

### Codebase Patterns to Reuse

**Components and patterns that SHOULD EXIST from dependencies**:

| Pattern/Component | Expected Location | Reuse in Tasks | Dependencies |
|-------------------|-------------------|----------------|--------------|
| greeting service | src/services/greeting.ts | T002 | S003-greeting-service |
| Express app | src/index.ts | T003 | S002-express-config |
| TypeScript config | tsconfig.json | All tasks | S001-project-setup |

### Performance Targets

| Target | Technique | Tasks | Validation |
|--------|-----------|-------|------------|
| <100ms response | Simple service call, no I/O | T002 | T001 (acceptance test) |

### Non-Functional Requirements

| Requirement | Implementation | Tasks | Checklist |
|-------------|----------------|-------|-----------|
| Appropriate status codes | Use 200 for success | T002 | [ ] Returns 200 OK |
| JSON response | Use res.json() | T002 | [ ] Content-Type: application/json |

---

## Phase 1: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE Phase 2

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [ ] T001 [P] Create route acceptance tests for /greet endpoint scenarios

**Implements**: FR-001 (GET /greet), FR-002 (name param), FR-003 (JSON response), FR-004 (service integration)

**Scenarios**: From spec.md acceptance criteria
1. Successful greeting with name parameter
2. Default greeting without name parameter

**Test Pattern**:
```typescript
import request from 'supertest';
import app from '../src/index';

describe('GET /greet', () => {
  it('should return personalized greeting with name parameter', async () => {
    const response = await request(app)
      .get('/greet?name=World')
      .expect(200)
      .expect('Content-Type', /json/);
    
    expect(response.body).toEqual({ message: 'Hello, World!' });
  });

  it('should return default greeting without name parameter', async () => {
    const response = await request(app)
      .get('/greet')
      .expect(200)
      .expect('Content-Type', /json/);
    
    expect(response.body).toEqual({ message: 'Hello, stranger!' });
  });
});
```

**Performance**: Validates <100ms response time (NFR-001)

**File**: `src/routes/greet.test.ts` (within test fixture structure)

## Phase 2: Core Implementation (ONLY after tests are failing)

- [ ] T002 Create /greet route handler with greeting service integration

**Implements**: FR-001 (endpoint), FR-002 (name param), FR-003 (JSON response), FR-004 (service integration)

**Pattern**: Express Router with service layer
```typescript
import { Router } from 'express';
import { greet } from '../services/greeting';

const router = Router();

router.get('/greet', (req, res) => {
  const name = req.query.name as string || '';
  const message = greet(name);
  res.json({ message });
});

export default router;
```

**Service Integration**: 
- Import greet function from S003-greeting-service
- Pass name parameter (empty string for missing param)
- Service handles "stranger" default

**Response**: 
- Use res.json() for proper JSON response (FR-003)
- Returns 200 OK by default (NFR-002)

**Testing**: T001 validates endpoint behavior

**File**: `src/routes/greet.ts`

## Phase 3: Integration

- [ ] T003 Register /greet route in Express application

**Implements**: FR-001 (make endpoint available)

**Pattern**: Route registration in main app
```typescript
import greetRouter from './routes/greet';
app.use('/', greetRouter);
```

**Integration Points**:
- Import router from T002
- Use app.use() to register at root path
- Route path is already /greet in router definition

**Testing**: T001 tests against full app instance

**File**: `src/index.ts` (modify existing from S002-express-config)

## Dependencies

- T001 must fail before T002 (TDD)
- T002 before T003 (route must exist before registration)
- All tasks depend on: S001, S002, S003

## Parallel Example

Only T001 can run independently (different file, test setup):
```
# Initial setup:
Task T001: Write failing acceptance tests in src/routes/greet.test.ts

# After tests fail (sequential):
Task T002: Implement route handler in src/routes/greet.ts
Task T003: Register route in src/index.ts
```

## Notes

- [P] only on T001 (independent test creation)
- T002 and T003 are sequential (implementation order matters)
- This is a TEST STORY - work stays in test fixture directory
- Verify tests fail before implementing (TDD validation)
- Simple implementation (<100 lines total)
- No external services or database

## Validation Checklist

*GATE: Checked before marking story complete*

- [ ] All FRs have corresponding tasks (✓ 4/4)
- [ ] All acceptance scenarios have tests (✓ 2/2)
- [ ] Service integration validated
- [ ] Performance target achievable (<100ms)
- [ ] All tests come before implementation (TDD)
- [ ] Task file paths specified
- [ ] Dependencies correctly declared in YAML front matter
