/**
 * ENFORCES the model-tiering doctrine (see `.speck/reference/host-capabilities.md`) and the
 * decoupled per-harness generation.
 *
 * Source of truth: `.cursor/agents/speck-*.md` owns the body; `agent-dispatch.json` owns the
 * roster, tier, independence, and canonical skills. `generate-agents.js` derives every `model`
 * value and the `.claude/*.md` + `.codex/*.toml` outputs via per-harness maps (Claude
 * bare aliases, Cursor slugs with no Sonnet/Haiku, Codex GPT slugs).
 *
 * Three guards:
 *  1. every agent's source `tier` matches its role in the doctrine (ROLE_TIER) — the "never
 *     cheap the planner or the auditor" rule, encoded;
 *  2. the roster on disk matches ROLE_TIER (a new agent must be assigned a tier);
 *  3. the generated harness files are in sync with source — regenerating produces no change,
 *     so a hand-edit to any generated file (or a source edit without regeneration) fails loudly.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { generateAgents, ROLE_TIER, TIER, pruneStale } from './generate-agents.js';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const SRC = join(ROOT, '.cursor', 'agents');
const CLAUDE = join(ROOT, '.claude', 'agents');
const CODEX = join(ROOT, '.codex', 'agents');
const DISPATCH_PATH = join(ROOT, '.speck', 'reference', 'agent-dispatch.json');
const DISPATCH = JSON.parse(readFileSync(DISPATCH_PATH, 'utf-8'));
const TIERS = ['frontier', 'mid', 'mechanical'];
const MODES = ['artifact-owner', 'decision-contributor', 'evidence-contributor', 'read-only-contributor', 'evaluator'];
const CHANGE_BEARING_SKILLS = new Set(['story-implement', 'harden', 'adjust', 'speck-migrate']);
const PROOF_PRODUCER_SKILLS = new Set(['speck-audit', 'speck-larp', 'visual-testing']);

// Independent doctrine pin — a LITERAL, deliberately NOT derived from agent-dispatch.json
// (ROLE_TIER is: both would move together if this list were built from DISPATCH too, which
// is exactly how the guard below silently went tautological once). This is the one place the
// "never cheap the planner or the auditor" doctrine (host-capabilities.md) is pinned outside
// prose, so a lone edit to agent-dispatch.json can never demote one of these roles unnoticed.
const DOCTRINE_FRONTIER_ROLES = ['speck-architect', 'speck-planner', 'speck-auditor', 'speck-validator'];

function assertDoctrinePinned(dispatch) {
  for (const name of DOCTRINE_FRONTIER_ROLES) {
    const tier = dispatch.roles?.[name]?.tier;
    if (tier !== 'frontier') {
      throw new Error(`${name}: doctrine requires frontier, got "${tier}" — never cheap the planner or the auditor`);
    }
  }
}

// Independent doctrine pin, part 2 — pinning the tier LABEL (above) is not enough: TIER's
// frontier row in generate-agents.js can be cheapened directly (e.g. claude.frontier
// 'opus' -> 'haiku') while agent-dispatch.json still says every role is "frontier" and
// every ROLE_TIER-vs-dispatch assertion in this file stays green. The only remaining place
// the doctrine lives is host-capabilities.md's documented Frontier row (Claude opus / Cursor
// claude-opus-4-8-thinking-high / Codex gpt-5.6-sol at high effort) — pin THOSE literal model
// values here too, independent of TIER, so cheapening TIER itself (dispatch untouched) is
// caught the same way a dispatch-alone edit is caught above.
const DOCTRINE_FRONTIER_MODEL = {
  claude: 'opus',
  cursor: 'claude-opus-4-8-thinking-high',
  codex: { model: 'gpt-5.6-sol', effort: 'high' },
};

const modelFromMd = (content) => (content.match(/^model:\s*(.+)$/m) || [])[1]?.trim();
const modelFromToml = (content) => (content.match(/^model\s*=\s*"([^"]*)"/m) || [])[1];
const effortFromToml = (content) => (content.match(/^model_reasoning_effort\s*=\s*"([^"]*)"/m) || [])[1];

// Checks GENERATED OUTPUT (what generateAgents actually produced for each harness) against
// the literal above — never against TIER, so a cheapened TIER cannot pass by agreeing with
// itself (the same tautology DOCTRINE_FRONTIER_ROLES exists to avoid one level up).
function assertDoctrineModelsPinned(out) {
  for (const name of DOCTRINE_FRONTIER_ROLES) {
    const claudeModel = modelFromMd(out.claude[`${name}.md`]);
    if (claudeModel !== DOCTRINE_FRONTIER_MODEL.claude) {
      throw new Error(
        `${name}: claude model "${claudeModel}" != doctrine-pinned "${DOCTRINE_FRONTIER_MODEL.claude}" — never cheap the planner or the auditor`,
      );
    }
    const cursorModel = modelFromMd(out.cursor[`${name}.md`]);
    if (cursorModel !== DOCTRINE_FRONTIER_MODEL.cursor) {
      throw new Error(
        `${name}: cursor model "${cursorModel}" != doctrine-pinned "${DOCTRINE_FRONTIER_MODEL.cursor}" — never cheap the planner or the auditor`,
      );
    }
    const codexModel = modelFromToml(out.codex[`${name}.toml`]);
    const codexEffort = effortFromToml(out.codex[`${name}.toml`]);
    if (codexModel !== DOCTRINE_FRONTIER_MODEL.codex.model || codexEffort !== DOCTRINE_FRONTIER_MODEL.codex.effort) {
      throw new Error(
        `${name}: codex model/effort "${codexModel}/${codexEffort}" != doctrine-pinned ` +
          `"${DOCTRINE_FRONTIER_MODEL.codex.model}/${DOCTRINE_FRONTIER_MODEL.codex.effort}" — never cheap the planner or the auditor`,
      );
    }
  }
}

const specAgents = readdirSync(SRC)
  .filter((f) => /^speck-.*\.md$/.test(f))
  .map((f) => f.replace(/\.md$/, ''));

const mdModel = (p) => (readFileSync(p, 'utf-8').match(/^model:\s*(.+)$/m) || [])[1]?.trim();
const tomlModel = (p) => (readFileSync(p, 'utf-8').match(/^model\s*=\s*"([^"]+)"/m) || [])[1];
const srcTier = (name) => (readFileSync(join(SRC, `${name}.md`), 'utf-8').match(/^tier:\s*(\S+)/m) || [])[1];

test('every speck-* agent declares a valid tier matching the doctrine', () => {
  for (const name of specAgents) {
    const tier = srcTier(name);
    assert.ok(TIERS.includes(tier), `${name}: source tier "${tier}" not in ${TIERS.join(' | ')}`);
    assert.equal(
      tier,
      ROLE_TIER[name],
      `${name}: source tier "${tier}" != doctrine tier "${ROLE_TIER[name]}". ` +
        'Frontier only at decompose/design/audit; never cheap the planner or the auditor.',
    );
  }
});

test('doctrine-critical roles (architect/planner/auditor/validator) are pinned to frontier by a literal independent of agent-dispatch.json', () => {
  assert.doesNotThrow(() => assertDoctrinePinned(DISPATCH));
});

test('a lone agent-dispatch.json edit demoting the auditor fails the independent doctrine pin', () => {
  // Mutate a SCRATCH copy of the dispatch file — not the real one — and prove the pin
  // still catches it. A guard built only from fields read out of this same JSON (the
  // tautology this regression exists to prevent) would pass this mutation silently.
  const scratchDir = mkdtempSync(join(tmpdir(), 'speck-dispatch-mutate-'));
  try {
    const scratchPath = join(scratchDir, 'agent-dispatch.json');
    const mutated = JSON.parse(JSON.stringify(DISPATCH));
    mutated.roles['speck-auditor'].tier = 'mechanical';
    writeFileSync(scratchPath, JSON.stringify(mutated, null, 2));

    const scratchDispatch = JSON.parse(readFileSync(scratchPath, 'utf-8'));
    assert.throws(
      () => assertDoctrinePinned(scratchDispatch),
      /speck-auditor: doctrine requires frontier/,
      'mutating dispatch alone must still fail the independent doctrine pin',
    );

    // Contrast: a guard derived FROM the same (possibly mutated) file agrees with itself
    // no matter what the tier is — this is the exact tautology the pin above must avoid.
    const tautologicalRoleTier = Object.fromEntries(
      Object.entries(scratchDispatch.roles || {}).map(([n, r]) => [n, r.tier]),
    );
    assert.doesNotThrow(
      () => assert.equal(scratchDispatch.roles['speck-auditor'].tier, tautologicalRoleTier['speck-auditor']),
      'demonstrates why a dispatch-derived-vs-itself comparison cannot catch this class of defect',
    );
  } finally {
    rmSync(scratchDir, { recursive: true, force: true });
  }
});

test('doctrine-critical roles generate the doctrine-pinned MODEL on every harness (pins the model, not just the tier label)', () => {
  const out = generateAgents({ write: false });
  assert.doesNotThrow(() => assertDoctrineModelsPinned(out));
});

test('cheapening TIER.*.frontier directly — agent-dispatch.json untouched, every role still "frontier" — fails the doctrine model pin (the reviewer\'s exact reproduction)', () => {
  // Reproduction: leave agent-dispatch.json alone and cheapen ONLY generate-agents.js's TIER
  // frontier row, exactly as the reviewer did (opus->haiku, claude-opus-4-8-thinking-high->
  // composer-2.5, gpt-5.6-sol/high->gpt-5.6-luna/low). Before this test existed, the full
  // suite (including 'each harness pins its own valid model vocabulary per tier') stayed
  // green because that check compares generated output against TIER itself — the same
  // tautology relocated one level down.
  const saved = {
    claude: TIER.claude.frontier,
    cursor: TIER.cursor.frontier,
    codex: { ...TIER.codex.frontier },
  };
  TIER.claude.frontier = 'haiku';
  TIER.cursor.frontier = 'composer-2.5';
  TIER.codex.frontier = { model: 'gpt-5.6-luna', effort: 'low' };
  try {
    const out = generateAgents({ write: false });
    assert.throws(
      () => assertDoctrineModelsPinned(out),
      /doctrine-pinned/,
      'cheapening TIER frontier directly, with dispatch.json untouched, must still fail the model pin',
    );
  } finally {
    TIER.claude.frontier = saved.claude;
    TIER.cursor.frontier = saved.cursor;
    TIER.codex.frontier = saved.codex;
  }
});

test('cheapening only the codex effort (frontier model string unchanged) still fails the doctrine model pin', () => {
  // Neighbouring input: a narrower cheapen than the reviewer's — same model slug, weaker
  // reasoning effort. Proves the pin checks effort independently, not just the model name.
  const savedEffort = TIER.codex.frontier.effort;
  TIER.codex.frontier = { ...TIER.codex.frontier, effort: 'low' };
  try {
    const out = generateAgents({ write: false });
    assert.throws(() => assertDoctrineModelsPinned(out), /doctrine-pinned/);
  } finally {
    TIER.codex.frontier = { ...TIER.codex.frontier, effort: savedEffort };
  }
});

test('cheapening only the cursor frontier slug (claude/codex unchanged) still fails the doctrine model pin', () => {
  // Neighbouring input: cheapen exactly one harness's frontier row (demote it to that
  // harness's own mid-tier slug) while leaving the other two harnesses at their doctrine
  // values. Proves the pin is per-harness, not an all-or-nothing comparison that a partial
  // cheapen could slip past.
  const saved = TIER.cursor.frontier;
  TIER.cursor.frontier = TIER.cursor.mid;
  try {
    const out = generateAgents({ write: false });
    assert.throws(() => assertDoctrineModelsPinned(out), /doctrine-pinned/);
  } finally {
    TIER.cursor.frontier = saved;
  }
});

test('the roster on disk matches ROLE_TIER', () => {
  const onDisk = new Set(specAgents);
  const governed = new Set(Object.keys(ROLE_TIER));
  for (const n of governed) assert.ok(onDisk.has(n), `ROLE_TIER lists ${n} but no source ${n}.md`);
  for (const n of onDisk) assert.ok(governed.has(n), `${n}.md exists but ROLE_TIER doesn't tier it`);
});

test('every retained agent has a canonical skill route and every route exists', () => {
  assert.equal(DISPATCH.schema_version, 1);
  const routed = new Set(Object.keys(DISPATCH.roles || {}));
  assert.deepEqual(routed, new Set(specAgents), 'agent-dispatch roles must exactly match the shipped roster');

  for (const name of specAgents) {
    assert.ok(TIERS.includes(DISPATCH.roles[name]?.tier), `${name}: dispatch tier is invalid`);
    assert.ok(MODES.includes(DISPATCH.roles[name]?.mode), `${name}: dispatch mode is invalid`);
    assert.equal(DISPATCH.roles[name].tier, ROLE_TIER[name], `${name}: dispatch tier drift`);
    assert.ok(DISPATCH.roles[name]?.independence?.length > 30, `${name}: independence contract is missing`);
    const skills = DISPATCH.roles[name]?.skills;
    assert.ok(Array.isArray(skills) && skills.length > 0, `${name}: no canonical skill routes`);
    for (const skill of skills) {
      assert.ok(
        existsSync(join(ROOT, '.cursor', 'skills', skill, 'SKILL.md')),
        `${name}: routed skill ${skill} does not exist`,
      );
      if (DISPATCH.roles[name].mode === 'read-only-contributor') {
        assert.ok(!CHANGE_BEARING_SKILLS.has(skill), `${name}: read-only role routes change-bearing skill ${skill}`);
      }
      if (name === 'speck-validator') {
        assert.ok(!PROOF_PRODUCER_SKILLS.has(skill), `${name}: readiness adjudicator routes proof producer ${skill}`);
      }
    }
  }
  assert.deepEqual(
    DISPATCH.roles['speck-validator'].skills,
    ['story-validate', 'epic-validate', 'project-validate'],
    'validator role must own only readiness adjudication',
  );
});

// AGENTS.md is governed independently by validate-corpus-budget.sh's own AGENTS.md ceiling.
// That ceiling's single source of truth is `.speck/reference/skill-load-budgets.json`'s
// `ceilings.agents_bytes` (validate-corpus-budget.sh reads it the same way, falling back to
// the historical 16384 default only when the registry or its ceilings block is missing —
// see that script's own comment naming this file as one of five copies that "could (and
// did) drift apart" when the number was restated as a literal here). Read it from the same
// registry so raising the registry ceiling raises what THIS test considers "AGENTS.md's own
// ceiling" too — a literal here would silently go stale the moment the registry changed,
// reproducing the original defect (documented gate PASS, this test RED) one field away.
const BUDGETS_PATH = join(ROOT, '.speck', 'reference', 'skill-load-budgets.json');
const AGENTS_BYTES_FALLBACK = 16384;
// Mirrors validate-corpus-budget.sh's own read of this same registry field-for-field: no
// file / unparseable JSON / no `ceilings` block at all -> keep the historical default
// (a minimal fixture without a full registry keeps working); a `ceilings` block that IS
// present but malformed (wrong type, missing key, non-positive) is a declared-but-unenforced
// ceiling and must fail loudly, never fall back silently.
function readAgentsCeiling(path = BUDGETS_PATH) {
  let data;
  try {
    data = JSON.parse(readFileSync(path, 'utf-8'));
  } catch {
    return AGENTS_BYTES_FALLBACK;
  }
  const c = data?.ceilings;
  if (c == null) return AGENTS_BYTES_FALLBACK;
  const validPositiveInt = (v) => Number.isInteger(v) && v > 0;
  if (typeof c !== 'object' || Array.isArray(c) || !validPositiveInt(c.agents_bytes) || !validPositiveInt(c.agents_lines)) {
    throw new Error(
      `${path}: ceilings.agents_bytes and ceilings.agents_lines must both be present positive integers ` +
        `(got agents_bytes=${JSON.stringify(c?.agents_bytes)} agents_lines=${JSON.stringify(c?.agents_lines)}) — ` +
        'matches validate-corpus-budget.sh: a declared-but-malformed ceiling is a loud FAIL, never a silent fallback',
    );
  }
  return c.agents_bytes;
}
const MAX_AGENTS_BYTES = readAgentsCeiling();
// MAX_OVERLAY_BYTES below is that same AGENTS.md budget PLUS explicit headroom for dispatch
// + the per-agent role prompt (current combined usage is ~4 KB), so growing AGENTS.md up to
// its own registry-declared ceiling can never trip this unrelated test on its own.
const MAX_ROLE_OVERLAY_HEADROOM = 8192;
const MAX_OVERLAY_BYTES = MAX_AGENTS_BYTES + MAX_ROLE_OVERLAY_HEADROOM;

test('agent prompts are thin adapters, not parallel methodology or chat schemas', () => {
  const alwaysOn = Buffer.byteLength(readFileSync(join(ROOT, 'AGENTS.md'), 'utf-8'));
  const dispatchBytes = Buffer.byteLength(readFileSync(DISPATCH_PATH, 'utf-8'));

  for (const name of specAgents) {
    const source = readFileSync(join(SRC, `${name}.md`), 'utf-8');
    assert.match(source, /\.speck\/reference\/agent-dispatch\.json/, `${name}: must load dispatch contract`);
    assert.match(source, /canonical skill/, `${name}: must enter through a canonical skill`);
    assert.match(source, /SKILL_UNAVAILABLE/, `${name}: must fail closed when its canonical skill is unavailable`);
    assert.doesNotMatch(source, /^#+\s+(Response|Output) Format\b/m, `${name}: chat output schema drift`);
    assert.ok(source.split('\n').length <= 24, `${name}: role prompt is no longer thin`);

    const overlay = alwaysOn + dispatchBytes + Buffer.byteLength(source);
    assert.ok(
      overlay <= MAX_OVERLAY_BYTES,
      `${name}: AGENTS + dispatch + role overlay ${overlay} bytes > ${MAX_OVERLAY_BYTES}`,
    );
  }
});

test("AGENTS.md can reach its own registry-declared ceiling (skill-load-budgets.json ceilings.agents_bytes) without tripping the unrelated role-overlay test", () => {
  // Reproduces the exact conflict from the finding without touching the real AGENTS.md:
  // an AGENTS.md at precisely validate-corpus-budget.sh's ceiling (read from the same
  // registry as MAX_AGENTS_BYTES above), plus the current largest dispatch + role prompt,
  // must stay inside MAX_OVERLAY_BYTES.
  const dispatchBytes = Buffer.byteLength(readFileSync(DISPATCH_PATH, 'utf-8'));
  const largestRoleBytes = Math.max(
    ...specAgents.map((name) => Buffer.byteLength(readFileSync(join(SRC, `${name}.md`), 'utf-8'))),
  );
  const overlayAtDocumentedCeiling = MAX_AGENTS_BYTES + dispatchBytes + largestRoleBytes;
  assert.ok(
    overlayAtDocumentedCeiling <= MAX_OVERLAY_BYTES,
    `an AGENTS.md at its own registry-declared ${MAX_AGENTS_BYTES}-byte ceiling must not fail the role-overlay ` +
      `test (got ${overlayAtDocumentedCeiling} > ${MAX_OVERLAY_BYTES}) — the two gates must not share a ceiling`,
  );
});

test('MAX_AGENTS_BYTES equals the live registry value, not a restated literal', () => {
  const registry = JSON.parse(readFileSync(BUDGETS_PATH, 'utf-8'));
  assert.equal(MAX_AGENTS_BYTES, registry.ceilings.agents_bytes);
});

test('raising the registry ceiling raises this file\'s notion of "AGENTS.md\'s own ceiling" too (the reviewer\'s exact reproduction)', () => {
  // Reviewer's reproduction: set skill-load-budgets.json ceilings.agents_bytes = 22000 and
  // pad AGENTS.md to 21999 bytes. validate-corpus-budget.sh reads the registry and reports
  // PASS at the raised limit. Before this fix, MAX_AGENTS_BYTES was a literal 16384 baked
  // into this file, so the unrelated role-overlay test stayed pinned to the OLD ceiling and
  // went RED at exactly the byte count the shell validator had just declared PASS for — the
  // same "documented gate PASS, unrelated agent test RED" defect the original finding named.
  const scratchDir = mkdtempSync(join(tmpdir(), 'speck-budget-ceiling-'));
  try {
    const scratchPath = join(scratchDir, 'skill-load-budgets.json');
    writeFileSync(scratchPath, JSON.stringify({ ceilings: { agents_bytes: 22000, agents_lines: 200 } }));
    const raisedCeiling = readAgentsCeiling(scratchPath);
    assert.equal(raisedCeiling, 22000, 'must read the raised ceiling from the registry, not stay pinned to 16384');

    // Recompute what this suite's real gate (MAX_OVERLAY_BYTES) would be if MAX_AGENTS_BYTES
    // tracked the raised registry value, and prove an AGENTS.md at the reviewer's exact
    // 21999-byte padding — which validate-corpus-budget.sh would now PASS — fits under it.
    const raisedOverlayBudget = raisedCeiling + MAX_ROLE_OVERLAY_HEADROOM;
    const dispatchBytes = Buffer.byteLength(readFileSync(DISPATCH_PATH, 'utf-8'));
    const largestRoleBytes = Math.max(
      ...specAgents.map((name) => Buffer.byteLength(readFileSync(join(SRC, `${name}.md`), 'utf-8'))),
    );
    const overlayAtReviewerPadding = 21999 + dispatchBytes + largestRoleBytes;
    assert.ok(
      overlayAtReviewerPadding <= raisedOverlayBudget,
      `a ceiling that MOVES WITH the registry must clear the reviewer's 21999-byte AGENTS.md ` +
        `(got overlay ${overlayAtReviewerPadding} > raised budget ${raisedOverlayBudget})`,
    );
  } finally {
    rmSync(scratchDir, { recursive: true, force: true });
  }
});

test('a ceilings block present but malformed (non-positive agents_bytes) fails loudly, matching validate-corpus-budget.sh\'s ERROR path — not a silent fallback', () => {
  const scratchDir = mkdtempSync(join(tmpdir(), 'speck-budget-malformed-'));
  try {
    const scratchPath = join(scratchDir, 'skill-load-budgets.json');
    writeFileSync(scratchPath, JSON.stringify({ ceilings: { agents_bytes: -5, agents_lines: 200 } }));
    assert.throws(() => readAgentsCeiling(scratchPath), /must both be present positive integers/);
  } finally {
    rmSync(scratchDir, { recursive: true, force: true });
  }
});

test('a ceilings block that is entirely absent falls back to the historical 16384 default, matching validate-corpus-budget.sh\'s fallback', () => {
  const scratchDir = mkdtempSync(join(tmpdir(), 'speck-budget-fallback-'));
  try {
    const scratchPath = join(scratchDir, 'skill-load-budgets.json');
    writeFileSync(scratchPath, JSON.stringify({ cases: [] }));
    assert.equal(readAgentsCeiling(scratchPath), AGENTS_BYTES_FALLBACK);
  } finally {
    rmSync(scratchDir, { recursive: true, force: true });
  }
});

test('unparseable registry JSON falls back to the historical default rather than throwing', () => {
  const scratchDir = mkdtempSync(join(tmpdir(), 'speck-budget-invalid-json-'));
  try {
    const scratchPath = join(scratchDir, 'skill-load-budgets.json');
    writeFileSync(scratchPath, '{not valid json');
    assert.equal(readAgentsCeiling(scratchPath), AGENTS_BYTES_FALLBACK);
  } finally {
    rmSync(scratchDir, { recursive: true, force: true });
  }
});

test('generated harness files are in sync with source (regenerate = no change, no orphans)', () => {
  const out = generateAgents({ write: false });
  const check = (dir, map, pattern) => {
    const expected = new Set(Object.keys(map));
    const onDisk = new Set(readdirSync(dir).filter((f) => pattern.test(f)));
    assert.deepEqual(
      onDisk,
      expected,
      `${dir}: on-disk speck-* files must exactly match generated output — a retired source must not leave orphans behind`,
    );
    for (const [f, content] of Object.entries(map)) {
      assert.equal(
        readFileSync(join(dir, f), 'utf-8'),
        content,
        `${dir}/${f} drifted from source — edit .cursor/agents source + run \`npm run gen-agents\`, don't hand-edit generated files`,
      );
    }
  };
  check(SRC, out.cursor, /^speck-.*\.md$/);
  check(CLAUDE, out.claude, /^speck-.*\.md$/);
  check(CODEX, out.codex, /^speck-.*\.toml$/);
});

test('pruneStale removes only files no longer in the generated map, leaving unrelated files alone', () => {
  const dir = mkdtempSync(join(tmpdir(), 'speck-prune-'));
  try {
    writeFileSync(join(dir, 'speck-retired.md'), 'stale — source and dispatch role were deleted');
    writeFileSync(join(dir, 'speck-keep.md'), 'still generated');
    writeFileSync(join(dir, 'not-an-agent.txt'), 'must survive pruning: pattern does not match');
    pruneStale(dir, new Set(['speck-keep.md']), /^speck-.*\.md$/);
    assert.deepEqual(
      readdirSync(dir).sort(),
      ['not-an-agent.txt', 'speck-keep.md'],
      'speck-retired.md must be unlinked; the unmatched file must survive',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('a lone ROLE_TIER change is refused rather than silently overwriting the source frontmatter', () => {
  // Simulates editing agent-dispatch.json alone: mutate the live ROLE_TIER binding (it is a
  // plain object, not frozen) without touching .cursor/agents/speck-validator.md's `tier:`
  // line. The two artifacts now disagree about a doctrine-critical role, which is an
  // unresolved conflict between two humans' intent — the generator must surface it, not
  // pick a winner. The semantic-conservation obligation 'custom-agents-enter-canonical-skills'
  // pins this comparison as a load-bearing carrier.
  const name = 'speck-validator';
  const original = ROLE_TIER[name];
  const mutated = original === 'frontier' ? 'mid' : 'frontier';
  ROLE_TIER[name] = mutated;
  try {
    assert.throws(
      () => generateAgents({ write: false }),
      new RegExp(`${name}: source tier ${original} != dispatch tier ${mutated}`),
      'a dispatch/source tier disagreement must throw, never regenerate silently',
    );
  } finally {
    ROLE_TIER[name] = original;
  }
});

test('each harness pins its own valid model vocabulary per tier', () => {
  for (const name of specAgents) {
    const tier = ROLE_TIER[name];
    assert.equal(mdModel(join(CLAUDE, `${name}.md`)), TIER.claude[tier], `${name}: claude model`);
    assert.equal(mdModel(join(SRC, `${name}.md`)), TIER.cursor[tier], `${name}: cursor model`);
    assert.equal(tomlModel(join(CODEX, `${name}.toml`)), TIER.codex[tier].model, `${name}: codex model`);
  }
});
