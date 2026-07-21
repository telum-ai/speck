/**
 * Regression for the 2026-07-21 agent decoupling: `.claude/agents` and `.codex/agents` used to
 * be SYMLINKS into `.cursor/agents`; they are now GENERATED real dirs (each harness has its own
 * model vocabulary). smartSync must:
 *   - migrate a legacy agent symlink to a real dir WITHOUT following it into `.cursor` (which
 *     would delete the real Cursor agents),
 *   - keep SKILLS symlinked,
 *   - preserve project-custom agent subdirs across the transition.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, symlinkSync, existsSync, lstatSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { smartSync } from './sync.js';

function setup() {
  const source = mkdtempSync(join(tmpdir(), 'speck-dec-src-'));
  const target = mkdtempSync(join(tmpdir(), 'speck-dec-tgt-'));

  // Source: real generated per-harness agent dirs + a shipped skill.
  for (const rel of ['.cursor/agents', '.claude/agents', '.codex/agents', '.cursor/skills/speck']) {
    mkdirSync(join(source, rel), { recursive: true });
  }
  writeFileSync(join(source, '.cursor/agents/speck-x.md'), 'cursor-src');
  writeFileSync(join(source, '.claude/agents/speck-x.md'), 'claude-src');
  writeFileSync(join(source, '.codex/agents/speck-x.toml'), 'codex-src');
  writeFileSync(join(source, '.cursor/skills/speck/SKILL.md'), 'skill-src');

  // Target: legacy layout — .cursor/agents is real, .claude/agents is a SYMLINK into it,
  // plus a project-custom agent subdir that must survive.
  mkdirSync(join(target, '.cursor/agents'), { recursive: true });
  writeFileSync(join(target, '.cursor/agents/speck-x.md'), 'cursor-OLD');
  mkdirSync(join(target, '.claude'), { recursive: true });
  symlinkSync(join('..', '.cursor', 'agents'), join(target, '.claude/agents'));
  mkdirSync(join(target, '.codex/agents/my-custom'), { recursive: true });
  writeFileSync(join(target, '.codex/agents/my-custom/AGENT.md'), 'CUSTOM');

  return { source, target };
}

test('legacy .claude/agents symlink migrates to a real dir with the generated file', () => {
  const { source, target } = setup();
  smartSync(source, target);

  const claudeAgents = join(target, '.claude/agents');
  assert.ok(existsSync(claudeAgents), '.claude/agents exists');
  assert.ok(!lstatSync(claudeAgents).isSymbolicLink(), '.claude/agents is a REAL dir, not a symlink');
  assert.equal(readFileSync(join(claudeAgents, 'speck-x.md'), 'utf-8'), 'claude-src', 'got the Claude-specific file');
});

test('.cursor/agents is not damaged by the symlink migration', () => {
  const { source, target } = setup();
  smartSync(source, target);
  // If the migration had followed the symlink, .cursor/agents would have been emptied/overwritten
  // via the link before its own ALWAYS_OVERWRITE copy — assert it holds the fresh source content.
  assert.equal(readFileSync(join(target, '.cursor/agents/speck-x.md'), 'utf-8'), 'cursor-src');
});

test('skills stay symlinked; agents do not', () => {
  const { source, target } = setup();
  smartSync(source, target);
  assert.ok(lstatSync(join(target, '.claude/skills')).isSymbolicLink(), '.claude/skills IS a symlink');
  assert.ok(!lstatSync(join(target, '.claude/agents')).isSymbolicLink(), '.claude/agents is NOT a symlink');
});

test('project-custom agent subdir survives the transition', () => {
  const { source, target } = setup();
  smartSync(source, target);
  assert.ok(
    existsSync(join(target, '.codex/agents/my-custom/AGENT.md')),
    'custom agent subdir preserved across ALWAYS_OVERWRITE',
  );
  assert.equal(readFileSync(join(target, '.codex/agents/speck-x.toml'), 'utf-8'), 'codex-src', 'shipped agent copied');
});
