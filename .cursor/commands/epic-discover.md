---
description: Analyze existing code or documentation to discover and define epics within a project.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Discover epic boundaries from existing code and documentation.

## Context Requirements

First, establish project context:
- If project specified in arguments, use it
- Otherwise ask: "Which project should I discover epics for?"
- Load project.md and any import report

Verify project has:
- Existing codebase path or
- Documentation to analyze or
- Previous import analysis

## Step 1: Analysis Preparation

### Determine Analysis Scope

Ask if not clear:
- "Should I analyze the entire codebase or specific areas?"
- "Any particular features you want me to focus on?"
- "Are there existing epic boundaries I should respect?"

### Load Previous Analysis

If project was imported:
- Load import report
- Review epic candidates
- Note confidence levels

## Step 2: Deep Code Analysis

### Structural Analysis

Examine code organization:

```bash
# Top-level feature directories
find [PROJECT_PATH] -type d -mindepth 1 -maxdepth 2 | grep -E "(feature|module|domain|service|component)s?" | sort

# Route/endpoint analysis
grep -r "router\|route\|endpoint\|path\|api/" [PROJECT_PATH] --include="*.{js,ts,py,java,go}" | grep -v node_modules | head -20

# Database schema indicators
find [PROJECT_PATH] -name "*.sql" -o -name "*migration*" -o -name "*schema*" | head -20

# Service boundaries
grep -r "class.*Service\|function.*Service" [PROJECT_PATH] --include="*.{js,ts,py,java,go}" | head -20
```

### Semantic Analysis

Look for business capabilities:

**Authentication Patterns:**
```
auth, login, logout, session, token, oauth, sso, 
password, credential, permission, role, access
```

**User Management Patterns:**
```
user, profile, account, settings, preferences,
registration, onboarding, avatar, notification
```

**Data Management Patterns:**
```
create, read, update, delete, list, search,
filter, sort, paginate, export, import
```

### Dependency Analysis

Trace connections between code areas:
- Import/require statements
- Database foreign keys
- API call patterns
- Shared utilities

## Step 3: Epic Boundary Definition

### Epic Candidate Evaluation

For each potential epic, assess:

**Cohesion Score** (1-10):
- Files work together: +3
- Shared data model: +2
- Common user goal: +3
- Single team ownership: +2

**Independence Score** (1-10):
- Few external dependencies: +3
- Clear API boundaries: +3
- Separate database tables: +2
- Independent deployment: +2

**Value Score** (1-10):
- Delivers user value alone: +4
- Clear success metrics: +3
- Business priority: +3

### Epic Sizing

Estimate story count by analyzing:
- Number of endpoints/routes
- Distinct UI components
- Database operations
- Business rules complexity

Size guidelines:
- 3-5 stories: Small epic
- 6-12 stories: Medium epic
- 13-20 stories: Large epic
- >20 stories: Consider splitting

## Step 4: Generate Epic Specifications

For each discovered epic:

### Create Epic Structure

```bash
mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]-[epic-name]
```

### Generate Epic Spec

Create epic.md with discovered information:

```markdown
# Epic: [Epic Name]

## Discovery Metadata
- **Discovered From**: [Code/Docs/Both]
- **Confidence Level**: [High/Medium/Low]
- **Analysis Date**: [Date]
- **Code Locations**: [Primary paths]

## Overview

[Generated description based on analysis]

## Discovered Components

### Code Structure
- Primary directory: [Path]
- Key files: [List]
- Dependencies: [List]

### Business Capabilities
[List of discovered capabilities]

### Technical Components
- Routes/Endpoints: [Count and list]
- Data Models: [List]
- Services: [List]
- UI Components: [List if applicable]

## User Stories (Discovered)

[For each identified capability:]

**Story**: [Inferred story name]
- Source: [File/endpoint that implies this]
- Confidence: [High/Medium/Low]
- Implementation Status: [Existing/Partial/None]

## Dependencies

### Internal Dependencies
- Depends on: [Other epics]
- Depended by: [Other epics]

### External Dependencies
- APIs: [External services]
- Libraries: [Key dependencies]

## Existing Implementation Analysis

### What Exists
- ✅ [Implemented feature]
- ✅ [Implemented feature]

### What's Missing
- ❌ [Gap identified]
- ❌ [Gap identified]

### Technical Debt
- ⚠️ [Issue found]
- ⚠️ [Issue found]

## Recommended Approach

Based on analysis:
1. [Recommendation]
2. [Recommendation]
3. [Recommendation]
```

## Step 5: Cross-Epic Analysis

### Dependency Map

Create visual representation:

```
Authentication Epic
    ↓ provides sessions to
User Management Epic
    ↓ provides users to
Content Management Epic
    ↓ provides content to
Analytics Epic
```

### Overlap Detection

Identify shared concerns:
- Shared files between epics
- Duplicate functionality
- Unclear boundaries

### Recommended Epic Order

Based on dependencies:
1. [Epic] - No dependencies
2. [Epic] - Depends on #1
3. [Epic] - Depends on #1, #2

## Step 6: Discovery Report

Generate comprehensive report:

```markdown
# Epic Discovery Report

## Summary
- **Epics Discovered**: [Number]
- **Total Estimated Stories**: [Number]
- **Code Coverage**: [Percentage of codebase touched]
- **Confidence Level**: [Overall assessment]

## Discovered Epics

### 1. [Epic Name]
- **Size**: [S/M/L]
- **Stories**: ~[Number]
- **Status**: [Greenfield/Partial/Complete]
- **Priority**: [High/Medium/Low]
- **Confidence**: [High/Medium/Low]

[Repeat for each epic]

## Epic Relationships

[Dependency diagram]

## Coverage Analysis

### Well-Covered Areas
- ✅ [Area]: [Epic covering it]

### Gaps Found
- ⚠️ [Code area]: No clear epic ownership
- ⚠️ [Feature]: Spread across multiple epics

## Recommendations

### Epic Boundaries
[Suggestions for refining boundaries]

### Implementation Order
[Recommended sequence with rationale]

### Risk Areas
[Technical debt or unclear areas]

## Next Steps

1. Review epic specifications
2. Refine boundaries with team
3. Prioritize epic order
4. Begin story extraction
```

## Step 7: Interactive Refinement

Present findings:
- "I've discovered [N] potential epics. Here's what I found..."
- "These boundaries make sense based on your code structure"
- "I'm less certain about [epic] - can you clarify?"

Get feedback:
- "Do these epic boundaries align with your team structure?"
- "Are there business boundaries I missed?"
- "Should any of these be combined or split?"

## Step 8: Guide Next Steps

Based on discovery:
- Many small epics → "Consider combining related ones"
- Few large epics → "Consider splitting by user journey"
- Clear boundaries → "Ready to extract stories"
- Unclear code → "Need team input on organization"

Recommend:
- `/epic-specify` - Formalize selected epics
- `/story-extract` - Extract stories from code
- `/epic-plan` - Create tech specs
- "Review with team for validation"

## Discovery Patterns

### Well-Structured Codebases
- Trust directory structure
- Epics align with top-level directories
- High confidence in boundaries

### Domain-Driven Codebases
- Epics align with bounded contexts
- Look for aggregates and entities
- Focus on business capabilities

### Legacy Codebases
- Ignore file organization
- Focus on user capabilities
- Plan refactoring within epics

### Microservices
- Services often = epics
- Check for service boundaries
- Consider cross-service epics

## Success Criteria

Successful epic discovery:
- ✅ All major features covered
- ✅ Clear boundaries defined
- ✅ Dependencies mapped
- ✅ Sizing seems reasonable
- ✅ Team agrees with structure
