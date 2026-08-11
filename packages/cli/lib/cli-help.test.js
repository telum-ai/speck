import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const here = dirname(fileURLToPath(import.meta.url));
const cli = join(here, '..', 'bin', 'speck.js');

for (const helpFlag of ['--help', '-h']) {
  test(`upgrade ${helpFlag} is read-only`, () => {
    const root = mkdtempSync(join(tmpdir(), 'speck-cli-help-'));
    try {
      writeFileSync(join(root, 'sentinel.txt'), 'unchanged\n');
      const before = readdirSync(root);
      const result = spawnSync(process.execPath, [cli, 'upgrade', helpFlag], {
        cwd: root,
        encoding: 'utf8',
        timeout: 10_000,
      });

      assert.equal(result.status, 0, result.stderr);
      assert.match(result.stdout, /USAGE/);
      assert.doesNotMatch(result.stdout, /Upgrading Speck/);
      assert.deepEqual(readdirSync(root), before);
      assert.equal(readFileSync(join(root, 'sentinel.txt'), 'utf8'), 'unchanged\n');
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });
}
