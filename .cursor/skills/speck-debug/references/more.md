# speck-debug / more

## Context Management Tip

If you suspect context rot (accumulated stale context causing confusion):

1. Prompt the user: "I recommend running `/summarize` to compact context"
2. After summarize, reload only the essential files:
   - Current spec.md
   - Current plan.md  
   - Specific file(s) being worked on
3. Re-attempt the operation with fresh, focused context

## Purpose

When an error occurs - whether in code generation, spec creation, or any other task - this command provides a structured approach to diagnose the root cause and create a targeted fix. Based on the principle that **any AI-generated error is traceable to a user/context issue**.

## When to Use

- Code doesn't compile or throws runtime errors
- Tests fail unexpectedly
- Generated spec doesn't match expectations
- Implementation deviates from plan
- Any confusion or unexpected behavior from the AI

## Fix: Code Change
Location: [file:line]
Problem: [description]
Solution: [specific change]
```

### Step 5: Document Learning (Optional Quick Capture)

If this error reveals a pattern worth capturing:

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
