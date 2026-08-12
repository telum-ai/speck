## Canonical Directory Structure

```
specs/projects/<PROJECT_ID>/
├── project-state.md            # PROVE: Auto-regenerated, single page. First read on engagement.
├── product-contract.md         # PROMISE: Paid promise + JTBD + magic moments + banned language + AI contract
├── evidence-contract.md        # PROVE: What counts as proof for this product
├── project-decisions-log.md    # PROVE: Decision locks with SHA + alternatives
├── project.md                  # PROMISE: Vision (current state — TRUTH)
├── PRD.md                      # PROMISE: Requirements (current state — TRUTH)
├── context.md                  # PROMISE: Constraints (current state — TRUTH)
├── architecture.md             # PROMISE: System design (current state — TRUTH; req. Platform / 4+ epic Build)
├── epics.md                    # BUILD: Epic index
├── project-analysis-report.md  # PROVE: Decorrelated multi-lens analysis of the planning corpus (req. Platform / 4+ epic Build)
├── constitution.md             # PROMISE: Principles + enforcement mechanisms (optional at Build)
├── domain-model.md             # PROMISE: Terminology (optional at Build; merged into product-contract)
├── ux-strategy.md              # PROMISE: UX principles (optional at Build; merged into product-contract)
├── design-system.md            # PROMISE: Design tokens + primitives index (optional at Build)
├── design-system/
│   └── primitives.md           # BUILD: Live primitive registry (UI projects)
├── personas/<id>.md            # PROVE: Detection signals + LARP script per persona
├── adaptive-axes/<name>.md     # PROMISE: Adaptive behavior decomposition (if product adapts)
├── project-import.md           # Brownfield only
├── project-landscape-overview.md  # Brownfield only
├── graph/witness.json          # PROVE: DERIVED witness graph; regenerated, never hand-edited
└── epics/E###-name/
    ├── epic.md                 # PROMISE: Epic scope
    ├── experience-chain.md     # BUILD: Required for UI epics
    ├── epic-tech-spec.md       # BUILD: Approach
    ├── traceability-matrix.md  # BUILD: Promise conservation ledger (PRM rows)
    ├── epic-breakdown.md       # BUILD: Story mapping
    ├── epic-validation-report.md  # PROVE: JTBD walkthrough included
    └── stories/S###-name/
        ├── spec.md             # PROMISE+BUILD: User experience-first spec
        ├── plan.md             # BUILD: Technical approach
        ├── tasks.md            # BUILD: Implementation checklist
        ├── story-analysis-report.md  # PROVE: Decorrelated multi-lens analysis (req. Build/Platform)
        ├── connoisseur-critique.md  # PROVE: Taste/craft critique (speck-larp Job C IS-IT-CRAFTED)
        ├── audit-report.md     # PROVE: Skeptical audit
        ├── validation-report.md  # PROVE: Evidence-backed, declares readiness state
        ├── screenshots/        # PROVE: Runtime LARP evidence (checked in)
        └── larp-recordings/    # PROVE: Recorded execution traces
```

**Naming**: `E###-epic-name` (or the ordinal `001-epic-name` as many repos use), `S###-story-name`. The witness graph's canonical epic id is the **dir basename**; cross-epic references resolve by ordinal shorthand (`004/S012`), full-dir, or bare-within-epic (`S012`). Acceptance criteria are `AC-N` anchors in story §2b; magic moments `MM-N` and jobs `JOB-N` in the product-contract — the number is the machine key a reference binds to.


## Canonical-Doc Routing (FORBID non-canonical filenames in `specs/`)

When you have content to write down, route it to its canonical home. **Never invent a new filename** in `specs/`. If you can't find a canonical home below, you've misidentified the content type — re-read this table, then ask the user before creating anything bespoke.

### Project-level (`specs/projects/<id>/`)

| Content type | Canonical home |
|---|---|
| Project vision changes | `project.md` |
| Requirements/features delivered | `PRD.md` |
| Epic index (waves, dependencies, E000 gate) | `epics.md` |
| Architectural decisions | `architecture.md` |
| Constraints discovered | `context.md` |
| Paid promise / differentiator / JTBD / magic moments / banned language | `product-contract.md` |
| Proof requirements / readiness gates / valid/invalid evidence sources | `evidence-contract.md` |
| Phase-boundary decisions (locked) | `project-decisions-log.md` |
| Current state for next-session pickup (auto-regen) | `project-state.md` |
| Drift / re-engagement report | `project-recheck-report.md` |
| Legacy truth re-prove report (cap-and-worklist) | `project-v8-reprove-report.md` |
| Pre-execution analysis of the planning corpus (decorrelated multi-lens) | `project-analysis-report.md` |
| Project-level skeptical audit findings | `project-audit-report.md` |
| Post-validation hardening report | `project-harden-report-*.md` |
| Post-validation project adjustment report | `project-adjust-report-*.md` |
| Project punch list (remaining work to ship) | `project-punch-list.md` |
| Project validation summary (companion to project-validation-report.md) | `project-validation-summary.md` |
| Multi-epic sequencing, dependencies, and resource plan | `project-roadmap.md` |
| Locked interface between parallel-executing epic/story owners (shared file/schema/migration serialization) | `seam-contract-*.md` |
| Sprint progress (Sprint play level only) | `sprint-log.md` |
| Domain terminology + entities + rules (Platform; merges to product-contract at Build) | `domain-model.md` |
| UX principles + voice/tone (Platform; merges to product-contract at Build) | `ux-strategy.md` |
| Technical principles (Platform; optional Build) | `constitution.md` |
| Design tokens / system (Platform; optional Build) | `design-system.md` |
| Live UI primitives registry (UI projects, all levels) | `design-system/primitives.md` |
| Per-persona detection + LARP script | `personas/<id>.md` |
| Adaptive behavior axes | `adaptive-axes/<name>.md` |
| Project retrospective | `project-retro.md` |
| Project validation evidence | `project-validation-report.md` |
| Project-level research report | `project-*-research-report-*.md` |
| Brownfield non-code import | `project-import.md` |
| Brownfield landscape overview | `project-landscape-overview.md` |
| Project learning | Current story/retro first; promote repeated reusable rules to project-owned `.speck/patterns/learned/` |
| Speck methodology defect | No project artifact; use `speck-feedback` |

### Workspace-level (repo root — not under `specs/`)

| Content type | Canonical home |
|---|---|
| GitHub / public project identity | Root `README.md` (user-owned body; Speck manages `<!-- SPECK:START -->` footer) |
| Agent methodology instructions | `AGENTS.md` (Speck manages `<!-- SPECK:START -->` block) |
| Speck methodology reference | `.speck/README.md` (always methodology — never project identity) |

### Epic-level (`specs/projects/<id>/epics/E###-name/`)

| Content type | Canonical home |
|---|---|
| Epic scope + value proposition | `epic.md` |
| Epic-specific principles (rare) | `constitution.md` (epic-level) |
| Epic-specific context (rare) | `context.md` (epic-level) |
| Epic technical architecture (cross-cutting epics) | `epic-architecture.md` |
| Epic technical approach (output of epic-plan) | `epic-tech-spec.md` |
| Promise conservation ledger (every upstream promise → story+AC, DEC, or open) | `traceability-matrix.md` |
| Runtime breadth coverage (opt-in torture tier; every cell RUN/waived/GAP) | `coverage-matrix.md` |
| Story map + ordering | `epic-breakdown.md` |
| Cross-screen UI flow + emotional state (REQUIRED for UI epics) | `experience-chain.md` |
| Backfilled UI-epic experience chain (pre-v7 brownfield migration exemption) | `experience-chain-historical.md` |
| User journey map | `user-journey.md` |
| Wireframes (epic-level) | `wireframes.md` |
| Epic-level skeptical audit findings | `audit-report.md` |
| Epic validation report (JTBD walkthrough) | `epic-validation-report.md` |
| Epic punch list (remaining work to ship) | `epic-punch-list.md` |
| Post-validation epic adjustment report | `epic-adjust-report-*.md` |
| Epic-level pre-implementation analysis (decorrelated multi-lens) | `epic-analysis-report.md` |
| Epic retrospective | `epic-retro.md` |
| Epic-scoped research report | `epic-*-research-report-*.md` |
| Brownfield epic-scoped code scan | `epic-codebase-scan*.md` |

### Story-level (`specs/projects/<id>/epics/E###-name/stories/S###-name/`)

| Content type | Canonical home |
|---|---|
| Story requirements + acceptance LARP + evidence required | `spec.md` |
| Story technical design | `plan.md` |
| Implementation task checklist | `tasks.md` |
| Data model | `data-model.md` |
| API/library contracts | `contracts/*.md` |
| UI spec (REQUIRED for UI-bearing stories) | `ui-spec.md` |
| Test scenarios / quickstart / manual validation | `quickstart.md` |
| Story-level pre-implementation analysis (decorrelated multi-lens; required Build/Platform) | `story-analysis-report.md` |
| Taste/craft critique (per-screen GOOD/ACCEPTABLE/BAD; witness-graph verdict source) | `connoisseur-critique.md` |
| Story-level skeptical audit findings | `audit-report.md` |
| Story validation evidence (declares readiness state) | `validation-report.md` |
| Post-validation story adjustment report | `story-adjust-report-*.md` |
| Story retrospective | `story-retro.md` |
| Runtime LARP screenshots / recordings (checked-in evidence) | `screenshots/`, `larp-recordings/`, `larp-evidence/` |
| Story-scoped research report | `story-*-research-report-*.md` |
| Brownfield story-scoped code scan | `codebase-scan-*.md` |

If a user requests bespoke docs (e.g., "create a positioning brief", "make a launch plan doc") — route the content into the canonical home and tell them where it landed. The ONLY exception is the user explicitly authoring a one-off note to themselves that should NOT inform agent decisions; in that case, name it `notes/<topic>.md` and exclude it from canonical reads.
