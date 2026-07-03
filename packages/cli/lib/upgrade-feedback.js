/**
 * Maps Speck releases to feedback items they address.
 * Shown after `speck upgrade` so users know which inline patches / CI overrides can be dropped.
 */

/** @type {{ version: string; items: { id: string; summary: string }[] }[]} */
export const FEEDBACK_ADDRESSED_BY_RELEASE = [
  {
    version: '8.0.0',
    items: [
      { id: '#78', summary: 'P1 — Evaluation Over Verification: split LARP into DOES-IT-WORK vs IS-IT-GOOD, forced per-screen pixel-grounded critique' },
      { id: '#74', summary: 'P2 — Price vs Free Substitute: value-defensibility / WTP-vs-$0 gate across product, evidence, premise-challenge, skeptical-review' },
      { id: '#75', summary: 'P2/P3 — AI action-claims / laundered "unreachable": reach doctrine, action-claim audit, diagnostic playbook' },
      { id: '#76.1', summary: 'P3 — Named-blocker cap by assertion: require logged, reproduced failure of actual LARP recipe before INTEGRATION-GREEN cap' },
      { id: '#76.2', summary: 'P2 — Skipped suite reads green: speck-audit retooled for mechanism-grounded test authenticity, skipped != run' },
      { id: '#76.3', summary: 'traceability parser bug: validate-traceability-matrix.sh extracts first canonical readiness-state token via enum regex' },
      { id: '#76.4', summary: 'P1/audit — Privacy reader sweep: exhaustive reader/writer sweep for privacy epics' },
      { id: '#77.1', summary: 'story-level shuffle rerun: random-order test execution in speck-audit' },
      { id: '#77.2', summary: 'P2 — RLS test bypasses guard: RLS/authz negative tests must attempt forbidden op as a real least-privileged principal' },
      { id: 'bloat', summary: 'Consolidation: retired 3 skills, unified scan, parameterized dispatchers, demoted 20 integration patterns + 6 visual hosts to lazy-load' },
      { id: 'migration', summary: 'Two-Layer Migration: mechanical Layer 1 (.v8-reprove-needed marker) + semantic Layer 2 (/speck-reprove cap-and-worklist)' },
    ],
  },
  {
    version: '7.17.0',
    items: [
      { id: 'g-plus-acl', summary: 'G+ — Irreversible-Action Control Tiers (0-3) in evidence-contract + compliance probe to prevent unauthorized state execution' },
      { id: 'd-rules-contracts', summary: 'D — Strict boundaries between AGENTS.md, product-contract, and evidence-contract to prevent context rot' },
      { id: 'f-mcp-fallback', summary: 'F — Resilient drop-tier fallback handling in research priority for tool and API outages' },
      { id: 'e-vcs-eval', summary: 'E — VCS-as-Eval metric signal engine (compute-eval-signals.sh) for override and survival rates + EVAL_SIGNAL_DRIFT.P2 in recheck' },
      { id: 'frontier-scan', summary: 'FTR — Continuous 4-angle SOTA frontier scanning skill (speck-frontier-scan) for evergreen SOTA alignment' },
      { id: 'k-ears', summary: 'K — EARS natural language templates (WHEN/SHALL) in story-specify to reduce requirements ambiguity' },
      { id: 'j-provenance', summary: 'J — Spec-to-Deployed Behavior Provenance ledger requirements in evidence-contract SHIP criteria' },
    ],
  },
  {
    version: '7.16.0',
    items: [
      { id: '#66.1', summary: 'P0 — granted Skill tool to all 5 lanes (speck-coder/auditor/validator/planner/scribe) and documented host fallback' },
      { id: '#66.2', summary: 'grep-verify transcript check recipe for "name":"Skill" and mandated separate independent auditor' },
      { id: '#66.3', summary: 'prod-build web LARP cautions: Turbopack hydration false-blocked limits and NEXT_PUBLIC_* build-time split-brain env variables' },
      { id: '#66.4', summary: 'epic-retrospective accepts orchestration-ledger + validation/audit-reports as fallback inputs' },
      { id: '#66.5', summary: 'lint-staged conflicted merge corruption prevention via git commit --no-verify and parent validation' },
      { id: '#66.6', summary: 'worktree hygiene regular remove checks and interrupted agent WIP recovery' },
      { id: '#66.7', summary: 'migration CREATE OR REPLACE FUNCTION regression protection and balanced story decrement/refund symmetry' },
      { id: 'project-adjust', summary: 'strategic pivots and contract changes via /project-adjust flow and report templates' },
      { id: 'change-cascade', summary: 'automated reverse change-cascade blast-radius computer via compute-cascade.sh and CASCADE_STALE.P1 recheck' },
      { id: 'lifecycle-router', summary: 'continuous post-completion triage routing (defect, story-adjust, epic-adjust, project-adjust) and softened retrospectives' },
      { id: 'legibility-probe', summary: 'first-time user comprehension/legibility check in project-validate and LEGIBILITY.P1 gate cap' },
    ],
  },
  {
    version: '7.15.0',
    items: [
      { id: '#65', summary: '/story-adjust + /epic-adjust deliberate post-validation re-engineering flow and reports (distinct from defect /harden)' },
      { id: 'G1', summary: 'G1 — schema-drift detection for INTEGRATION-GREEN: live database objects matched to migrations + write-path check' },
      { id: 'G2', summary: 'G2 — clean build requirement before UX-RC LARP claims to prevent stale incremental caches' },
      { id: 'G3', summary: 'G3 — full pre-commit gate (tests, eslint, typecheck, banned-language, build) verification for delegated sub-agents' },
      { id: 'G4', summary: 'G4 — traceability-matrix retrofit/finalization mode + pilot-gated lifecycle status and Backing column' },
    ],
  },
  {
    version: '7.14.2',
    items: [
      { id: 'S5', summary: 'banned-language-lint.sh line 40 — empty-safe EXTRA_ARGS expansion for bash 3.2 + set -u (macOS pre-commit crash)' },
      { id: 'S6', summary: 'banned-language-lint --staged scopes to product surfaces only (framework/specs excluded — Speck upgrade commits pass)' },
    ],
  },
  {
    version: '7.14.1',
    items: [
      { id: 'S1', summary: 'INTEGRATION-GREEN state — real round-trip smoke per evidence-contract §7 external service (catches mock-blind 429/auth failures)' },
      { id: 'S2', summary: 'Cap Status column in deferral tables — implementation-pending caps at NO-SHIP (unbuilt code cannot pass as IMPL-GREEN)' },
      { id: 'S3', summary: 'API-RC evidence partition in evidence-contract §8 (autonomous vs human/creds-gated)' },
      { id: 'S4', summary: 'Placeholder scanner skips bracketed code tokens; story-spec accepts As a|an|the user stories' },
    ],
  },
  {
    version: '7.14.0',
    items: [
      { id: 'E1', summary: 'Promise conservation: traceability-matrix.md + validate-traceability-matrix.sh (epic-plan produces, epic-analyze blocks, story-validate cites, epic-validate re-walks)' },
      { id: 'E2', summary: 'Design docs are promises — wireframes/experience-chain seams enumerated or DEC-descoped ("wireframes are inspiration" banned)' },
      { id: 'E3', summary: 'Anti-simulation Verify-Skills Gate + sub-agent return contract (skills_invoked) in /epic + /story; advance-on-evidence not file-presence' },
      { id: 'E4', summary: 'Chaining/continuation closers in story-specify/epic-specify/speck-audit — orchestrated runs do not stop at the menu' },
      { id: 'E5', summary: 'UX-RC autonomous-vs-gated partition in evidence-contract; built-app browser LARP + stored axe JSON; deferral classification in report templates' },
      { id: 'E6', summary: 'Parallel-epic-execution pattern + orchestration-ledger (survives compaction/spend/rate-limit)' },
      { id: 'E7', summary: 'Push-before-spawn, worktree disk hygiene, real wall-clock migration timestamps (concurrency guards)' },
      { id: '#62', summary: 'settings-drift-check.sh mapfile → bash-3.2 read-loop + portability lint' },
      { id: '#63', summary: 'banned-language-lint.sh §7 phrase-splitting + scope (drop specs/) + whole-word matching' },
      { id: 'E8', summary: 'validate-readiness-evidence scans screenshots/+larp-evidence/; guide-not-block rejection messages; NEXT_PUBLIC bundle-scan allowlist note' },
    ],
  },
  {
    version: '7.13.3',
    items: [
      { id: 'G1', summary: 'Epic-level worktree isolation + daily rebase cadence documented in AGENTS.md' },
      { id: 'G2', summary: 'Per-epic DEC bands in speck-decision-log (E002 → DEC-0201+) prevent number races' },
      { id: 'G3', summary: 'project-state.md merge-only regen on epic/* branches — skip local overwrite' },
      { id: 'G4', summary: 'Migration ownership rule — own-your-tables, freeze foundation, 14-digit UTC timestamps' },
      { id: 'G5', summary: 'Epic concurrency waves in epics-list-template + project-plan; integrator gating' },
      { id: 'G6', summary: '/speck parallel epic spawn affordance with wave-safety validation' },
    ],
  },
  {
    version: '7.13.2',
    items: [
      { id: 'S1', summary: 'Ambition-aware UI path in epic-specify — Redesign Ambition blocks Rubric Mode default' },
      { id: 'S2', summary: 'Promise-coverage (unaddressed-promise gap) check in epic-analyze and project-analyze' },
      { id: 'S3', summary: 'Forbidding-context filter for banned-language-lint (NOT This / Banned columns)' },
      { id: 'S4', summary: 'banned-language-lint --staged + pre-commit hook wiring' },
      { id: 'S5', summary: 'validate-epic-spec X-Y range parse + overview awk fix' },
      { id: 'S6', summary: 'speck-decision-log index reconciliation from DEC- headings' },
      { id: 'S7', summary: 'staleness-check false-DRIFT fix via rev-list commit count' },
    ],
  },
  {
    version: '7.13.1',
    items: [
      { id: 'F1', summary: 'Form Validation Matrix in ui-spec-template.md and story-ui-spec' },
      { id: 'F2', summary: 'Anti-Surrogate Rules in speck-audit (prohibit API bypass of UI)' },
      { id: 'F3', summary: 'Pass-Count Honesty & Test Hygiene in evidence-contract' },
      { id: 'F4', summary: 'Keystone Dependencies convention + skip-with-reason rules' },
      { id: 'F5', summary: 'JTBD cold-start LARP as centerpiece of epic validation' },
      { id: 'F6', summary: 'Mandatory validation report Deferrals/Not Verified section' },
      { id: 'F7', summary: 'validate-story-spec resilience to Status vs Current State header' },
      { id: 'F8', summary: '/harden flow and harden-report template for post-validate fixing' },
      { id: 'F9', summary: 'Artifact-Config Drift as SHIP-RC only class to prevent false UX-RC claims' },
      { id: 'F10', summary: 'Boundary-crossing try-catch error attribution check' },
    ],
  },
  {
    version: '7.8.0',
    items: [
      { id: 'H1', summary: 'Command-type Stop hook (lifecycle-scoped)' },
      { id: 'H2', summary: 'SPECK-managed settings blocks + reconcile-settings' },
      { id: 'H3', summary: 'SETTINGS_DRIFT detection on /recheck' },
      { id: 'H4', summary: 'Auto-reconcile on speck upgrade / init' },
    ],
  },
  {
    version: '7.9.0',
    items: [
      { id: '—', summary: 'larp-play, compress, visual assets pipeline, readiness evidence gates' },
    ],
  },
  {
    version: '7.9.1',
    items: [
      { id: 'V1', summary: 'pre-commit-hook empty-array unbound variable' },
      { id: 'V2', summary: 'Multi-line bracket placeholder false-positive' },
      { id: 'V3', summary: 'Fenced code-block placeholder skip' },
      { id: 'V4', summary: 'Generic-ID descriptive-reference filter' },
      { id: 'V5', summary: 'validate-story-spec Draft (Placeholder) lifecycle gating' },
    ],
  },
  {
    version: '7.9.2',
    items: [
      { id: '—', summary: 'larp-play unused import removed' },
    ],
  },
  {
    version: '7.12.1',
    items: [
      { id: 'M1', summary: 'Rendering Gotchas in primitives registry + audit/visual-quality grep for pixel-level anti-patterns' },
      { id: 'M2', summary: 'Asset single-source norm + asset-drift-check.sh for duplicate SVG geometry (ASSET_DRIFT.P1 on /recheck)' },
      { id: 'M3', summary: 'Brownfield UI Rubric Mode in /epic-specify — shared Screen Rubric instead of duplicate wireframes' },
    ],
  },
  {
    version: '7.11.0',
    items: [
      { id: 'P1a', summary: 'Quality Judgment loop (Judge -> Fix -> Re-prove) added to evidence-contract' },
      { id: 'P1b', summary: 'Numeric 0-10 JTBD scoring with hard caps and anti-inflation rules' },
      { id: 'P1c', summary: 'Density budget prompt added to experience-chain and ui-spec templates' },
      { id: 'P1d', summary: 'Signal -> Reaction Ledger added to product-contract' },
      { id: 'P1e', summary: 'Longitudinal Proof Mode and timeline.jsonl requirements' },
      { id: 'P2a', summary: 'Human Language Pass guidelines added to product-contract and validation reports' },
      { id: 'P2b', summary: 'speck validate --active-only and pre-commit reconcile hint for legacy projects' },
      { id: 'P2c', summary: 'LARP Runway and build fingerprinting efficiency controls' },
      { id: 'Drift', summary: 'Intra-v7 template-drift detector (manifest + header-diff check) on upgrade & recheck' },
    ],
  },
  {
    version: '7.10.1',
    items: [
      { id: 'P3-fix', summary: 'Orchestrator driving pattern corrected — /story and /epic MUST invoke downstream skills, not inline artifacts' },
    ],
  },
  {
    version: '7.10.0',
    items: [
      { id: 'P1', summary: 'Version-pin freshness check in epic-tech-spec template' },
      { id: 'P2', summary: 'typecheck in tasks-template verification phase' },
      { id: 'P3', summary: '/story and /epic orchestrators MUST invoke downstream skills (anti-pattern fix in v7.10.1)' },
      { id: 'P4', summary: 'Upgrade output lists addressed feedback items' },
      { id: 'P5', summary: 'Feedback file template at .speck/templates/feedback/template.md' },
      { id: 'P6', summary: 'Constitution-as-code pattern doc' },
      { id: 'V6', summary: 'validate-artifact-docs aligned to v7 canonical artifacts' },
      { id: 'V7', summary: 'Recipe extends: chain validation' },
    ],
  },
];

function parseVersion(v) {
  return parseFloat(String(v).replace(/^v/, ''));
}

/**
 * @param {string} fromVersion
 * @param {string} toVersion
 * @returns {{ version: string; items: { id: string; summary: string }[] }[]}
 */
export function getFeedbackAddressedBetween(fromVersion, toVersion) {
  const from = parseVersion(fromVersion);
  const to = parseVersion(toVersion);
  if (Number.isNaN(from) || Number.isNaN(to) || to <= from) {
    return [];
  }
  return FEEDBACK_ADDRESSED_BY_RELEASE.filter((entry) => {
    const v = parseVersion(entry.version);
    return v > from && v <= to;
  });
}

/**
 * @param {string} fromVersion
 * @param {string} toVersion
 */
export function printFeedbackAddressed(fromVersion, toVersion) {
  const entries = getFeedbackAddressedBetween(fromVersion, toVersion);
  if (entries.length === 0) return;

  console.log('\n📬 Addresses feedback from prior sessions:');
  for (const entry of entries) {
    console.log(`   ${entry.version}:`);
    for (const item of entry.items) {
      console.log(`     • ${item.id} — ${item.summary}`);
    }
  }
  console.log('\n   If you applied inline patches for fixed items, drop them after verifying upgrade.');
  console.log('   Remove any `continue-on-error: true` CI overrides for fixed validators.');
}
