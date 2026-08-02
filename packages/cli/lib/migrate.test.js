/**
 * Tests for v7 → v8 migration detection + the .v8-reprove-needed marker (Speck v8, Layer 1).
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, writeFileSync, rmSync, copyFileSync } from 'node:fs';
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

/* ===========================================================================
 * v10.1 — THE LANE GOES MINOR-CAPABLE (#103's class: two halves, one clock)
 *
 * The registry was built version-agnostic while its predicate stayed major-only, so a
 * migration registered in 10.1 could not fire for a 10.0 → 10.1 upgrade. That constraint is
 * exactly what forced v9.6 and v10 to be batched into a single major.
 * =========================================================================== */

/* ---------------------------------------------------------------------------
 * THE FROZEN DECISION TABLE — the acceptance criterion for this change.
 *
 * Every value below was CAPTURED from v10.0.0 before the refactor, by running
 * detectMigration() and pendingMigrations() over the shipped registry. It is a
 * behaviour freeze, not an aspiration: making the predicate version-keyed must not
 * move a single one of these decisions.
 *
 * It asserts through pendingMigrations() rather than by calling appliesTo() directly,
 * deliberately — the calling CONVENTION is what changes, so a test that hand-picks the
 * arguments would freeze the wrong thing and pass either way.
 * ------------------------------------------------------------------------- */

const V10_BUILTINS = [
  'v10-stamp-template-version',
  'v10-lift-serves-frontmatter',
  'v10-gate-registry-scope-subject-columns',
  'v10-banned-language-scope-any-depth',
];

// The v10.1 riders. They are NOT part of the freeze — they are what the freeze made possible:
// every row below whose TARGET reaches 10.1 now carries them, and every row whose target stops
// at 10.0 (or whose origin is already past 10.1) is byte-for-byte the v10.0.0 decision. That
// split IS the assertion: the minor lane fires exactly where a minor lane should, and nowhere
// a major-keyed predicate used to fire.
const V10_1_BUILTINS = [
  'v10-1-rebuild-witness-graph',
  'v10-1-stamp-citation-types',
];

// [from, to, { scaffoldV7, reproveV8, graphV9, migrateV10, targetMajor }, pendingIds]
const FROZEN_CROSSINGS = [
  ['6.0.0', '7.0.0', [true, false, false, false, 7], []],
  ['6.1.14', '7.20.1', [true, false, false, false, 7], []],
  ['7.20.1', '8.0.0', [false, true, false, false, 8], []],
  ['6.0.0', '8.0.0', [true, true, false, false, 8], []],
  ['8.6.0', '9.0.0', [false, false, true, false, 9], []],
  ['6.0.0', '9.0.0', [true, true, true, false, 9], []],
  ['9.0.0', '9.1.0', [false, false, false, false, 9], []],
  ['9.6.0', '9.7.0', [false, false, false, false, 9], []],
  ['9.6.0', '10.0.0', [false, false, false, true, 10], V10_BUILTINS],
  ['8.6.0', '10.0.0', [false, false, true, true, 10], V10_BUILTINS],
  ['6.0.0', '10.0.0', [true, true, true, true, 10], V10_BUILTINS],
  ['10.0.0', '10.1.0', [false, false, false, false, 10], V10_1_BUILTINS],
  ['10.0.0', '10.4.1', [false, false, false, false, 10], V10_1_BUILTINS],
  ['10.9.0', '10.10.0', [false, false, false, false, 10], []],
  ['10.0.0', '11.0.0', [false, false, false, false, 11], V10_1_BUILTINS],
  [null, '9.0.0', [true, true, true, false, 9], []],
  [null, '10.0.0', [true, true, true, true, 10], V10_BUILTINS],
  [null, '10.1.0', [true, true, true, true, 10], [...V10_BUILTINS, ...V10_1_BUILTINS]],
  ['7.20.1', 'not-a-version', [false, false, false, false, null], []],
  ['v7.20.1', 'v8.0.0', [false, true, false, false, 8], []],
];

test('FROZEN: every v7/v8/v9/v10 crossing decides exactly as v10.0.0 decided', () => {
  const dir = tempTarget(true);
  try {
    const registry = getRegisteredMigrations();
    for (const [from, to, flags, expectedPending] of FROZEN_CROSSINGS) {
      const label = `${from ?? '(unknown)'} → ${to}`;
      const d = detectMigration(from, to);
      assert.deepEqual(
        [d.scaffoldV7, d.reproveV8, d.graphV9, d.migrateV10, d.targetMajor],
        flags,
        `detectMigration drifted for ${label}`,
      );
      assert.deepEqual(
        pendingMigrations(dir, from, to, { registry }).map(m => m.id),
        expectedPending,
        `the shipped registry's applicability drifted for ${label}`,
      );
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* --- (b) the semver comparison, and the ordering trap ---------------------- */

test('compareVersions: 10.10.0 > 10.9.0 > 10.1.0 — the trap a string compare gets wrong', async () => {
  const { compareVersions, parseVersion } = await import('./migrate.js');

  // The whole reason this helper exists. Left as a string compare it reads
  // '10.10.0' < '10.9.0' (because '1' < '9' at index 3) and nothing surfaces for months.
  assert.ok('10.10.0' < '10.9.0', 'the trap is real: a string compare inverts these');
  assert.equal(compareVersions('10.10.0', '10.9.0'), 1);
  assert.equal(compareVersions('10.9.0', '10.1.0'), 1);
  assert.equal(compareVersions('10.1.0', '10.10.0'), -1);
  assert.equal(compareVersions('9.9.9', '10.0.0'), -1, 'major dominates');
  assert.equal(compareVersions('10.1.0', '10.1.0'), 0);
  assert.equal(compareVersions('v10.1.0', '10.1.0'), 0, 'a v prefix is not a version difference');
  assert.equal(compareVersions('10.0.10', '10.0.9'), 1, 'patch compares numerically too');
  assert.equal(compareVersions(null, '10.0.0'), null, 'unknown is not comparable, and says so');
  assert.equal(compareVersions('not-a-version', '10.0.0'), null);

  assert.deepEqual(parseVersion('v10.10.3'), { major: 10, minor: 10, patch: 3 });
  assert.deepEqual(parseVersion('10.1'), { major: 10, minor: 1, patch: 0 });
  assert.equal(parseVersion('not-a-version'), null);
});

test('atOrAfter: fires on the MINOR that introduces it, never before, never after it landed', async () => {
  const { atOrAfter } = await import('./migrate.js');
  const p = atOrAfter('10.1.0');

  assert.equal(p('10.0.0', '10.1.0'), true, 'the crossing that introduces it');
  assert.equal(p('10.0.0', '10.3.0'), true, 'a jump straight past it still needs it');
  assert.equal(p('10.0.0', '11.0.0'), true, 'and so does a major jump over it');
  assert.equal(p('9.6.0', '10.1.0'), true);
  assert.equal(p(null, '10.1.0'), true, 'unknown origin applies — the ledger is the real guard');

  assert.equal(p('10.0.0', '10.0.9'), false, 'the upgrade never reaches 10.1.0');
  assert.equal(p('10.1.0', '10.2.0'), false, 'the project was already at/past it');
  assert.equal(p('10.2.0', '10.3.0'), false);
  assert.equal(p('10.0.0', 'not-a-version'), false, 'an unreadable target cannot claim to reach it');

  // The ordering trap, through the predicate rather than the comparator.
  assert.equal(atOrAfter('10.9.0')('10.1.0', '10.10.0'), true, '10.10.0 is AFTER 10.9.0');
  assert.equal(atOrAfter('10.10.0')('10.0.0', '10.9.0'), false, '10.9.0 is BEFORE 10.10.0');
});

/* --- (a) full versions to the predicate, majors in ctx --------------------- */

test('appliesTo receives FULL versions plus ctx majors; a 2-arg predicate keeps the old shape', () => {
  const dir = tempTarget(true);
  try {
    const seen = [];
    const modern = {
      id: 'm-modern',
      description: 'three-parameter predicate',
      appliesTo: (fromVersion, toVersion, ctx) => {
        seen.push({ fromVersion, toVersion, ctx });
        return true;
      },
      run: () => {},
    };
    // The pre-10.1 shape, verbatim from the shipped registrations. It must keep receiving
    // MAJORS: handed '10.0.0' instead of 10, `'10.0.0' >= 10` is NaN-false and the migration
    // silently never runs — a false negative with no error anywhere.
    let legacyArgs = null;
    const legacy = {
      id: 'm-legacy-shape',
      description: 'two-parameter major-keyed predicate',
      appliesTo: (fromMajor, toMajor) => {
        legacyArgs = [fromMajor, toMajor];
        return toMajor >= 10 && (fromMajor == null || fromMajor < 10);
      },
      run: () => {},
    };

    const pending = pendingMigrations(dir, '9.6.0', '10.0.0', { registry: [modern, legacy] });
    assert.deepEqual(pending.map(m => m.id), ['m-modern', 'm-legacy-shape']);

    assert.equal(seen[0].fromVersion, '9.6.0', 'the modern predicate gets the FULL from-version');
    assert.equal(seen[0].toVersion, '10.0.0', 'and the FULL to-version');
    assert.equal(seen[0].ctx.fromMajor, 9, 'with the parsed majors carried in ctx');
    assert.equal(seen[0].ctx.toMajor, 10);
    assert.deepEqual(legacyArgs, [9, 10], 'the 2-arg shape still gets majors, positionally');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* --- (c) a MINOR crossing must run a pending minor migration --------------- */

test('runPostUpgradeMigrations: a 10.0 → 10.1 MINOR crossing runs the 10.1 migration', async () => {
  const { atOrAfter } = await import('./migrate.js');
  const dir = tempTarget(true);
  try {
    let ran = 0;
    const registry = [
      { id: 'm-10-1', description: 'a 10.1 artifact migration', version: '10.1.0',
        appliesTo: atOrAfter('10.1.0'), run: () => { ran += 1; } },
    ];

    const summary = runPostUpgradeMigrations(dir, '10.0.0', '10.1.0', { registry });

    assert.equal(ran, 1, 'a brand-new minor migration must not be invisible to the upgrade');
    assert.deepEqual(summary.named.applied, ['m-10-1']);
    assert.ok(summary.actions.includes('namedMigrations'), 'the lane running must be reported');
    assert.equal(readAppliedLedger(dir).find(e => e.id === 'm-10-1').status, 'applied');

    // Still once-only. The replay is not even a "skip" — with the ledger recorded, nothing
    // is pending and no major flag is set, so the whole function short-circuits before the
    // lane. run() must not fire again, and the summary must say plainly that nothing ran.
    const again = runPostUpgradeMigrations(dir, '10.0.0', '10.1.0', { registry });
    assert.equal(ran, 1, 'run() must NOT fire a second time');
    assert.equal(again.named, null);
    assert.deepEqual(again.actions, []);
    assert.equal(
      readAppliedLedger(dir).find(e => e.id === 'm-10-1').status,
      'applied',
      'and the ledger still holds the record that made the replay a no-op',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('runPostUpgradeMigrations: a minor crossing with NOTHING pending still runs nothing', () => {
  // The other half of (c): making minors capable must not make every minor upgrade do work.
  const dir = tempTarget(true);
  try {
    const summary = runPostUpgradeMigrations(dir, '10.0.0', '10.1.0', { registry: [] });
    assert.equal(summary.kind, null);
    assert.deepEqual(summary.actions, []);
    assert.equal(summary.named, null);
    assert.ok(!existsSync(join(dir, '.speck', 'project.json')), 'no ledger may be scaffolded');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* --- (d) multi-hop -------------------------------------------------------- */

/** A versioned migration for the multi-hop tests. `appliesTo` is left to the lane to derive. */
function versionedMigration(id, version, run) {
  return { id, description: `migration introduced in ${version}`, version, run };
}

test('multi-hop: 10.0 → 10.3 runs the 10.1, 10.2 and 10.3 migrations once each, in version order', () => {
  const dir = tempTarget(true);
  try {
    const order = [];
    // Registered OUT of version order on purpose: version order must come from the version,
    // not from whichever module happened to import first.
    const registry = [
      versionedMigration('m-10-3', '10.3.0', () => order.push('10.3.0')),
      versionedMigration('m-10-1', '10.1.0', () => order.push('10.1.0')),
      versionedMigration('m-10-2', '10.2.0', () => order.push('10.2.0')),
    ];

    const result = runNamedMigrations(dir, '10.0.0', '10.3.0', { registry });

    assert.deepEqual(order, ['10.1.0', '10.2.0', '10.3.0'], 'a hop must replay history forwards');
    assert.deepEqual(result.applied, ['m-10-1', 'm-10-2', 'm-10-3']);
    assert.deepEqual(result.failed, []);

    // Once each, forever: the second pass is all skips.
    const second = runNamedMigrations(dir, '10.0.0', '10.3.0', { registry });
    assert.deepEqual(second.applied, []);
    assert.deepEqual(second.skipped, ['m-10-1', 'm-10-2', 'm-10-3']);
    assert.deepEqual(order, ['10.1.0', '10.2.0', '10.3.0'], 'no run() fired twice');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('multi-hop: a THROWING middle migration does not strand the later ones, and is retried', () => {
  const dir = tempTarget(true);
  try {
    const order = [];
    let middleThrows = true;
    const registry = [
      versionedMigration('m-10-1', '10.1.0', () => order.push('10.1.0')),
      versionedMigration('m-10-2', '10.2.0', () => {
        order.push('10.2.0');
        if (middleThrows) throw new Error('10.2 blew up mid-hop');
      }),
      versionedMigration('m-10-3', '10.3.0', () => order.push('10.3.0')),
    ];

    const first = runNamedMigrations(dir, '10.0.0', '10.3.0', { registry });
    assert.deepEqual(order, ['10.1.0', '10.2.0', '10.3.0'], '10.3 must still run after 10.2 threw');
    assert.deepEqual(first.applied, ['m-10-1', 'm-10-3']);
    assert.deepEqual(first.failed.map(f => f.id), ['m-10-2']);
    assert.match(first.failed[0].error, /blew up mid-hop/);
    assert.equal(readAppliedLedger(dir).find(e => e.id === 'm-10-2').status, 'failed');

    // Resumable across the hop: only the failed one is pending, and it retries in place.
    assert.deepEqual(
      pendingMigrations(dir, '10.0.0', '10.3.0', { registry }).map(m => m.id),
      ['m-10-2'],
    );
    middleThrows = false;
    const second = runNamedMigrations(dir, '10.0.0', '10.3.0', { registry });
    assert.deepEqual(second.applied, ['m-10-2']);
    assert.deepEqual(second.skipped, ['m-10-1', 'm-10-3']);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('multi-hop ordering: 10.10.0 runs AFTER 10.9.0, not before it', () => {
  // The ordering trap where it actually bites: run order. A string sort would put
  // '10.10.0' before '10.9.0' and apply a later schema change to an earlier shape.
  const dir = tempTarget(true);
  try {
    const order = [];
    const registry = [
      versionedMigration('m-10-10', '10.10.0', () => order.push('10.10.0')),
      versionedMigration('m-10-9', '10.9.0', () => order.push('10.9.0')),
      versionedMigration('m-10-2', '10.2.0', () => order.push('10.2.0')),
    ];
    runNamedMigrations(dir, '10.1.0', '10.11.0', { registry });
    assert.deepEqual(order, ['10.2.0', '10.9.0', '10.10.0']);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('multi-hop: a hop that stops SHORT of a version does not run that version migration', () => {
  const dir = tempTarget(true);
  try {
    const order = [];
    const registry = [
      versionedMigration('m-10-1', '10.1.0', () => order.push('10.1.0')),
      versionedMigration('m-10-2', '10.2.0', () => order.push('10.2.0')),
      versionedMigration('m-10-5', '10.5.0', () => order.push('10.5.0')),
    ];
    const r = runNamedMigrations(dir, '10.0.0', '10.2.0', { registry });
    assert.deepEqual(order, ['10.1.0', '10.2.0'], '10.5 has not shipped for this workspace yet');
    assert.deepEqual(r.applied, ['m-10-1', 'm-10-2']);
    assert.ok(!readAppliedLedger(dir).some(e => e.id === 'm-10-5'), 'and it is not recorded either');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('registerMigration: a NEW two-parameter predicate warns that it will receive majors', async () => {
  // The one live trap left by supporting both shapes. `atOrAfter`/`crossesMajor` are tagged
  // and a bare `version` derives a tagged predicate, so the only way to fall in is to
  // hand-roll a version-keyed rule with two declared parameters — which then silently
  // receives majors, compares NaN, and never fires. Zero noise for correct registrations;
  // loud at exactly the moment the trap is being set.
  const { registerMigration: reg } = await import('./migrate.js');
  const warnings = [];
  const original = console.warn;
  console.warn = (...args) => warnings.push(args.join(' '));
  try {
    reg({
      id: 'm-two-param-warns',
      description: 'hand-rolled two-parameter predicate',
      appliesTo: (from, to) => to >= 11 && (from == null || from < 11),
      run: () => {},
    });
  } finally {
    console.warn = original;
  }
  assert.equal(warnings.length, 1, 'exactly one warning, on the registration that earned it');
  assert.match(warnings[0], /m-two-param-warns/);
  assert.match(warnings[0], /major/i, 'it must say WHICH arguments the predicate will receive');

  // And a correctly-shaped registration stays silent.
  const quiet = [];
  console.warn = (...args) => quiet.push(args.join(' '));
  try {
    reg({ id: 'm-versioned-quiet', description: 'derived predicate', version: '10.1.0', run: () => {} });
  } finally {
    console.warn = original;
  }
  assert.deepEqual(quiet, [], 'a `version`-derived predicate is the blessed shape — no noise');
});

test('registerMigration: `version` alone derives appliesTo, and is rejected when unparsable', async () => {
  const { registerMigration: reg } = await import('./migrate.js');
  assert.throws(
    () => reg({ id: 'v-bad', version: 'ten-point-one', run: () => {} }),
    /version/,
    'an unparsable version cannot order or gate anything',
  );
  assert.throws(
    () => reg({ id: 'v-neither', run: () => {} }),
    /appliesTo|version/,
    'a migration with neither a version nor a predicate has no firing rule at all',
  );
});

/* --- (e) --list names the introducing version ----------------------------- */

test('migrate --list: names the VERSION that introduced each pending migration', async () => {
  const { atOrAfter } = await import('./migrate.js');
  const dir = tempTarget(true);
  try {
    writeFileSync(join(dir, '.speck', 'VERSION'), '10.3.0\n');
    const registry = [
      { id: 'm-done', description: 'already ran', version: '10.1.0', appliesTo: atOrAfter('10.1.0'), run: () => {} },
      { id: 'm-todo', description: 'still pending', version: '10.2.0', appliesTo: atOrAfter('10.2.0'), run: () => {} },
    ];
    runNamedMigrations(dir, '10.0.0', '10.3.0', { registry: [registry[0]] });

    let result;
    const out = captureLog(() => {
      result = migrateCommand(dir, { list: true, registry });
    });

    assert.deepEqual(result.pending.map(m => m.id), ['m-todo']);
    // The actionable fact: WHICH version brought this migration into existence.
    const todoLine = out.split('\n').find(l => l.includes('m-todo'));
    assert.match(todoLine, /10\.2\.0/, 'a pending migration must name its introducing version');
    const doneLine = out.split('\n').find(l => l.includes('m-done'));
    assert.match(doneLine, /10\.1\.0/, 'and the ledger remembers it for the applied ones');

    assert.equal(
      readAppliedLedger(dir).find(e => e.id === 'm-done').version,
      '10.1.0',
      'the ledger records the introducing version, so --list does not depend on the registry',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* ===========================================================================
 * v10.1 — THE TWO MINOR-INTRODUCED ARTIFACT MIGRATIONS
 *
 * B1 built the minor-capable lane (above) precisely so v10.1's two breaking artifact
 * changes could ride the upgrade. Both shipped WITHOUT a registration, which is the same
 * defect in both directions:
 *
 *   entry_point/wiring_witness on every prm+story node    → _graph_signature() changes →
 *     every witness.json committed under v10.0.0 reads GRAPH_STALE.P2 / GRAPH_CAP = STALE
 *     against a v10.1 fresh compile. Measured on a clean fixture: v10.0.0 build+check exits 0
 *     at INTEGRATION-GREEN; the same tree under v10.1 scripts is STALE. 100% of consumers go
 *     green→red on code they did not change, and /story-implement prints the banner on every
 *     story. crossesMajor(10) does NOT fire for 10.0 → 10.1, so nothing rebuilt them.
 *
 *   typed citations (§11a)                                → the stamp mechanism attached to
 *     nothing at all: four registrations existed, every one of them version '10.0.0'.
 * =========================================================================== */

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const REAL_GRAPH_SCRIPT = join(REPO_ROOT, '.speck', 'scripts', 'graph', 'speck_graph.py');

/**
 * A stub stamp script that types `login.test.ts` IN PLACE, leaving every other byte —
 * including the authored column padding — exactly where the author put it. This is what the
 * shipped stamp mode does today, and the only shape the migration is allowed to write.
 *
 * Written as single-quoted JS strings on purpose: a template literal would eat bash's
 * `${...}` expansions.
 */
const STAMP_STUB_PRESERVING = [
  '#!/usr/bin/env bash',
  'set -euo pipefail',
  'write=false; target=""',
  'for a in "$@"; do',
  '  case "$a" in',
  '    --stamp-types|--strict) ;;',
  '    --write) write=true ;;',
  '    *) target="$a" ;;',
  '  esac',
  'done',
  'out=""; changed=false',
  'while IFS= read -r line || [[ -n "$line" ]]; do',
  '  new="${line//login.test.ts/test:login.test.ts}"',
  '  [[ "$new" != "$line" ]] && changed=true',
  '  out+="$new"$\'\\n\'',
  'done < "$target"',
  'if [[ "$write" == true && "$changed" == true ]]; then printf "%s" "$out" > "$target"; fi',
  'echo "Citations: stamped"',
  'exit 0',
  '',
].join('\n');

/**
 * The stub that reproduces the defect the audit measured across 24 files: it rebuilds any row
 * it touched out of TRIMMED cells, collapsing the author's column padding. The stamp mode has
 * since been fixed to splice in place, so this stub — not the shipped script — is what keeps
 * the guard honest: it pins the migration's own promise (annotate, never reformat) against
 * whoever edits the stamper next.
 */
const STAMP_STUB_REFLOWING = [
  '#!/usr/bin/env bash',
  'set -euo pipefail',
  'write=false; target=""',
  'for a in "$@"; do',
  '  case "$a" in',
  '    --stamp-types|--strict) ;;',
  '    --write) write=true ;;',
  '    *) target="$a" ;;',
  '  esac',
  'done',
  'out=""; changed=false',
  'while IFS= read -r line || [[ -n "$line" ]]; do',
  '  new="${line//login.test.ts/test:login.test.ts}"',
  '  if [[ "$new" != "$line" ]]; then',
  '    changed=true',
  '    IFS="|" read -r -a cells <<< "$new"',
  '    rebuilt="|"',
  '    for (( i=1; i<${#cells[@]}; i++ )); do',
  '      c="${cells[$i]}"',
  '      c="${c#"${c%%[![:space:]]*}"}"',
  '      c="${c%"${c##*[![:space:]]}"}"',
  '      if [[ -z "$c" && $i -eq $(( ${#cells[@]} - 1 )) ]]; then continue; fi',
  '      rebuilt+=" $c |"',
  '    done',
  '    new="$rebuilt"',
  '  fi',
  '  out+="$new"$\'\\n\'',
  'done < "$target"',
  'if [[ "$write" == true && "$changed" == true ]]; then printf "%s" "$out" > "$target"; fi',
  'echo "Citations: stamped"',
  'exit 0',
  '',
].join('\n');

/** A workspace on 10.1.0, wired the way `speck upgrade` leaves .speck/scripts/. */
function v101Workspace({ graph = true, stamp = null } = {}) {
  const dir = tempTarget(true);
  writeFileSync(join(dir, '.speck', 'VERSION'), '10.1.0\n');
  if (graph) {
    mkdirSync(join(dir, '.speck', 'scripts', 'graph'), { recursive: true });
    copyFileSync(REAL_GRAPH_SCRIPT, join(dir, '.speck', 'scripts', 'graph', 'speck_graph.py'));
  }
  if (stamp) {
    const validators = join(dir, '.speck', 'scripts', 'validation', 'validators');
    mkdirSync(validators, { recursive: true });
    writeFileSync(join(validators, 'validate-evidence-citations.sh'), stamp);
  }
  return dir;
}

/**
 * The smallest project the real extractor resolves cleanly: one magic moment, one story
 * that serves it, one matrix row discharging it. Deliberately the REAL artifacts — the
 * whole finding is about what the real extractor now puts on a node.
 */
function writeFixtureProject(targetDir, id = '001-demo') {
  const proj = join(targetDir, 'specs', 'projects', id);
  const story = join(proj, 'epics', '001-alpha', 'stories', 'S001-foo');
  mkdirSync(story, { recursive: true });
  writeFileSync(join(proj, 'product-contract.md'), [
    '# Product Contract: Demo',
    '',
    '## 2. Primary Persona',
    '**JTBD** (`JOB-1`): When X, I want Y, so that Z.',
    '',
    '## 5. Magic Moments',
    '### MM-1 — First wow',
    '',
  ].join('\n'));
  writeFileSync(join(story, 'spec.md'), [
    '---',
    'artifact_type: story-spec',
    'depends_on: []',
    'blocks: []',
    'serves: [MM-1]',
    'readiness_state_verified: UX-RC',
    '---',
    '# Story: Foo',
    '#### AC-1 — Primary',
    '',
  ].join('\n'));
  writeFileSync(join(proj, 'epics', '001-alpha', 'traceability-matrix.md'), [
    '# Matrix: Alpha',
    '## 2. Traceability Matrix',
    '| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |',
    '|--------|--------|---------|-------------------------------|-----|-------|--------|',
    '| PRM-001 | product-contract §5 MM-1 | wow lands | S001 / AC-1 | — | ux-rc | discharged |',
    '',
  ].join('\n'));
  return proj;
}

/** An artifact carrying an untyped citation in a PADDED table — the stamp migration's subject. */
const PADDED_CITATION_REPORT = [
  '# Validation Report',
  '',
  '| Claim type               | Evidence                                  | Notes             |',
  '|--------------------------|-------------------------------------------|-------------------|',
  '| correctness              | login.test.ts                             | authored padding  |',
  '',
].join('\n');

function runGraph(script, ...args) {
  const r = spawnSync('python3', [script, ...args], { encoding: 'utf-8' });
  return `${r.stdout || ''}${r.stderr || ''}`;
}

/** Rewrite a committed witness.json into the shape v10.0.0's extractor produced. */
function downgradeWitnessToV10_0(proj) {
  const p = join(proj, 'graph', 'witness.json');
  const g = JSON.parse(readFileSync(p, 'utf-8'));
  for (const n of g.nodes) {
    if (!n.attrs) continue;
    delete n.attrs.entry_point;
    delete n.attrs.wiring_witness;
  }
  writeFileSync(p, JSON.stringify(g, null, 2) + '\n');
}

/* --- (a) both are REGISTERED, on the minor lane ---------------------------- */

test('v10.1: BOTH minor artifact migrations are registered, keyed to 10.1.0', async () => {
  const { REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID } = await import('./migrate.js');
  const byId = new Map(getRegisteredMigrations().map(m => [m.id, m]));

  for (const id of [REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID]) {
    const m = byId.get(id);
    assert.ok(m, `${id} must ship registered — an unregistered migration attaches to nothing`);
    assert.equal(m.version, '10.1.0', `${id} must declare the release that introduced it`);
    // The whole point: it fires on the MINOR crossing that shipped it. crossesMajor(10) —
    // what all four v10.0.0 built-ins use — is false for 10.0 → 10.1.
    assert.equal(
      m.appliesTo('10.0.0', '10.1.0', { fromMajor: 10, toMajor: 10 }),
      true,
      `${id} must apply to the 10.0 → 10.1 crossing that introduced it`,
    );
    assert.equal(
      m.appliesTo('10.1.0', '10.2.0', { fromMajor: 10, toMajor: 10 }),
      false,
      `${id} must not re-propose itself on a later hop`,
    );
  }
});

/* --- (b) the graph rebuild, end to end on the real extractor --------------- */

test('v10.1: a witness built under v10.0.0 is STALE, and CLEAN after the migration runs', async () => {
  const { REBUILD_WITNESS_GRAPH_ID } = await import('./migrate.js');
  const dir = v101Workspace();
  try {
    const proj = writeFixtureProject(dir);
    const script = join(dir, '.speck', 'scripts', 'graph', 'speck_graph.py');

    runGraph(script, 'build', proj);
    downgradeWitnessToV10_0(proj);

    // RED: the exact consumer-visible symptom, measured — not asserted.
    const before = runGraph(script, 'check', proj);
    assert.match(before, /GRAPH_STALE/, 'a v10.0.0-shaped witness must read stale under v10.1');
    assert.match(before, /GRAPH_CAP = STALE/, 'and it caps the whole project');

    const m = getRegisteredMigrations().find(x => x.id === REBUILD_WITNESS_GRAPH_ID);
    const result = runNamedMigrations(dir, '10.0.0', '10.1.0', { registry: [m] });
    assert.deepEqual(result.applied, [REBUILD_WITNESS_GRAPH_ID]);
    assert.deepEqual(result.failed, []);

    // GREEN: same tree, same scripts, no spec edited — only the derived artifact rebuilt.
    const after = runGraph(script, 'check', proj);
    assert.doesNotMatch(after, /GRAPH_STALE/, 'the migration must clear the staleness it was written for');
    assert.doesNotMatch(after, /GRAPH_CAP = STALE/);
    // And the rebuild is what did it: the new schema keys are on the committed nodes now.
    const witness = JSON.parse(readFileSync(join(proj, 'graph', 'witness.json'), 'utf-8'));
    assert.ok(
      witness.nodes.some(n => n.attrs && 'entry_point' in n.attrs && 'wiring_witness' in n.attrs),
      'the committed witness must carry the v10.1 node schema',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('v10.1: rebuild-witness-graph THROWS when speck_graph.py is missing (never silent success)', async () => {
  const { REBUILD_WITNESS_GRAPH_ID } = await import('./migrate.js');
  const dir = v101Workspace({ graph: false });
  try {
    writeFixtureProject(dir);
    const m = getRegisteredMigrations().find(x => x.id === REBUILD_WITNESS_GRAPH_ID);
    const result = runNamedMigrations(dir, '10.0.0', '10.1.0', { registry: [m] });

    // A `return 0` here would record 'applied' and RETIRE the rebuild forever, leaving every
    // consumer permanently STALE — the documented failure contract of this lane.
    assert.deepEqual(result.applied, []);
    assert.equal(result.failed.length, 1);
    assert.match(result.failed[0].error, /speck_graph\.py/);
    assert.deepEqual(
      pendingMigrations(dir, '10.0.0', '10.1.0', { registry: [m] }).map(x => x.id),
      [REBUILD_WITNESS_GRAPH_ID],
      'a failed rebuild stays pending so the next run retries it',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('v10.1: a project with NO committed witness is left unbuilt, not silently graphed', async () => {
  const { REBUILD_WITNESS_GRAPH_ID } = await import('./migrate.js');
  const dir = v101Workspace();
  try {
    const proj = writeFixtureProject(dir);
    assert.ok(!existsSync(join(proj, 'graph', 'witness.json')));

    const m = getRegisteredMigrations().find(x => x.id === REBUILD_WITNESS_GRAPH_ID);
    const result = runNamedMigrations(dir, '10.0.0', '10.1.0', { registry: [m] });
    assert.deepEqual(result.applied, [REBUILD_WITNESS_GRAPH_ID], 'nothing stale, nothing to fix');
    assert.ok(
      !existsSync(join(proj, 'graph', 'witness.json')),
      'building a first graph is /speck-graph-up\'s gesture, behind identity hardening — a ' +
        'migration that minted one here could invent DANGLING_REF.P1 caps that did not exist',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* --- (c) the reflow guard: the real control point on the stamp ------------- */

test('v10.1: findTableReflow catches collapsed padding and passes an in-place type splice', async () => {
  const { findTableReflow } = await import('./migrate.js');
  const before = '| correctness   | login.test.ts        | note   |';

  assert.equal(
    findTableReflow(before, '| correctness   | test:login.test.ts        | note   |'),
    null,
    'splicing the type INTO the cell leaves every authored byte of padding where it was',
  );
  assert.match(
    findTableReflow(before, '| correctness | test:login.test.ts | note |') || '',
    /padding/,
    'rebuilding the row from trimmed cells is the destructive rewrite the audit measured',
  );
  assert.match(
    findTableReflow(before, '| correctness   | test:login.test.ts        |') || '',
    /cell count/,
    'a dropped cell is a corrupted row, not a stamp',
  );
  assert.match(
    findTableReflow('a\nb\n', 'a\n') || '',
    /line count/,
    'a dropped line is a corrupted file, not a stamp',
  );
});

test('v10.1: the stamp migration WRITES when the stamp preserves the table', async () => {
  const { STAMP_CITATION_TYPES_ID, findTableReflow } = await import('./migrate.js');
  const dir = v101Workspace({ stamp: STAMP_STUB_PRESERVING });
  try {
    const proj = writeFixtureProject(dir);
    const report = join(proj, 'epics', '001-alpha', 'stories', 'S001-foo', 'validation-report.md');
    writeFileSync(report, PADDED_CITATION_REPORT);

    const m = getRegisteredMigrations().find(x => x.id === STAMP_CITATION_TYPES_ID);
    const result = runNamedMigrations(dir, '10.0.0', '10.1.0', { registry: [m] });
    assert.deepEqual(result.applied, [STAMP_CITATION_TYPES_ID]);

    const after = readFileSync(report, 'utf-8');
    assert.match(after, /test:login\.test\.ts/, 'the citation is typed');
    assert.equal(
      findTableReflow(PADDED_CITATION_REPORT, after),
      null,
      'and not one byte of the authored table padding moved',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('v10.1: a REFLOWING stamp is rolled back byte-for-byte and stays PENDING', async () => {
  const { STAMP_CITATION_TYPES_ID } = await import('./migrate.js');
  const dir = v101Workspace({ stamp: STAMP_STUB_REFLOWING });
  try {
    const proj = writeFixtureProject(dir);
    const report = join(proj, 'epics', '001-alpha', 'stories', 'S001-foo', 'validation-report.md');
    writeFileSync(report, PADDED_CITATION_REPORT);

    const m = getRegisteredMigrations().find(x => x.id === STAMP_CITATION_TYPES_ID);
    const result = runNamedMigrations(dir, '10.0.0', '10.1.0', { registry: [m] });

    assert.deepEqual(result.applied, [], 'a destructive stamp is never recorded as applied');
    assert.equal(result.failed.length, 1);
    assert.match(result.failed[0].error, /padding|reflow/i);
    assert.equal(
      readFileSync(report, 'utf-8'),
      PADDED_CITATION_REPORT,
      'the file must be restored byte-for-byte — the migration leaves NO damage behind',
    );
    assert.deepEqual(
      pendingMigrations(dir, '10.0.0', '10.1.0', { registry: [m] }).map(x => x.id),
      [STAMP_CITATION_TYPES_ID],
      'and it stays pending, so it applies the run after the stamp mode is fixed',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('v10.1: stamp-citation-types THROWS when validate-evidence-citations.sh is missing (never silent success)', async () => {
  // The third of three structurally similar "script is missing -> throw" sites in this file
  // (lift-serves, rebuild-witness-graph, and this one). Isolated to a ONE-migration registry —
  // { registry: [m] } — so mutating either of the OTHER two throw sites cannot flip this test:
  // it exercises exactly the STAMP_CITATION_TYPES_ID run() and nothing else in the lane.
  const { STAMP_CITATION_TYPES_ID } = await import('./migrate.js');
  const dir = v101Workspace({ stamp: null }); // validators/validate-evidence-citations.sh absent
  try {
    writeFixtureProject(dir);
    assert.ok(
      !existsSync(join(dir, '.speck', 'scripts', 'validation', 'validators', 'validate-evidence-citations.sh')),
    );

    const m = getRegisteredMigrations().find(x => x.id === STAMP_CITATION_TYPES_ID);
    const result = runNamedMigrations(dir, '10.0.0', '10.1.0', { registry: [m] });

    // A `return 0` here would record 'applied' and RETIRE the stamp forever, leaving every
    // citation permanently untyped — the documented failure contract of this lane, proven now
    // for this rider rather than merely claimed by analogy to its two siblings.
    assert.deepEqual(result.applied, [], 'a no-op stamp is NOT an application');
    assert.equal(result.failed.length, 1);
    assert.equal(result.failed[0].id, STAMP_CITATION_TYPES_ID);
    assert.match(result.failed[0].error, /validate-evidence-citations\.sh/);
    assert.equal(
      readAppliedLedger(dir).find(e => e.id === STAMP_CITATION_TYPES_ID).status,
      'failed',
    );

    // "--list still shows it PENDING": the whole point of recording 'failed'.
    assert.deepEqual(
      pendingMigrations(dir, '10.0.0', '10.1.0', { registry: [m] }).map(x => x.id),
      [STAMP_CITATION_TYPES_ID],
      'a failed stamp stays pending so the next run retries it once the script is restored',
    );
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('v10.1: with the citation script absent, a real upgrade reports 1 applied 1 failed, and --list still shows it PENDING', async () => {
  // The end-to-end shape of the hand-verified claim, through the real CLI-facing
  // migrateCommand()/runNamedMigrations() pipeline and the REAL run() bodies of both v10.1
  // riders (graph script present, citation script absent) — not a fake stand-in.
  //
  // Scoped to exactly these two ids (not the bare module registry): by this point in the file,
  // earlier tests have permanently registered their own throwaway migrations onto the shared
  // module-level MIGRATION_REGISTRY (e.g. a `version: '10.1.0'` one with an empty run()), and
  // the module registry offers no way to unregister them. Asserting on the real registry
  // wholesale would make this test's pass/fail depend on unrelated tests' registration order
  // rather than on the STAMP_CITATION_TYPES_ID throw site this test exists to prove.
  const { STAMP_CITATION_TYPES_ID, REBUILD_WITNESS_GRAPH_ID, getRegisteredMigrations: reg } =
    await import('./migrate.js');
  const dir = v101Workspace({ graph: true, stamp: null });
  try {
    const proj = writeFixtureProject(dir);
    runGraph(join(dir, '.speck', 'scripts', 'graph', 'speck_graph.py'), 'build', proj);

    const registry = reg().filter(m => m.id === REBUILD_WITNESS_GRAPH_ID || m.id === STAMP_CITATION_TYPES_ID);
    assert.equal(registry.length, 2, 'both real v10.1 riders must be found in the shipped registry');

    const out = captureLog(() => {
      migrateCommand(dir, { run: true, from: '10.0.0', to: '10.1.0', registry });
    });

    assert.match(out, /1 applied, 0 skipped, 1 failed/, out);
    const ledger = readAppliedLedger(dir);
    assert.equal(ledger.find(e => e.id === REBUILD_WITNESS_GRAPH_ID)?.status, 'applied');
    assert.equal(ledger.find(e => e.id === STAMP_CITATION_TYPES_ID)?.status, 'failed');

    const list = captureLog(() => {
      migrateCommand(dir, { list: true, from: '10.0.0', to: '10.1.0', registry });
    });
    assert.match(list, /PENDING \(1\)/, list);
    const pendingBlock = list.split('APPLIED')[0];
    assert.ok(pendingBlock.includes(STAMP_CITATION_TYPES_ID), `must still list as pending\n${list}`);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* --- (d) the upgrade, end to end ------------------------------------------ */

test('v10.1: a 10.0 → 10.1 upgrade runs BOTH, once each; a second upgrade is a no-op', async () => {
  const { REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID } = await import('./migrate.js');
  const dir = v101Workspace({ stamp: STAMP_STUB_PRESERVING });
  try {
    const proj = writeFixtureProject(dir);
    const report = join(proj, 'epics', '001-alpha', 'stories', 'S001-foo', 'validation-report.md');
    writeFileSync(report, PADDED_CITATION_REPORT);
    runGraph(join(dir, '.speck', 'scripts', 'graph', 'speck_graph.py'), 'build', proj);
    downgradeWitnessToV10_0(proj);

    const first = runPostUpgradeMigrations(dir, '10.0.0', '10.1.0', {});
    // Through the REAL module registry, not an injected one — the defect was that the shipped
    // registry contained nothing for this crossing. Filtered to the v10.1 riders because earlier
    // tests in this file deliberately register throwaway 10.1.0 entries into that same registry.
    assert.deepEqual(
      first.named.applied.filter(id => id.startsWith('v10-1-')),
      [REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID],
      'a MINOR crossing must run both — this is the capability B1 built and both clusters declined',
    );
    assert.deepEqual(first.named.failed, []);
    // No major was crossed, so the summary reports the lane, not a v10 crossing.
    assert.deepEqual(first.actions, ['namedMigrations']);

    const stampedOnce = readFileSync(report, 'utf-8');

    const second = runPostUpgradeMigrations(dir, '10.0.0', '10.1.0', {});
    assert.deepEqual(second.named, null, 'nothing pending → the lane does not even run');
    assert.equal(readFileSync(report, 'utf-8'), stampedOnce, 'and no artifact is touched twice');

    const ledger = readAppliedLedger(dir);
    for (const id of [REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID]) {
      const e = ledger.filter(x => x.id === id);
      assert.equal(e.length, 1, `${id} is recorded exactly once`);
      assert.equal(e[0].status, 'applied');
      assert.equal(e[0].version, '10.1.0', 'the ledger remembers the introducing release');
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

/* --- (e) the operator surface, through the REAL bin/speck.js -------------- */

test('v10.1: `speck migrate --list --from 10.0.0 --to 10.1.0` names BOTH as pending, with v10.1.0', async () => {
  const { REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID } = await import('./migrate.js');
  const dir = v101Workspace();
  try {
    const r = spawnSync(
      process.execPath,
      [SPECK_BIN, 'migrate', '--list', '--from', '10.0.0', '--to', '10.1.0'],
      { cwd: dir, encoding: 'utf-8' },
    );
    const out = `${r.stdout}${r.stderr}`;
    assert.equal(r.status, 0, out);

    // The reported symptom was literally `PENDING (0)`: the mechanism attached to nothing.
    assert.match(out, /PENDING \(2\)/, out);
    const pendingBlock = out.split('APPLIED')[0];
    for (const id of [REBUILD_WITNESS_GRAPH_ID, STAMP_CITATION_TYPES_ID]) {
      const line = pendingBlock.split('\n').find(l => l.includes(id));
      assert.ok(line, `${id} must be listed as pending\n${out}`);
      assert.match(line, /\[v10\.1\.0\]/, `${id} must name the release that introduced it`);
    }
    // The v10.0.0 built-ins are NOT pending for a within-major hop.
    for (const id of V10_BUILTINS) {
      assert.ok(!pendingBlock.includes(id), `${id} crossed at v10.0.0 and must not re-propose`);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
