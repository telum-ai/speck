import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { smartSync } from './sync.js';

const MANAGED = '<!-- SPECK:START -->\n@AGENTS.md\n<!-- SPECK:END -->';

function setup(targetClaude = null) {
  const source = mkdtempSync(join(tmpdir(), 'speck-claude-src-'));
  const target = mkdtempSync(join(tmpdir(), 'speck-claude-tgt-'));
  writeFileSync(join(source, 'AGENTS.md'), '<!-- SPECK:START -->\n# Speck\n<!-- SPECK:END -->\n');
  writeFileSync(join(source, 'CLAUDE.md'), `${MANAGED}\n`);
  if (targetClaude !== null) writeFileSync(join(target, 'CLAUDE.md'), targetClaude);
  return { source, target };
}

test('clean init distributes the Claude import', () => {
  const { source, target } = setup();
  smartSync(source, target);
  assert.ok(existsSync(join(target, 'CLAUDE.md')));
  assert.equal(readFileSync(join(target, 'CLAUDE.md'), 'utf8'), `${MANAGED}\n`);
});

test('upgrade preserves project-owned Claude instructions', () => {
  const { source, target } = setup('# Project rules\n\nKeep this instruction.\n');
  smartSync(source, target);
  assert.equal(
    readFileSync(join(target, 'CLAUDE.md'), 'utf8'),
    `${MANAGED}\n\n# Project rules\n\nKeep this instruction.\n`,
  );
});

test('upgrade adopts a legacy bare import and stays idempotent', () => {
  const { source, target } = setup('@AGENTS.md\n\n# Project rules\n');
  smartSync(source, target);
  smartSync(source, target);
  const content = readFileSync(join(target, 'CLAUDE.md'), 'utf8');
  assert.equal(content, `${MANAGED}\n\n# Project rules\n`);
  assert.equal((content.match(/@AGENTS\.md/g) || []).length, 1);
  assert.equal((content.match(/<!-- SPECK:START -->/g) || []).length, 1);
});

test('upgrade replaces only a stale managed block', () => {
  const stale = '<!-- SPECK:START -->\n@OLD.md\n<!-- SPECK:END -->\n\n# Mine\n';
  const { source, target } = setup(stale);
  smartSync(source, target);
  assert.equal(readFileSync(join(target, 'CLAUDE.md'), 'utf8'), `${MANAGED}\n\n# Mine\n`);
});
