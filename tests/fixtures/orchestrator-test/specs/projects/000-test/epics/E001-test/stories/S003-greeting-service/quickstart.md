# Quickstart: Greeting Service

## Overview

This document provides test scenarios to validate the greeting service implementation.

## Setup

```bash
# No setup required - pure function with no dependencies
```

## Test Scenarios

### Scenario 1: Greet with Valid Name

**Objective**: Verify greeting with a valid name

**Steps**:
1. Import the `greet` function
2. Call `greet("Alice")`
3. Verify the response is `"Hello, Alice!"`

**Expected Result**:
```typescript
const result = greet("Alice");
expect(result).toBe("Hello, Alice!");
```

**Pass Criteria**: Output exactly matches `"Hello, Alice!"`

---

### Scenario 2: Greet with Empty Name

**Objective**: Verify default greeting for empty string

**Steps**:
1. Import the `greet` function
2. Call `greet("")`
3. Verify the response is `"Hello, stranger!"`

**Expected Result**:
```typescript
const result = greet("");
expect(result).toBe("Hello, stranger!");
```

**Pass Criteria**: Output exactly matches `"Hello, stranger!"`

---

### Scenario 3: Greet with Whitespace-Only Name

**Objective**: Verify default greeting for whitespace-only input

**Steps**:
1. Import the `greet` function
2. Call `greet("   ")`
3. Verify the response is `"Hello, stranger!"`

**Expected Result**:
```typescript
const result = greet("   ");
expect(result).toBe("Hello, stranger!");
```

**Pass Criteria**: Output exactly matches `"Hello, stranger!"`

---

### Scenario 4: Greet with Null/Undefined

**Objective**: Verify handling of null/undefined inputs

**Steps**:
1. Import the `greet` function
2. Call `greet(null)` and `greet(undefined)`
3. Verify both return `"Hello, stranger!"`

**Expected Result**:
```typescript
expect(greet(null as any)).toBe("Hello, stranger!");
expect(greet(undefined as any)).toBe("Hello, stranger!");
```

**Pass Criteria**: Both calls return `"Hello, stranger!"`

---

## Performance Validation

### Scenario 5: Response Time

**Objective**: Verify response time < 5ms (per NFR-001)

**Steps**:
1. Call `greet("Alice")` 1000 times
2. Measure average execution time
3. Verify average < 5ms

**Expected Result**:
- Average execution time < 5ms
- Typically < 0.01ms for pure function

**Pass Criteria**: Average response time under target

---

## Validation Checklist

- [ ] Valid name returns personalized greeting
- [ ] Empty string returns default greeting
- [ ] Whitespace-only returns default greeting
- [ ] Null/undefined handled gracefully
- [ ] Response time meets NFR-001 target
- [ ] Function is stateless (no side effects)
- [ ] All acceptance scenarios pass
