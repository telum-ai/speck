# speck-learn / quick-learning-title

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

### Continuous Feedback Capture Trigger
If you capture a `GOTCHA` or `DEBT` that stems from a Speck template or script limitation, you **MUST** run `/speck-feedback` (or read `.cursor/skills/speck-feedback/SKILL.md`) to propose a template or script enhancement. Do not let workarounds go undocumented.

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
