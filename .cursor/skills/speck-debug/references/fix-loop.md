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

Re-run the failing operation after the fix. Update binding artifacts when truth changed; use `/speck-learn` only for a reusable discovery.
