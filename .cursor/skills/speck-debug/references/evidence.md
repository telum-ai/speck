# speck-debug / evidence

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
