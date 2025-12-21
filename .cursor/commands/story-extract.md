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

Generate spec.md:

```markdown
# Story: [Extracted Story Name]

## Extraction Metadata
- **Source Files**: [Primary files analyzed]
- **Implementation Status**: [Complete/Partial/Unknown]
- **Extraction Date**: [Date]
- **Confidence Level**: [High/Medium/Low]

## User Story

As a [user type - inferred from code]
I want to [action - from function/endpoint name]
So that [value - inferred from business logic]

**Note**: User story inferred from implementation

## Current Implementation

### Code Locations
- Primary logic: [file:line]
- UI components: [file:line]
- API endpoints: [file:line]
- Tests: [file:line]

### Functionality Discovered

✅ **Implemented Features:**
- [Feature from code]
- [Feature from code]

⚠️ **Partial/Unclear:**
- [Feature that seems incomplete]

❌ **Missing/TODO:**
- [From TODO comments]
- [From error handlers]

## Acceptance Criteria (Extracted)

Based on implementation:

1. **[Criteria from validation]**
   - Source: [file:line]
   - Implementation: [How it's checked]

2. **[Criteria from business logic]**
   - Source: [file:line]
   - Implementation: [How it works]

3. **[Criteria from tests]**
   - Source: [test file]
   - Test case: [description]

## Technical Specification

### API Details
```
[Method] [Endpoint]
Request: [Extracted schema]
Response: [Extracted schema]
Auth: [Required/Optional]
```

### Data Model
```
[Entity]: {
  field: type, // From code
  field: type
}
```

### Business Rules
From code logic:
- Rule: [Implementation]
- Rule: [Implementation]

### Error Handling
- [Error case]: [How handled]
- [Error case]: [How handled]

## UI/UX Extraction

### Components Used
- [Component]: [Purpose]
- [Component]: [Purpose]

### User Flow
1. [Step from code]
2. [Step from code]
3. [Step from code]

### States Handled
- Loading: [How shown]
- Error: [How displayed]
- Success: [Feedback method]
- Empty: [What displays]

## Test Coverage Analysis

### Existing Tests
- ✅ [Test scenario]: [test file]
- ✅ [Test scenario]: [test file]

### Missing Tests
- ❌ [Scenario not tested]
- ❌ [Edge case not covered]

## Technical Debt Identified

From code analysis:
- ⚠️ [Issue found]
- ⚠️ [Refactoring needed]

## Gaps and Questions

### Clarification Needed
1. [Unclear business rule]: [Why uncertain]
2. [Missing information]: [What's needed]

### Potential Improvements
1. [Improvement opportunity]
2. [Performance optimization]

## Related Stories

Dependencies found:
- Uses: [Other feature/story]
- Used by: [Other feature/story]
```

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

Generate summary of extraction:

```markdown
# Story Extraction Report

## Summary
- **Epic**: [Epic name]
- **Stories Extracted**: [Number]
- **Code Coverage**: [Lines/files analyzed]
- **Implementation Status**: [Overall percentage]

## Extracted Stories

### Complete Implementations
1. **[Story name]**: 100% implemented
   - Confidence: High
   - Tests: Yes
   - Documentation: [Yes/No]

### Partial Implementations
1. **[Story name]**: ~[%] implemented
   - Missing: [What's not done]
   - Confidence: Medium

### Discovered but Unimplemented
1. **[Story name]**: TODO found
   - Source: [Where referenced]
   - Priority: [Inferred]

## Code Quality Insights

### Well-Implemented Areas
- ✅ [Area]: Clean, tested, documented

### Needs Attention
- ⚠️ [Area]: [Issues found]

### Technical Debt
- 🚩 [Debt item]: [Impact]

## Coverage Analysis

### Epic Coverage
- Total epic scope: ~[X] stories
- Implemented: [Y] stories
- Coverage: [Y/X]%

### Missing Features
From analysis, these seem missing:
- [Expected feature not found]
- [Common pattern not implemented]

## Recommendations

1. **High Priority Reviews**
   - [Story]: [Why needs review]

2. **Refactoring Opportunities**
   - [Area]: [Benefit]

3. **Test Coverage Gaps**
   - [Story]: Missing [test type]

## Next Steps

- [ ] Review extracted stories with team
- [ ] Validate business rules
- [ ] Plan missing implementations
- [ ] Update story priorities
- [ ] Create tech debt tickets
```

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
