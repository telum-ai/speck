---
name: speck-learn
description: Load to capture a quick learning, pattern, or insight outside the formal retrospective process. Use for mid-story discoveries, surprising gotchas, or performance insights that shouldn't wait until story completion.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

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

**Prevention/Application**:
[How to use this going forward]
```

### Step 3: Determine Scope and Application

**Immediate Application** (apply now if clearly applicable):

1. **If RULE type**: 
   - Check if `.cursor/rules/` has relevant rule file
   - Propose specific update to rule
   - Ask: "Should I update this rule now?"

2. **If PATTERN/ARCH type**:
   - Check if similar work is happening in current epic
   - Propose update to epic-architecture.md or future story specs
   - Ask: "Should I apply this to related work?"

3. **If GOTCHA type**:
   - Check for future stories that might hit same issue
   - Propose spec updates with warnings
   - Ask: "Should I warn other affected specs?"

4. **If PERF type**:
   - Document in current story's plan or validation-report
   - Note for performance testing strategy

5. **If DEBT type**:
   - Create TODO comment in code
   - Add to technical debt log if exists

### Step 4: Persist Learning

**Option A: Commit Tag** (for learnings during implementation):
```bash
# Add to next commit message body:
[TYPE]: [Summary] - [Brief details]

# Example:
GOTCHA: Timezone must be normalized before comparison - PostgreSQL stores in UTC
```

**Option B: Direct Rule Update** (for RULE types with user approval):
- Update the specific .mdc file
- Commit with: `chore(rules): [description of rule update]`

### Step 5: Output Confirmation

```
📚 Learning Captured!

Type: [TYPE]
Summary: [One-line summary]

Applied To:
- [List of files/specs updated, or "Will appear in story retro"]

Next Commit Should Include:
[TYPE]: [Summary]

Related Work Notified:
- [List of future stories/specs warned, or "None applicable"]
```

## Integration with Retrospectives

Learnings captured via `/speck-learn`:
- Will be picked up by `/story-retrospective` from commit tags
- Contribute to pattern validation (2+ occurrences = validated pattern)
- Flow up through epic → project retrospectives

## Quick Examples

**Example 1: Pattern Discovery**
```
/speck-learn "PostgreSQL window functions are 10x faster than Python loops for time overlap detection"

→ Type: PATTERN
→ Summary: Use window functions for time overlaps
→ Applied: Updated plan.md with pattern note
→ Commit tag: PATTERN: Window functions for time overlaps - 10x faster
```

**Example 2: Gotcha Encountered**
```
/speck-learn "iOS certificate setup requires Apple Developer account and takes 45 minutes"

→ Type: GOTCHA  
→ Summary: iOS cert requires Apple Developer account - 45min setup
→ Applied: Updated Story S003 (also iOS) with time warning
→ Commit tag: GOTCHA: iOS cert requires Apple Developer account - 45min setup
```

**Example 3: Rule Update Needed**
```
/speck-learn "Always run VACUUM ANALYZE after bulk inserts in PostgreSQL"

→ Type: RULE
→ Summary: VACUUM ANALYZE after bulk inserts
→ Applied: Updated .cursor/rules/database.mdc
→ Commit: chore(rules): add VACUUM ANALYZE requirement after bulk inserts
```

---

**Position in Flow**: Anytime during development  
**Duration**: 2-5 minutes  
**Purpose**: Capture learnings immediately, apply where applicable  
**Relationship to Retros**: Pre-seeds retrospective data, enables validation
