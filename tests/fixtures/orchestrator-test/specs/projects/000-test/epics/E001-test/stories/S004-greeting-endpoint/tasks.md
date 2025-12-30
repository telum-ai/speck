---
depends_on: [S001-project-setup, S002-express-config, S003-greeting-service]
blocks: []
---

# Tasks: S004 Create /greet Endpoint

**Input**: Design documents from story directory
**Prerequisites**: spec.md (required), plan.md (required)

## Implementation Context

### FR → Task Mapping

| FR ID | Requirement Summary | Implementing Tasks | Test Coverage |
|-------|---------------------|-------------------|---------------|
| FR-001 | Endpoint SHALL be available at GET /greet | T003 | tests/routes/greet.test.ts |
| FR-002 | Endpoint SHALL accept `name` as query parameter | T003 | tests/routes/greet.test.ts |
| FR-003 | Endpoint SHALL return JSON response with `message` field | T003 | tests/routes/greet.test.ts |
| FR-004 | Endpoint SHALL use the greeting service | T003 | tests/routes/greet.test.ts |

### Research Decisions Reference

1. **Express Router Pattern** (affects T003, T004)
   - **Why**: Modular route organization
   - **How**: Create separate router file and register in main app
   - **Performance**: Minimal overhead, <100ms target

### Phase 1: Setup

No setup tasks needed - project already configured by dependencies.

### Phase 2: Tests First (TDD)

- [x] T001 [P] Create route test file

**Implements**: FR-001, FR-002, FR-003, FR-004

**Pattern**: Express route testing with supertest
```typescript
import request from 'supertest';
import app from '../../src/index';

describe('GET /greet', () => {
  it('returns greeting with name parameter', async () => {
    const response = await request(app).get('/greet?name=World');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'Hello, World!' });
  });

  it('returns default greeting without name parameter', async () => {
    const response = await request(app).get('/greet');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'Hello, stranger!' });
  });
});
```

**File**: `tests/routes/greet.test.ts`

### Phase 3: Core Implementation

- [x] T002 [P] Create greet route handler

**Implements**: FR-001, FR-002, FR-003, FR-004

**Pattern**: Express router with service integration (from plan.md)
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

**Testing**: Tests from T001 validate this implementation

**File**: `src/routes/greet.ts`

- [x] T003 Register route in main application

**Implements**: Integration of FR-001

**Pattern**: Route registration in Express app
```typescript
import greetRouter from './routes/greet';
app.use('/', greetRouter);
```

**File**: `src/index.ts` (modify)

### Phase 4: Integration & External Services

No external integration needed for this simple endpoint.

### Phase 5: Polish & Validation

- [x] T004 [P] Verify response time meets NFR-001 (<100ms)

**Implements**: NFR-001

**Pattern**: Performance validation
- Run tests with timing checks
- Verify endpoint responds in <100ms

**File**: Manual verification during testing

## Dependencies
- Tests (T001) before implementation (T002, T003)
- T002 must complete before T003 (route must exist before registration)

## Parallel Example
```
# T001 and T002 can run in parallel (different files)
Task T001: tests/routes/greet.test.ts
Task T002: src/routes/greet.ts
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- T003 depends on T002 (cannot register non-existent route)
