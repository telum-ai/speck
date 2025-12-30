# Data Model: Greeting Service

## Overview

The greeting service is a pure function with no persistent state. This document defines the input/output data contracts.

## Function Signature

```typescript
function greet(name: string): string
```

## Input Data

### Parameter: name

| Property | Type | Required | Constraints | Description |
|----------|------|----------|-------------|-------------|
| name | string | Yes | Any string | Name to include in greeting |

**Validation Rules**:
- Empty string → treated as no name provided
- Whitespace-only string → treated as no name provided
- `null`/`undefined` → treated as no name provided
- Non-empty, non-whitespace string → used in greeting

**Normalization**:
- Input is trimmed of leading/trailing whitespace
- After trimming, empty strings trigger default behavior

## Output Data

### Return Value: greeting

| Property | Type | Format | Description |
|----------|------|--------|-------------|
| greeting | string | "Hello, {name}!" or "Hello, stranger!" | Personalized greeting message |

**Output Rules**:
- If valid name provided: `"Hello, {name}!"`
- If no valid name: `"Hello, stranger!"`

## State Management

**Stateless**: This function has no side effects and maintains no state.

- No database interactions
- No external API calls
- No file I/O
- No global variables
- Pure function: same input always produces same output

## Examples

| Input | Output |
|-------|--------|
| `"Alice"` | `"Hello, Alice!"` |
| `"Bob Smith"` | `"Hello, Bob Smith!"` |
| `""` | `"Hello, stranger!"` |
| `"   "` | `"Hello, stranger!"` |
| `null` | `"Hello, stranger!"` |
| `undefined` | `"Hello, stranger!"` |
