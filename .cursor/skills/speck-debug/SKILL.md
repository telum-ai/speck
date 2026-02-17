---
name: speck-debug
description: Diagnose and resolve any error by structured analysis, treating errors as learning opportunities
disable-model-invocation: false
---

---
description: Diagnose and resolve any error by structured analysis, treating errors as learning opportunities.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

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
- Unclear edge cases
- Vague user story description

**2. Context Engineering Issue** (Critical information was missing or stale):
- Missing file/code that was needed
- Stale information from previous context
- Too much irrelevant context causing confusion
- Missing constraints or rules

**3. Technical Issue** (Implementation bug or gap):
- Actual code bug
- Missing dependency
- Environment mismatch
- API misuse

### Step 3: Diagnose the Specific Cause

**For Prompt Issues**:
- Review the original spec/plan that led to this code
- Identify which requirement was ambiguous
- Check if acceptance criteria covered this case

**For Context Issues**:
- What files were NOT in context when error occurred?
- What information should have been loaded?
- Is there context rot (too much accumulated context)?

**For Technical Issues**:
- What specific line/file has the bug?
- What was the intended behavior vs actual?
- Are there similar patterns elsewhere that work?

### Step 4: Generate Targeted Fix

Based on diagnosis, create a specific fix:

**If Prompt Issue**:
```markdown
## Fix: Update Spec/Plan
The ambiguity was: [describe]
Add to spec.md:
- [ ] Clarify: [specific requirement]
- [ ] Add acceptance criteria: [specific scenario]
```

**If Context Issue**:
```markdown
## Fix: Load Required Context
Missing context: [list files/information]
Action: Read and incorporate:
- [ ] File: [path]
- [ ] Information: [what was needed]
```

**If Technical Issue**:
```markdown
## Fix: Code Change
Location: [file:line]
Problem: [description]
Solution: [specific change]
```

### Step 5: Document Learning (Optional Quick Capture)

If this error reveals a pattern worth capturing:

```markdown
## Quick Learning

**Type**: [GOTCHA | PATTERN | RULE | ARCH]

**Summary**: [One-line description]

**Details**: [Brief explanation of the learning]

**Prevention**: [How to avoid this in the future]
```

Suggest running `/speck-learn` to properly capture this learning for future reference.

### Step 6: Apply Fix and Verify

1. Apply the identified fix
2. Re-run the failed operation
3. Verify the error is resolved
4. If error persists, return to Step 2 with new information

## Error Categories Quick Reference

| Error Type | Common Causes | Typical Fix |
|-----------|---------------|-------------|
| Compilation | Missing imports, syntax | Load file context, fix syntax |
| Runtime | Null/undefined, type mismatch | Add guards, check types |
| Test Failure | Spec mismatch, setup issue | Update test or implementation |
| Spec Mismatch | Ambiguous requirements | Clarify spec, add scenarios |
| Implementation Drift | Missing plan context | Reload plan.md, re-align |

## Context Management Tip

If you suspect context rot (accumulated stale context causing confusion):

1. Prompt the user: "I recommend running `/summarize` to compact context"
2. After summarize, reload only the essential files:
   - Current spec.md
   - Current plan.md  
   - Specific file(s) being worked on
3. Re-attempt the operation with fresh, focused context

## Output Summary

```
🔍 Debug Analysis Complete

Error: [Brief description]
Root Cause: [Prompt | Context | Technical] Issue
Diagnosis: [Specific cause]

Fix Applied:
- [What was changed]

Verification:
- [Result of re-running operation]

Learning Captured: [Yes/No - suggest /speck-learn if valuable]
```

---

**Philosophy**: Every error is a learning opportunity. This structured approach ensures we diagnose correctly, fix precisely, and capture insights for future improvement.
