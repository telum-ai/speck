/**
 * Tests for v7 → v8 migration detection + the .v8-reprove-needed marker (Speck v8, Layer 1).
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  detectMigration,
  writeV8ReproveMarker,
  writeV9GraphMarker,
  runPostUpgradeMigrations,
  registerMigration,
  getRegisteredMigrations,
  readAppliedLedger,
  pendingMigrations,
  runNamedMigrations,
  migrateCommand,
  STAMP_TEMPLATE_VERSION_ID,
  LIFT_SERVES_ID,
} from './migrate.js';

const SPECK_BIN = join(dirname(fileURLToPath(import.meta.url)), '..', 'bin', 'speck.js');

function tempTarget(withSpeck = true) {
  const dir = mkdtempSync(join(tmpdir(), 'speck-migrate-'));
  if (withSpeck) mkdirSync(join(dir, '.speck'), { recursive: true });
  return dir;
}

/** Build a throwaway registry so a test never mutates the module-level one. */
function fakeMigration(id, run, appliesTo = () => true) {
  return { id, description: `test migration ${id}`, appliesTo, run };
}

/** Capture console.log for the duration of fn. Returns the joined output. */
function captureLog(fn) {
  const lines = [];
  const original = console.log;
  console.log = (...args) => lines.push(args.join(' '));
  try {
    fn();
  } finally {
    console.log = original;
  }
  return lines.join('\n');
}

test('detectMigration: 6.x → 7.x scaffolds v7, no v8 reprove', () => {
  const r = detectMigration('6.1.14', '7.20.1');
  assert.equal(r.scaffoldV7, true);
  assert.equal(r.reproveV8, false);
  assert.equal(r.targetMajor, 7);
});

test('detectMigration: 7.x → 8.x reproves v8, no v7 scaffold', () => {
  const r = detectMigration('7.20.1', '8.0.0');
  assert.equal(r.scaffoldV7, false);
  assert.equal(r.reproveV8, true);
  assert.equal(r.targetMajor, 8);
});

test('detectMigration: 6.x → 8.x needs BOTH v7 scaffold and v8 reprove', () => {
  const r = detectMigration('6.0.0', '8.0.0');
  assert.equal(r.scaffoldV7, true);
  assert.equal(r.reproveV8, true);
});

test('detectMigration: same-major (8 → 8) needs neither', () => {
  const r = detectMigration('8.0.0', '8.1.0');
  assert.equal(r.scaffoldV7, false);
  assert.equal(r.reproveV8, false);
});

test('detectMigration: 8.x → 9.x needs graphV9, not v7/v8', () => {
  const r = detectMigration('8.6.0', '9.0.0');
  assert.equal(r.scaffoldV7, false);
  assert.equal(r.reproveV8, false);
  assert.equal(r.graphV9, true);
  assert.equal(r.targetMajor, 9);
});

test('detectMigration: 6.x → 9.x chains all three (scaffold + reprove + graph)', () => {
  const r = detectMigration('6.0.0', '9.0.0');
  assert.equal(r.scaffoldV7, true);
  assert.equal(r.reproveV8, true);
  assert.equal(r.graphV9, true);
});

test('detectMigration: same-major (9 → 9) needs no graphV9', () => {
  const r = detectMigration('9.0.0', '9.1.0');
  assert.equal(r.graphV9, false);
});

test('detectMigration: v-prefixed and unknown targets', () => {
  const pref = detectMigration('v7.20.1', 'v8.0.0');
  assert.equal(pref.reproveV8, true);
  const unknown = detectMigration('7.20.1', 'not-a-version');
  assert.equal(unknown.scaffoldV7, false);
  assert.equal(unknown.reproveV8, false);
  assert.equal(unknown.targetMajor, null);
});

test('writeV8ReproveMarker: writes marker, is idempotent, needs .speck', () => {
  const dir = tempTarget(true);
  try {
    const first = writeV8ReproveMarker(dir, '8.0.0');
    assert.equal(first.written, true);
    assert.ok(existsSync(join(dir, '.speck', '.v8-reprove-needed')));
    const body = readFileSync(join(dir, '.speck', '.v8-reprove-needed'), 'utf-8');
    assert.match(body, /RE-PROVE/);
    assert.match(body, /\/speck-reprove/);
    assert.match(body, /INTEGRATION-GREEN/);

    // Idempotent: second call must not overwrite.
    const second = writeV8ReproveMarker(dir, '8.0.0');
    assert.equal(second.written, false);
    assert.equal(second.reason, 'marker already present');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }

  const noSpeck = tempTarget(false);
  try {
    const r = writeV8ReproveMarker(noSpeck, '8.0.0');
    assert.equal(r.written, false);
  } finally {
    rmSync(noSpeck, { recursive: true, force: true });
  }
});

test('writeV9GraphMarker: writes marker, is idempotent, needs .speck', () => {
  const dir = tempTarget(true);
  try {
    const first = writeV9GraphMarker(dir, '9.0.0');
    assert.equal(first.written, true);
    assert.ok(existsSync(join(dir, '.speck', '.v9-graph-needed')));
    const body = readFileSync(join(dir, '.speck', '.v9-graph-needed'), 'utf-8');
    assert.match(body, /WITNESS-GRAPH/);
    assert.match(body, /\/speck-graph-up/);
    assert.match(body, /road-to-completion\.md/);
    const second = writeV9GraphMarker(dir, '9.0.0');
    assert.equal(second.written, false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: 8 → 9 writes graph marker, kind v8-to-v9', () => {
  const dir = tempTarget(true);
  try {
    const summary = runPostUpgradeMigrations(dir, '8.6.0', '9.0.0');
    assert.equal(summary.kind, 'v8-to-v9');
    assert.equal(summary.targetMajor, 9);
    assert.equal(summary.v9Graph.written, true);
    assert.ok(existsSync(join(dir, '.speck', '.v9-graph-needed')));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: 7 → 8 writes marker and reports kind v7-to-v8', () => {
  const dir = tempTarget(true);
  try {
    const summary = runPostUpgradeMigrations(dir, '7.20.1', '8.0.0');
    assert.equal(summary.kind, 'v7-to-v8');
    assert.equal(summary.targetMajor, 8);
    assert.equal(summary.projects.length, 0);
    assert.ok(summary.v8Reprove && summary.v8Reprove.written);
    assert.ok(existsSync(join(dir, '.speck', '.v8-reprove-needed')));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: no-op within same major returns null kind', () => {
  const dir = tempTarget(true);
  try {
    const summary = runPostUpgradeMigrations(dir, '8.0.0', '8.1.0');
    assert.equal(summary.kind, null);
    assert.equal(summary.v8Reprove, null);
    assert.ok(!existsSync(join(dir, '.speck', '.v8-reprove-needed')));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// ---------------------------------------------------------------------------
// v10 — the migration lane (detection, registry, applied ledger, CLI surface)
// ---------------------------------------------------------------------------

test('detectMigration: 9.x → 10.x sets migrateV10 and nothing older', () => {
  const r = detectMigration('9.6.0', '10.0.0');
  assert.equal(r.migrateV10, true);
  assert.equal(r.graphV9, false, '9.6 already has the graph — do not re-run graphV9');
  assert.equal(r.reproveV8, false);
  assert.equal(r.scaffoldV7, false);
  assert.equal(r.targetMajor, 10, 'majorOf must read "10" as ten, not one');
});

test('detectMigration: 8.x → 10.x chains graphV9 + migrateV10 only', () => {
  const r = detectMigration('8.6.0', '10.0.0');
  assert.equal(r.scaffoldV7, false, 'an 8.x project already has v7 artifacts');
  assert.equal(r.reproveV8, false, 'an 8.x project already crossed the v8 re-prove');
  assert.equal(r.graphV9, true);
  assert.equal(r.migrateV10, true);
});

test('detectMigration: 6.x → 10.x chains all four crossings', () => {
  const r = detectMigration('6.0.0', '10.0.0');
  assert.equal(r.scaffoldV7, true);
  assert.equal(r.reproveV8, true);
  assert.equal(r.graphV9, true);
  assert.equal(r.migrateV10, true);
});

test('detectMigration: same-major (10 → 10) needs no migrateV10', () => {
  const r = detectMigration('10.0.0', '10.4.1');
  assert.equal(r.migrateV10, false);
});

test('runPostUpgradeMigrations: 8.x → 10.0 executes actions in dependency order', () => {
  const dir = tempTarget(true);
  try {
    // The ORDER claim is about EXECUTION, not bookkeeping, so it is observed from inside
    // a migration: by the time the named lane runs, graphV9's marker must already be on
    // disk. A summary array alone would pass even if the lane ran first.
    let graphMarkerSeen = null;
    const probe = fakeMigration('m-order-probe', target => {
      graphMarkerSeen = existsSync(join(target, '.speck', '.v9-graph-needed'));
    });

    const summary = runPostUpgradeMigrations(dir, '8.6.0', '10.0.0', { registry: [probe] });

    assert.equal(graphMarkerSeen, true, 'graphV9 must have run BEFORE the named lane');
    assert.deepEqual(summary.actions, ['graphV9', 'migrateV10']);
    assert.equal(summary.kind, 'v8-to-v10');
    assert.ok(summary.v9Graph && summary.v9Graph.written);
    assert.deepEqual(summary.named.applied, ['m-order-probe'], 'v10 runs the named-migration lane');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: 9.6 → 9.7 runs NOTHING (old no-op behaviour held)', () => {
  const dir = tempTarget(true);
  try {
    const summary = runPostUpgradeMigrations(dir, '9.6.0', '9.7.0');
    assert.equal(summary.kind, null);
    assert.deepEqual(summary.actions, []);
    assert.equal(summary.named, null);
    // A within-major upgrade must not create a ledger, i.e. must not touch project.json.
    assert.ok(!existsSync(join(dir, '.speck', 'project.json')));
    assert.ok(!existsSync(join(dir, '.speck', '.v9-graph-needed')));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: refuses a non-workspace dir directly, and scaffolds nothing', () => {
  // Defense-in-depth, not the primary guard: migrateCommand() already refuses a non-workspace
  // dir before it ever reaches this function, and the only shipped caller (upgrade.js) invokes
  // it after saveVersion() has written .speck/VERSION. This test targets runPostUpgradeMigrations
  // itself so a FUTURE direct caller (bypassing migrateCommand) cannot silently scaffold
  // .speck/project.json into a directory that was never a Speck workspace — recordMigration()
  // does `mkdirSync(dirname(p), { recursive: true })` on whatever targetDir it is handed.
  const dir = tempTarget(false); // no .speck/ at all
  try {
    writeFileSync(join(dir, 'readme.txt'), 'just some directory\n');
    let ran = 0;
    const registry = [fakeMigration('m-should-not-run-either', () => { ran += 1; })];
    assert.throws(
      () => runPostUpgradeMigrations(dir, '9.6.0', '10.0.0', { registry }),
      /Not a Speck workspace/,
    );
    assert.equal(ran, 0, 'no migration may execute outside a workspace');
    assert.ok(!existsSync(join(dir, '.speck')), 'runPostUpgradeMigrations must not create .speck/');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('registerMigration: the module registry accepts a migration and rejects a bad one', () => {
  const before = getRegisteredMigrations().length;
  assert.ok(before >= 1, 'the built-in template_version migration ships registered');
  assert.ok(getRegisteredMigrations().some(m => m.id === STAMP_TEMPLATE_VERSION_ID));

  assert.throws(() => registerMigration({ id: 'no-run' }), /run\(\)/);
  assert.throws(
    () => registerMigration(fakeMigration(STAMP_TEMPLATE_VERSION_ID, () => {})),
    /already registered/,
    'a duplicate id must be refused — the ledger keys on id',
  );
  assert.equal(getRegisteredMigrations().length, before, 'rejected registrations do not land');
});

test('runNamedMigrations: an applied migration is SKIPPED on a second run (idempotence)', () => {
  const dir = tempTarget(true);
  try {
    let runs = 0;
    const registry = [fakeMigration('m-once', () => { runs += 1; })];

    const first = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry });
    assert.deepEqual(first.applied, ['m-once']);
    assert.deepEqual(first.skipped, []);
    assert.equal(runs, 1);

    // The ledger is the persisted proof — reload it from disk, not from memory.
    const ledger = readAppliedLedger(dir);
    assert.equal(ledger.find(e => e.id === 'm-once').status, 'applied');
    const onDisk = JSON.parse(readFileSync(join(dir, '.speck', 'project.json'), 'utf-8'));
    assert.ok(Array.isArray(onDisk.applied_migrations));
    assert.equal(onDisk.applied_migrations[0].id, 'm-once');

    const second = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry });
    assert.deepEqual(second.skipped, ['m-once']);
    assert.deepEqual(second.applied, []);
    assert.equal(runs, 1, 'run() must NOT fire a second time');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runNamedMigrations: preserves unrelated project.json keys when recording', () => {
  const dir = tempTarget(true);
  try {
    writeFileSync(
      join(dir, '.speck', 'project.json'),
      JSON.stringify({ play_level: 'platform', speck_version: '9.6.0' }, null, 2) + '\n',
    );
    runNamedMigrations(dir, '9.6.0', '10.0.0', { registry: [fakeMigration('m-keep', () => {})] });
    const pj = JSON.parse(readFileSync(join(dir, '.speck', 'project.json'), 'utf-8'));
    assert.equal(pj.play_level, 'platform', 'the ledger must not eat play_level');
    assert.equal(pj.speck_version, '9.6.0');
    assert.equal(pj.applied_migrations[0].id, 'm-keep');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runNamedMigrations: a throwing migration is recorded FAILED, siblings still run, retried next time', () => {
  const dir = tempTarget(true);
  try {
    let aRuns = 0, cRuns = 0, bRuns = 0;
    let bShouldThrow = true;
    const registry = [
      fakeMigration('m-a', () => { aRuns += 1; }),
      fakeMigration('m-b', () => { bRuns += 1; if (bShouldThrow) throw new Error('boom in b'); }),
      fakeMigration('m-c', () => { cRuns += 1; }),
    ];

    const first = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry });
    assert.deepEqual(first.applied, ['m-a', 'm-c'], 'the throw must not abort the siblings');
    assert.equal(first.failed.length, 1);
    assert.equal(first.failed[0].id, 'm-b');
    assert.match(first.failed[0].error, /boom in b/);
    assert.equal(cRuns, 1, 'm-c runs even though m-b threw before it');

    const ledger = readAppliedLedger(dir);
    assert.equal(ledger.find(e => e.id === 'm-b').status, 'failed');
    assert.notEqual(ledger.find(e => e.id === 'm-b').status, 'applied');

    // Resumable: a FAILED migration is retried, its already-applied siblings are not.
    bShouldThrow = false;
    const second = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry });
    assert.deepEqual(second.applied, ['m-b'], 'only the failed one is retried');
    assert.deepEqual(second.skipped, ['m-a', 'm-c']);
    assert.equal(aRuns, 1);
    assert.equal(bRuns, 2);
    assert.equal(readAppliedLedger(dir).find(e => e.id === 'm-b').status, 'applied');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runNamedMigrations: appliesTo gates by version crossing', () => {
  const dir = tempTarget(true);
  try {
    let ran = 0;
    const registry = [
      fakeMigration('m-v10', () => { ran += 1; }, (from, to) => to >= 10 && (from == null || from < 10)),
    ];
    const within = runNamedMigrations(dir, '9.6.0', '9.7.0', { registry });
    assert.deepEqual(within.applied, []);
    assert.equal(ran, 0);
    const crossing = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry });
    assert.deepEqual(crossing.applied, ['m-v10']);
    assert.equal(ran, 1);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('pendingMigrations: applicable-and-unrecorded only', () => {
  const dir = tempTarget(true);
  try {
    const registry = [
      fakeMigration('m-1', () => {}),
      fakeMigration('m-2', () => {}),
      fakeMigration('m-never', () => {}, () => false),
    ];
    assert.deepEqual(
      pendingMigrations(dir, '9.6.0', '10.0.0', { registry }).map(m => m.id),
      ['m-1', 'm-2'],
    );
    runNamedMigrations(dir, '9.6.0', '10.0.0', { registry: [registry[0]] });
    assert.deepEqual(
      pendingMigrations(dir, '9.6.0', '10.0.0', { registry }).map(m => m.id),
      ['m-2'],
      'an applied id drops out of pending',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('migrateCommand --list: prints pending vs applied on the surface the user reads', () => {
  const dir = tempTarget(true);
  try {
    const registry = [
      fakeMigration('m-done', () => {}),
      fakeMigration('m-todo', () => {}),
    ];
    runNamedMigrations(dir, '9.6.0', '10.0.0', { registry: [registry[0]] });

    let result;
    const out = captureLog(() => {
      result = migrateCommand(dir, { list: true, from: '9.6.0', to: '10.0.0', registry });
    });

    // Assert on the PRINTED text: --list has no other observable surface.
    assert.match(out, /PENDING/);
    assert.match(out, /APPLIED/);
    assert.match(out, /m-todo/);
    assert.match(out, /m-done/);
    // m-done must be under APPLIED, m-todo under PENDING — not merely both present.
    const pendingIdx = out.indexOf('PENDING');
    const appliedIdx = out.indexOf('APPLIED');
    assert.ok(pendingIdx < appliedIdx);
    assert.ok(out.indexOf('m-todo') > pendingIdx && out.indexOf('m-todo') < appliedIdx);
    assert.ok(out.indexOf('m-done') > appliedIdx);

    assert.deepEqual(result.pending.map(m => m.id), ['m-todo']);
    assert.deepEqual(result.applied.map(e => e.id), ['m-done']);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('migrateCommand: on a workspace ALREADY on the target major, pending is still found', () => {
  // The hole this pins: a hand-run `speck migrate --list` happens AFTER the upgrade wrote
  // .speck/VERSION. If `from` defaulted to that file, from and to would both be 10.x, every
  // appliesTo would answer false, and the command would report "PENDING (0)" for a project
  // where nothing had actually run. A manual invocation cannot know what the project came
  // FROM — so it must not guess. The ledger, not the version range, is what keeps it safe.
  const dir = tempTarget(true);
  try {
    writeFileSync(join(dir, '.speck', 'VERSION'), '10.0.0\n');
    const registry = [
      fakeMigration('m-v10', () => {}, (from, to) => to >= 10 && (from == null || from < 10)),
    ];
    let result;
    const out = captureLog(() => {
      result = migrateCommand(dir, { list: true, registry });
    });
    assert.deepEqual(result.pending.map(m => m.id), ['m-v10']);
    assert.match(out, /PENDING \(1\)/);
    assert.equal(result.targetVersion, '10.0.0', 'target comes from the authoritative VERSION file');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('migrateCommand --run: executes pending migrations and reports them', () => {
  const dir = tempTarget(true);
  try {
    let ran = 0;
    const registry = [fakeMigration('m-run', () => { ran += 1; })];
    const out = captureLog(() => {
      migrateCommand(dir, { run: true, from: '9.6.0', to: '10.0.0', registry });
    });
    assert.equal(ran, 1);
    assert.match(out, /m-run/);
    assert.equal(readAppliedLedger(dir).find(e => e.id === 'm-run').status, 'applied');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// --- The one real built-in migration, proving the lane end-to-end ------------

function writeArtifact(dir, relPath, body) {
  const full = join(dir, relPath);
  mkdirSync(join(full, '..'), { recursive: true });
  writeFileSync(full, body);
  return full;
}

test('stamp-template-version: stamps frontmatter artifacts, skips the rest, is idempotent', () => {
  const dir = tempTarget(true);
  try {
    const withFm = writeArtifact(
      dir,
      'specs/projects/demo/product-contract.md',
      '---\nspeck_version: 9.0\nartifact_type: product-contract\n---\n\n# Contract\n',
    );
    const alreadyStamped = writeArtifact(
      dir,
      'specs/projects/demo/epics/E001/epic.md',
      '---\nspeck_version: 9.0\ntemplate_version: "8.1.0"\n---\n\n# Epic\n',
    );
    const noFm = writeArtifact(dir, 'specs/projects/demo/project-state.md', '# State\n\nno frontmatter here\n');
    const outsideSpecs = writeArtifact(dir, 'README.md', '---\nspeck_version: 9.0\n---\n\n# Readme\n');

    const migration = getRegisteredMigrations().find(m => m.id === STAMP_TEMPLATE_VERSION_ID);
    assert.ok(migration, 'built-in must be registered');
    assert.equal(migration.appliesTo(9, 10), true);
    assert.equal(migration.appliesTo(10, 10), false);

    migration.run(dir, { targetVersion: '10.0.0' });

    assert.match(readFileSync(withFm, 'utf-8'), /^template_version: "10\.0\.0"$/m);
    // Stamped AFTER speck_version, matching the template frontmatter ordering.
    assert.match(
      readFileSync(withFm, 'utf-8'),
      /speck_version: 9\.0\ntemplate_version: "10\.0\.0"\nartifact_type/,
    );
    assert.match(readFileSync(alreadyStamped, 'utf-8'), /template_version: "8\.1\.0"/);
    assert.doesNotMatch(readFileSync(alreadyStamped, 'utf-8'), /10\.0\.0/, 'never overwrite an existing stamp');
    assert.equal(readFileSync(noFm, 'utf-8'), '# State\n\nno frontmatter here\n');
    assert.doesNotMatch(readFileSync(outsideSpecs, 'utf-8'), /template_version/, 'only specs/projects/ is in scope');

    // Idempotent: a second run changes nothing.
    const snapshot = readFileSync(withFm, 'utf-8');
    migration.run(dir, { targetVersion: '10.1.0' });
    assert.equal(readFileSync(withFm, 'utf-8'), snapshot);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: 9.6 → 10.0 stamps a real artifact and records the built-in', () => {
  const dir = tempTarget(true);
  try {
    const artifact = writeArtifact(
      dir,
      'specs/projects/demo/product-contract.md',
      '---\nspeck_version: 9.0\nartifact_type: product-contract\n---\n\n# Contract\n',
    );
    const summary = runPostUpgradeMigrations(dir, '9.6.0', '10.0.0');
    assert.deepEqual(summary.actions, ['migrateV10']);
    assert.ok(summary.named.applied.includes(STAMP_TEMPLATE_VERSION_ID));
    assert.match(readFileSync(artifact, 'utf-8'), /template_version: "10\.0\.0"/);
    assert.equal(
      readAppliedLedger(dir).find(e => e.id === STAMP_TEMPLATE_VERSION_ID).status,
      'applied',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// ---------------------------------------------------------------------------
// Workspace identity — `speck migrate` must refuse a directory that is not a
// Speck workspace instead of inventing a target version and scaffolding state.
// ---------------------------------------------------------------------------

test('migrateCommand: --list in a NON-workspace directory refuses instead of guessing', () => {
  const dir = tempTarget(false); // no .speck/ at all
  try {
    writeFileSync(join(dir, 'readme.txt'), 'just some directory\n');
    assert.throws(
      () => captureLog(() => migrateCommand(dir, { list: true })),
      /Not a Speck workspace/,
      'a confident PENDING list for a non-project is a lie, not a listing',
    );
    assert.ok(!existsSync(join(dir, '.speck')), '--list must not create .speck/');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('migrateCommand: --run in a NON-workspace directory refuses and scaffolds NOTHING', () => {
  // The reproduced P1: with no .speck/VERSION the target silently became a hardcoded
  // 10.0.0 while `from` is null by design, so every appliesTo() answered true, every
  // migration "applied", and .speck/project.json was created in a stranger's directory.
  const dir = tempTarget(false);
  try {
    writeFileSync(join(dir, 'readme.txt'), 'just some directory\n');
    let ran = 0;
    const registry = [fakeMigration('m-should-not-run', () => { ran += 1; })];
    assert.throws(
      () => captureLog(() => migrateCommand(dir, { run: true, registry })),
      /Not a Speck workspace/,
    );
    assert.equal(ran, 0, 'no migration may execute outside a workspace');
    assert.ok(!existsSync(join(dir, '.speck')), '.speck/ must not be scaffolded here');
    assert.ok(!existsSync(join(dir, '.speck', 'project.json')));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('migrateCommand: a .speck/ with no VERSION and no --to is an error, not a default', () => {
  // The secondary half of the same defect: the old fallback was the literal '10.0.0',
  // which is a lie the day v11 ships. There is no safe default — the target version
  // decides which migrations "apply", so an unknown target must stop the command.
  const dir = tempTarget(true); // .speck/ exists, .speck/VERSION does not
  try {
    assert.throws(
      () => captureLog(() => migrateCommand(dir, { list: true })),
      /VERSION/,
    );
    // ...and naming the jump explicitly still works.
    let result;
    captureLog(() => { result = migrateCommand(dir, { list: true, to: '10.0.0', registry: [] }); });
    assert.equal(result.targetVersion, '10.0.0');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('speck migrate --run (real CLI): non-workspace dir exits NON-ZERO and creates nothing', () => {
  // End-to-end through bin/speck.js, because the defect was reported as an exit code and a
  // stray .speck/ on disk — neither of which a direct migrateCommand() call can observe.
  const dir = tempTarget(false);
  try {
    writeFileSync(join(dir, 'readme.txt'), 'just some directory\n');
    const r = spawnSync(process.execPath, [SPECK_BIN, 'migrate', '--run'], {
      cwd: dir,
      encoding: 'utf-8',
    });
    assert.notEqual(r.status, 0, `expected non-zero exit, got ${r.status}\n${r.stdout}${r.stderr}`);
    assert.match(`${r.stdout}${r.stderr}`, /Not a Speck workspace/);
    assert.doesNotMatch(`${r.stdout}${r.stderr}`, /applied, 0 skipped/, 'must not report success');
    assert.ok(!existsSync(join(dir, '.speck')), 'no .speck/ may appear in a non-workspace');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// ---------------------------------------------------------------------------
// lift-serves — a migration that did nothing must never record 'applied'
// ---------------------------------------------------------------------------

test('lift-serves: a MISSING speck_graph.py records FAILED and stays pending (never silent success)', () => {
  const dir = tempTarget(true);
  try {
    // A project exists and the graph script does NOT — the sync that ships it is broken
    // or half-applied. Recording 'applied' here would permanently retire the lift, leaving
    // every story un-migrated → ORPHAN_STORY.P1 → /story-implement blocked.
    mkdirSync(join(dir, 'specs', 'projects', 'demo'), { recursive: true });
    assert.ok(!existsSync(join(dir, '.speck', 'scripts', 'graph', 'speck_graph.py')));

    const lift = getRegisteredMigrations().find(m => m.id === LIFT_SERVES_ID);
    assert.ok(lift, 'the lift-serves migration ships registered');
    assert.throws(() => lift.run(dir, { targetVersion: '10.0.0' }), /speck_graph\.py/);

    const result = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry: [lift] });
    assert.deepEqual(result.applied, [], 'a no-op lift is NOT an application');
    assert.equal(result.failed.length, 1);
    assert.equal(result.failed[0].id, LIFT_SERVES_ID);
    assert.equal(readAppliedLedger(dir).find(e => e.id === LIFT_SERVES_ID).status, 'failed');

    // The whole point of recording 'failed': it is PENDING again, so the next run retries it.
    assert.deepEqual(
      pendingMigrations(dir, '9.6.0', '10.0.0', { registry: [lift] }).map(m => m.id),
      [LIFT_SERVES_ID],
      'a failed lift must be retried once the script is restored',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('lift-serves: a ZERO-project workspace is a genuine no-op and records APPLIED', () => {
  // DECISION: zero projects is NOT the missing-script case. There are no story specs whose
  // prose claims could need lifting, and any project created after v10 is authored against
  // the `serves:` frontmatter slot from the start — so nothing is left for a later run to
  // pick up. Recording 'applied' is the honest answer; retrying forever would not be.
  const dir = tempTarget(true);
  try {
    mkdirSync(join(dir, '.speck', 'scripts', 'graph'), { recursive: true });
    writeFileSync(join(dir, '.speck', 'scripts', 'graph', 'speck_graph.py'), '# stub\n');

    const lift = getRegisteredMigrations().find(m => m.id === LIFT_SERVES_ID);
    const result = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry: [lift] });
    assert.deepEqual(result.applied, [LIFT_SERVES_ID]);
    assert.deepEqual(result.failed, []);
    assert.equal(readAppliedLedger(dir).find(e => e.id === LIFT_SERVES_ID).status, 'applied');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// ---------------------------------------------------------------------------
// Two shipped guarantees that had no test
// ---------------------------------------------------------------------------

test('stamp-template-version: a file with UNTERMINATED frontmatter is left byte-identical', () => {
  // The shipped guarantee is "not ours to repair". Without this test, replacing the
  // `close === -1` bail with `close = lines.length` keeps every other assertion green
  // while the migration starts writing into files whose frontmatter never closes.
  const dir = tempTarget(true);
  try {
    const body = '---\nspeck_version: 9.0\nartifact_type: spec\n\n# Body, and the block never closed\n';
    const unterminated = writeArtifact(dir, 'specs/projects/demo/broken.md', body);
    // A sibling with GOOD frontmatter, so a passing test cannot be explained by the
    // migration simply not reaching this directory.
    const healthy = writeArtifact(
      dir,
      'specs/projects/demo/good.md',
      '---\nspeck_version: 9.0\n---\n\n# Fine\n',
    );

    const migration = getRegisteredMigrations().find(m => m.id === STAMP_TEMPLATE_VERSION_ID);
    migration.run(dir, { targetVersion: '10.0.0' });

    assert.equal(readFileSync(unterminated, 'utf-8'), body, 'unterminated block must be untouched');
    assert.doesNotMatch(readFileSync(unterminated, 'utf-8'), /template_version/);
    assert.match(readFileSync(healthy, 'utf-8'), /template_version: "10\.0\.0"/, 'the walk did reach this dir');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('readAppliedLedger: a BARE-STRING entry counts as applied, so it never re-runs', () => {
  // The comment on the normalisation says the point is that a completed migration must
  // never re-run. Without this test, deleting the string branch turns every hand-written
  // or legacy ledger entry into null → dropped → the migration fires a second time.
  const dir = tempTarget(true);
  try {
    writeFileSync(
      join(dir, '.speck', 'project.json'),
      JSON.stringify({ play_level: 'build', applied_migrations: ['m-legacy'] }, null, 2) + '\n',
    );

    const ledger = readAppliedLedger(dir);
    assert.deepEqual(ledger.map(e => e.id), ['m-legacy'], 'a bare string is a ledger entry, not junk');
    assert.equal(ledger[0].status, 'applied');

    // The consequence that actually matters: it is not pending, and run() does not fire.
    let ran = 0;
    const registry = [fakeMigration('m-legacy', () => { ran += 1; })];
    assert.deepEqual(pendingMigrations(dir, '9.6.0', '10.0.0', { registry }), []);
    const result = runNamedMigrations(dir, '9.6.0', '10.0.0', { registry });
    assert.deepEqual(result.skipped, ['m-legacy']);
    assert.deepEqual(result.applied, []);
    assert.equal(ran, 0, 'a completed migration must never re-run');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* ===========================================================================
 * #98 — the §6a Scope + Subject column insert.
 *
 * These use a dynamic import rather than extending the module's top-level import list, purely to
 * keep the edit surface of this file to one appended block.
 * =========================================================================== */

const LEGACY_6A = [
  '# Evidence Contract',
  '',
  '## 6. Required Static Evidence',
  '',
  '### 6a. CI-Enforced Gate Registry',
  '',
  '| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |',
  '|---------|------------------|-------|--------|--------|--------|',
  '| banned | `.speck/scripts/banned-language-lint.sh` | pre-commit | copy | banned-language | — |',
  '| slow-e2e | `npx playwright test` | ci:push | e2e | — | waived DEC-123 |',
  '',
  '## 7. Required Live-Service Evidence',
  '',
  '| Endpoint | Expected |',
  '|----------|----------|',
  '| /health | 200 |',
  '',
].join('\n');

test('#98: inserts Scope + Subject after Domain, preserving every existing cell', async () => {
  const { insertGateRegistryColumns } = await import('./migrate.js');
  const dir = tempTarget(true);
  try {
    const f = join(dir, 'evidence-contract.md');
    writeFileSync(f, LEGACY_6A);
    assert.equal(insertGateRegistryColumns(f), true, 'a legacy 6-column §6a must be widened');

    const out = readFileSync(f, 'utf-8').split('\n');
    assert.equal(
      out[6],
      '| Gate ID | Command / Script | Stage | Domain | Scope | Subject | Canary | Waiver |',
      'the two new labels go between Domain and Canary',
    );
    assert.match(out[7], /^\|[-| ]+\|$/, 'separator stays a well-formed markdown separator');
    assert.equal(
      out[7].split('|').length,
      out[6].split('|').length,
      'separator column count must track the widened header',
    );

    // THE ASSERTION THAT MATTERS: the pre-existing cells did not shift a column. A canary key that
    // lands in the Scope cell reads as an un-canaried gate; a `waived DEC-123` that lands in Canary
    // reads as an unknown canary key AND an unwaived dark gate.
    assert.equal(
      out[8],
      '| banned | `.speck/scripts/banned-language-lint.sh` | pre-commit | copy | — | — | banned-language | — |',
    );
    assert.equal(
      out[9],
      '| slow-e2e | `npx playwright test` | ci:push | e2e | — | — | — | waived DEC-123 |',
    );

    // The §7 table in the same document is NOT a gate registry and must be untouched.
    assert.ok(readFileSync(f, 'utf-8').includes('| Endpoint | Expected |'), '§7 header untouched');
    assert.ok(readFileSync(f, 'utf-8').includes('| /health | 200 |'), '§7 row untouched');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('#98: the column insert is idempotent by inspection, not only by ledger', async () => {
  const { insertGateRegistryColumns } = await import('./migrate.js');
  const dir = tempTarget(true);
  try {
    const f = join(dir, 'evidence-contract.md');
    writeFileSync(f, LEGACY_6A);
    insertGateRegistryColumns(f);
    const once = readFileSync(f, 'utf-8');
    // A `.speck/` re-sync can lose the ledger. If a second run widened the table again, every
    // consumer would read Canary out of the Subject cell — a corrupted artifact with no ledger
    // entry to explain it.
    assert.equal(insertGateRegistryColumns(f), false, 'a second run must report no change');
    assert.equal(readFileSync(f, 'utf-8'), once, 'and must leave the file byte-identical');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('#98: a migrated contract still parses correctly in validate-gate-liveness.sh', async () => {
  // The producer/consumer round-trip, across the migration. Asserting on the markdown alone proves
  // the string is shaped right; this proves the CONSUMER agrees — the waiver must still be found in
  // its (now shifted) real column, which is the failure mode a mid-table insert causes.
  const { insertGateRegistryColumns } = await import('./migrate.js');
  const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
  const validator = join(repoRoot, '.speck', 'scripts', 'validation', 'validators', 'validate-gate-liveness.sh');
  if (!existsSync(validator)) return;   // running from a consumer sync without the validators

  const dir = tempTarget(true);
  try {
    const f = join(dir, 'evidence-contract.md');
    writeFileSync(f, LEGACY_6A);
    insertGateRegistryColumns(f);
    const r = spawnSync('bash', [validator, f], { encoding: 'utf-8' });
    const out = `${r.stdout}${r.stderr}`;
    assert.match(out, /GATE_WAIVER_UNBACKED\.P2.*slow-e2e/, 'the Waiver cell must still be read as a waiver');
    assert.match(out, /DEC-123/, 'and its DEC must survive the insert intact');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('#98: the column insert is registered on the v10 lane', async () => {
  const { getRegisteredMigrations: reg, GATE_REGISTRY_SCOPE_SUBJECT_ID } = await import('./migrate.js');
  const m = reg().find(x => x.id === GATE_REGISTRY_SCOPE_SUBJECT_ID);
  assert.ok(m, 'a breaking §6a schema change with no registered migration is not shippable');
  assert.equal(m.appliesTo(9, 10), true, 'must fire on the 9 → 10 crossing');
  assert.equal(m.appliesTo(null, 10), true, 'and on an unknown origin (a hand-run `speck migrate`)');
  assert.equal(m.appliesTo(10, 10), false, 'but not on a 10.x → 10.y upgrade');
});

/* --- v10 banned_language.scope default flip (cluster W5) ------------------------------
 *
 * The flip itself is a code default, not an artifact edit, so it is tempting to ship it with
 * no migration at all. That is exactly the failure: a DEFAULT is invisible, and a team whose
 * pre-commit gate silently starts inspecting a thousand previously-unreached files has nothing
 * in the diff to explain why. The migration writes the resolution down per project, so the
 * change is legible and the opt-out is one word.
 */

test('#98.1: the banned_language.scope flip is registered on the v10 lane', async () => {
  const { getRegisteredMigrations: reg, BANNED_LANGUAGE_SCOPE_ID } = await import('./migrate.js');
  const m = reg().find(x => x.id === BANNED_LANGUAGE_SCOPE_ID);
  assert.ok(m, 'a default flip that changes what a shipped gate inspects needs a migration');
  assert.equal(m.appliesTo(9, 10), true, 'must fire on the 9 → 10 crossing');
  assert.equal(m.appliesTo(null, 10), true, 'and on an unknown origin (a hand-run `speck migrate`)');
  assert.equal(m.appliesTo(10, 10), false, 'but not on a 10.x → 10.y upgrade');
});

test('#98.1: records the new default for a project that never declared a scope', async () => {
  const { pinBannedLanguageScope } = await import('./migrate.js');
  const dir = tempTarget(true);
  try {
    const p = join(dir, '.speck', 'project.json');
    writeFileSync(p, JSON.stringify({ project_id: 'x', play_level: 'sprint' }, null, 2) + '\n');
    assert.equal(pinBannedLanguageScope(dir), true);
    const pj = JSON.parse(readFileSync(p, 'utf-8'));
    assert.equal(pj.banned_language.scope, 'any-depth', 'the new default must be legible in the diff');
    assert.equal(pj.project_id, 'x', 'and every other key must survive');
    // Idempotent by INSPECTION, not only by the ledger: a mid-run crash re-runs this.
    assert.equal(pinBannedLanguageScope(dir), false, 'a second run must be a no-op');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('#98.1: never overrides a scope the project already declared', async () => {
  const { pinBannedLanguageScope } = await import('./migrate.js');
  const dir = tempTarget(true);
  try {
    const p = join(dir, '.speck', 'project.json');
    writeFileSync(
      p,
      JSON.stringify(
        { project_id: 'x', banned_language: { scope: 'legacy-root', exclude: ['**/legacy/**'] } },
        null,
        2,
      ) + '\n',
    );
    assert.equal(pinBannedLanguageScope(dir), false, 'a deliberate opt-out is an opinion, not a gap');
    const pj = JSON.parse(readFileSync(p, 'utf-8'));
    assert.equal(pj.banned_language.scope, 'legacy-root');
    assert.deepEqual(pj.banned_language.exclude, ['**/legacy/**'], 'sibling keys untouched');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
