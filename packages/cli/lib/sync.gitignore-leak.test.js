import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { smartSync } from './sync.js';

// packages/cli/lib -> repo root
const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

// Patterns that mean something only inside the Speck source repo's own eval
// harness. They must never show up in a downstream project's .gitignore.
const SPECK_INTERNAL_EVAL_PATTERNS = [
  'tests/eval/behavioral/.runs/',
  'tests/eval/behavioral/reports/',
  'tests/eval/skill-routing/reports/',
  'tests/eval/reports/latest.md',
];

test('mergeGitignore does not leak Speck-internal eval ignores into a downstream project', () => {
  const target = mkdtempSync(join(tmpdir(), 'speck-gitignore-tgt-'));
  writeFileSync(join(target, '.gitignore'), 'node_modules/\ndist/\n.env\ntests/eval/reports/\n');

  // Use the real, shipped Speck source dir (repo root) as the sync source -
  // this exercises the exact .gitignore that gets tarballed and merged into
  // consumer repos on init/upgrade.
  smartSync(REPO_ROOT, target);

  const merged = readFileSync(join(target, '.gitignore'), 'utf8');
  for (const pattern of SPECK_INTERNAL_EVAL_PATTERNS) {
    assert.ok(
      !merged.split('\n').includes(pattern),
      `expected downstream .gitignore to NOT contain Speck-internal pattern "${pattern}", got:\n${merged}`,
    );
  }
  // The project's own pre-existing patterns must survive untouched.
  assert.ok(merged.includes('tests/eval/reports/'));
  assert.ok(merged.includes('node_modules/'));
});
