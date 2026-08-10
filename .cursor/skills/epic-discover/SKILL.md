---
name: epic-discover
description: Discovers epic candidates. Use when scanning for new epic scope.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-discover

Input: `$ARGUMENTS` (project id, code path, focus areas).
Output: `[EPIC_DIR]/epic.md` per discovered epic + discovery summary (stdout).
Template: `.speck/templates/epic/epic-template.md` (no separate discovery template).
Prereq: project with codebase or import artifacts.

## 0. Template

Read `.speck/templates/epic/epic-template.md` — defines epic sections to populate.

## 1. Context

Resolve project from args or ask. Load `project.md`, `project-import.md` if present.

Verify: codebase path, docs, or import report exists.

Scope questions if unclear: whole codebase vs areas; features to focus; existing boundaries to respect.

## 2. Code analysis

```bash
# Feature dirs
find [PROJECT_PATH] -type d -mindepth 1 -maxdepth 2 \
  | grep -Ei '(feature|module|domain|service|component)s?' | sort

# Routes
grep -rE 'router|route|endpoint|path|api/' [PROJECT_PATH] \
  --include='*.{js,ts,py,java,go}' | grep -v node_modules | head -20

# Schema
find [PROJECT_PATH] -name '*.sql' -o -name '*migration*' -o -name '*schema*' | head -20

# Services
grep -rE 'class.*Service|function.*Service' [PROJECT_PATH] \
  --include='*.{js,ts,py,java,go}' | head -20
```

Semantic clusters: auth, user-mgmt, CRUD/data patterns. Trace imports, FKs, API calls, shared utils.

## 3. Epic boundary scoring

Per candidate epic score (1–10 each):

| Dimension | Signals |
|-----------|---------|
| Cohesion | shared files (+3), shared model (+2), common user goal (+3), single team (+2) |
| Independence | few deps (+3), clear API (+3), separate tables (+2), independent deploy (+2) |
| Value | standalone value (+4), metrics (+3), priority (+3) |

Size: 3–5 stories small · 6–12 medium · 13–20 large · >20 split.

## 4. Generate epics

Per discovered epic:

```bash
mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]-[name]
```

Write `epic.md` from template:
- Populate from code behavior + docs
- `[FROM SCAN]` under Information Sources for code evidence
- `[INFERRED]` for unverified inferences
- `[NEEDS CLARIFICATION: …]` for uncertain items
- Do NOT paste endpoint/file inventories into `epic.md` — those go in `epic-codebase-scan.md` via `/speck-scan --level epic`

## 5. Cross-epic analysis

Map dependencies (which epic blocks which). Detect overlap: shared files, duplicate features, unclear boundaries. Recommend build order: no-deps first → dependents.

## 6. Discovery summary (stdout only)

Return (no new report template):
- Epics: name, size, est. stories, confidence
- Dependency order
- Coverage gaps / unclear boundaries
- Next: `/epic-clarify`, `/speck-scan --level epic`, `/story-extract`, `/epic-specify`, `/project-plan`

## 7. Refinement

Present findings; ask: boundaries align with team? combine/split? Validate uncertain epics.

Route by outcome:
- Many small → suggest combine
- Few large → suggest split by journey
- Clear → `/story-extract` or `/epic-plan`
- Unclear → team input + `/speck-scan --level epic`

## Patterns

| Codebase | Approach |
|----------|----------|
| Well-structured | Trust top-level dirs |
| DDD | Bounded contexts, aggregates |
| Legacy | User capabilities over file layout |
| Microservices | Service ≈ epic; watch cross-service epics |

## NEVER / ALWAYS

- NEVER invent a discovery report template file
- NEVER put deep technical inventories in `epic.md`
- NEVER skip dependency map
- ALWAYS mark inference confidence honestly
- ALWAYS recommend `/speck-scan --level epic` before planning for evidence depth
