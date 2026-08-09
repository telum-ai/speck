# speck-frontier-scan / lenses

## Purpose

`speck-frontier-scan` is a self-refreshing, proactive process skill that prevents Speck from falling behind SOTA (State of the Art) advancements in AI-driven software engineering. 

Rather than treating methodology rules as static or frozen, this skill codifies a continuous research-and-apply ritual. It ensures that the engineering agent proactively scans for new industry standards, parses active AI evaluation reports (e.g. SWE-bench updates, Berkeley RDI, academic agentic security preprints), and updates Speck's templates, skills, and validators additively.

## When to Run

- On a scheduled `/loop` cadence (e.g. quarterly or every 30 days)
- When a major new model family or agentic framework is released
- When starting a brand new Platform-level project to establish a modern research baseline
- Explicitly requested by the user: `/speck-frontier-scan` or "refresh SOTA baseline"
- **Product-market recheck** (`--product`): re-validate a product's differentiator / "no competitor does X" claims against the live market — on cadence, or when `/recheck` flags `MARKET_DRIFT` (see **Product Mode** below, issue #80)

## Product Mode (`--product`) — competitive-claim re-validation (issue #80)

This skill also runs against a **product's live market** instead of Speck's own methodology. Trigger: `/speck-frontier-scan --product` (or "product-market" in `$ARGUMENTS`), or when `/recheck` surfaces `MARKET_DRIFT`. It reuses the machinery above — resilient Perplexity/WebSearch, dated report, cited sources — but re-points the four angles:

1. **Direct competitors & feature parity** — who now ships the capability §3 claims is unique? Name products + dates.
2. **Substitute / DIY landscape** — free general-purpose AI + effort, OSS, free tiers (feeds `product-contract.md` §2a Value Defensibility).
3. **Category & pricing shifts** — reference-price movement, table-stakes creep, new entrants.
4. **Targeted falsification** — take each absolute claim from §3 "Core differentiator" and §3a Anti-Differentiators and assign a verdict — **HOLDS | ERODED | FALSE** — each with a cited source + date.

**Inputs**: `product-contract.md` §2a/§3/§3a, `PRD.md` Competitive Landscape, legacy `value-defensibility.md`.

**Output**: `specs/projects/<PROJECT_ID>/project-market-research-report-<YYYYMMDD>.md` (matches the existing `project-*-research-report-*.md` routing glob — no new routing row). Reuse the report skeleton above with the four angles re-pointed.

**Then**:
- Propose concrete `/project-adjust` deltas to §3 / §2a / §3a / PRD. **Never auto-rewrite §3** — the differentiator is an always-preserve; STOP-AND-PROPOSE.
- Re-stamp the differentiator via the SOLE writer (`stamp-market.sh` refuses without an existing report, and for `holds` requires `sources ≥ market_sources_floor` — so a claim can never read fresh without a real sourced re-validation behind it, P2):

  ```bash
  .speck/scripts/stamp-market.sh specs/projects/<PROJECT_ID>/product-contract.md \
    --verdict holds --sources <N> --scan project-market-research-report-<YYYYMMDD>.md
  ```

  An `eroded`/`false` verdict is stamped honestly and then treated as `MARKET_DRIFT.P1` by `/recheck` to force the fix (evaluation over verification).

**Cadence & config** (all optional in `.speck/project.json`, absent = safe default): `market_absolute_claim_days` (default **30** — deliberately below the observed ~8-week rot half-life), `market_scan_cadence_days` (default **45** for consumer/SaaS/paid-API, **90** for infra/backend), `market_sources_floor` (default **3**), `market_scan` (`false` opts a claim-free internal tool out). Sprint play level is skipped (no `product-contract.md`).
