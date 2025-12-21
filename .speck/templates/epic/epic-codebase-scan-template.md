# Epic Codebase Scan: [Epic Name]

**Scan Date**: [YYYY-MM-DD]  
**Epic Domain**: [What this epic focuses on - e.g., "Authentication & Authorization"]  
**Confidence**: MEDIUM (Pattern matching + shallow code reading)  
**Relevant Findings**: [X]  
**Skipped Items**: [Y] (not relevant to this epic)

---

## Epic Scope Context

This epic focuses on: [Brief description from epic.md - 2-3 sentences]

**Relevance Filter Applied**:
- ✅ **Included**: [What domains/patterns were considered relevant]
  - Example: Auth middleware, session management, JWT patterns, login flows
- ⏭️ **Skipped**: [What domains/patterns were filtered out]
  - Example: Product catalog, payment processing, admin dashboards

**Search Strategy**:
- Searched for: [Keywords and file patterns used - e.g., "*auth*", "*login*", "*session*"]
- Analyzed: [X] files in this domain
- Filtered out: [Y] files not relevant to this epic

---

## Similar Implementations (Relevant to THIS Epic)

### [Feature Name 1]
- **Location**: `[path/to/feature/files]`
- **Relevance**: [Explain why this matters to YOUR epic - e.g., "Similar OAuth flow pattern"]
- **Pattern**: [What approach/pattern it uses at high level]
- **Reusable for Your Epic**: [What specifically can be reused or adapted]
- **Key Files**:
  - `[file1.py]` - [Purpose]
  - `[file2.ts]` - [Purpose]
- **Lessons Learned**: [What worked well, what to avoid]
- **Confidence**: MEDIUM (found by pattern match, shallow code reading)

### [Feature Name 2]
- **Location**: `[path/to/feature/files]`
- **Relevance**: [Why this matters to your epic]
- **Pattern**: [Approach used]
- **Reusable for Your Epic**: [Specific components/patterns]
- **Key Files**:
  - `[file1.py]` - [Purpose]
- **Lessons Learned**: [Observations]
- **Confidence**: MEDIUM

[Limit to 2-3 most relevant similar features - quality over quantity]

**Note**: These are the most relevant implementations found. [X] other features were skipped as not relevant to this epic's domain.

---

## Reusable Components (For THIS Epic)

| Component | Location | Purpose | Fit for Your Epic | Confidence |
|-----------|----------|---------|-------------------|------------|
| [Component1] | `[path]` | [What it does] | [How it helps YOUR epic specifically] | MEDIUM |
| [Component2] | `[path]` | [What it does] | [How it helps YOUR epic specifically] | MEDIUM |
| [Component3] | `[path]` | [What it does] | [How it helps YOUR epic specifically] | MEDIUM |

**Filtering Applied**: Only components directly relevant to [epic domain] are listed.  
**Skipped**: [X] components not relevant to this epic's scope.

---

## Integration Points (That THIS Epic Touches)

### [Service/API Name 1]
- **Relevance**: [Why your epic needs to integrate with this]
- **Current Usage**: [Where it's used in similar features]
- **Integration Pattern**: [How it's currently integrated - e.g., "REST API with JWT auth"]
- **Example File**: `[file-to-reference.py]` (don't copy full code here)
- **Notes**: [Any gotchas or considerations for your epic]

### [Service/API Name 2]
- **Relevance**: [Why this matters to your epic]
- **Current Usage**: [Existing integration points]
- **Integration Pattern**: [Approach used]
- **Example File**: `[file-to-reference.ts]`
- **Notes**: [Important considerations]

[Only list integrations THIS epic will actually use - be selective]

**Skipped Integrations**: [List any major integrations in the codebase that are NOT relevant to this epic]

---

## Patterns to Follow (Domain-Specific)

### [Pattern Name 1 - e.g., "JWT Middleware Pattern"]
- **Used in**: `[location1]`, `[location2]`
- **Relevance**: [How this pattern applies to YOUR epic specifically]
- **Approach**: [High-level description of the pattern]
- **Why Good for Your Epic**: [Benefits for your specific use case]
- **Example to Study**: `[file-to-look-at.py]` (don't paste code - just point to it)
- **Confidence**: MEDIUM (pattern exists, validated by presence)

### [Pattern Name 2 - e.g., "Error Handling Strategy"]
- **Used in**: `[locations]`
- **Relevance**: [Application to your epic]
- **Approach**: [Description]
- **Why Good for Your Epic**: [Benefits]
- **Example to Study**: `[file-reference]`
- **Confidence**: MEDIUM

[Limit to 3-5 most relevant patterns - focus on what YOUR epic needs]

---

## Anti-Patterns Found (In This Domain)

### [Anti-Pattern Name - e.g., "Hardcoded Credentials"]
- **Found in**: `[location]`
- **Problem**: [Why this is bad for this domain]
- **Impact on Your Epic**: [How this could hurt your epic if replicated]
- **Better Approach**: [Recommendation for YOUR epic]
- **Example to Avoid**: `[file-with-anti-pattern]`

### [Anti-Pattern Name 2]
- **Found in**: `[location]`
- **Problem**: [Issue]
- **Impact on Your Epic**: [Relevance]
- **Better Approach**: [Recommendation]

[Only include anti-patterns relevant to this epic's domain]

---

## Testing Approaches (For This Domain)

### Unit Tests
- **Pattern Observed**: [Testing approach used in similar features]
- **Example Files**: `[test-file-1.py]`, `[test-file-2.py]`
- **Applicability to Your Epic**: [How this testing pattern fits your epic]
- **Coverage Areas**: [What aspects these tests cover]

### Integration Tests
- **Pattern Observed**: [Approach used for integration testing]
- **Example Files**: `[test-file.py]`
- **Applicability to Your Epic**: [How this applies to your integration needs]
- **Coverage Areas**: [What integration points are tested]

### [Other Test Types if Relevant]
- **Pattern Observed**: [Approach]
- **Example Files**: [References]
- **Applicability to Your Epic**: [How it fits]

---

## Recommendations for YOUR Epic

### Components to Reuse
1. **[Component Name]**: [Specific guidance on how to use it in your epic]
   - Location: `[path]`
   - Usage: [How to integrate]
   - Modifications needed: [Any adaptations required]

2. **[Component Name]**: [Guidance]
   - Location: `[path]`
   - Usage: [Integration approach]
   - Modifications needed: [Adaptations]

### Patterns to Adopt
1. **[Pattern Name]**: [Where to apply in your epic]
   - Reference: `[file-to-study]`
   - Application: [Specific use case in your epic]
   - Benefit: [Why this helps your epic]

2. **[Pattern Name]**: [Application guidance]
   - Reference: `[file]`
   - Application: [Use case]
   - Benefit: [Value]

### New Development Needed
1. **[What's Missing]**: [Why your epic needs this that doesn't exist yet]
   - Gap: [What's not in the codebase]
   - Impact: [Why this matters for your epic]
   - Recommendation: [How to approach building it]

2. **[What's Missing]**: [Reasoning]
   - Gap: [Description]
   - Impact: [Effect on epic]
   - Recommendation: [Approach]

### What to Avoid
1. **[Anti-Pattern or Legacy Code]**: [Why your epic should NOT replicate this]
   - Problem: [Issue with existing approach]
   - Alternative: [Better approach for your epic]

---

## Confidence & Limitations

### Confidence Level: MEDIUM

**What we validated**:
- ✅ Patterns exist in the codebase (found by search)
- ✅ Read enough code to understand general approach
- ✅ Identified integration points that matter to this epic
- ✅ Found reusable components in this domain
- ✅ Filtered out irrelevant code (focused scan)

**What we did NOT validate**:
- ❌ Deep implementation details (need story-level scan for that)
- ❌ All edge cases and error handling
- ❌ Performance characteristics under load
- ❌ Complete test coverage of patterns
- ❌ Hidden dependencies or coupling

### Limitations

- **Focus**: This scan analyzed ONLY [epic domain] - [Y] other areas were skipped
- **Depth**: Shallow code reading (10-20 lines per example) - not exhaustive analysis
- **Recency**: Snapshot as of [date] - code may have changed
- **Patterns**: Identified by surface-level analysis - may miss nuances
- **Time**: 15-20 minute focused scan - not comprehensive code review

### When Story-Level Scan is Needed

Run `/story-scan` for specific stories when you need:
- Deep implementation details (HIGH confidence)
- Copy-paste-adapt code examples
- Complete understanding of edge cases
- Specific file-by-file implementation guidance

---

## Next Steps for YOUR Epic

1. **Incorporate findings** into `/epic-plan` technical design
2. **Use patterns** identified here in epic architecture
3. **Reuse components** where applicable
4. **Avoid anti-patterns** found in this domain
5. **Run `/story-scan`** for individual stories when detailed implementation guidance needed

---

## Scan Metadata

**Epic**: [Epic Name]  
**Domain Focus**: [What this epic covers]  
**Generated**: [YYYY-MM-DD HH:MM:SS]  
**Scan Duration**: [X] minutes  
**Items Analyzed**: [Y] files/patterns in this domain  
**Items Skipped**: [Z] files not relevant to this epic  
**Confidence**: MEDIUM (Pattern matching + shallow code reading)

---

**This scan informs**: `/epic-plan`, `/epic-architecture`  
**For deeper analysis**: Run `/story-scan` on individual stories  
**Confidence comparison**: Project-scan (LOW) → Epic-scan (MEDIUM) ← You are here → Story-scan (HIGH)

---

*Epic codebase scan template - provides focused, medium-confidence analysis of existing patterns relevant to this epic's domain*

