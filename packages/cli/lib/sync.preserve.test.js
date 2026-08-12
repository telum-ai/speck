/**
 * Tests that smartSync preserves PROJECT-CUSTOM skill/agent directories across upgrades.
 *
 * Regression for the keegt 2026-07-10 upgrade: `.cursor/skills` is an ALWAYS_OVERWRITE
 * directory (rmSync + copyDir), and custom skills MUST live there because `.claude/skills`
 * and `.codex/skills` are symlinks into it — so wholesale replacement silently deleted the
 * project's four keegt-content-* skills. Unknown subdirs now survive; Speck-shipped dirs
 * are still fully overwritten from source.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { smartSync } from './sync.js';

function makeDirs() {
  const source = mkdtempSync(join(tmpdir(), 'speck-sync-src-'));
  const target = mkdtempSync(join(tmpdir(), 'speck-sync-tgt-'));
  // Source ships one skill
  mkdirSync(join(source, '.cursor', 'skills', 'speck'), { recursive: true });
  writeFileSync(join(source, '.cursor', 'skills', 'speck', 'SKILL.md'), 'shipped v-NEW');
  // Target has the shipped skill (old version) + a project-custom skill
  mkdirSync(join(target, '.cursor', 'skills', 'speck'), { recursive: true });
  writeFileSync(join(target, '.cursor', 'skills', 'speck', 'SKILL.md'), 'shipped v-OLD');
  mkdirSync(join(target, '.cursor', 'skills', 'myproject-custom'), { recursive: true });
  writeFileSync(join(target, '.cursor', 'skills', 'myproject-custom', 'SKILL.md'), 'CUSTOM');
  return { source, target };
}

test('smartSync: project-custom skill dir survives upgrade', () => {
  const { source, target } = makeDirs();
  smartSync(source, target);
  const customPath = join(target, '.cursor', 'skills', 'myproject-custom', 'SKILL.md');
  assert.ok(existsSync(customPath), 'custom skill must survive the upgrade');
  assert.equal(readFileSync(customPath, 'utf8'), 'CUSTOM');
});

test('smartSync: removes retired level aliases without deleting custom skills', () => {
  const { source, target } = makeDirs();
  const retired = [
    'project-adjust', 'epic-adjust', 'story-adjust',
    'project-analyze', 'epic-analyze', 'story-analyze',
    'retrospective', 'speck-catch-up', 'speck-reprove', 'speck-graph-up',
  ];
  for (const name of retired) {
    const dir = join(target, '.cursor', 'skills', name);
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, 'SKILL.md'), 'RETIRED');
  }

  smartSync(source, target);

  for (const name of retired) {
    assert.ok(!existsSync(join(target, '.cursor', 'skills', name)), `${name} must be removed`);
  }
  assert.ok(existsSync(join(target, '.cursor', 'skills', 'myproject-custom', 'SKILL.md')));
});

test('smartSync: Speck-shipped skill dir is still fully overwritten', () => {
  const { source, target } = makeDirs();
  smartSync(source, target);
  const shippedPath = join(target, '.cursor', 'skills', 'speck', 'SKILL.md');
  assert.equal(readFileSync(shippedPath, 'utf8'), 'shipped v-NEW');
});

test('smartSync: stale file inside a shipped skill dir does NOT survive (full replace)', () => {
  const { source, target } = makeDirs();
  writeFileSync(join(target, '.cursor', 'skills', 'speck', 'stale-extra.md'), 'stale');
  smartSync(source, target);
  assert.ok(
    !existsSync(join(target, '.cursor', 'skills', 'speck', 'stale-extra.md')),
    'files inside Speck-shipped dirs must not be preserved'
  );
});

test('smartSync: custom agent dir survives via the same rule', () => {
  const { source, target } = makeDirs();
  mkdirSync(join(source, '.cursor', 'agents'), { recursive: true });
  writeFileSync(join(source, '.cursor', 'agents', 'speck-coder.md'), 'shipped');
  mkdirSync(join(target, '.cursor', 'agents', 'my-custom-agent'), { recursive: true });
  writeFileSync(join(target, '.cursor', 'agents', 'my-custom-agent', 'AGENT.md'), 'CUSTOM-AGENT');
  smartSync(source, target);
  assert.ok(existsSync(join(target, '.cursor', 'agents', 'my-custom-agent', 'AGENT.md')));
});

test('smartSync: ships runtime reference files required by AGENTS and skills', () => {
  const { source, target } = makeDirs();
  mkdirSync(join(source, '.speck', 'reference'), { recursive: true });
  writeFileSync(join(source, '.speck', 'reference', 'canonical-routing.md'), 'CURRENT ROUTING');

  smartSync(source, target);

  assert.equal(
    readFileSync(join(target, '.speck', 'reference', 'canonical-routing.md'), 'utf8'),
    'CURRENT ROUTING',
  );
});

test('smartSync: excludes generated caches from shipped runtime', () => {
  const { source, target } = makeDirs();
  const scripts = join(source, '.speck', 'scripts');
  mkdirSync(join(scripts, '__pycache__'), { recursive: true });
  writeFileSync(join(scripts, 'profile-check.py'), 'print("runtime")');
  writeFileSync(join(scripts, '__pycache__', 'profile-check.cpython-312.pyc'), 'BYTECODE');
  writeFileSync(join(scripts, '.DS_Store'), 'MACOS');

  smartSync(source, target);

  assert.ok(existsSync(join(target, '.speck', 'scripts', 'profile-check.py')));
  assert.ok(!existsSync(join(target, '.speck', 'scripts', '__pycache__')));
  assert.ok(!existsSync(join(target, '.speck', 'scripts', '.DS_Store')));
});

test('smartSync: preserves project-created learned patterns while retiring former Speck files', () => {
  const { source, target } = makeDirs();
  const learned = join(target, '.speck', 'patterns', 'learned');
  mkdirSync(join(learned, 'gotchas'), { recursive: true });
  mkdirSync(join(learned, 'testing'), { recursive: true });
  writeFileSync(join(learned, 'gotchas', 'project-only.md'), 'PROJECT LEARNING');
  writeFileSync(join(learned, 'testing', 'mirror-sweep.md'), 'FORMER SPECK FILE');

  smartSync(source, target);

  assert.equal(
    readFileSync(join(learned, 'gotchas', 'project-only.md'), 'utf8'),
    'PROJECT LEARNING',
  );
  assert.ok(!existsSync(join(learned, 'testing', 'mirror-sweep.md')));
});

test('smartSync: removes framework-only eval while preserving project feedback', () => {
  const { source, target } = makeDirs();
  mkdirSync(join(target, '.speck', 'eval', 'reports'), { recursive: true });
  mkdirSync(join(target, '.speck', 'feedback'), { recursive: true });
  writeFileSync(join(target, '.speck', 'eval', 'reports', 'old.md'), 'META');
  writeFileSync(join(target, '.speck', 'feedback', 'old.md'), 'META');

  smartSync(source, target);

  assert.ok(!existsSync(join(target, '.speck', 'eval')));
  assert.equal(
    readFileSync(join(target, '.speck', 'feedback', 'old.md'), 'utf8'),
    'META',
  );
});
