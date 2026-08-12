---
name: speck-learn
description: Captures a project learning at discovery. Use when waiting for retrospective risks losing or repeating it.
---

# speck-learn

Capture the smallest durable truth and apply it where it is already binding.

1. Classify it as `PATTERN`, `GOTCHA`, `PERF`, `ARCH`, `RULE`, or `DEBT`.
2. Record context, evidence, scope, and the next application in the current story artifact or commit body. A `DEBT` also names its owner and trigger.
3. Update affected specs, plans, tests, decisions, or code now; do not create a second source of truth just to preserve the observation.
4. A first occurrence stays local and is harvested by `story-retrospective`. Repeated, independently useful occurrences may be promoted by epic or project retrospective into project-owned `.speck/patterns/learned/`.
5. Route a Speck template, script, or methodology defect to `speck-feedback`; it is not a project pattern.

Promotion requires evidence of recurrence and a named consumer. Vanilla Speck ships no learned project patterns.
