# speck-debug / fix-loop

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
