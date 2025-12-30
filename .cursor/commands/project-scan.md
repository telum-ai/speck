---
description: Quick landscape survey for brownfield projects to identify architecture shape and potential epic areas (directional, low confidence).
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Quick codebase survey to understand the high-level architecture shape and identify potential epic areas (directional, validate with epic/story scans).

## Subagent Parallelization

This command benefits from parallel speck-explorer execution:

```
├── [Parallel] speck-explorer: "Keyword heatmap for src/auth/"
├── [Parallel] speck-explorer: "Keyword heatmap for src/api/"
├── [Parallel] speck-explorer: "Keyword heatmap for src/models/"
├── [Parallel] speck-explorer: "Keyword heatmap for src/components/"
├── [Parallel] speck-explorer: "Coupling analysis for top modules"
└── [Wait] → Synthesize into landscape overview
```

**Speedup**: 3-4x compared to sequential scanning.

## Purpose

**Quick landscape survey** to understand the 30,000-foot view after `/project-import`.

**Time**: 10-15 minutes (quick scan, not deep analysis)  
**Confidence**: LOW - directional hints only, validate with epic-scan  
**Prerequisites**: project.md exists (from import or specify)  
**Output**: Landscape overview with potential epic areas  
**Next Step**: Run `/epic-scan` to validate epic boundaries and patterns

## When to Use

- **After `/project-import`** - Get quick overview of imported codebase
- **Brownfield projects** - Understand the landscape before detailed analysis
- **Before epic planning** - Identify potential epic areas to explore
- **Quick health check** - Periodic re-scan after major changes

**Not for**: Deep analysis, pattern extraction, or confident assessments (use epic/story scans)

## Scan Process

### Step 1: Load Context

1. Determine project:
   - If in project directory, use current project
   - Otherwise ask: "Which project to scan?"

2. Load minimal project.md:
   - Understand project type and basic info
   - Get codebase path
   - Check if brownfield (needs scan) or greenfield (skip scan)

3. Parse optional domain argument:
   - `--domain=all` (default): Full scan
   - `--domain=frontend`: UI only
   - `--domain=backend`: API/services only
   - `--domain=infrastructure`: Config/deployment only
   - `--domain=quality`: Tests/docs only

### Step 2: Quick Landscape Analysis

**Run light analysis** (no deep code reading):

**Architecture & Structure**:
```bash
# Quick directory survey
ls -la [CODEBASE]
find [CODEBASE] -maxdepth 2 -type d | head -20

# Spot check for architecture indicators
ls [CODEBASE] | grep -E "services|modules|packages|frontend|backend"
```

Extract (broad strokes only):
- Architecture pattern: "Appears to be monolithic/microservices/modular"
- Major boundaries: "Has frontend/, backend/, database/"
- Organization: "Feature-based/layer-based/hybrid"

**Technology Inventory** (Major items only):
```bash
# Check for package manifests
ls [CODEBASE] | grep -E "package.json|requirements.txt|pom.xml|go.mod|Cargo.toml"

# Quick language count
find [CODEBASE] -type f -name "*.py" | wc -l
find [CODEBASE] -type f -name "*.ts" -o -name "*.tsx" | wc -l
find [CODEBASE] -type f -name "*.js" -o -name "*.jsx" | wc -l
```

Extract (primary tech only):
- Primary languages: "Python, TypeScript" (NO versions - just names)
- Main frameworks: "FastAPI, React" (NO versions - just names)
- Database type: "SQL database found" (NO specific version)

**DO NOT**:
- ❌ Count lines of code precisely
- ❌ Run test suites for coverage
- ❌ Read code for patterns
- ❌ Analyze code quality
- ❌ Make health assessments

### Step 3: Hardened Brownfield Analysis (Generic)

**Goal**: Identify "center of gravity" for features using generic heuristics that work for any language.

#### A. Keyword Heatmap Analysis
Run this generic keyword scan to find where business concepts live. This identifies feature clusters regardless of directory naming.

```bash
# 1. Define generic domain keywords
KEYWORDS="auth login user profile pay order product cart admin report api db model ui component test util"

# 2. Identify top-level directories to scan (ignore hidden/config dirs)
DIRS=$(find [CODEBASE] -maxdepth 1 -type d | grep -v "^\." | grep -v "^__" | grep -v "node_modules" | grep -v "venv")

# 3. For each directory, count keyword hits (recursive, case-insensitive)
echo "--- KEYWORD HEATMAP ---"
for dir in $DIRS; do
  echo "Directory: $dir"
  for word in $KEYWORDS; do
    # Fast count of files containing the keyword
    count=$(grep -r -i -l "$word" "$dir" 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
      echo "  - $word: $count files"
    fi
  done
done
```

**Analyze Heatmap**:
- High `auth/login` count in `src/lib/`? → Auth logic is likely there (even if not named `auth`).
- High `ui/component` count in `packages/core`? → Shared UI library.
- High `db/model` count everywhere? → Leaky abstraction or decentralized data.

#### B. Simplified Dependency/Coupling Graph
Estimate module coupling by checking how often top-level modules reference each other. This assumes folder names are used as namespaces/imports (common in most languages).

```bash
# 1. Identify modules (top-level directories)
MODULES=$(find [CODEBASE] -maxdepth 1 -type d -not -path '*/.*' -not -name "node_modules" -not -name "venv" -exec basename {} \;)

# 2. Check for cross-references (generic grep)
echo "--- COUPLING GRAPH ---"
for mod1 in $MODULES; do
  for mod2 in $MODULES; do
    if [ "$mod1" != "$mod2" ]; then
       # Search for mod1's name inside mod2's files
       refs=$(grep -r "$mod1" "[CODEBASE]/$mod2" 2>/dev/null | wc -l)
       if [ "$refs" -gt 0 ]; then
         echo "$mod2 references $mod1: $refs times"
       fi
    fi
  done
done
```

**Analyze Coupling**:
- `frontend` references `backend` heavily? → Tight coupling or direct API calls.
- `utils` referenced by everything? → Foundational shared library.
- Circular references (A refs B, B refs A)? → Potential architectural issue.

### Step 4: Spot Potential Epic Areas (Low-to-Medium Confidence)

Combine **Directory Scan** (Step 2) with **Heatmap Data** (Step 3).

**Identify epic candidates based on data:**
1. **High-Density Clusters**: Directories with high keyword counts.
2. **Coupling Centers**: Modules that are heavily referenced (Shared/Core epics).
3. **Directory Names**: Explicit naming (e.g., `/auth`, `/payments`).

**Create Potential Epic Areas List**:
```markdown
## Potential Epic Areas (Validated by Heatmap)

### Area 1: [Name - e.g. User Management]
- **Found**: [Directory path]
- **Heatmap Signal**: High count of 'user', 'profile', 'auth' keywords
- **Coupling**: Referenced by [X, Y] modules
- **Confidence**: LOW/MEDIUM - backed by keyword density, still directional
- **Next**: Run `/epic-scan --domain=user` to validate patterns

### Area 2: [Name]
- **Found**: [Directory path]
- **Heatmap Signal**: [Keywords found]
- **Confidence**: LOW/MEDIUM
- **Next**: Run `/epic-scan`
```

### Step 5: Generate Landscape Report

Create landscape overview using `.speck/templates/project/project-landscape-overview-template.md`:

1. **Fill Executive Summary** with scale indicators.
2. **Fill Architecture** with observed structure.
3. **Fill Technology** with discovered languages/frameworks.
4. **NEW: Fill Codebase Heatmap & Clusters** section with data from Step 3.
5. **Fill Potential Epic Areas** with candidates from Step 4.

### Step 6: Save and Route

1. **Save landscape report**:
   - Full report: `[PROJECT_DIR]/project-landscape-overview.md`

2. **Update project.md**:
   - Add reference to landscape overview
   - Update status to "Landscape Surveyed"

3. **Output summary and routing**:

```
✅ Project Landscape Survey Complete!

Survey Summary (Enhanced Brownfield Scan):
- Type: Brownfield
- Architecture: Appears to be [pattern]
- Heatmap: Identified [X] keyword clusters
- Coupling: Found [Y] module relationships

Potential Epic Areas:
1. [Area name] - [Reason: e.g. "High 'auth' keyword density"]
2. [Area name] - [Reason: e.g. "Heavily referenced module"]
3. [Continue listing...]

Full report: specs/projects/[PROJECT_ID]/project-landscape-overview.md

Next Steps (CHOOSE ONE PATH):

PATH A - Validate Epic Areas First (Recommended):
1. Pick 1-2 interesting potential areas
2. Run /epic-scan --domain=[area] to validate each
   → Finds patterns and implementations
   → Confirms it's a real epic
3. After validating epics, run /project-context
4. Then run /project-architecture

PATH B - Skip to Project-Level Context (Simple Projects):
1. Run /project-context to extract constraints
2. Run /project-architecture to document design
3. Run /project-plan to create PRD
```

---

## Integration with Other Commands

**Requires**:
- `/project-import` - Creates minimal project.md first

**Feeds into (Choose path)**:
- `/epic-scan --domain=X` - Validate specific epic areas (RECOMMENDED)
- `/project-context` - Extract constraints (can skip epic-scan for simple projects)

**Related**:
- `/epic-scan` - Medium-depth domain analysis
- `/story-scan` - Deep story-level code analysis

---

## Error Handling

**No project.md found**:
```
ERROR: No project.md found. Run /project-import or /project-specify first.
```

**No code found** (Greenfield):
```
NOTE: No code found at [path]. This is a greenfield project.
Skipping landscape survey. You can proceed directly to:
- /project-context (define constraints)
- /project-plan (create PRD)
```

**Scan too large**:
```
WARNING: Codebase is very large (>100K files).
Suggest focused survey: /project-scan --domain=backend
```

---

**Position in Flow**: After import, before epic validation  
**Duration**: 10-15 minutes (quick survey)  
**Confidence**: LOW (directional; validate boundaries and patterns with `/epic-scan`)  
**Purpose**: Spot potential epic areas with data backing  
**Output**: project-landscape-overview.md with potential areas
