/**
 * Tests for v7 → v8 migration detection + the .v8-reprove-needed marker (Speck v8, Layer 1).
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  detectMigration,
  writeV8ReproveMarker,
  runPostUpgradeMigrations,
} from './migrate.js';

function tempTarget(withSpeck = true) {
  const dir = mkdtempSync(join(tmpdir(), 'speck-migrate-'));
  if (withSpeck) mkdirSync(join(dir, '.speck'), { recursive: true });
  return dir;
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
