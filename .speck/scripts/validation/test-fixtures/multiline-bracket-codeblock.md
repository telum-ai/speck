# Epic Tech Spec Fixture

```ts
const sensitiveFields = [
  // Norwegian-specific
  'fodselsnummer', 'fnr', 'personnummer',
  // Art. 9 health-data
  'healthNote', 'health_note', 'injury', 'injuryDescription',
  // Payment + secrets
  'cardNumber', 'cvv', 'vippsToken', 'paymentToken',
  'apiKey', 'serviceRoleKey', 'jwtSecret',
];
```

This file should pass placeholder validation because the multi-line bracket span is inside a fenced code block.
