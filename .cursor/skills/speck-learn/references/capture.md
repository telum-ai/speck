# speck-learn / capture

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).



## Purpose

Capture valuable learnings immediately as they occur, without waiting for the formal retrospective process. This enables just-in-time knowledge capture and immediate application.

## When to Use

- You discovered a useful pattern mid-implementation
- You hit a gotcha worth documenting now
- You found a performance optimization worth remembering
- You made an architecture decision worth recording
- Any "aha moment" that shouldn't wait for retro

## Quick Learning Types

| Type | Description | Example |
|------|-------------|---------|
| **PATTERN** | Reusable code/design pattern | "Use PostgreSQL window functions for time overlaps" |
| **GOTCHA** | Surprise or pitfall to avoid | "iOS cert requires Apple Developer account - 45min setup" |
| **PERF** | Performance insight | "Query reduced from 500ms to 50ms with proper indexing" |
| **ARCH** | Architecture decision | "Chose WebSocket over polling for <2s latency" |
| **RULE** | Cursor rule update needed | "Always VACUUM ANALYZE after bulk inserts" |
| **DEBT** | Technical debt created | "No retry logic - add after validating base functionality" |

## Learning Capture Process

### Step 1: Identify Learning Type

Ask if not provided:
- "What type of learning is this? (PATTERN/GOTCHA/PERF/ARCH/RULE/DEBT)"

### Step 2: Capture Learning Details

Gather the following:
```markdown
## Quick Learning: [Title]

**Type**: [PATTERN | GOTCHA | PERF | ARCH | RULE | DEBT]

**Context**: [Where/when this was discovered]

**Summary**: [One-line description]

**Details**: 
[Fuller explanation of the learning]

**Evidence** (if applicable):
- Before: [previous state/measurement]
- After: [new state/measurement]
