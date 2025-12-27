# Implementation Plan: S007 Integration Tests

## Technical Approach

Use Vitest with supertest for HTTP testing.

```typescript
import { describe, it, expect } from 'vitest';
import request from 'supertest';
import app from '../src/index';

describe('GET /greet', () => {
  it('returns greeting with name', async () => {
    const res = await request(app).get('/greet?name=World');
    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Hello, World!');
  });
});
```

## Files to Create

- `tests/integration/greet.test.ts`
- `vitest.config.ts` (update)
