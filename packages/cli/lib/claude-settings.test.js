/**
 * Tests for Claude settings reconciliation (v7.8.0)
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

import {
  getAtPath,
  setAtPath,
  detectSettingsDrift,
  reconcileSettings,
  hashValue,
} from './claude-settings.js';

const EXAMPLE = {
  _speck_managed: { version: '7.8.0', blocks: ['hooks.Stop', 'hooks.SessionStart'] },
  permissions: { allow: ['Bash(node *)'] },
  hooks: {
    Stop: [{ hooks: [{ type: 'command', command: 'bash .claude/hooks/stop-gate.sh' }] }],
    SessionStart: [{ hooks: [{ type: 'command', command: 'echo hi' }] }],
  },
};

function setupWorkspace(activeSettings = null) {
  const dir = mkdtempSync(join(tmpdir(), 'speck-settings-'));
  mkdirSync(join(dir, '.claude'), { recursive: true });
  writeFileSync(join(dir, '.claude/settings.json.example'), `${JSON.stringify(EXAMPLE, null, 2)}\n`);
  if (activeSettings) {
    writeFileSync(join(dir, '.claude/settings.json'), `${JSON.stringify(activeSettings, null, 2)}\n`);
  }
  return dir;
}

test('getAtPath and setAtPath round-trip nested keys', () => {
  const obj = {};
  setAtPath(obj, 'hooks.Stop', [{ hooks: [] }]);
  assert.deepEqual(getAtPath(obj, 'hooks.Stop'), [{ hooks: [] }]);
});

test('detectSettingsDrift reports missing active settings', () => {
  const dir = setupWorkspace();
  const result = detectSettingsDrift(dir);
  assert.equal(result.missingFile, true);
  assert.ok(result.drift.length >= 2);
  assert.equal(result.drift[0].severity, 'P0');
});

test('detectSettingsDrift reports legacy prompt Stop hook', () => {
  const dir = setupWorkspace({
    hooks: {
      Stop: [{ hooks: [{ type: 'prompt', prompt: 'Verify tasks.md status' }] }],
    },
  });
  const result = detectSettingsDrift(dir);
  assert.ok(result.drift.some(d => d.summary.includes('legacy prompt-type Stop hook')));
});

test('reconcileSettings creates settings from example when missing', () => {
  const dir = setupWorkspace();
  const result = reconcileSettings(dir, { apply: true });
  assert.equal(result.created, true);
  assert.ok(existsSync(join(dir, '.claude/settings.json')));
  const active = JSON.parse(readFileSync(join(dir, '.claude/settings.json'), 'utf-8'));
  assert.equal(active.hooks.Stop[0].hooks[0].type, 'command');
});

test('reconcileSettings preserves user permissions while updating managed hooks', () => {
  const dir = setupWorkspace({
    permissions: { allow: ['Bash(custom *)'], deny: ['Read(./secrets/**)'] },
    env: { MY_VAR: '1' },
    hooks: {
      Stop: [{ hooks: [{ type: 'prompt', prompt: 'old broken hook about tasks.md' }] }],
      SessionStart: [{ hooks: [{ type: 'command', command: 'echo stale' }] }],
    },
  });

  const result = reconcileSettings(dir, { apply: true });
  assert.ok(result.changes.includes('hooks.Stop'));

  const active = JSON.parse(readFileSync(join(dir, '.claude/settings.json'), 'utf-8'));
  assert.deepEqual(active.permissions.allow, ['Bash(custom *)']);
  assert.equal(active.env.MY_VAR, '1');
  assert.equal(active.hooks.Stop[0].hooks[0].type, 'command');
  assert.equal(active._speck_managed.version, '7.8.0');
});

test('hashValue is stable for identical objects', () => {
  const a = { type: 'command', command: 'bash foo.sh' };
  assert.equal(hashValue(a), hashValue({ ...a }));
});
