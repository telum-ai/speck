# Quickstart: Greeting Service

## Purpose
This document provides test scenarios that validate the greeting service implementation against the specification.

## Prerequisites
- Node.js 18+ installed
- Jest test framework configured
- TypeScript compiler configured

## Test Scenarios

### Scenario 1: Greet with Valid Name
**Requirement**: FR-002 (Return greeting in format "Hello, {name}!")

```typescript
import { greet } from '../src/services/greeting-service';

test('greets with valid name', () => {
  const result = greet('Alice');
  expect(result).toBe('Hello, Alice!');
});
```

**Expected Behavior**:
- Input: "Alice"
- Output: "Hello, Alice!"
- Validation: String format matches exactly

### Scenario 2: Greet with Empty Name
**Requirement**: FR-003 (Handle empty names)

```typescript
test('greets with empty name', () => {
  const result = greet('');
  expect(result).toBe('Hello, stranger!');
});
```

**Expected Behavior**:
- Input: "" (empty string)
- Output: "Hello, stranger!"
- Validation: Default greeting returned

### Scenario 3: Greet with Whitespace-Only Name
**Requirement**: FR-003 (Handle empty names)

```typescript
test('greets with whitespace-only name', () => {
  const result = greet('   ');
  expect(result).toBe('Hello, stranger!');
});
```

**Expected Behavior**:
- Input: "   " (whitespace only)
- Output: "Hello, stranger!"
- Validation: Whitespace is trimmed, treated as empty

### Scenario 4: Greet with Undefined
**Requirement**: FR-003 (Handle empty names)

```typescript
test('greets with undefined', () => {
  const result = greet(undefined);
  expect(result).toBe('Hello, stranger!');
});
```

**Expected Behavior**:
- Input: undefined
- Output: "Hello, stranger!"
- Validation: Optional parameter handled correctly

### Scenario 5: Greet with No Arguments
**Requirement**: FR-001, FR-003 (Accept optional name, handle empty)

```typescript
test('greets with no arguments', () => {
  const result = greet();
  expect(result).toBe('Hello, stranger!');
});
```

**Expected Behavior**:
- Input: (no arguments)
- Output: "Hello, stranger!"
- Validation: Optional parameter defaults correctly

### Scenario 6: Performance Check
**Requirement**: NFR-001 (Response time < 5ms)

```typescript
test('executes within performance target', () => {
  const start = performance.now();
  greet('Performance Test');
  const duration = performance.now() - start;
  
  expect(duration).toBeLessThan(5);
});
```

**Expected Behavior**:
- Execution time: < 5ms
- Validation: Performance requirement met

## Running the Tests

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test greeting-service.test.ts
```

## Success Criteria

All tests MUST pass for the story to be considered complete:
- ✅ Scenario 1: Valid name greeting
- ✅ Scenario 2: Empty name handling
- ✅ Scenario 3: Whitespace handling
- ✅ Scenario 4: Undefined handling
- ✅ Scenario 5: No arguments handling
- ✅ Scenario 6: Performance target met

## Acceptance Validation

After implementation, verify:
1. All unit tests pass
2. Code coverage is 100% (single function, easily testable)
3. No linting errors
4. TypeScript compiles without errors
5. Performance target consistently met (<5ms)
