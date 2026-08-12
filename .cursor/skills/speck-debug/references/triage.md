# speck-debug / triage

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).



## Purpose

When an error occurs - whether in code generation, spec creation, or any other task - this command provides a structured approach to diagnose the root cause and create a targeted fix. Based on the principle that **any AI-generated error is traceable to a user/context issue**.

## When to Use

- Code doesn't compile or throws runtime errors
- Tests fail unexpectedly
- Generated spec doesn't match expectations
- Implementation deviates from plan
- Any confusion or unexpected behavior from the AI

## Debug Process

### Step 1: Capture the Error Context

**Document the current state**:
```
Error Type: [Compilation | Runtime | Test Failure | Spec Mismatch | Implementation Drift | Other]
Error Message: [Exact error text or description]
What Was Attempted: [The action that produced the error]
Expected Outcome: [What should have happened]
Actual Outcome: [What actually happened]
```

**Ask clarifying questions if error context is unclear**:
- "Can you paste the exact error message?"
- "What command or action triggered this?"
- "What were you expecting to happen?"

### Step 2: Analyze Root Cause Categories

Errors typically fall into three categories:

**1. Prompt Engineering Issue** (User didn't express clearly what they wanted):
- Ambiguous requirements in spec
- Missing acceptance criteria
