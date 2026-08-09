# speck-debug / debug-process

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
