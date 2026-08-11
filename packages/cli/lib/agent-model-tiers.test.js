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
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { generateAgents, ROLE_TIER, TIER } from './generate-agents.js';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const SRC = join(ROOT, '.cursor', 'agents');
const CLAUDE = join(ROOT, '.claude', 'agents');
const CODEX = join(ROOT, '.codex', 'agents');
const DISPATCH_PATH = join(ROOT, '.speck', 'reference', 'agent-dispatch.json');
const DISPATCH = JSON.parse(readFileSync(DISPATCH_PATH, 'utf-8'));
const TIERS = ['frontier', 'mid', 'mechanical'];
const MODES = ['artifact-owner', 'decision-contributor', 'evidence-contributor', 'read-only-contributor', 'evaluator'];

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
    }
  }
});

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
    assert.ok(overlay <= 16384, `${name}: AGENTS + dispatch + role overlay ${overlay} bytes > 16384`);
  }
});

test('generated harness files are in sync with source (regenerate = no change)', () => {
  const out = generateAgents({ write: false });
  const check = (dir, map) => {
    for (const [f, content] of Object.entries(map)) {
      assert.equal(
        readFileSync(join(dir, f), 'utf-8'),
        content,
        `${dir}/${f} drifted from source — edit .cursor/agents source + run \`npm run gen-agents\`, don't hand-edit generated files`,
      );
    }
  };
  check(SRC, out.cursor);
  check(CLAUDE, out.claude);
  check(CODEX, out.codex);
});

test('each harness pins its own valid model vocabulary per tier', () => {
  for (const name of specAgents) {
    const tier = ROLE_TIER[name];
    assert.equal(mdModel(join(CLAUDE, `${name}.md`)), TIER.claude[tier], `${name}: claude model`);
    assert.equal(mdModel(join(SRC, `${name}.md`)), TIER.cursor[tier], `${name}: cursor model`);
    assert.equal(tomlModel(join(CODEX, `${name}.toml`)), TIER.codex[tier].model, `${name}: codex model`);
  }
});
