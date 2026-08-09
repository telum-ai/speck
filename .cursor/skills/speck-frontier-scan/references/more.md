# speck-frontier-scan / more

## When to Run

- On a scheduled `/loop` cadence (e.g. quarterly or every 30 days)
- When a major new model family or agentic framework is released
- When starting a brand new Platform-level project to establish a modern research baseline
- Explicitly requested by the user: `/speck-frontier-scan` or "refresh SOTA baseline"
- **Product-market recheck** (`--product`): re-validate a product's differentiator / "no competitor does X" claims against the live market — on cadence, or when `/recheck` flags `MARKET_DRIFT` (see **Product Mode** below, issue #80)

## 2. The 4-Angle SOTA Audit
### Angle 1: Architectures & Execution Topologies
- **Frontier Findings**: ...
- **Speck Baseline Comparison**: ...

### Angle 2: Context Engineering & Retention
- **Frontier Findings**: ...
- **Speck Baseline Comparison**: ...

### Angle 3: Agent Verification & Reward Hacking
- **Frontier Findings**: ...
- **Speck Baseline Comparison**: ...

### Angle 4: Spec-Driven Development (SDD)
- **Frontier Findings**: ...
- **Speck Baseline Comparison**: ...

## Behavior Rules

- NEVER use vague or generic AI hype terminology in reports (e.g. "groundbreaking", "revolutionary"); keep findings cited and technically specific.
- ALWAYS cite sources with links or researcher/institution names (e.g. "Berkeley RDI, 2026").
- NEVER bypass the canonical routing table; delta actions must map to existing, valid Speck files.
- ALWAYS follow the resilient MCP/tool fallback rules if Perplexity is down or has quota limitations.

## 3. High-Value Deltas & Canonical Mapping
| Delta ID | Description | Severity/Impact | Target Canonical Artifact | Status |
|----------|-------------|-----------------|---------------------------|--------|
| FTR-001  | [Description] | [High/Med/Low]  | `evidence-contract-template.md` | Proposed |

## Integration Points

- Required input: Perplexity/WebSearch access, existing Speck methodology (`AGENTS.md`).
- Required output: `project-frontier-research-report-<YYYYMMDD>.md` (with SHA stamp).
- Downstream consumers: `/project-adjust`, `/epic-adjust`, and developer-facing backlogs.

## Prerequisites

- Access to Perplexity MCP (`perplexity_research` / `perplexity_search`) or resilient fallback web search tools
- Active project specs directory (`specs/projects/<PROJECT_ID>/`)

## 1. Executive Summary
[High-level overview of the frontier landscape, changes since the last scan, and the net impact on the active project]
