/**
 * Post-upgrade migration runner.
 *
 * Detects when an upgrade crosses a major version boundary that needs
 * project-level artifact scaffolding (currently v6 → v7) and runs the
 * appropriate migration script for every project under specs/projects/.
 *
 * Silent and idempotent: if a project already has v7 artifacts, the
 * migration script skips it. If there are no projects, nothing happens.
 */

import { existsSync, readdirSync, statSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { execSync } from 'child_process';

/**
 * Parse a version string like "v7.0.0", "7.0.0", or "v6.1.14" into an integer major.
 * Returns null for unparsable input.
 */
function majorOf(version) {
  if (!version) return null;
  const m = String(version).match(/v?(\d+)\./);
  return m ? parseInt(m[1], 10) : null;
}

/**
 * Find every project directory under specs/projects/.
 * A project is any direct subdirectory of specs/projects/.
 */
function findProjects(targetDir) {
  const projectsRoot = join(targetDir, 'specs', 'projects');
  if (!existsSync(projectsRoot)) return [];
  try {
    return readdirSync(projectsRoot)
      .map(name => join(projectsRoot, name))
      .filter(p => {
        try {
          return statSync(p).isDirectory();
        } catch {
          return false;
        }
      });
  } catch {
    return [];
  }
}

/**
 * Run the v6 → v7 migration script for a single project.
 * Returns { path, created, ok, output }.
 */
function migrateProjectV7(targetDir, projectPath, options = {}) {
  const script = join(targetDir, '.speck', 'scripts', 'migrate.sh');
  if (!existsSync(script)) {
    return { path: projectPath, created: 0, ok: false, output: 'migrate.sh not present' };
  }

  try {
    const output = execSync(`bash "${script}" "${projectPath}"`, {
      cwd: targetDir,
      encoding: 'utf-8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    // Count scaffolded artifacts by parsing the script's output ("✅" for each created/updated)
    const created = (output.match(/^✅ /gm) || []).length;

    if (options.verbose) {
      console.log(output);
    }

    return { path: projectPath, created, ok: true, output };
  } catch (err) {
    return {
      path: projectPath,
      created: 0,
      ok: false,
      output: err.stdout?.toString() || err.message,
    };
  }
}

/**
 * Decide which post-upgrade actions the (currentVersion → targetVersion)
 * transition requires. Actions are independent and can combine (a v6 → v8
 * jump needs both):
 *   - scaffoldV7: run the per-project v6 → v7 artifact scaffolding script
 *   - reproveV8:  drop the .speck/.v8-reprove-needed marker (semantic re-prove)
 *
 * Exported for testability.
 */
export function detectMigration(currentVersion, targetVersion) {
  const fromMajor = majorOf(currentVersion);
  const toMajor = majorOf(targetVersion);
  if (toMajor == null) {
    return { scaffoldV7: false, reproveV8: false, graphV9: false, migrateV10: false, targetMajor: null };
  }

  // Crossing into v7 from anything older → run v6→v7 scaffolding per project.
  // (Also fires on a v6→v8 jump: you need the v7 artifacts before the v8 re-prove.)
  const scaffoldV7 = toMajor >= 7 && (fromMajor == null || fromMajor < 7);

  // Crossing into v8 from anything older → semantic re-prove (cap-and-worklist).
  // The mechanical upgrade is trusted; v7-era "green" is NOT (see docs/v8/v8-north-star.md §5).
  const reproveV8 = toMajor >= 8 && (fromMajor == null || fromMajor < 8);

  // Crossing into v9 from anything older → establish the witness graph as the spine.
  // Chain-aware: a v6→v9 jump runs scaffoldV7 → reproveV8 → graphV9 in dependency order (the
  // graph extracts from the v7 artifacts and inherits the v8 caps). See docs/v9/v9-north-star.md §4.
  const graphV9 = toMajor >= 9 && (fromMajor == null || fromMajor < 9);

  // Crossing into v10 from anything older → run the named-migration lane (below).
  // Same chain-aware idiom as its three predecessors: a v6→v10 jump runs
  // scaffoldV7 → reproveV8 → graphV9 → migrateV10 in that order, because each step
  // reads what the one before it produced. Unlike v7/v8/v9 — whose real work is a
  // human-gestured skill behind a marker file — v10's work is mechanical and is
  // PERFORMED here, by the registry, against real artifacts.
  const migrateV10 = toMajor >= 10 && (fromMajor == null || fromMajor < 10);

  return { scaffoldV7, reproveV8, graphV9, migrateV10, targetMajor: toMajor };
}

/**
 * Write the repo-level .speck/.v8-reprove-needed marker — the direct analog of
 * v6→v7's .speck/.migration-needs-catchup. Non-destructive and idempotent:
 * never overwrites an existing marker. Returns { written, path, reason }.
 */
export function writeV8ReproveMarker(targetDir, targetVersion = '8.0.0') {
  const speckDir = join(targetDir, '.speck');
  if (!existsSync(speckDir)) {
    return { written: false, path: null, reason: '.speck directory not present' };
  }
  const markerPath = join(speckDir, '.v8-reprove-needed');
  if (existsSync(markerPath)) {
    return { written: false, path: markerPath, reason: 'marker already present' };
  }
  const date = new Date().toISOString().slice(0, 10);
  const body = `V8 SEMANTIC RE-PROVE NEEDED

This project was upgraded to Speck v8 (Evaluation Over Verification) on ${date}
(target ${targetVersion}). The mechanical upgrade — files, alias-shims, lazy patterns,
version — is done. But v8 does NOT trust v7-era "green" as evaluation-proven
(see docs/v8/v8-north-star.md §5).

BEFORE any new feature work, run:  /speck-reprove

It will:
  - triage suspect-green artifacts against the four v8 principles (P1-P4),
  - cap effective shippable state at INTEGRATION-GREEN,
  - revert consumer FELT-GOOD to \`uncovered\`,
  - preserve each historical v7 claim but stamp it [pre-v8-proof],
  - build a prioritized worklist and emit project-v8-reprove-report.md.

States climb back to \`verified\` only as real v8 evidence lands. Nothing is reset
to zero; nothing suspect keeps claiming ship-readiness.

Delete this marker only after /speck-reprove has produced the report and the
worklist is tracked.
`;
  writeFileSync(markerPath, body);
  return { written: true, path: markerPath, reason: null };
}

/**
 * Write the repo-level .speck/.v9-graph-needed marker — the v9 analog of writeV8ReproveMarker.
 * The mechanical upgrade cannot BUILD the graph (it needs identity hardened first, and the per-project
 * graph work is a reversible gesture the /speck-graph-up skill owns). Non-destructive, idempotent.
 */
export function writeV9GraphMarker(targetDir, targetVersion = '9.0.0') {
  const speckDir = join(targetDir, '.speck');
  if (!existsSync(speckDir)) {
    return { written: false, path: null, reason: '.speck directory not present' };
  }
  const markerPath = join(speckDir, '.v9-graph-needed');
  if (existsSync(markerPath)) {
    return { written: false, path: markerPath, reason: 'marker already present' };
  }
  const date = new Date().toISOString().slice(0, 10);
  const body = `V9 WITNESS-GRAPH TRUTH NOT YET ESTABLISHED

This project was upgraded to Speck v9 (the witness graph is the spine) on ${date}
(target ${targetVersion}). The mechanical upgrade — files, scripts, version — is done.
But the graph itself has NOT been built: it requires identity hardened first, and the
per-project graph work + retroactive cleanup is a reversible gesture the skill owns
(see docs/v9/v9-north-star.md §4).

BEFORE any new feature work, run:  /speck-graph-up

It will (chain-aware — runs /speck-catch-up or /speck-reprove first if their markers exist):
  - harden identity (AC-N numbering; surface MM-N/JOB-N for manual add; make lint-refs resolve),
  - build the witness graph (specs/projects/<id>/graph/witness.json),
  - run retroactive-cleanup reconcilers (--dry-run first; heal stale digests, over-claimed
    matrices, [pre-v9-proof] caps) — the road already walked,
  - emit road-to-completion.md and render project-state FROM the graph.

Delete this marker ONLY after witness.json + road-to-completion.md exist and project-state
renders from the graph. Until then, the engagement gate refuses feature work.
`;
  writeFileSync(markerPath, body);
  return { written: true, path: markerPath, reason: null };
}

/* ===========================================================================
 * THE NAMED-MIGRATION LANE (v10)
 * ===========================================================================
 *
 * WHY THIS EXISTS
 * scaffoldV7 / reproveV8 / graphV9 are each ONE all-or-nothing thing that happens
 * when you cross one major. That shape stops working at v10, which carries several
 * INDEPENDENT artifact migrations (a §6a column insertion, a serves-frontmatter lift,
 * a validation-report section). Three properties the old shape cannot give:
 *
 *   1. Each must run at most ONCE per project, forever — not "once per upgrade".
 *      A re-run of `speck upgrade`, or a later 10.x → 11.x, must not insert the same
 *      column twice. Version comparison alone cannot answer "did this already run?"
 *      once an artifact has been hand-edited since.
 *   2. One failing migration must not take the others down with it. An upgrade that
 *      aborts halfway leaves the project in a state no one can name.
 *   3. A failure must be RESUMABLE: retried on the next run, while its already-
 *      applied siblings stay skipped.
 *
 * The answer is a registry of named migrations plus a per-project applied ledger
 * persisted at `.speck/project.json` → `applied_migrations`.
 *
 * HOW TO REGISTER ONE (this is the surface other v10 work builds on):
 *
 *     import { registerMigration } from './migrate.js';
 *
 *     registerMigration({
 *       id: 'v10-traceability-6a-column',      // stable forever; it is the ledger key
 *       description: 'Insert the §6a witness column into traceability-matrix.md',
 *       appliesTo: (fromMajor, toMajor) => toMajor >= 10 && (fromMajor == null || fromMajor < 10),
 *       run: (targetDir, ctx) => { ... },      // throw to fail; return value ignored
 *     });
 *
 * CONTRACT for run(targetDir, ctx):
 *   - targetDir is the WORKSPACE root — the directory holding `.speck/` and `specs/projects/`.
 *   - ctx is { currentVersion, targetVersion, fromMajor, toMajor }.
 *   - It MUST be safe to run on a project that is already partly migrated: the ledger
 *     protects against a second run, but a mid-run crash does not, so make the write
 *     itself idempotent (check-then-write) rather than relying on the ledger alone.
 *   - Throwing is how you fail. The lane records `failed`, keeps going, and retries you
 *     next time. Do NOT catch-and-return-false: a swallowed failure records as applied
 *     and is then never retried, which is exactly the bug the ledger exists to prevent.
 *   - id must be unique. A duplicate id throws at registration, loudly, at import time —
 *     because two migrations sharing a ledger key means one of them silently never runs.
 */

const MIGRATION_REGISTRY = [];

/**
 * Register a named migration. Throws on a malformed or duplicate migration —
 * at import time, where it is a five-second fix, rather than mid-upgrade in a
 * user's repo where it is a corrupted artifact.
 */
export function registerMigration(migration) {
  if (!migration || typeof migration !== 'object') {
    throw new Error('registerMigration: expected a migration object');
  }
  const { id, description, appliesTo, run } = migration;
  if (typeof id !== 'string' || id.trim() === '') {
    throw new Error('registerMigration: migration needs a non-empty string id');
  }
  if (typeof run !== 'function') {
    throw new Error(`registerMigration: migration "${id}" needs a run() function`);
  }
  if (typeof appliesTo !== 'function') {
    throw new Error(`registerMigration: migration "${id}" needs an appliesTo(fromMajor, toMajor) function`);
  }
  if (MIGRATION_REGISTRY.some(m => m.id === id)) {
    throw new Error(`registerMigration: "${id}" is already registered (ids are ledger keys and must be unique)`);
  }
  MIGRATION_REGISTRY.push({ id, description: description || id, appliesTo, run });
  return MIGRATION_REGISTRY.length;
}

/** The registered migrations, in registration order. Copy — callers cannot mutate the lane. */
export function getRegisteredMigrations() {
  return MIGRATION_REGISTRY.slice();
}

/* --- the applied ledger ---------------------------------------------------
 *
 * Lives in `.speck/project.json` rather than its own dotfile so it travels with the
 * project's other Speck state and survives a `.speck/` re-sync: the upgrade path
 * rewrites scripts and templates wholesale, and a ledger in a scratch file would be
 * silently erased — after which every one-shot migration would run a second time.
 */

function projectJsonPath(targetDir) {
  return join(targetDir, '.speck', 'project.json');
}

function readProjectJson(targetDir) {
  const p = projectJsonPath(targetDir);
  if (!existsSync(p)) return null;
  try {
    const parsed = JSON.parse(readFileSync(p, 'utf-8'));
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

/**
 * Read the applied-migration ledger. Returns an array of
 * `{ id, status: 'applied' | 'failed', at, error? }`, normalised.
 *
 * Tolerates a bare-string entry (`["v10-foo"]`) as `applied`: an early hand-written
 * ledger, or a future simplification, must never cause a completed migration to re-run.
 */
export function readAppliedLedger(targetDir) {
  const pj = readProjectJson(targetDir);
  const raw = pj && Array.isArray(pj.applied_migrations) ? pj.applied_migrations : [];
  return raw
    .map(entry => {
      if (typeof entry === 'string') return { id: entry, status: 'applied', at: null };
      if (entry && typeof entry === 'object' && typeof entry.id === 'string') {
        return { ...entry, status: entry.status === 'failed' ? 'failed' : 'applied' };
      }
      return null;
    })
    .filter(Boolean);
}

/**
 * Record one migration outcome, preserving every other key in project.json.
 * Written after EACH migration, not once at the end: "individually resumable" means
 * a crash between two migrations must still leave the finished one recorded.
 */
function recordMigration(targetDir, id, status, error) {
  const pj = readProjectJson(targetDir) || {};
  const entries = readAppliedLedger(targetDir).filter(e => e.id !== id);
  const entry = { id, status, at: new Date().toISOString() };
  if (status === 'failed' && error) entry.error = String(error);
  entries.push(entry);
  const next = { ...pj, applied_migrations: entries };
  const p = projectJsonPath(targetDir);
  mkdirSync(dirname(p), { recursive: true });
  writeFileSync(p, JSON.stringify(next, null, 2) + '\n');
  return entry;
}

function resolveRegistry(options) {
  return Array.isArray(options.registry) ? options.registry : MIGRATION_REGISTRY;
}

/**
 * Migrations that apply to this version crossing and are not already recorded as applied.
 * A `failed` entry is PENDING again — that is the resumability guarantee.
 */
export function pendingMigrations(targetDir, currentVersion, targetVersion, options = {}) {
  const fromMajor = majorOf(currentVersion);
  const toMajor = majorOf(targetVersion);
  const done = new Set(readAppliedLedger(targetDir).filter(e => e.status === 'applied').map(e => e.id));
  return resolveRegistry(options).filter(m => {
    if (done.has(m.id)) return false;
    try {
      return !!m.appliesTo(fromMajor, toMajor);
    } catch {
      // A migration whose own gate throws is not silently skipped — treat it as
      // applicable so the failure surfaces in the run report instead of vanishing.
      return true;
    }
  });
}

/**
 * Run every pending named migration for this crossing.
 * Returns { applied: [id], skipped: [id], failed: [{ id, error }] }.
 */
export function runNamedMigrations(targetDir, currentVersion, targetVersion, options = {}) {
  const fromMajor = majorOf(currentVersion);
  const toMajor = majorOf(targetVersion);
  const ctx = { currentVersion, targetVersion, fromMajor, toMajor };
  const result = { applied: [], skipped: [], failed: [] };
  const done = new Set(readAppliedLedger(targetDir).filter(e => e.status === 'applied').map(e => e.id));

  for (const m of resolveRegistry(options)) {
    let applicable;
    try {
      applicable = !!m.appliesTo(fromMajor, toMajor);
    } catch {
      applicable = true;
    }
    if (!applicable) continue;

    if (done.has(m.id)) {
      result.skipped.push(m.id);
      if (options.verbose) console.log(`   ⏭  ${m.id} — already applied`);
      continue;
    }

    try {
      m.run(targetDir, ctx);
      recordMigration(targetDir, m.id, 'applied');
      result.applied.push(m.id);
      if (options.verbose) console.log(`   ✅ ${m.id} — ${m.description}`);
    } catch (err) {
      const message = err?.message || String(err);
      recordMigration(targetDir, m.id, 'failed', message);
      result.failed.push({ id: m.id, error: message });
      // Deliberately NOT rethrown: one broken migration must not strand the others,
      // and the ledger keeps it pending so the next run retries it.
      if (options.verbose) console.log(`   ❌ ${m.id} — FAILED: ${message} (will retry on next run)`);
    }
  }

  return result;
}

/* --- built-in migration: stamp template_version ---------------------------- */

export const STAMP_TEMPLATE_VERSION_ID = 'v10-stamp-template-version';

/**
 * Insert `template_version` into an artifact's YAML frontmatter. Returns true if written.
 *
 * Scope is deliberately narrow — only files that ALREADY carry frontmatter are touched.
 * Manufacturing a frontmatter block on a doc that has none would change how every
 * downstream reader parses that file, which is a migration of a different size than
 * "backfill a missing key".
 */
function stampTemplateVersion(filePath, version) {
  const raw = readFileSync(filePath, 'utf-8');
  const lines = raw.split('\n');
  if (lines[0].trim() !== '---') return false;

  let close = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === '---') { close = i; break; }
  }
  if (close === -1) return false; // unterminated frontmatter — not ours to repair

  const fm = lines.slice(1, close);
  if (fm.some(l => /^\s*template_version\s*:/.test(l))) return false; // already stamped; never overwrite

  // Sit directly under speck_version when present, matching how every template in
  // .speck/templates/ orders its frontmatter — so a stamped artifact and a fresh one
  // from the template diff cleanly.
  let insertAt = 1;
  for (let i = 0; i < fm.length; i++) {
    if (/^\s*speck_version\s*:/.test(fm[i])) { insertAt = i + 2; break; }
  }
  lines.splice(insertAt, 0, `template_version: "${version}"`);
  writeFileSync(filePath, lines.join('\n'));
  return true;
}

/** Every .md under specs/projects/, recursively. */
function findProjectMarkdown(targetDir) {
  const root = join(targetDir, 'specs', 'projects');
  const out = [];
  const walk = dir => {
    let names;
    try { names = readdirSync(dir); } catch { return; }
    for (const name of names) {
      const full = join(dir, name);
      let st;
      try { st = statSync(full); } catch { continue; }
      if (st.isDirectory()) walk(full);
      else if (name.endsWith('.md')) out.push(full);
    }
  };
  if (existsSync(root)) walk(root);
  return out.sort();
}

// The first real rider on the lane. `template_version` exists today ONLY in the
// frontmatter of .speck/templates/** — verified: no script writes it, and no artifact
// under specs/projects/ carries it unless it was copied byte-for-byte from a template.
// Artifacts an agent wrote from a template's *content* have no stamp at all, so nothing
// downstream can tell which template generation produced them. Backfill it once, so the
// v10 schema-drift gate has a field to compare against.
registerMigration({
  id: STAMP_TEMPLATE_VERSION_ID,
  description: 'Backfill template_version into existing project artifact frontmatter',
  appliesTo: (fromMajor, toMajor) => toMajor >= 10 && (fromMajor == null || fromMajor < 10),
  run: (targetDir, ctx = {}) => {
    const version = ctx.targetVersion || '10.0.0';
    let stamped = 0;
    for (const file of findProjectMarkdown(targetDir)) {
      if (stampTemplateVersion(file, version)) stamped += 1;
    }
    return stamped;
  },
});

/* --- built-in migration: lift prose-derived `serves` claims into frontmatter (issue #97) --- */

export const LIFT_SERVES_ID = 'v10-lift-serves-frontmatter';

// WHY THIS MUST RIDE THE UPGRADE, not wait for a human gesture.
// Before v10 the witness graph minted a story's `serves` edges from `re.findall` over its whole
// spec body, so NAMING a magic-moment id was CLAIMING it. v10 derives `serves` from the structured
// `serves:` frontmatter slot only. That flip is correct and it is breaking: every wired magic
// moment in every existing project would become PHANTOM_PROMISE.P1 and every wired story
// ORPHAN_STORY.P1 — and ORPHAN_STORY blocks /story-implement through check-story-prereqs.sh. So
// the data moves with the code, here, on upgrade day.
//
// WHAT IT DOES NOT DO: it does not lift lines that read as disclaimers ("None claimed.",
// "MM-1 and MM-2 are not claimed here"). Those were the bug — 10 of 15 edges false in one measured
// repo, 8 of them from disclaiming sentences. Writing them into a structured slot would migrate the
// bug instead of the data. They are printed for the author, who decides. The full pre-flight is
// `speck_graph.py migrate <PROJECT_DIR> --lift-serves` (dry-run, prints every claim + source line).
registerMigration({
  id: LIFT_SERVES_ID,
  description: 'Lift pre-v10 prose-derived MM/JOB delivery claims into story `serves:` frontmatter',
  appliesTo: (fromMajor, toMajor) => toMajor >= 10 && (fromMajor == null || fromMajor < 10),
  run: (targetDir) => {
    const script = join(targetDir, '.speck', 'scripts', 'graph', 'speck_graph.py');
    if (!existsSync(script)) {
      // NOT a silent success. `return 0` here recorded status 'applied' for a lift that moved
      // nothing — and pendingMigrations() filters on status === 'applied', so the ledger would
      // retire it FOREVER. Every story stays un-migrated → ORPHAN_STORY.P1 → /story-implement
      // blocked by check-story-prereqs.sh: exactly the failure this migration exists to prevent.
      // Throwing is this lane's documented failure contract (see the comment below): it records
      // 'failed', keeps the siblings running, and stays PENDING for the next run — by which time
      // the `.speck/` sync that ships this script has landed.
      throw new Error(
        '.speck/scripts/graph/speck_graph.py is missing — the serves-lift cannot run. ' +
          'Re-run `speck upgrade` to restore .speck/scripts/, then `speck migrate --run`.',
      );
    }
    // A workspace with ZERO projects is a different case, and it is a GENUINE no-op: there are
    // no story specs whose prose claims could need lifting, and any project created from here on
    // is authored against the v10 `serves:` frontmatter slot from the start. Nothing is left
    // undone for a later run to pick up, so recording 'applied' is the honest answer — this one
    // deliberately does NOT stay pending.
    let lifted = 0;
    for (const projectPath of findProjects(targetDir)) {
      // Throwing is the contract for failure: the lane records it, keeps going, and retries next
      // run. Swallowing it would record "applied" for a project whose claims never moved.
      const out = execSync(
        `python3 "${script}" migrate "${projectPath}" --lift-serves --write`,
        { cwd: targetDir, encoding: 'utf-8', stdio: ['ignore', 'pipe', 'pipe'] },
      );
      const m = out.match(/^APPLIED: (\d+) claim\(s\)/m);
      if (m) lifted += parseInt(m[1], 10);
    }
    return lifted;
  },
});

/**
 * `speck migrate --list` / `speck migrate --run` — the operator surface on the lane.
 *
 * --list answers "what is still pending for this project, and what already ran?" without
 * touching anything. --run executes the pending set.
 *
 * THE DEFAULT THAT MATTERS: `from` defaults to UNKNOWN (null), not to .speck/VERSION.
 * A hand-run `speck migrate` happens AFTER an upgrade has already advanced VERSION, so
 * defaulting `from` to that file would make from and to the same major, answer every
 * appliesTo with false, and print "PENDING (0)" for a project where nothing had run.
 * Unknown-origin is the honest reading, and every appliesTo already treats `fromMajor ==
 * null` as "applies" — the LEDGER, not the version range, is what makes a re-run safe.
 * `to` defaults to .speck/VERSION, which is authoritative for what this workspace is on.
 * --from/--to override both, for tests and for replaying a specific jump.
 *
 * IDENTITY IS CHECKED BEFORE ANY DEFAULT IS APPLIED. `from` being unknown is by design;
 * `to` being unknown is not, and the two used to combine into a silent disaster: with no
 * .speck/VERSION the target fell back to a hardcoded '10.0.0', which — against a null
 * `from` — answered every appliesTo() with true. Run in a directory that was never a Speck
 * project, the command therefore printed "✅ 2 applied, 0 skipped, 0 failed" and scaffolded
 * .speck/project.json into a stranger's folder. The literal was also a lie waiting for v11.
 * So: no .speck/ → refuse; no resolvable target → refuse. Neither is guessable.
 */
export function migrateCommand(targetDir, options = {}) {
  if (!existsSync(join(targetDir, '.speck'))) {
    throw new Error(
      `Not a Speck workspace: ${targetDir} has no .speck/ directory.\n` +
        '   The migration lane edits this project\'s artifacts and writes its ledger to\n' +
        '   .speck/project.json, so running it here would scaffold state for a project that\n' +
        '   does not exist. Run `speck init` here, or cd to your Speck workspace root.',
    );
  }

  const targetVersion = options.to || readWorkspaceVersion(targetDir);
  if (!targetVersion) {
    throw new Error(
      `Cannot determine the migration target: .speck/VERSION is missing or empty in ${targetDir}.\n` +
        '   There is no safe default — the target version is what decides which migrations apply,\n' +
        '   so assuming one would apply the wrong set. Run `speck upgrade` to (re)write\n' +
        '   .speck/VERSION, or pass `--to <version>` to replay a specific jump.',
    );
  }

  const currentVersion = options.from ?? null;
  const ledger = readAppliedLedger(targetDir);
  const pending = pendingMigrations(targetDir, currentVersion, targetVersion, options);

  if (options.run) {
    console.log(`🔁 Running ${pending.length} pending migration(s) for ${currentVersion || '(unknown)'} → ${targetVersion}...`);
    const result = runNamedMigrations(targetDir, currentVersion, targetVersion, { ...options, verbose: true });
    console.log(
      `\n✅ ${result.applied.length} applied, ${result.skipped.length} skipped, ${result.failed.length} failed.`,
    );
    return { mode: 'run', currentVersion, targetVersion, ...result };
  }

  // --list (also the default): print PENDING first, then APPLIED. Pending is the
  // actionable half, so it goes where the eye lands.
  console.log(`🥓 Speck migrations for ${currentVersion || '(unknown)'} → ${targetVersion}\n`);
  console.log(`PENDING (${pending.length})`);
  if (pending.length === 0) console.log('  (none)');
  for (const m of pending) console.log(`  • ${m.id} — ${m.description}`);
  console.log(`\nAPPLIED (${ledger.length})`);
  if (ledger.length === 0) console.log('  (none)');
  for (const e of ledger) {
    const when = e.at ? ` (${String(e.at).slice(0, 10)})` : '';
    const mark = e.status === 'failed' ? '✗ FAILED' : '✓';
    console.log(`  ${mark} ${e.id}${when}${e.error ? ` — ${e.error}` : ''}`);
  }
  return { mode: 'list', currentVersion, targetVersion, pending, applied: ledger };
}

/** Read `.speck/VERSION` — authoritative for "which version is this workspace on". */
function readWorkspaceVersion(targetDir) {
  const p = join(targetDir, '.speck', 'VERSION');
  if (!existsSync(p)) return null;
  try {
    return readFileSync(p, 'utf-8').trim() || null;
  } catch {
    return null;
  }
}

/**
 * Run any post-upgrade migrations needed. Idempotent and silent unless
 * options.verbose is set. Returns a summary object:
 *   { kind, targetMajor, actions: [...], projects: [...], v8Reprove, v9Graph, named }
 */
export function runPostUpgradeMigrations(targetDir, currentVersion, targetVersion, options = {}) {
  const { scaffoldV7, reproveV8, graphV9, migrateV10, targetMajor } = detectMigration(currentVersion, targetVersion);
  const summary = {
    kind: null,
    targetMajor,
    actions: [],
    projects: [],
    v8Reprove: null,
    v9Graph: null,
    named: null,
  };

  // A named migration can be pending even without a major crossing (a failed one being
  // retried), so the no-op guard asks the registry too — but only after the cheap flags,
  // so a within-major upgrade of a project with no ledger still costs one existsSync.
  const pending = pendingMigrations(targetDir, currentVersion, targetVersion, options);

  if (!scaffoldV7 && !reproveV8 && !graphV9 && !migrateV10 && pending.length === 0) {
    summary.targetMajor = null;
    return summary;
  }

  if (scaffoldV7) {
    if (options.verbose) {
      console.log(`\n🔁 Detected ${currentVersion} → ${targetVersion} crossing into v7. Running v6→v7 scaffolding...`);
    }
    const projects = findProjects(targetDir);
    if (projects.length === 0) {
      if (options.verbose) {
        console.log('   No projects under specs/projects/ — nothing to scaffold.');
      }
    } else {
      for (const proj of projects) {
        summary.projects.push(migrateProjectV7(targetDir, proj, options));
      }
    }
    summary.kind = reproveV8 ? 'v6-to-v8' : 'v6-to-v7';
    summary.actions.push('scaffoldV7');
  }

  if (reproveV8) {
    if (options.verbose) {
      console.log(`\n🔁 Detected crossing into Speck v8. Writing .speck/.v8-reprove-needed marker (semantic re-prove)...`);
    }
    summary.v8Reprove = writeV8ReproveMarker(targetDir, targetVersion);
    if (!summary.kind) summary.kind = 'v7-to-v8';
    summary.actions.push('reproveV8');
  }

  if (graphV9) {
    if (options.verbose) {
      console.log(`\n🔁 Detected crossing into Speck v9. Writing .speck/.v9-graph-needed marker (witness graph)...`);
    }
    summary.v9Graph = writeV9GraphMarker(targetDir, targetVersion);
    if (!summary.kind) summary.kind = 'v8-to-v9';
    else if (summary.kind === 'v6-to-v8') summary.kind = 'v6-to-v9';
    else if (summary.kind === 'v7-to-v8') summary.kind = 'v7-to-v9';
    summary.actions.push('graphV9');
  }

  // LAST, always: the named migrations edit artifacts, and the three steps above are what
  // produce (v7) and re-truth (v8/v9) the artifacts they edit. Running the lane earlier
  // would migrate files that the very same upgrade is about to scaffold or rewrite.
  if (migrateV10 || pending.length > 0) {
    if (options.verbose) {
      console.log(`\n🔁 Running ${pending.length} named artifact migration(s)...`);
    }
    summary.named = runNamedMigrations(targetDir, currentVersion, targetVersion, options);
    if (migrateV10) {
      summary.actions.push('migrateV10');
      summary.kind = summary.kind ? `${summary.kind.split('-to-')[0]}-to-v10` : 'v9-to-v10';
    }
  }

  return summary;
}

/**
 * Standalone helper to manually invoke v7 migration (e.g. for `speck migrate v7` CLI command).
 */
export function migrateToV7(targetDir, options = {}) {
  return runPostUpgradeMigrations(targetDir, '6.0.0', '7.0.0', options);
}
