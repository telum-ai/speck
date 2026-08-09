# project-evidence-contract / sprint

### 1. Detect project, play level, and archetype

Find `specs/projects/<PROJECT_ID>/`. Read `.speck/project.json` → `play_level` and `project_archetype`. (If `project_archetype` is missing, default to `consumer_product` or infer from stack/context).
Read `_active_recipe` field from `project.md` frontmatter.

If recipe exists, load `.speck/recipes/<recipe>/recipe.yaml` → `evidence_contract:` section (defaults per recipe).

**Archetype Adaptation**:
Adapt your writing of the template sections based on the detected `project_archetype` (see `evidence-contract-template.md` for explicit WHEN/SKIP criteria):
- **For `infra_service` / `backend_api` (Non-UI / Systems work)**:
  - In Section 4 (LARP), write the "Integration / Stress-Test Scenarios" (Option B).
  - In Section 7 (Readiness State Gate Criteria), map to API-RC, metered billing, and OPERATIONAL-RC.
- **For `consumer_product` / `b2b_saas` / `internal_tool` (UI/Human-facing products)**:
  - Write standard Option A human-persona-based LARP and standard UX-RC/SHIP-RC gate checklists.

### 2. Read prerequisites (parallel)

```
├── [Parallel] speck-explorer: Read product-contract.md (magic moments + AI behavior contract inform LARP requirements)
├── [Parallel] speck-explorer: Read context.md (platform constraints, compliance requirements)
├── [Parallel] speck-explorer: Read architecture.md if exists (external services + integrations)
└── [Parallel] speck-explorer: Read recipe.yaml visual_testing + evidence_contract sections
```

### 3. Identify target platforms

Ask user (with recipe defaults pre-filled):
- "What platforms ship in production?"
- For each platform: build artifact + distribution

### 4. Per-platform proof rules (skeptical-review primitive)

For each platform, the evidence is platform-specific. Common starting points by platform:

| Platform | Valid proof (start) | Invalid proof (start) |
|----------|---------------------|------------------------|
| iOS native (Expo/RN/native) | Standalone sim build, TestFlight, AXe screenshots, AX trees, native logs | Browser localhost, Expo Go, Safari, dev-client launcher |
