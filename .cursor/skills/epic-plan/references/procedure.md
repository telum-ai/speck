# epic-plan — procedure

Input: `$ARGUMENTS`.
Output: `[EPIC_DIR]/epic-tech-spec.md`, `[EPIC_DIR]/traceability-matrix.md`.
Templates: `.speck/templates/epic/epic-tech-spec-template.md`, `.speck/templates/epic/traceability-matrix-template.md`.
Prereq: `epic.md` exists (`/epic-specify`); `/epic-constitution` before plan if constitution needed.

## 0. Templates

Read both templates before writing.

## 1. Load corpus

STOP if `epic.md` missing → `/epic-specify`.

Load (if present):
- `epic.md`, `PRD.md`, `project.md`
- `product-contract.md` — §1/§3/§3a/§4/§5/§10 routed to this epic
- `experience-chain.md` — every seam rule §2–§9
- `wireframes.md`, `user-journey.md`
- `epic-architecture.md`, `epic-*-research-report-*.md`, `epic-codebase-scan*.md`
- `[EPIC_DIR]/constitution.md` + `specs/projects/[PROJECT_ID]/constitution.md` — combined MUST/SHOULD; note deviations explicitly
- `ux-strategy.md`, `design-system.md`

UI epic without journey/wireframes → WARN; do not block.

## 2. Architecture gate

Run separate `/epic-architecture` if ANY: cross-cutting; new pattern; new external dep; complex data model (>5 entities); security-critical; strict SLA; high ambiguity.

Skip embed if ALL: established patterns; single domain; standard CRUD; clear path.

If `epic-architecture.md` exists → architecture-informed mode; else direct mode + inline decisions.

## 3. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`. Gap areas: implementation patterns, libraries, integration, testing, performance.

Deep research needed → PAUSE: write `epic-plan-research-prompt-[topic].md`; user runs external research → `epic-plan-research-report-[topic].md`; re-run.

Parallel subagents optional for research topics.

## 4. Write epic-tech-spec.md

Fill template from corpus + research. Embed findings in "Research Informing This Specification."

Incorporate UX when present:
- Journey stages → story groupings
- Wireframe screen inventory → UI story list
- Pain points → UX quality requirements
- Add "UX Design Context" section

Update `epic.md` status → Technical Specification Complete.

## 5. Promise traceability matrix (REQUIRED)

Read `.speck/templates/epic/traceability-matrix-template.md`.

Enumerate every promise → `PRM-NNN` row at **status=open** (or **pilot-gated** if retrofitted):

| Source | Promises |
|--------|----------|
| `product-contract.md` | §1/§3/§3a/§4/§5/§10 for this epic |
| `epic.md` | Every `FR-[EPIC]-###`, `NFR-###` |
| `wireframes.md` | Every screen + element/state (Default/Loading/Empty/Error/Success) |
| `experience-chain.md` | Every seam §2–§9 |
| Absent source | Write `N/A — no UI surface` (never assume) |

Retrofit mode: seed from `audit-report.md` or scan; consolidate with fine-grained refs in `Backing` column.

Write `[EPIC_DIR]/traceability-matrix.md`. Ledger for `/epic-analyze` + `/epic-validate`.

Validate:
```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh [EPIC_DIR]
```

Missing matrix → P1; re-run step 5.

## 6. Validation

- All stories have technical approach
- Architecture supports requirements
- Security + performance addressed
- Research embedded with sources

## 7. Next

| Step | When |
|------|------|
| `/epic-breakdown` | Required — story mapping |
| `/epic-analyze` | Required before ANY story work |
| `/story-specify` | After analyze CLEAN/NEEDS_FIXES |
| `/epic-validate` | After all stories validated — NOT planning |

## NEVER / ALWAYS

- NEVER skip traceability matrix
- NEVER omit wireframe element or seam from matrix
- NEVER run `/epic-constitution` after plan when rules should constrain spec — run first, re-plan
- NEVER hand-enumerate MM/JOB — use graph at analyze time
- ALWAYS load `product-contract.md` + `experience-chain.md` when present
- ALWAYS embed research in spec, not orphan prompts
