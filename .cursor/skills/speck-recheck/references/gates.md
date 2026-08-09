# speck-recheck / gates

## 5. Update project-state.md

Invoke `/project-state`. Populate blocking issues (P0/P1), truth staleness, `[NEEDS USER REVIEW]` appendix, REPLACE marker appendix. Next action: resolve drift before feature work.

## 6. Decision gate

| Finding | Action |
|---------|--------|
| `V8_REPROVE.P1` | BLOCK feature work → `/speck-reprove` first |
| P0 drift | BLOCK feature work; surface remediations; recommend `/audit`; refuse `/story-implement`, `/epic-plan` |
| `MARKET_DRIFT.P1` / `WEDGE_DRIFT.P1` | Do not block implement; BLOCK COMMERCIAL-RC/SHIP-RC and spec-derived marketing copy until `/speck-frontier-scan --product` or `/project-adjust` |
| Analysis P1 codes | Do not block in-flight story; BLOCK next `/epic-specify` until `/project-analyze` clears |
| `ANALYSIS_GRANDFATHERED.P2` | Never block; surface loudly every recheck |
| P1–P3 only | Surface; user proceeds at discretion |
| No drift | Before re-stamp: run `observe-guard.sh --licenses accumulating` on observation-based findings; `OBSERVATION_UNEXPOSED_BLOCKING.P1` → hold those artifacts; re-stamp rest. Otherwise re-stamp all truth artifacts with fresh `verified` date |

## 7. Write report

Path: `specs/projects/<PROJECT_ID>/project-recheck-report-<YYYYMMDD>.md`. Template in skill references.

```bash
bash .speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/project-recheck-report-<YYYYMMDD>.md
```

Report summary per skill template. Always write dated report even if green.

## Integration

Reads: truth artifacts, personas, staleness/replace-marker scripts.
Invokes: `/larp`, `/project-state`.
Writes: dated recheck report; re-stamps truth artifacts on green.

## Host portability

Subagent parallelization (speck-scanner, speck-auditor) preferred on Claude; Cursor/Codex run core scripts sequentially in main context. Evidence requirements identical across hosts.
