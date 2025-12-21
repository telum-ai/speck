# Project Landscape Overview: [Project Name]

**Scan Date**: [YYYY-MM-DD]  
**Scan Type**: Quick Survey (10-15 minutes)  
**Confidence**: LOW - Directional only  
**Codebase Path**: [/path/to/codebase/]

---

## Executive Summary

**⚠️ This is a quick landscape survey, not a deep analysis. All findings need validation.**

[2-3 sentences describing what was found at a high level - keep it brief and honest about limitations]

**Scale Indicators**:
- Architecture: Appears to be [monolithic/microservices/modular/hybrid]
- Primary languages: [Language1, Language2, Language3]
- Rough size: ~[X] source files
- Organization: [Feature-based/layer-based/domain-driven/unclear]

**Potential Epic Areas**: [X] areas spotted (LOW confidence - validate with epic-scan)

---

## Architecture Overview (Surface Level)

### Observed Structure

```
[project-root]/
├── [directory1]/  ([Brief description - e.g., "Backend API"])
│   ├── [subdir1]/ ([Purpose])
│   └── [subdir2]/ ([Purpose])
├── [directory2]/  ([Brief description - e.g., "Frontend UI"])
│   ├── [subdir1]/ ([Purpose])
│   └── [subdir2]/ ([Purpose])
└── [directory3]/  ([Brief description - e.g., "Database migrations"])
```

**Pattern**: Appears to be [describe observed organizational pattern at high level]

**Note**: This is based on directory structure only. Run `/epic-scan` to validate architecture within domains.

---

## Technology Landscape

### Primary Technologies (Names only - no versions yet)

**Backend** (if found):
- Language: [e.g., Python, Java, Go, Node.js]
- Framework: [e.g., FastAPI, Django, Spring Boot, Express] (detected from package manifest)
- Database: [e.g., PostgreSQL, MySQL, MongoDB] (spotted in config/migrations)

**Frontend** (if found):
- Language: [e.g., TypeScript, JavaScript]
- Framework: [e.g., React, Vue, Angular, Svelte] (detected from package.json)
- Build Tool: [e.g., Vite, webpack, Next.js] (detected from config)

**Infrastructure** (if found):
- Containerization: [e.g., Docker found/Not found]
- CI/CD: [e.g., GitHub Actions, GitLab CI, None detected]

**Note**: Version numbers and detailed dependencies should be extracted during `/project-context` phase.

---

## Codebase Heatmap & Clusters (Generic Analysis)

### 1. Keyword Heatmap
*Where are the business concepts located?*

| Directory | Keyword Hits (Top 3) | Primary Domain |
|-----------|----------------------|----------------|
| [path/to/dir] | [auth: 15, user: 10, api: 5] | [e.g. Auth/User] |
| [path/to/dir] | [product: 20, order: 15, pay: 8] | [e.g. E-commerce] |
| [path/to/dir] | [util: 50, common: 30] | [e.g. Shared Lib] |

### 2. Complexity Clusters
*Where is the most code? (Top 5 directories by file count)*

1. **[Directory Path]**: ~[X] files - [Brief assessment of what's here]
2. **[Directory Path]**: ~[X] files - [Brief assessment]
3. **[Directory Path]**: ~[X] files - [Brief assessment]
4. **[Directory Path]**: ~[X] files - [Brief assessment]
5. **[Directory Path]**: ~[X] files - [Brief assessment]

**Interpretation**: High-density clusters often indicate core domains or monolithic hotspots.

### 3. Module Coupling (Top References)
*Which modules are most depended upon?*

- **[Module A]**: Referenced [X] times by [Module B, Module C]
- **[Module B]**: Referenced [Y] times by [Module A]

---

## Potential Epic Areas (⚠️ LOW/MEDIUM CONFIDENCE)

**Warning**: These are candidates based on directory structure and keyword heatmaps. Run `/epic-scan --domain=X` on each area to validate.

### Area 1: [Name Based on Directory/Files Found]
- **Location**: [Directory path or file pattern]
- **Initial Assessment**: "Appears to be [X] based on [directory names/file patterns]"
- **Reasoning**: [Why we think this is an epic area - e.g., "High 'auth' keyword density (15 hits)"]
- **Confidence**: MEDIUM - backed by heatmap
- **Next Step**: Run `/epic-scan --domain=[area-name]` to validate

### Area 2: [Name]
- **Location**: [Directory path or file pattern]
- **Initial Assessment**: "Looks like [X] functionality"
- **Reasoning**: [Why this might be an epic area]
- **Confidence**: LOW - needs validation
- **Next Step**: Run `/epic-scan --domain=[area-name]` to confirm

### Area 3: [Name]
- **Location**: [Directory path or file pattern]
- **Initial Assessment**: "[Brief guess]"
- **Reasoning**: [Evidence from quick scan]
- **Confidence**: LOW - pattern match only
- **Next Step**: Run `/epic-scan --domain=[area-name]` to analyze

[Continue for each spotted area - typically 5-10 potential areas]

**Relationship Between Areas** (Guessed):
```
[Area 1] (appears foundational)
    ↓
[Area 2] [Area 3] (seem to depend on Area 1)
    ↓
[Area 4] [Area 5] (higher-level features)
```

**Note**: These dependencies are GUESSES based on common patterns. Epic-scan will validate actual relationships.

---

## What We Didn't Analyze (Intentionally)

This quick scan **did not**:
- ❌ **Read code or extract patterns** → Use `/epic-scan` for domain-specific patterns
- ❌ **Run tests or measure coverage** → Expensive operation, not needed for landscape view
- ❌ **Assess code quality or technical debt** → Requires deep analysis
- ❌ **Identify specific technologies with versions** → Needs package manifest inspection
- ❌ **Make confident epic breakdowns** → Needs code reading and validation
- ❌ **Estimate story counts** → Can't determine from directory structure
- ❌ **Analyze integration points** → Too detailed for landscape survey
- ❌ **Evaluate performance characteristics** → Needs profiling and analysis
- ❌ **Check security posture** → Needs security audit

**Why we skipped these**: This is a 10-15 minute survey to understand the landscape. Deep analysis happens at epic and story levels.

---

## Recommended Next Steps

### Path A: Validate Epic Areas (Recommended for Brownfield)

1. **Review** this landscape overview to get oriented
2. **Pick 1-2 interesting potential areas** from the list above
3. **Run `/epic-scan --domain=[area]`** on each to:
   - Validate it's actually an epic-worthy domain
   - Find patterns and similar implementations
   - Get MEDIUM-confidence assessment (15-20 min per area)
4. **After validating epics**, run `/project-context` to extract constraints
5. **Then run `/project-architecture`** to document design patterns
6. **Finally run `/project-plan`** to create PRD with validated epics

### Path B: Skip to Project-Level Context (For Simple Projects)

1. **Review** this landscape overview
2. **Run `/project-context`** to extract constraints
   - Uses this landscape's tech stack overview
   - Creates context.md
3. **Run `/project-architecture`** to document design
   - Uses this landscape's structure overview
   - Creates architecture.md
4. **Run `/project-plan`** to create PRD
   - Uses potential areas as epic hints (LOW confidence)
   - Creates PRD.md + epics/

**Recommendation**: For brownfield projects with existing code, Path A (validate epics first) provides much higher confidence in your planning.

---

## Confidence & Limitations

### Confidence Level: LOW/MEDIUM

**What we validated**:
- ✅ Directory structure exists and follows [pattern]
- ✅ Primary languages identified from file extensions
- ✅ Framework names detected from package manifests
- ✅ Potential feature areas spotted from directory names
- ✅ Keyword heatmaps identify content clusters

**What we did NOT validate**:
- ❌ Epic boundaries (just directional hints)
- ❌ Code patterns or quality
- ❌ Integration complexity
- ❌ Technical debt levels
- ❌ Test coverage or completeness
- ❌ Actual vs. expected functionality

### Limitations

- **Time**: 10-15 minute scan - not comprehensive
- **Depth**: Directory/file scanning only - no code reading
- **Scope**: Focused on [all/frontend/backend/infrastructure] only
- **Recency**: Snapshot as of [date] - code may have changed

### When to Re-scan

Re-run `/project-scan` when:
- Major architectural changes occur
- New major domains/epics added
- Technology stack significantly changes
- Bringing new team members up to speed

---

## Scan Metadata

**Generated**: [YYYY-MM-DD HH:MM:SS]  
**Duration**: [X] minutes  
**Directories Scanned**: [X]  
**Files Spotted**: [X]  
**Potential Epic Areas**: [X]

---

**Next Command**: `/epic-scan --domain=[choose-an-area]` or `/project-context`  
**Confidence Level**: LOW (Quick survey only)  
**Validation Required**: Yes - use epic-scan on each potential area

---

*This landscape overview informs: `/epic-scan`, `/project-context`, `/project-architecture`*
