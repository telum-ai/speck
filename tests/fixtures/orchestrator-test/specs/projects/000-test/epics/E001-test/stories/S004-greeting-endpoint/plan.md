# Implementation Plan: S004 Create /greet Endpoint

## Technical Approach

### Phase 1: Route Setup

Create Express route handler in `src/routes/greet.ts`:

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

### Phase 2: Integration

Register route in `src/index.ts`:

```typescript
import greetRouter from './routes/greet';
app.use('/', greetRouter);
```

## Testing Strategy

- Unit test: Mock greeting service, verify route calls it correctly
- Integration test: Full request/response cycle

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/routes/greet.ts` | Create | Route handler |
| `src/index.ts` | Modify | Register route |
| `src/routes/greet.test.ts` | Create | Unit tests |

## Estimated Effort

- Development: 30 minutes
- Testing: 15 minutes
