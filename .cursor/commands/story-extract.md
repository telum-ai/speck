---
description: Extract story specifications from existing code implementations, creating detailed documentation for implemented features.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Extract story-level specifications from existing code.

## Context Requirements

Establish the hierarchy:
- Project identification
- Epic identification  
- Code location or specific features

Ask if not provided:
- "Which epic should I extract stories from?"
- "Any specific code areas to focus on?"

## Step 1: Code Area Analysis

### Identify Story Boundaries

Look for natural story indicators:

**Frontend Indicators:**
- Page components
- Form implementations
- UI features
- User interactions

**Backend Indicators:**
- API endpoints
- Business operations
- Database transactions
- Background jobs

**Full-Stack Indicators:**
- Complete user workflows
- Feature flags
- Test suites
- Documentation sections

### Size Assessment

Determine if code represents:
- Single story (one user goal)
- Multiple stories (several goals)
- Partial story (incomplete feature)
- Epic-level scope (too large)

## Step 2: Story Extraction Process

For each identified story area:

### Code Comprehension

```bash
# Examine the primary file
cat [FILE_PATH] | grep -E "function|class|export|def" | head -20

# Find related files
grep -r "[FUNCTION_NAME]" [PROJECT_PATH] --include="*.{js,ts,py,java,go}" | grep -v node_modules

# Look for tests
find [PROJECT_PATH] -name "*test*" -o -name "*spec*" | xargs grep -l "[FEATURE_NAME]"

# Check for documentation
grep -r "[FEATURE_NAME]" [PROJECT_PATH] --include="*.md" 
```

### Extract Story Components

**User Story Format:**
From code behavior, infer:
- Who: User type from auth checks, routes
- What: Action from function names, endpoints  
- Why: Business value from comments, docs

**Acceptance Criteria:**
From implementation, extract:
- Input validation rules
- Business logic conditions
- Output format/behavior
- Error handling cases

**Technical Details:**
Document what exists:
- API endpoints used
- Database operations
- External integrations
- UI components

## Step 3: Generate Story Specifications

Create story structure:

```bash
mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-[story-name]
```

Generate the story artifacts using existing Speck templates (this command does NOT have its own output template).

1) Generate `spec.md` (WHAT/WHY) using the story spec template:
- **Load and follow the template exactly**: `.speck/templates/story/story-template.md`
- Populate from observed behavior in code/tests/docs
- Mark uncertain inferences as: `[NEEDS CLARIFICATION: ...]`
- **Do not** include deep implementation details, schemas, or file-by-file inventories here (those belong in the scan report)

2) Generate `codebase-scan-extracted.md` (HOW/WHERE evidence) using the scan template:
- **Load and follow the template exactly**: `.speck/templates/story/codebase-scan-template.md`
- Capture:
  - Primary files and entry points
  - Routes/endpoints, data models, and integration points (if relevant)
  - Observed validation/error handling patterns
  - Test locations + missing tests
  - Notable technical debt / anti-patterns discovered

**Traceability markers**:
- Use `[FROM SCAN]` for facts derived directly from code reading/search
- Use `[INFERRED]` for inferred behavior not directly verified

## Step 4: Bulk Story Extraction

For extracting multiple stories:

### Batch Analysis

```bash
# Find all endpoints in a router
grep -E "get\(|post\(|put\(|delete\(" [ROUTER_FILE]

# Find all page components
find [PAGES_DIR] -name "*.jsx" -o -name "*.tsx" | grep -v test

# Find all service methods
grep -E "async|function|def" [SERVICE_FILE] | grep -v private
```

### Story Grouping

Group related code into stories:
- CRUD operations → Separate stories
- Multi-step workflows → Single story
- Variations → Story with conditions

### Batch Generation

Create multiple story specs efficiently:
1. Identify all story candidates
2. Generate specs in batch
3. Mark for review
4. Create extraction report

## Step 5: Extraction Report

Return an extraction summary as command output (do not introduce a new “report template” doc).

Include:
- Epic + code scope analyzed
- Story directories created/updated
- Per-story status: Complete / Partial / Unknown + confidence
- Biggest gaps/questions needing human clarification
- Recommended next command(s): `/story-clarify`, `/story-plan`, `/story-validate`, or follow-up scan

## Step 6: Interactive Review

Present extraction results:
- "I've extracted [N] stories from your codebase"
- "Found [X] complete, [Y] partial implementations"
- "Several areas need clarification..."

Ask for validation:
- "Do these story boundaries make sense?"
- "Are the extracted rules correct?"
- "What's the history behind [partial feature]?"

## Step 7: Guide Next Steps

Based on extraction:

**If mostly complete:**
- "Your epic is well-implemented!"
- "Consider `/story-validate` for quality check"
- "Document any undocumented features"

**If many gaps:**
- "Several stories need completion"
- "Consider `/story-plan` for missing pieces"
- "Consider `/story-scan` for a deep, HIGH-confidence implementation guide before planning"
- "Prioritize based on user value"

**If messy code:**
- "Refactoring needed before new features"
- "Consider technical debt epic"
- "Plan incremental improvements"

## Extraction Patterns

### Well-Documented Code
- High confidence in extraction
- Clear story boundaries
- Business rules evident

### Test-Driven Code
- Extract stories from test names
- Acceptance criteria from test cases
- High confidence in behavior

### Legacy Code
- Lower confidence
- Focus on behavior, not structure
- More clarification needed

### Prototype Code
- Many gaps expected
- Focus on intent
- Plan production implementation

## Success Criteria

Successful extraction:
- ✅ All implemented features documented
- ✅ Story boundaries make sense
- ✅ Technical debt identified
- ✅ Team validates accuracy
- ✅ Clear path forward
