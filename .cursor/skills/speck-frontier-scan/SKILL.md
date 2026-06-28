---
name: speck-frontier-scan
description: Execute a 4-angle SOTA frontier scan on autonomous engineering practices. Scans current academic, enterprise, and open-source benchmarks (Architectures, Context Engineering, Verification, Spec-Driven Development) using Perplexity/WebSearch, synthesizes deltas against the Speck baseline, maps them to canonical files, and proposes spec-adjustments. Recommended quarterly or on a recurring /loop cadence.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`speck-frontier-scan` is a self-refreshing, proactive process skill that prevents Speck from falling behind SOTA (State of the Art) advancements in AI-driven software engineering. 

Rather than treating methodology rules as static or frozen, this skill codifies a continuous research-and-apply ritual. It ensures that the engineering agent proactively scans for new industry standards, parses active AI evaluation reports (e.g. SWE-bench updates, Berkeley RDI, academic agentic security preprints), and updates Speck's templates, skills, and validators additively.

## When to Run

- On a scheduled `/loop` cadence (e.g. quarterly or every 30 days)
- When a major new model family or agentic framework is released
- When starting a brand new Platform-level project to establish a modern research baseline
- Explicitly requested by the user: `/speck-frontier-scan` or "refresh SOTA baseline"

## Prerequisites

- Access to Perplexity MCP (`perplexity_research` / `perplexity_search`) or resilient fallback web search tools
- Active project specs directory (`specs/projects/<PROJECT_ID>/`)

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

## 1. Executive Summary
[High-level overview of the frontier landscape, changes since the last scan, and the net impact on the active project]

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

## 3. High-Value Deltas & Canonical Mapping
| Delta ID | Description | Severity/Impact | Target Canonical Artifact | Status |
|----------|-------------|-----------------|---------------------------|--------|
| FTR-001  | [Description] | [High/Med/Low]  | `evidence-contract-template.md` | Proposed |

## 4. Proposed Action Plan (Reversible Change-Cascade)
[Provide concrete instructions or story specifications to implement the changes. If any existing validated features are affected, run compute-cascade.sh to trace the blast radius.]

*[as of SHA <commit-hash> | verified against SOTA <YYYY-MM-DD>]*
```

### 5. Apply SHA Stamp & Recheck

Apply the SHA stamp to the research report:
```bash
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/project-frontier-research-report-<YYYYMMDD>.md
```

Trigger `/project-state` to record the new frontier research report under project assets and update the state.

## Behavior Rules

- NEVER use vague or generic AI hype terminology in reports (e.g. "groundbreaking", "revolutionary"); keep findings cited and technically specific.
- ALWAYS cite sources with links or researcher/institution names (e.g. "Berkeley RDI, 2026").
- NEVER bypass the canonical routing table; delta actions must map to existing, valid Speck files.
- ALWAYS follow the resilient MCP/tool fallback rules if Perplexity is down or has quota limitations.

## Integration Points

- Required input: Perplexity/WebSearch access, existing Speck methodology (`AGENTS.md`).
- Required output: `project-frontier-research-report-<YYYYMMDD>.md` (with SHA stamp).
- Downstream consumers: `/project-adjust`, `/epic-adjust`, and developer-facing backlogs.
