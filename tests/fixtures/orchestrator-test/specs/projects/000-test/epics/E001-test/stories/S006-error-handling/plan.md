# Implementation Plan: S006 Error Handling

## Technical Approach

Create global error handling middleware:

```typescript
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    code: 'INTERNAL_ERROR'
  });
});
```

## Files to Create/Modify

| File | Action |
|------|--------|
| `src/middleware/error-handler.ts` | Create |
| `src/index.ts` | Modify |
