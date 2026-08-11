# epic-validate / mutation

## 10. Mutation (epic-cited guards)

Same rules as story-validate. **Merged-tree rule**: mutation SHA = merge commit; conductor re-runs in merged tree. Worktree-branch SHA = finding.

Receipt verify:
```bash
.speck/scripts/validation/mutate-guard.sh --verify-receipt [EPIC_DIR]/epic-validation-report.md
```
