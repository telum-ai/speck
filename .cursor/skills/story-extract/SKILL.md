---
name: story-extract
description: Reverse-engineers story specs and code scans. Use at story entry before story-clarify when code lacks Speck artifacts.
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

## 6. Review and continue

Surface uncertain boundaries, low-confidence inferences, and gaps needing clarification. Do not create a separate extraction report.

Route: re-read the marked canonical Story flow in root `AGENTS.md` and resume at its first incomplete slot; many gaps may require scan/planning, while a scope too messy for one story becomes a debt epic.

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
