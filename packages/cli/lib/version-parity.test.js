import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

const readJson = (p) => JSON.parse(readFileSync(p, 'utf8'));

// The two package.json versions drifted to 9.6.0 vs 8.6.0 unnoticed. It matters more than a stale
// banner: the migration lane resolves a target version, and anything falling back to the CLI's own
// version would have computed toMajor=8 — silently answering `false` for every v10 migration and
// applying none of them. A version that is wrong by two majors is a migration that never runs.
test('packages/cli/package.json version matches the root package.json version', () => {
  const root = readJson(join(ROOT, 'package.json')).version;
  const cli = readJson(join(ROOT, 'packages', 'cli', 'package.json')).version;
  assert.equal(cli, root, `packages/cli/package.json is ${cli} but root package.json is ${root}`);
});

// .speck/VERSION is written into every downstream project on upgrade and is what detect-version.sh
// reports. If it trails the release, projects believe they are on an older Speck than they are.
test('.speck/VERSION matches the root package.json version', () => {
  const root = readJson(join(ROOT, 'package.json')).version;
  const speck = readFileSync(join(ROOT, '.speck', 'VERSION'), 'utf8').trim();
  assert.equal(speck, root, `.speck/VERSION is ${speck} but root package.json is ${root}`);
});

// Twice in one release a finished *.test.sh landed outside the npm test chain — ~105 assertions
// dark on arrival, both times caught by review rather than by a gate. The chain is a hand-maintained
// `&&` list with no globs, so forgetting one is the default outcome, not an unlucky one. This is the
// gate: a shell test that exists but is never invoked is indistinguishable from one that passes.
test('every *.test.sh under .speck/scripts is wired into the npm test chain', () => {
  const chain = readJson(join(ROOT, 'package.json')).scripts.test;

  const walk = (dir, out = []) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      const p = join(dir, e.name);
      if (e.isDirectory()) {
        // test-fixtures holds deliberately-malformed inputs, not runnable suites.
        if (e.name === 'test-fixtures' || e.name === 'node_modules') continue;
        walk(p, out);
      } else if (e.name.endsWith('.test.sh')) {
        out.push(p.slice(ROOT.length + 1));
      }
    }
    return out;
  };

  const scriptsDir = join(ROOT, '.speck', 'scripts');
  if (!existsSync(scriptsDir)) return;

  const unwired = walk(scriptsDir).filter((rel) => !chain.includes(rel));
  assert.deepEqual(
    unwired,
    [],
    `these shell suites exist but never run in CI:\n  ${unwired.join('\n  ')}\n` +
      'Append `&& bash <path>` to the "test" script in package.json.'
  );
});
