# Automated Template Validation System

## Overview

Speck uses Cursor hooks to automatically validate filled-out templates after each file edit. This provides **immediate feedback** on spec quality without requiring manual validation commands.

## How It Works

### 1. Cursor Hook Triggers

After every file edit, Cursor calls:
```json
{
  "hooks": {
    "afterFileEdit": [
      { "command": "bash ./hooks/after-file-edit.sh" }
    ]
  }
}
```

### 2. Router Script

`after-file-edit.sh` runs Speck’s stable hooks and then dispatches validation via `validate-template.sh`.

**Speck hooks (stable):**
- `log-file-edit.sh` → learning capture
- `validate-template.sh` → routes to validators (below)

**Project extensions (optional):**
- Add scripts to `.cursor/hooks/hooks/hooks.d/afterFileEdit/pre/*.sh` (runs before Speck hooks)
- Add scripts to `.cursor/hooks/hooks/hooks.d/afterFileEdit/post/*.sh` (runs after Speck hooks)

`validate-template.sh` detects file type and routes to appropriate validator:
- `specs/*/spec.md` → `validate-story-spec.sh`
- `specs/*/epic.md` → `validate-epic-spec.sh`
- `specs/*/plan.md` → `validate-story-plan.sh`
- `specs/*/tasks.md` → `validate-story-tasks.sh`
- `specs/*/epic-tech-spec.md` → `validate-epic-tech-spec.sh`

**Note**: The hook router currently **does not** validate `PRD.md` or `validation-report.md` (they are detected but intentionally skipped).

### Dependencies

Hook scripts parse Cursor’s JSON payload using:
- `jq` (preferred), or
- `python3` (fallback)

If neither is available, hooks skip validation/logging gracefully.

### Speck Upgrade Preservation Note

Project-specific hook extensions should live under:
- `.cursor/hooks/hooks/hooks.d/afterFileEdit/**`

These extension points are **preserved by the Speck CLI** during `speck init` / `speck upgrade`
so upgrades won’t overwrite or delete your custom hook scripts.

### 3. Validators

Each validator checks quantitative rules and provides enriched error messages:

**Validation Types**:
- ERROR: Must fix before proceeding (CI fails in `--strict` mode; agents should treat as a gate)
- WARNING: Should fix (best practice violation; does not fail CI by default)
- SUCCESS: Quality check passed

**Enriched Messages**:
```
ERROR: Missing user story format
Fix: Add 'As a [user], I want to [action] so that [benefit]'
     See: .speck/templates/story/story-template.md
```

## Validation Rules

### Story Spec (spec.md)

**Errors**:
- Missing user story format
- No acceptance scenarios

**Warnings**:
- Purpose too brief (<50 chars) or too long (>500 chars)
- No functional requirements
- Requirements missing SHALL/MUST
- Too many scenarios (>5, consider splitting)
- Unresolved [NEEDS CLARIFICATION] markers
- Implementation details in spec
- Missing lifecycle state tracking

### Epic Spec (epic.md)

**Errors**:
- Missing overview/purpose

**Warnings**:
- Overview too brief (<100 chars) or too long (>1000 chars)
- Missing success criteria
- No functional requirements
- Requirements missing SHALL/MUST
- No story count estimate
- Too many stories (>20, consider splitting)
- Unresolved [NEEDS CLARIFICATION] markers
- Missing dependencies section
- Implementation details in spec

### Story Plan (plan.md)

**Errors**:
- Missing technical approach

**Warnings**:
- Approach too brief (<100 chars)
- Data mentioned but no data-model.md
- APIs mentioned but no contracts/
- Complexity without evidence
- Too many new files (>3)
- Missing dependencies
- Missing testing strategy

### Story Tasks (tasks.md)

**Errors**:
- No tasks found

**Warnings**:
- Too many tasks (>20)
- Not organized into phases
- No parallel tasks marked [P]
- No test tasks
- Task ID gaps
- Ambiguous descriptions (TODO/TBD)
- Creating too many files (>3)

## Quantitative Thresholds

Inspired by OpenSpec validation constants:

| Item | Minimum | Maximum | Why |
|------|---------|---------|-----|
| Purpose section | 50 chars | 500 chars | Prevent too brief or too verbose |
| Epic overview | 100 chars | 1000 chars | Ensure adequate but scannable |
| Scenarios per story | 1 | 5 | Too many = multiple stories |
| Stories per epic | 3 | 20 | Too many = multiple epics |
| Tasks per story | 1 | 20 | Too many = story too large |
| New files per story | 0 | 3 | Simplicity-first principle |

## Simplicity-First Enforcement

Validators check for evidence when complexity is added:

**Triggers**:
- Creating >1 file
- Mentioning "abstract", "framework", "pattern"
- Complex architecture

**Requires Evidence**:
- Performance: "Measured X ms, target <Y ms"
- Scale: "Must support N users"
- Abstraction: "Same code in 3+ places"

**Example**:
```
WARNING: Complexity mentioned without evidence
Suggestion: Add performance/scale/abstraction evidence
            See AGENTS.md 'Simplicity-First Principles'
```

## Benefits

### 1. Immediate Feedback
- Validation runs automatically after every save
- No need to remember to run `/story-validate`
- Catch issues during writing, not after

### 2. Prevents Common Mistakes
- Missing user stories
- Specs without acceptance criteria
- Plans without technical approach
- Over-complex solutions without justification

### 3. Enforces Standards
- Normative language (SHALL/MUST)
- Lifecycle state tracking
- GIVEN/WHEN/THEN format
- Quantitative thresholds

### 4. Educates While Working
- "Fix:" guidance shows how to resolve
- References templates and rules
- Explains why it matters

### 5. Non-Blocking
- Warnings don't prevent saves
- Errors guide but don't block
- Progressive improvement

## CI Mode (Strict)

The validator scripts also support a CI-friendly strict mode:

- Running a validator with `--strict` makes it **exit non-zero when errors > 0**
- Hooks run validators **without** `--strict` to remain non-blocking during drafting
- CI runs validators **with** `--strict` to enforce minimum quality gates

**CI Workflow**: See `.github/workflows/speck-validation.yml`

## How to Use

### As AI Agent

When creating/editing specs:
1. Save the file
2. Hook runs automatically
3. Review validation output
4. Address errors/warnings
5. Save again to re-validate

### As Human User

Validation appears in terminal after each save:
```
✓ User story format found
✓ Has 2 acceptance scenario(s)
⚠ WARNING: Purpose section is brief (45 < 50 chars)
   Suggestion: Expand purpose to explain problem/benefit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Errors: 0 | Warnings: 1
Epic spec has warnings. Consider addressing before /epic-plan.
```

## Disabling Validation

If validation is too noisy during drafting:

**Temporarily disable**:
```bash
# Comment out in hooks.json
{
  "afterFileEdit": [
    { "command": "./hooks/log-file-edit.sh" }
    // { "command": "./hooks/validate-template.sh" }
  ]
}
```

**Permanently disable for a file type**:
```bash
# Edit validate-template.sh, add case to skip
case "$filename" in
  epic.md)
    # Skip epic validation during early drafting
    exit 0
    ;;
esac
```

## Extending Validators

### Add New Validator

1. Create `validators/validate-[type].sh`
2. Follow structure from existing validators
3. Add case to `validate-template.sh`
4. Make executable: `chmod +x validators/validate-[type].sh`

### Add New Rule

Edit relevant validator script:
```bash
# Check for new pattern
if echo "$content" | grep -q "pattern"; then
  log_success "Pattern found"
else
  log_warning "Missing pattern" \
    "Add pattern because [reason]
    Example: [how to fix]"
fi
```

## Integration with Commands

Validation complements command validation:

**Hook Validation** (automatic):
- Runs after every edit
- Quantitative checks
- Format validation
- Best practice warnings

**Command Validation** (explicit):
- `/story-validate` - Comprehensive validation
- Spec vs implementation match
- Test coverage
- Performance requirements
- Constitution compliance

**Both Are Needed**:
- Hooks catch issues early (during writing)
- Commands catch issues late (before deployment)

## Files

```
.cursor/hooks/
├── hooks.json                        # Hook configuration
└── hooks/
    ├── log-file-edit.sh              # Learning capture
    ├── validate-template.sh          # Router
    └── validators/
        ├── validate-story-spec.sh    # Story spec validation
        ├── validate-epic-spec.sh     # Epic spec validation
        ├── validate-story-plan.sh    # Story plan validation
        ├── validate-story-tasks.sh   # Story tasks validation
        └── validate-epic-tech-spec.sh # Epic tech spec validation
```

## References

- Cursor Hooks: https://cursor.com/docs/agent/hooks
- OpenSpec Validation: Inspired by quantitative thresholds
- Simplicity-First: See AGENTS.md
- Normative Language: See AGENTS.md
- Template Structure: See `.speck/templates/`

---

**Version**: 1.0  
**Updated**: 2025-10-30  
**Integration**: Automated via Cursor hooks

