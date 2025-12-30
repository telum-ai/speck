---
description: Create Speck structure for an existing codebase, preparing it for detailed analysis.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Import an existing project into the Speck structure.

## Purpose

**Lightweight setup command** that creates Speck structure for existing projects. Does NOT do analysis - that's what `/project-scan` (landscape survey) and `/epic-scan` (deeper) are for.

**Time**: ~10 minutes  
**Output**: Skeleton project.md with basic info  
**Next Step**: Run `/project-scan` for detailed analysis

## Import Process Overview

This command handles three scenarios:
1. **Code-only**: Existing codebase with no documentation
2. **Docs-only**: Existing documentation with no code
3. **Both**: Existing code and documentation

## Step 1: Project Discovery (Basic Info Only)

Gather minimal information to create structure:

**If no arguments provided, ask:**
- "What project would you like to import into Speck?"
- "Where is the project located?" (path or repository URL)
- "What's the project name?"

**Quick identification** (no deep analysis):
```bash
# Just check what type of project (2-3 commands max)
ls [PROJECT_PATH] | grep -E "package.json|requirements.txt|pom.xml|go.mod"

# Quick language detection
find [PROJECT_PATH] -maxdepth 3 -type f \( -name "*.py" -o -name "*.ts" -o -name "*.js" \) | head -3
```

Extract minimal info:
- Project name (from folder or ask)
- Primary language (just one, don't enumerate all)
- Project type (web app, API, library, mobile)
- Existing docs location (if any)

Extract minimal info:
- Project name (from folder or ask)
- Primary language (just one, don't enumerate all)
- Project type (web app, API, library, mobile)
- Existing docs location (if any)

## Step 2: Create Speck Structure

**Create project directory structure**:
```bash
# Run structure creation script
bash .speck/scripts/bash/create-new-project.sh --json "[PROJECT_NAME]"

# This creates:
specs/projects/[PROJECT_ID]/
├── project.md          # Skeleton (to be filled)
└── epics/              # Empty (scan will suggest)
```

## Step 3: Generate Minimal project.md

Create skeleton project.md with ONLY basic info:

```markdown
# Project Specification: [Project Name]

**Project ID**: [Generated ID]  
**Created**: [Date]  
**Status**: Imported (Needs Scan)  
**Scale**: [INFERRED FROM CODE: Estimate based on codebase size]

> **Import Note**: This is a brownfield import. Run `/project-scan` for comprehensive analysis.
> Marked sections with [INFERRED FROM CODE] are preliminary and should be validated.

---

## 🎯 Project Overview

[INFERRED FROM CODE: Basic description from README or package.json if found]

**Type**: [INFERRED FROM CODE: e.g., "Web application", "API service"]

**Primary Technologies**:
- Language: [INFERRED FROM CODE: e.g., "Python", "TypeScript"]
- Framework: [INFERRED FROM CODE: e.g., "FastAPI", "React"]

---

## 📁 Codebase Location

**Source**: [Absolute path to code]  
**Structure**: [INFERRED FROM CODE: e.g., "Monorepo", "Backend + Frontend"]

---

## ⚠️ Next Steps Required

**CRITICAL**: This is a skeleton. Run these commands to complete import:

1. **Run `/project-scan`** - Comprehensive codebase analysis
   - Architecture shape (30,000-foot view)
   - Potential epic areas (directional; validate with `/epic-scan`)
   - High-level tech inventory (major languages/frameworks)
   - Outputs: project-landscape-overview.md

2. **Run `/project-context`** - Extract constraints from scan
   - Technical constraints
   - Team context
   - Standards

3. **Run `/project-architecture`** - Document existing design from scan
   - System architecture
   - Component structure
   - Integration points

4. **Run `/project-plan`** - Create PRD from findings
   - Organize features into epics
   - Create requirements

5. **Begin epic development** - Start implementing/enhancing

---

[INFERRED FROM CODE] markers throughout indicate preliminary information.
Run `/project-scan` to replace with comprehensive analysis.
```

## Step 4: Handle Documentation Import

**If README or docs found**:
- Read README for project description
- Extract high-level goals
- Add to project.md (still marked [INFERRED FROM DOCS])

**Don't**:
- Don't try to parse all documentation
- Don't extract architecture details
- Don't identify all epics
- Scan will do the (still lightweight) landscape survey. Deep code analysis happens later via `/epic-scan` and `/story-scan`.

## Step 5: Output Summary & Routing

```
✅ Project Import Complete!

Created:
- specs/projects/[PROJECT_ID]/
- Skeleton project.md with basic info

Project: [Name]
Type: [Web app/API/etc]  
Language: [Primary language]

⚠️ IMPORTANT: This is a lightweight import!

Next Steps (REQUIRED):
1. Run /project-scan for a quick landscape survey
   → Architecture shape (directional)
   → Potential epic areas to validate
   → High-level tech inventory
   → Outputs: project-landscape-overview.md
   
2. Run /project-context to extract constraints
   → Uses scan findings
   
3. Run /project-architecture to document design
   → Uses scan + context
   
4. Run /project-plan to create PRD
   → Organizes into epics

The scan will produce a directional landscape overview to guide the rest of the setup (validate details via `/epic-scan` and `/story-scan` as needed).
```

## Integration with Other Commands

**Feeds into**:
- `/project-scan` - Uses minimal project.md as context for a landscape survey
- User has structure ready for scan to populate

**Does NOT**:
- ❌ Do comprehensive analysis (that's scan)
- ❌ Extract all patterns (that's scan)
- ❌ Suggest specific epics (that's scan)
- ❌ Create architecture docs (that's architecture command)

## Success Criteria

A successful import:
- ✅ Speck structure created
- ✅ Minimal project.md exists
- ✅ User guided to next steps
- ✅ Takes ~10 minutes (not hours!)
- ✅ Doesn't duplicate scan work

**If you find yourself doing deep analysis in import, STOP and move it to `/epic-scan` / `/story-scan`!**

---

**Position in Flow**: First step for brownfield projects  
**Duration**: ~10 minutes (quick setup)  
**Purpose**: Create structure, not analyze  
**Output**: Skeleton structure + guidance to scan
