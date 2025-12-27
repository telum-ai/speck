# Implementation Plan: S005 Add Request Validation

## Technical Approach

### Validation Middleware

Create validation middleware using express-validator:

```typescript
import { query, validationResult } from 'express-validator';

export const validateGreetRequest = [
  query('name')
    .optional()
    .isString()
    .isLength({ max: 100 })
    .escape(),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
];
```

## Testing Strategy

- Unit tests for validation rules
- Integration tests for error responses

## Files to Create/Modify

| File | Action |
|------|--------|
| `src/middleware/validation.ts` | Create |
| `src/routes/greet.ts` | Modify |
