---
name: project-import
description: Extracts project context from existing docs. Use at brownfield start before speck-scan and project-specify.
---

# project-import

Lightweight brownfield bootstrap (~10 min). Does **not** analyze code — `/speck-scan --level project` does.
Output: skeleton `specs/projects/[PROJECT_ID]/project.md` + empty `epics/`.

## 1. Discover

From args or ask: project name, source path or repo URL, `[PROJECT_ID]`.

Minimal detection only (2–3 commands):

```bash
ls [PROJECT_PATH] | grep -E 'package.json|requirements.txt|pom.xml|go.mod'
find [PROJECT_PATH] -maxdepth 3 -type f \( -name '*.py' -o -name '*.ts' -o -name '*.js' \) | head -3
```

Extract: name, primary language (one), type (web/API/library/mobile), docs location if any.

Scenarios: code-only, docs-only, both.

## 2. Create structure

```bash
bash .speck/scripts/bash/create-new-project.sh --json "[PROJECT_NAME]"
```

Creates `specs/projects/[PROJECT_ID]/project.md` skeleton + `epics/`.

## 3. Minimal project.md

Mark `[INFERRED FROM CODE]` / `[INFERRED FROM DOCS]` on preliminary fields. Sections:

- Overview — type, primary language/framework from README or manifest if found
- Codebase location — absolute source path, structure hint
- Status: Imported (Needs Scan)
- Next steps block pointing to `/speck-scan --level project`

If README/docs found: high-level goals only — no architecture extraction, no epic list.

## 4. STOP depth guard

If doing comprehensive analysis, architecture extraction, or epic identification → STOP; defer to `/speck-scan --level project`, `/speck-scan --level epic`, `/speck-scan --level story`.

## 5. Continue

Re-read the canonical Entry flow in root `AGENTS.md` and continue at its first incomplete slot.

## Success criteria

| Check | |
|-------|--|
| Speck structure exists | |
| Minimal project.md | |
| User routed to scan | |
| No duplicate scan work | |

Position: first step for brownfield. Duration target: ~10 minutes.

## NEVER / ALWAYS

- NEVER deep-analyze in import
- NEVER parse all documentation
- NEVER suggest specific epics here
- ALWAYS mark inferred sections
- ALWAYS route to `/speck-scan --level project` next
