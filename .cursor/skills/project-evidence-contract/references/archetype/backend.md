# project-evidence-contract / backend

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
Valid proof sources defined: <count>
Invalid proof sources defined: <count>
Readiness states with gate criteria: 8 (NO-SHIP, IMPL-GREEN, INTEGRATION-GREEN, UX-RC, API-RC, COMMERCIAL-RC, SHIP-RC, SHIP)
LARP requirements: <count> personas × <count> states
Adversarial probes: <count>

Next steps:
1. Review the contract — this is what validation gates will enforce
2. /project-plan can now proceed (PRD + epics)
3. Stories' validation reports will be checked against these criteria
```

## Boundaries (Rules vs Contracts)

To prevent competing constitutions and instruction rot, there is a strict separation of concerns between project governance files:
1. **`AGENTS.md` (Workspace Agent Rules)**: Workspace-level static configuration and general behavior instructions for all AI agents entering the repo (general tooling, coding style, CLI shortcuts, and command mappings).
2. **`product-contract.md` (The Promise)**: Product-level specification outlining the paid promise, core user personas, magic moments, and user-facing copy/language constraints.
3. **`evidence-contract.md` (The Proof)**: Operational contract defining what counts as verifiable proof of functional correctness and readiness states, invalid proof sources, and adversarial probes.

These files must never duplicate or contradict instructions. `evidence-contract.md` must focus purely on verifying that the promise is kept at runtime via concrete, tamper-proof evidence sources.

## Behavior Rules
