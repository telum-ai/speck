# Implementation Plan: S010 API Documentation

## Technical Approach

Use swagger-jsdoc with swagger-ui-express:

```typescript
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const specs = swaggerJsdoc({
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Greeting API',
      version: '1.0.0',
    },
  },
  apis: ['./src/routes/*.ts'],
});

app.use('/docs', swaggerUi.serve, swaggerUi.setup(specs));
```

## Files to Create/Modify

| File | Action |
|------|--------|
| `src/swagger.ts` | Create |
| `src/routes/greet.ts` | Add JSDoc comments |
| `src/index.ts` | Register /docs route |
