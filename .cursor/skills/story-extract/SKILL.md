---
name: story-extract
description: Extracts stories from epic materials. Use when mining story candidates.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story-extract

Input: `$ARGUMENTS` (project, epic, code path, focus).
Output: `[STORY_DIR]/spec.md`, `[STORY_DIR]/codebase-scan-extracted.md`.
Templates: `.speck/templates/story/story-template.md`, `.speck/templates/story/codebase-scan-template.md`.

## 0. Templates

Read both templates before writing.

## 1. Context

Resolve project + epic + code location from args or ask.

## 2. Find story boundaries

| Layer | Indicators |
|-------|------------|
| Frontend | pages, forms, UI features, interactions |
| Backend | endpoints, business ops, DB transactions, jobs |
| Full-stack | complete workflows, feature flags, test suites |

Size: single story · multiple · partial · epic-level (too large → split).

## 3. Code comprehension

```bash
grep -E 'function|class|export|def' [FILE] | head -20
grep -r '[SYMBOL]' [PROJECT_PATH] --include='*.{js,ts,py,java,go}' | grep -v node_modules
find [PROJECT_PATH] -name '*test*' -o -name '*spec*' | xargs grep -l '[FEATURE]' 2>/dev/null
grep -r '[FEATURE]' [PROJECT_PATH] --include='*.md'
```

Infer: user (auth/routes), action (names/endpoints), value (comments/docs). AC from validation rules, logic branches, outputs, error paths.

## 4. Write artifacts

Per story:

```bash
mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-[name]
```

**spec.md** (WHAT/WHY):
- Fill story template from observed behavior
- `[NEEDS CLARIFICATION: …]` for uncertain
- No file inventories or schemas here

**codebase-scan-extracted.md** (HOW/WHERE):
- Fill scan template: files, routes, models, integrations, validation/error patterns, tests, debt
- `[FROM SCAN]` — verified from code
- `[INFERRED]` — not directly verified

## 5. Bulk extraction

Batch: list endpoints, pages, service methods → group into stories (CRUD separate; multi-step workflow single).

## 6. Extraction summary (stdout)

Return (no report template file):
- Scope analyzed
- Stories created/updated
- Per-story: Complete / Partial / Unknown + confidence
- Gaps needing clarification
- Next: `/story-clarify`, `/story-plan`, `/story-validate`, `/speck-scan --level story`

## 7. Review

Present count + confidence; ask: boundaries correct? rules accurate?

Route: mostly complete → validate; many gaps → plan/scan; messy → debt epic.

## Patterns

| Code | Confidence |
|------|------------|
| Well-documented | High |
| Test-driven | High — extract from test names |
| Legacy | Lower — more clarification |
| Prototype | Gaps expected |

## NEVER / ALWAYS

- NEVER invent extraction report template
- NEVER put implementation inventories in spec.md
- NEVER mark inferred behavior as verified
- ALWAYS write both spec + scan-extracted
- ALWAYS report confidence per story
