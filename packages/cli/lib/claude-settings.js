/**
 * Claude Code settings reconciliation for Speck-managed hook blocks.
 *
 * Speck owns hooks.Stop, hooks.SessionStart, hooks.PostToolUse (see _speck_managed
 * in settings.json.example). User owns permissions, env, and custom hook types.
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'fs';
import { join } from 'path';
import { createHash } from 'crypto';

export const DEFAULT_MANAGED_BLOCKS = [
  'hooks.Stop',
  'hooks.SessionStart',
  'hooks.PostToolUse',
];

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf-8'));
}

function writeJson(path, obj) {
  writeFileSync(path, `${JSON.stringify(obj, null, 2)}\n`, 'utf-8');
}

export function getManagedBlocks(exampleJson) {
  const blocks = exampleJson?._speck_managed?.blocks;
  return Array.isArray(blocks) && blocks.length > 0 ? blocks : DEFAULT_MANAGED_BLOCKS;
}

export function getAtPath(obj, path) {
  if (!obj || !path) return undefined;
  const parts = path.split('.');
  let cur = obj;
  for (const part of parts) {
    if (cur == null || typeof cur !== 'object') return undefined;
    cur = cur[part];
  }
  return cur;
}

export function setAtPath(obj, path, value) {
  const parts = path.split('.');
  let cur = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    const part = parts[i];
    if (!(part in cur) || typeof cur[part] !== 'object' || cur[part] === null) {
      cur[part] = {};
    }
    cur = cur[part];
  }
  cur[parts[parts.length - 1]] = structuredClone(value);
}

export function hashValue(val) {
  return createHash('sha256').update(JSON.stringify(val ?? null)).digest('hex').slice(0, 12);
}

function valuesEqual(a, b) {
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
}

/**
 * Detect drift between active settings and example for Speck-managed blocks.
 * @returns {{ drift: Array, hasActive: boolean, hasExample: boolean, missingFile?: boolean, error?: string }}
 */
export function detectSettingsDrift(targetDir) {
  const examplePath = join(targetDir, '.claude/settings.json.example');
  const activePath = join(targetDir, '.claude/settings.json');

  if (!existsSync(examplePath)) {
    return { drift: [], hasActive: existsSync(activePath), hasExample: false };
  }

  let example;
  try {
    example = readJson(examplePath);
  } catch (err) {
    return { drift: [], hasExample: true, hasActive: existsSync(activePath), error: err.message };
  }

  const managed = getManagedBlocks(example);
  const drift = [];

  if (!existsSync(activePath)) {
    for (const blockPath of managed) {
      const exampleVal = getAtPath(example, blockPath);
      if (exampleVal !== undefined) {
        drift.push({
          path: blockPath,
          severity: 'P0',
          summary: 'settings.json missing — Speck-managed hooks not installed',
          exampleHash: hashValue(exampleVal),
        });
      }
    }
    return { drift, hasActive: false, hasExample: true, missingFile: true };
  }

  let active;
  try {
    active = readJson(activePath);
  } catch (err) {
    return {
      drift: [{
        path: '.claude/settings.json',
        severity: 'P0',
        summary: `Invalid JSON in active settings: ${err.message}`,
      }],
      hasActive: true,
      hasExample: true,
    };
  }

  for (const blockPath of managed) {
    const exampleVal = getAtPath(example, blockPath);
    const activeVal = getAtPath(active, blockPath);
    if (!valuesEqual(exampleVal, activeVal)) {
      drift.push({
        path: blockPath,
        severity: 'P0',
        summary: activeVal === undefined
          ? 'missing in active settings'
          : 'differs from settings.json.example',
        activeHash: hashValue(activeVal),
        exampleHash: hashValue(exampleVal),
      });
    }
  }

  // Legacy prompt-type Stop hook is a known infinite-loop class
  const stopHooks = getAtPath(active, 'hooks.Stop');
  if (Array.isArray(stopHooks)) {
    for (const entry of stopHooks) {
      const inner = entry?.hooks;
      if (Array.isArray(inner)) {
        for (const h of inner) {
          if (h?.type === 'prompt' && typeof h.prompt === 'string' && h.prompt.includes('tasks.md')) {
            drift.push({
              path: 'hooks.Stop',
              severity: 'P0',
              summary: 'legacy prompt-type Stop hook (tasks.md gate) — replace with command hook via reconcile-settings',
              activeHash: hashValue(h),
            });
            break;
          }
        }
      }
    }
  }

  return { drift, hasActive: true, hasExample: true };
}

/**
 * Reconcile Speck-managed blocks from example into active settings.
 * @returns {{ ok: boolean, drift: Array, applied: boolean, changes: string[], created?: boolean, message?: string }}
 */
export function reconcileSettings(targetDir, options = {}) {
  const { apply = true, verbose = false } = options;
  const examplePath = join(targetDir, '.claude/settings.json.example');
  const activePath = join(targetDir, '.claude/settings.json');

  if (!existsSync(examplePath)) {
    return { ok: false, drift: [], applied: false, changes: [], message: 'No .claude/settings.json.example found' };
  }

  const example = readJson(examplePath);
  const managed = getManagedBlocks(example);
  const detection = detectSettingsDrift(targetDir);

  if (!apply) {
    return {
      ok: true,
      drift: detection.drift,
      applied: false,
      changes: detection.drift.map(d => d.path),
    };
  }

  mkdirSync(join(targetDir, '.claude'), { recursive: true });

  let active;
  let created = false;

  if (!existsSync(activePath)) {
    copyFileSync(examplePath, activePath);
    created = true;
    if (verbose) {
      console.log('  ✅ Created .claude/settings.json from example');
    }
    return {
      ok: true,
      drift: detection.drift,
      applied: true,
      changes: managed,
      created: true,
      message: 'Created settings.json from example',
    };
  }

  active = readJson(activePath);
  const changes = [];

  for (const blockPath of managed) {
    const exampleVal = getAtPath(example, blockPath);
    const activeVal = getAtPath(active, blockPath);
    if (!valuesEqual(exampleVal, activeVal)) {
      setAtPath(active, blockPath, exampleVal);
      changes.push(blockPath);
    }
  }

  if (example._speck_managed) {
    if (!valuesEqual(active._speck_managed, example._speck_managed)) {
      active._speck_managed = structuredClone(example._speck_managed);
      if (!changes.includes('_speck_managed')) {
        changes.push('_speck_managed');
      }
    }
  }

  if (changes.length > 0 || created) {
    writeJson(activePath, active);
  }

  return {
    ok: true,
    drift: detection.drift,
    applied: changes.length > 0 || created,
    changes,
    created,
    message: changes.length > 0
      ? `Reconciled ${changes.length} Speck-managed block(s)`
      : 'Claude settings already in sync',
  };
}

/**
 * Post-upgrade helper: reconcile settings and return summary for console output.
 */
export function runSettingsReconcile(targetDir, options = {}) {
  const detection = detectSettingsDrift(targetDir);
  const result = reconcileSettings(targetDir, { apply: true, verbose: options.verbose });

  return {
    ...result,
    hadDrift: detection.drift.length > 0,
    driftBefore: detection.drift,
  };
}
