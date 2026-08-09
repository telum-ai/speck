# speck-frontier-scan / output

## Execution Steps

### 1. Perform 4-Angle SOTA Research

Invoke deep web search across the following four research angles:

1. **Architectures & Execution Topologies**: Search for multi-agent coordination, conductor/worker patterns, babysit-merge, and agent-VCS lifecycle integration.
2. **Context Engineering & long-horizon retention**: Search for model context management, JIT (just-in-time) retrieval, compaction, prompt-caching optimization, and instruction-rot prevention.
3. **Agent Verification, Reliability & Reward Hacking**: Search for agent testing harnesses, self-verification loops, adversarial protection, and reward-hacking defenses (e.g. preventing agent editing of test logic).
4. **Spec-Driven Development (SDD)**: Search for requirements grammar (e.g. EARS, Gherkin), spec-to-deployed provenance, and spec-first generation maturity curves.

### 2. Synthesize Against Speck Baseline

Compare findings against the current Speck codebase and methodology artifacts:
- What does Speck currently do well? (e.g. Promise->Build->Prove, Traceability Matrix, Adversarial Probe Suite)
- Where are the execution or context gaps?
- What are the concrete, high-value improvements (deltas)?

### 3. Map Deltas to Canonical Speck Homes

For each identified delta, find its canonical location in the Speck directory structure (per `AGENTS.md` routing table):
- Core promise rules → `product-contract.md`
- Verifiable proof rules, anti-proof, or irreversible action tiers → `evidence-contract.md`
- Codebase style, agent-behavior rules → `AGENTS.md`
- Validation logic → `.speck/scripts/validation/validators/`
- Orchestration patterns, conductor rules → `.speck/patterns/learned/process/parallel-epic-execution.md`

### 4. Author the Frontier Research Report

Write a dated, markdown-compliant research report to:
`specs/projects/<PROJECT_ID>/project-frontier-research-report-<YYYYMMDD>.md`

The report **SHALL** utilize the following template:

```markdown
# Speck Frontier SOTA Research Report (<YYYYMMDD>)

## Behavior Rules

- NEVER use vague or generic AI hype terminology in reports (e.g. "groundbreaking", "revolutionary"); keep findings cited and technically specific.
- ALWAYS cite sources with links or researcher/institution names (e.g. "Berkeley RDI, 2026").
- NEVER bypass the canonical routing table; delta actions must map to existing, valid Speck files.
- ALWAYS follow the resilient MCP/tool fallback rules if Perplexity is down or has quota limitations.

## Integration Points

- Required input: Perplexity/WebSearch access, existing Speck methodology (`AGENTS.md`).
- Required output: `project-frontier-research-report-<YYYYMMDD>.md` (with SHA stamp).
- Downstream consumers: `/project-adjust`, `/epic-adjust`, and developer-facing backlogs.
