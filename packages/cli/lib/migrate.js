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
import { join, dirname, basename } from 'path';
import { execSync, execFileSync } from 'child_process';

/**
 * Parse a version string like "v7.0.0", "7.0.0", or "v6.1.14" into an integer major.
 * Returns null for unparsable input.
 */
function majorOf(version) {
  if (!version) return null;
  const m = String(version).match(/v?(\d+)\./);
  return m ? parseInt(m[1], 10) : null;
}

/* ===========================================================================
 * VERSION ARITHMETIC (v10.1)
 * ===========================================================================
 *
 * `majorOf` above is deliberately untouched: detectMigration()'s four major flags are
 * frozen behaviour, and the legacy two-argument `appliesTo` shape is still handed exactly
 * the integers it was handed in v10.0.0. What follows is the NEW arithmetic, used only by
 * the version-keyed half of the lane.
 *
 * WHY THIS EXISTS AT ALL. The registry was built version-agnostic while its predicate
 * stayed major-only, so a migration registered in 10.1 could not fire for a 10.0 → 10.1
 * upgrade — the halves rode different clocks. That is what forced v9.6 and v10 to be
 * batched into a single major release.
 */

/**
 * Parse "v10.10.3" / "10.1" / "10" into { major, minor, patch }. Missing components are 0
 * (10.1 means 10.1.0). Returns null for anything with no leading numeric major — including
 * null/undefined, which is how "unknown origin" travels through this module.
 *
 * Pre-release and build metadata are intentionally NOT modelled. Speck ships plain X.Y.Z,
 * and a half-implemented precedence rule that silently mis-orders `10.1.0-rc1` would be
 * worse than not accepting one at all: everything after the first non-matching character
 * is ignored, so `10.1.0-rc1` reads as 10.1.0.
 */
export function parseVersion(version) {
  if (version === null || version === undefined) return null;
  const m = String(version).trim().match(/^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?/);
  if (!m) return null;
  return {
    major: parseInt(m[1], 10),
    minor: m[2] === undefined ? 0 : parseInt(m[2], 10),
    patch: m[3] === undefined ? 0 : parseInt(m[3], 10),
  };
}

/**
 * Compare two versions numerically, component by component: -1 / 0 / 1, or **null when
 * either side is unparsable** (an unknown version is not "smaller", it is not comparable —
 * returning 0 or -1 there would silently answer a question nobody can answer).
 *
 * THE TRAP THIS EXISTS FOR: `'10.10.0' < '10.9.0'` is TRUE as a string compare, because '1'
 * sorts before '9' at index 3. Lexicographic ordering is right for the first nine minors and
 * then quietly inverts, which is the kind of defect that does not surface for months —
 * by which time a 10.10 schema change has been applied before the 10.9 one it depends on.
 *
 * Callers must null-check: `compareVersions(a, b) < 0` reads false for null, which is the
 * safe direction for a gate but the WRONG direction for a sort comparator.
 */
export function compareVersions(a, b) {
  const pa = parseVersion(a);
  const pb = parseVersion(b);
  if (pa == null || pb == null) return null;
  for (const key of ['major', 'minor', 'patch']) {
    if (pa[key] !== pb[key]) return pa[key] < pb[key] ? -1 : 1;
  }
  return 0;
}

/**
 * The predicate a MINOR-introduced migration wants: "this upgrade reaches `introducedIn`,
 * and the project was not already at or past it".
 *
 *     registerMigration({ id: '...', version: '10.1.0', appliesTo: atOrAfter('10.1.0'), run })
 *
 * Both halves matter. Reaching it is what makes a 10.0 → 10.3 hop run the 10.1 migration.
 * Not-already-past-it is what stops a 10.2 → 10.3 upgrade from re-proposing work that shipped
 * a release ago — belt to the ledger's braces, since the ledger is the authority on "already
 * ran" and this is only the authority on "in scope for this crossing".
 *
 * An UNKNOWN origin applies (a hand-run `speck migrate` cannot know what the project came
 * from, and the ledger is the real guard). An unknown TARGET does not: a version that cannot
 * be read cannot be claimed to reach anything.
 */
export function atOrAfter(introducedIn) {
  if (parseVersion(introducedIn) == null) {
    throw new Error(`atOrAfter: "${introducedIn}" is not a parsable version (expected X.Y.Z)`);
  }
  // Three declared parameters on purpose — arity is one of the two signals that tells the
  // lane this is a version-keyed predicate rather than the pre-10.1 major-keyed shape.
  const fn = (fromVersion, toVersion, _ctx) => {
    const reaches = compareVersions(toVersion, introducedIn);
    if (reaches == null || reaches < 0) return false;
    const alreadyThere = compareVersions(fromVersion, introducedIn);
    return alreadyThere == null || alreadyThere < 0;
  };
  fn.speckVersionKeyed = true;
  fn.speckIntroducedIn = introducedIn;
  return fn;
}

/**
 * The predicate the four shipped v10 migrations use — "crossing INTO major N from anything
 * older". The expression is byte-for-byte the one they carried in v10.0.0, kept as its own
 * helper rather than folded into atOrAfter('N.0.0') so that the frozen decisions are
 * preserved by construction and not by an argument about equivalence.
 */
export function crossesMajor(major) {
  // ctx.fromMajor / ctx.toMajor are ALWAYS what the lane supplies, and they come from
  // `majorOf` — the v10.0.0 parser. Preferring them keeps every in-lane decision
  // bit-identical to what v10.0.0 decided, whatever the positional arguments now carry.
  // The fallback is only reached by a direct call (a test, a REPL), where a bare major
  // and a full version are both reasonable things to hand a major-keyed predicate.
  const majorFrom = v => {
    const parsed = parseVersion(v);
    return parsed == null ? null : parsed.major;
  };
  const fn = (fromVersion, toVersion, ctx) => {
    const c = ctx || {};
    const fromMajor = c.fromMajor !== undefined ? c.fromMajor : majorFrom(fromVersion);
    const toMajor = c.toMajor !== undefined ? c.toMajor : majorFrom(toVersion);
    return toMajor != null && toMajor >= major && (fromMajor == null || fromMajor < major);
  };
  fn.speckVersionKeyed = true;
  fn.speckIntroducedIn = `${major}.0.0`;
  return fn;
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
 *       version: '10.1.0',                     // the release that INTRODUCED it
 *       appliesTo: atOrAfter('10.1.0'),        // optional — derived from `version` if omitted
 *       run: (targetDir, ctx) => { ... },      // throw to fail; return value ignored
 *     });
 *
 * `version` (v10.1+) is the release that introduced the migration. It does three jobs:
 * it derives `appliesTo` when you do not write one, it is the RUN ORDER on a multi-hop
 * upgrade (10.0 → 10.3 replays 10.1, then 10.2, then 10.3), and it is what
 * `speck migrate --list` prints — because "which release brought this into existence" is
 * the fact an operator staring at a pending migration actually needs.
 *
 * CONTRACT for appliesTo(fromVersion, toVersion, ctx):
 *   - fromVersion / toVersion are the FULL version strings ('10.0.0'), not majors. This is
 *     the v10.1 change: a major-keyed predicate cannot express "introduced in 10.1", so a
 *     minor-release migration was structurally invisible to the upgrade that shipped it.
 *   - ctx is { currentVersion, targetVersion, fromMajor, toMajor } — the parsed majors are
 *     carried there, so a genuinely major-keyed rule still has them without re-parsing.
 *   - fromVersion is null when the origin is unknown (a hand-run `speck migrate`). Treat
 *     that as "applies": the LEDGER, not the version range, is what makes a re-run safe.
 *   - BACKWARD COMPATIBILITY — a predicate declared with FEWER THAN THREE parameters and
 *     not built by atOrAfter/crossesMajor is treated as the pre-10.1 major-keyed shape and
 *     is called with `(fromMajor, toMajor)` exactly as v10.0.0 called it. This is not
 *     cosmetic: handed the string '10.0.0', the old body `toMajor >= 10` evaluates NaN >= 10
 *     → false, and the migration silently never runs. A false negative with no error
 *     anywhere is the single worst outcome this lane can produce, so the old shape keeps
 *     its old arguments forever. Write new predicates with three declared parameters, or
 *     just pass `version` and let the lane derive one.
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
  const { id, description, version, appliesTo, run } = migration;
  if (typeof id !== 'string' || id.trim() === '') {
    throw new Error('registerMigration: migration needs a non-empty string id');
  }
  if (typeof run !== 'function') {
    throw new Error(`registerMigration: migration "${id}" needs a run() function`);
  }
  // An unparsable version is refused at registration rather than tolerated, because it is
  // BOTH the ordering key and (often) the gate: a version nobody can compare sorts
  // arbitrarily against its siblings and answers "does this crossing reach it?" with a
  // shrug. Five-second fix here; an out-of-order artifact rewrite in a user's repo later.
  if (version !== undefined && parseVersion(version) == null) {
    throw new Error(
      `registerMigration: migration "${id}" has an unparsable version "${version}" (expected X.Y.Z)`,
    );
  }
  if (typeof appliesTo !== 'function' && version === undefined) {
    throw new Error(
      `registerMigration: migration "${id}" needs an appliesTo(fromVersion, toVersion, ctx) ` +
        'function, a `version` to derive one from, or both',
    );
  }
  if (MIGRATION_REGISTRY.some(m => m.id === id)) {
    throw new Error(`registerMigration: "${id}" is already registered (ids are ledger keys and must be unique)`);
  }
  // The one trap left by supporting both predicate shapes. Nothing shipped hits this — the
  // four built-ins use crossesMajor(), and `version` alone derives a tagged atOrAfter() — so
  // it is silent in normal use and speaks only when someone hand-rolls a two-parameter rule.
  // A warning rather than a throw because the old shape is genuinely still supported; what is
  // NOT acceptable is finding out months later that a migration never fired.
  if (
    typeof appliesTo === 'function' &&
    appliesTo.speckVersionKeyed !== true &&
    appliesTo.length < 3
  ) {
    console.warn(
      `⚠️  registerMigration: "${id}" declares appliesTo with ${appliesTo.length} parameter(s), so it ` +
        'will be called with MAJORS (fromMajor, toMajor) — the pre-v10.1 shape.\n' +
        '   If you meant a version-keyed rule, use `atOrAfter("X.Y.Z")`, pass `version: "X.Y.Z"`, or ' +
        'declare three parameters (fromVersion, toVersion, ctx).\n' +
        '   A version-keyed body handed a major compares against undefined and never fires.',
    );
  }
  MIGRATION_REGISTRY.push({
    id,
    description: description || id,
    version: version === undefined ? null : version,
    appliesTo: typeof appliesTo === 'function' ? appliesTo : atOrAfter(version),
    run,
  });
  return MIGRATION_REGISTRY.length;
}

/** The registered migrations, in registration order. Copy — callers cannot mutate the lane. */
export function getRegisteredMigrations() {
  return MIGRATION_REGISTRY.slice();
}

/* --- how the lane calls a predicate, and what order it walks the registry in ---
 *
 * Both helpers below operate on RAW registry entries, not on what registerMigration()
 * normalised — because `options.registry` (tests, and any caller replaying a specific set)
 * bypasses registerMigration entirely. Doing the work here means the two paths cannot
 * diverge, which is precisely the class of bug this whole change is about.
 */

/** The version that introduced a migration, from the entry or from its predicate. */
export function migrationVersion(migration) {
  if (migration && typeof migration.version === 'string' && migration.version.trim() !== '') {
    return migration.version;
  }
  const from = migration && migration.appliesTo && migration.appliesTo.speckIntroducedIn;
  return typeof from === 'string' ? from : null;
}

/**
 * Ask one migration whether it applies to this crossing, honouring both predicate shapes.
 * See the CONTRACT block above for why the two-parameter shape keeps receiving majors.
 */
function migrationApplies(migration, fromVersion, toVersion, ctx) {
  let fn = migration.appliesTo;
  if (typeof fn !== 'function') {
    const v = migrationVersion(migration);
    // Neither a predicate nor a version: there is no rule at all. Treat it as applicable so
    // it surfaces in the run report instead of vanishing — the same policy the try/catch
    // below applies to a predicate that throws.
    if (v == null) return true;
    fn = atOrAfter(v);
  }
  const versionKeyed = fn.speckVersionKeyed === true || fn.length >= 3;
  return versionKeyed ? !!fn(fromVersion, toVersion, ctx) : !!fn(ctx.fromMajor, ctx.toMajor);
}

/**
 * Registry order for a run: by introducing version ascending, then by registration order.
 *
 * Multi-hop is why this is not cosmetic. A 10.0 → 10.3 upgrade replays three releases'
 * worth of migrations in one pass, and each was written against the artifact shape the
 * previous one left behind — so 10.1 must run before 10.2, whatever order the modules
 * happened to import in. Comparison is numeric (see compareVersions): a string sort puts
 * 10.10.0 BEFORE 10.9.0.
 *
 * UNVERSIONED migrations sort first, stable among themselves. They predate the versioned
 * lane (or are a caller's ad-hoc registry), so registration order is the only ordering
 * information they carry, and running them ahead of the versioned ones preserves exactly
 * the sequence v10.0.0 used.
 */
export function sortMigrations(list) {
  return list
    .map((m, i) => ({ m, i, v: migrationVersion(m) }))
    .sort((a, b) => {
      if (a.v && b.v) {
        const c = compareVersions(a.v, b.v);
        if (c != null && c !== 0) return c;
      } else if (a.v && !b.v) {
        return 1;
      } else if (!a.v && b.v) {
        return -1;
      }
      return a.i - b.i; // stable: registration order breaks every tie
    })
    .map(x => x.m);
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
function recordMigration(targetDir, id, status, error, version) {
  const pj = readProjectJson(targetDir) || {};
  const entries = readAppliedLedger(targetDir).filter(e => e.id !== id);
  const entry = { id, status, at: new Date().toISOString() };
  // Additive, and additive on purpose: an older ledger with no `version` still reads and
  // still suppresses a re-run. Recording it means `--list` can name the introducing release
  // for an APPLIED migration whose registration has since been retired from the registry.
  if (version) entry.version = version;
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
  const ctx = migrationContext(currentVersion, targetVersion);
  const done = new Set(readAppliedLedger(targetDir).filter(e => e.status === 'applied').map(e => e.id));
  return sortMigrations(resolveRegistry(options)).filter(m => {
    if (done.has(m.id)) return false;
    try {
      return migrationApplies(m, currentVersion, targetVersion, ctx);
    } catch {
      // A migration whose own gate throws is not silently skipped — treat it as
      // applicable so the failure surfaces in the run report instead of vanishing.
      return true;
    }
  });
}

/**
 * The ctx every predicate and every run() receives. The majors come from `majorOf` — the
 * v10.0.0 parser, unchanged — so a major-keyed predicate gets exactly the integers it
 * always got, whichever path it arrives by.
 */
function migrationContext(currentVersion, targetVersion) {
  return {
    currentVersion,
    targetVersion,
    fromMajor: majorOf(currentVersion),
    toMajor: majorOf(targetVersion),
  };
}

/**
 * Run every pending named migration for this crossing.
 * Returns { applied: [id], skipped: [id], failed: [{ id, error }] }.
 */
export function runNamedMigrations(targetDir, currentVersion, targetVersion, options = {}) {
  const ctx = migrationContext(currentVersion, targetVersion);
  const result = { applied: [], skipped: [], failed: [] };
  const done = new Set(readAppliedLedger(targetDir).filter(e => e.status === 'applied').map(e => e.id));

  // Version order, not registration order: a multi-hop upgrade replays several releases in
  // one pass, and each migration was written against the shape its predecessor left behind.
  for (const m of sortMigrations(resolveRegistry(options))) {
    let applicable;
    try {
      applicable = migrationApplies(m, currentVersion, targetVersion, ctx);
    } catch {
      applicable = true;
    }
    if (!applicable) continue;

    if (done.has(m.id)) {
      result.skipped.push(m.id);
      if (options.verbose) console.log(`   ⏭  ${m.id} — already applied`);
      continue;
    }

    const version = migrationVersion(m);
    try {
      m.run(targetDir, ctx);
      recordMigration(targetDir, m.id, 'applied', null, version);
      result.applied.push(m.id);
      if (options.verbose) console.log(`   ✅ ${m.id} — ${m.description}`);
    } catch (err) {
      const message = err?.message || String(err);
      recordMigration(targetDir, m.id, 'failed', message, version);
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
  version: '10.0.0',
  appliesTo: crossesMajor(10),
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
  version: '10.0.0',
  appliesTo: crossesMajor(10),
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

/* --- built-in migration: insert §6a's Scope + Subject columns (issue #98) ------------------- */

export const GATE_REGISTRY_SCOPE_SUBJECT_ID = 'v10-gate-registry-scope-subject-columns';

// The §6a header, as v10 defines it. seed-gate-registry.sh's GATE_REGISTRY_COLUMNS is the
// authority; this migration only has to know WHERE the two new labels go relative to the old
// six, which is what makes the insert positional rather than a re-seed.
const GATE_REGISTRY_NEW_COLUMNS = ['Scope', 'Subject'];
const GATE_REGISTRY_INSERT_AFTER = 'domain'; // lowercased header label

/**
 * Insert `Scope` and `Subject` into one §6a table, in place, preserving every existing cell.
 *
 * WHY NOT JUST RE-SEED. seed-gate-registry.sh can rewrite the table from the recipe, and that is
 * the right tool when the registry is still scaffold. It is the wrong tool here: by the time a
 * project upgrades, §6a rows have been hand-amended — waivers cited against real DECs, canary keys
 * chosen, stages corrected against what CI actually does. Re-seeding would silently discard all of
 * it and replace it with the recipe's defaults, and a lost `waived DEC-####` reads as an unwaived
 * dark gate on the next run. So this walks the existing table and widens it.
 *
 * Idempotent by inspection, not by ledger: if the header already carries both labels the file is
 * left byte-identical. The ledger stops a second RUN; this stops a second run from corrupting
 * anything if the ledger is ever lost (a `.speck/` re-sync, a hand-edited project.json).
 *
 * Returns true when the file was rewritten.
 */
export function insertGateRegistryColumns(file) {
  let text;
  try {
    text = readFileSync(file, 'utf-8');
  } catch {
    return false;
  }
  const lines = text.split('\n');

  // Find the §6a table: the first `| Gate ID | …` header row under a `### 6a.` heading. Anchoring
  // on the heading matters — an evidence contract can carry other pipe tables (§6 evidence lists,
  // §7 banned-language tables), and widening one of those would corrupt a document that was fine.
  let inSection = false;
  let headerIdx = -1;
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (/^### 6a\./.test(l)) { inSection = true; continue; }
    if (inSection && /^#{2,3} /.test(l)) break;
    if (inSection && /^\|\s*Gate ID\s*\|/i.test(l)) { headerIdx = i; break; }
  }
  if (headerIdx === -1) return false;

  const cellsOf = (line) => line.replace(/^\|/, '').replace(/\|\s*$/, '').split('|');
  const header = cellsOf(lines[headerIdx]).map(c => c.trim());
  const lower = header.map(c => c.toLowerCase());
  // Already migrated (or hand-authored against v10) → leave it exactly as it is.
  if (GATE_REGISTRY_NEW_COLUMNS.every(c => lower.some(h => h.startsWith(c.toLowerCase())))) return false;

  const anchor = lower.findIndex(h => h.startsWith(GATE_REGISTRY_INSERT_AFTER));
  // No Domain column means this is not a table whose shape we can reason about positionally.
  // Refusing is the honest answer: a wrong insert point silently re-maps every later cell, which
  // is the exact class of bug the header-keyed conversion exists to prevent.
  if (anchor === -1) return false;
  const at = anchor + 1;

  const widen = (line, fill) => {
    const cells = cellsOf(line);
    if (cells.length < header.length) return line;  // a ragged row: leave it, do not guess
    cells.splice(at, 0, ...fill);
    return '|' + cells.join('|') + '|';
  };

  const out = lines.slice();
  out[headerIdx] = widen(lines[headerIdx], GATE_REGISTRY_NEW_COLUMNS.map(c => ` ${c} `));
  for (let i = headerIdx + 1; i < out.length; i++) {
    if (!/^\|/.test(out[i])) break;                       // end of the table
    if (/^\|[-: |]+\|\s*$/.test(out[i])) {                // the markdown separator row
      out[i] = widen(out[i], GATE_REGISTRY_NEW_COLUMNS.map(c => '-'.repeat(Math.max(3, c.length))));
      continue;
    }
    // A data row. `—` is §6a's established "not declared" value (Canary/Waiver already use it) and
    // reads as undeclared to every consumer: validate-gate-liveness skips it, the probe treats a
    // missing runtime report as GATE_SCOPE_UNREPORTED.P3. Inventing a scope here would be worse
    // than admitting there isn't one — a wrong Scope cell is a false green with a paper trail.
    out[i] = widen(out[i], GATE_REGISTRY_NEW_COLUMNS.map(() => ' — '));
  }

  const next = out.join('\n');
  if (next === text) return false;
  writeFileSync(file, next);
  return true;
}

// WHY THIS RIDES THE UPGRADE. #98 adds two REQUIRED columns to §6a. Without the insert, a v10
// consumer reading a pre-v10 six-column table finds no Scope cell — which is handled (it degrades
// to "undeclared", not to a false finding) — but the project never gets prompted to declare one,
// and the whole point of the schema change is that the declaration is what makes vacuity visible.
// Widening the table on upgrade day turns "nobody added the column" into a visible `—` a human can
// fill, in every project, without anyone remembering to run a script.
registerMigration({
  id: GATE_REGISTRY_SCOPE_SUBJECT_ID,
  description: "Insert the §6a Scope + Subject columns into existing evidence contracts (#98)",
  version: '10.0.0',
  appliesTo: crossesMajor(10),
  run: (targetDir) => {
    let widened = 0;
    for (const file of findProjectMarkdown(targetDir)) {
      if (!/evidence-contract\.md$/.test(file)) continue;
      if (insertGateRegistryColumns(file)) widened += 1;
    }
    return widened;
  },
});

/* --- built-in migration: pin banned_language.scope so the v10 default flip is a DIFF --- */

export const BANNED_LANGUAGE_SCOPE_ID = 'v10-banned-language-scope-any-depth';

// WHY A BEHAVIOUR FLIP NEEDS A MIGRATION AT ALL.
// v10 changes `banned_language.scope` from "legacy-root" to "any-depth": product surfaces are
// recognised by path SEGMENT, so a monorepo's frontend/src/** is finally reached. Measured
// blindness under the old default was 0 of 1194 files in one repo and 0 of 590 in another, on a
// gate wired into every commit — so the flip is the point of the major, not a side effect. It is
// safe only because --strings-only removed the false-conviction class that blocked it in v9.6
// (`import { createClient } from "./api"` reported ❌ "API" — 4 hit(s)).
//
// But a DEFAULT is invisible. Without this, a team upgrades and their pre-commit gate silently
// starts inspecting a thousand files it never touched before, with nothing in the diff to explain
// why. So the resolution is written down, per project, on upgrade day: the change shows up in
// `.speck/project.json`, `speck migrate --list` names it, and a team that needs the old behaviour
// edits one word to "legacy-root" instead of hunting for a flag.
//
// It is deliberately NON-DESTRUCTIVE: a project that already declares a scope — including one that
// deliberately declares "legacy-root" — is left exactly as it is. The migration records the NEW
// default for projects that never had an opinion, and never overrides one that did.
export function pinBannedLanguageScope(targetDir, scope = 'any-depth') {
  const p = projectJsonPath(targetDir);
  if (!existsSync(p)) return false;
  const pj = readProjectJson(targetDir);
  if (!pj) return false;
  const bl = pj.banned_language && typeof pj.banned_language === 'object' && !Array.isArray(pj.banned_language)
    ? pj.banned_language
    : {};
  // An existing declaration is an OPINION. Overwriting it would be the migration deciding
  // something the project already decided — including silently un-doing a deliberate opt-out.
  if (typeof bl.scope === 'string' && bl.scope.trim() !== '') return false;
  const next = { ...pj, banned_language: { ...bl, scope } };
  writeFileSync(p, JSON.stringify(next, null, 2) + '\n');
  return true;
}

registerMigration({
  id: BANNED_LANGUAGE_SCOPE_ID,
  description: 'Record the v10 banned_language.scope default (any-depth) in .speck/project.json',
  version: '10.0.0',
  appliesTo: crossesMajor(10),
  run: (targetDir) => (pinBannedLanguageScope(targetDir) ? 1 : 0),
});

/* ===========================================================================
 * THE v10.1 RIDERS — the first two migrations to use the MINOR lane
 * ===========================================================================
 *
 * Both of the artifact changes below shipped in v10.1 with NO registration, and the four
 * migrations above cannot cover them: every one of them gates on `crossesMajor(10)`, which is
 * FALSE for a 10.0 → 10.1 upgrade. `speck migrate --list --from 10.0.0 --to 10.1.0` therefore
 * printed `PENDING (0)` on a release that had already changed two artifact contracts.
 *
 * That is precisely the hole the version-keyed half of this lane was built to close in this
 * same wave. They are registered here with `version: '10.1.0'` + `atOrAfter('10.1.0')`, which
 * fires on the crossing that shipped them, on any later hop that steps over 10.1 (10.0 → 10.4),
 * and never again once a project is past it.
 */

/* --- built-in migration (10.1): rebuild every committed witness graph -------- */

export const REBUILD_WITNESS_GRAPH_ID = 'v10-1-rebuild-witness-graph';

// WHY THIS MUST RIDE THE UPGRADE.
// v10.1's extractor puts `entry_point` and `wiring_witness` on EVERY `prm` and `story` node, and
// `_graph_signature()` hashes the whole node list — so a witness.json committed under v10.0.0 can
// no longer equal a v10.1 fresh compile, whatever the project did or did not change. Measured on a
// clean fixture: built + checked under v10.0.0 → exit 0, GRAPH_CAP = INTEGRATION-GREEN; the same
// tree read by v10.1 scripts → GRAPH_STALE.P2, GRAPH_CAP = STALE. That is 100% of consumers going
// green→red on code they did not touch, with /story-implement printing the STALE banner on every
// story in every project. The graph is DERIVED, so the fix is mechanical and belongs on upgrade day.
//
// SCOPE — only projects that already committed a witness. A project with no witness.json reads
// `unbuilt`, which explicitly does NOT cap, and minting its first graph here would be the wrong
// gesture: the first build belongs to /speck-graph-up, behind identity hardening, because an
// unhardened project's fresh graph can carry DANGLING_REF.P1 caps that did not exist a minute ago.
// Fixing staleness must not manufacture a different green→red.
registerMigration({
  id: REBUILD_WITNESS_GRAPH_ID,
  description:
    'Rebuild each committed witness graph for the v10.1 node schema (entry_point + wiring_witness)',
  version: '10.1.0',
  appliesTo: atOrAfter('10.1.0'),
  run: (targetDir) => {
    const script = join(targetDir, '.speck', 'scripts', 'graph', 'speck_graph.py');
    if (!existsSync(script)) {
      // The same failure contract the serves-lift documents, for the same reason: `return 0` here
      // records status 'applied', pendingMigrations() filters applied ids out, and the rebuild is
      // RETIRED FOREVER — leaving every consumer permanently STALE with nothing left in the ledger
      // to say why. Throwing records 'failed', lets the siblings finish, and stays pending until
      // the `.speck/` sync that ships this script has landed.
      throw new Error(
        '.speck/scripts/graph/speck_graph.py is missing — the v10.1 witness graphs cannot be ' +
          'rebuilt, and every committed graph stays STALE. Re-run `speck upgrade` to restore ' +
          '.speck/scripts/, then `speck migrate --run`.',
      );
    }
    let rebuilt = 0;
    for (const projectPath of findProjects(targetDir)) {
      if (!existsSync(join(projectPath, 'graph', 'witness.json'))) continue;
      // Throwing is the contract: a project whose rebuild fails must not be recorded as done.
      // `build` re-renders road-to-completion.md in the same call, so the two derived artifacts
      // cannot come out of this disagreeing with each other.
      //
      // execFileSync, not execSync: `projectPath` is a directory name from the user's specs tree,
      // and interpolating one into a shell string makes a folder called `$(…)` executable.
      execFileSync('python3', [script, 'build', projectPath], {
        cwd: targetDir,
        encoding: 'utf-8',
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      rebuilt += 1;
    }
    return rebuilt;
  },
});

/* --- built-in migration (10.1): stamp typed citations ----------------------- */

export const STAMP_CITATION_TYPES_ID = 'v10-1-stamp-citation-types';

/**
 * Does `after` differ from `before` by anything other than content GROWING inside a table cell?
 * Returns null when the change is admissible, or a human-readable description of the first
 * violation.
 *
 * WHY A STRUCTURAL INVARIANT AND NOT A DIFF OF THE STAMPER'S OUTPUT MESSAGE. The property that
 * matters is a property of the FILE, so it is checked on the file: same number of lines, same
 * number of cells per line, and — the one that actually catches this defect — byte-identical
 * leading and trailing whitespace on every cell. Splicing `test:` into a citation grows the cell's
 * CONTENT and leaves its padding untouched. Rebuilding the row out of trimmed cells collapses that
 * padding, which is what a measured `--stamp-types --write` did across 24 files: an authored table
 * came back as `| a | b | c |` with every column alignment gone. A migration is not entitled to
 * reformat prose it was only asked to annotate.
 */
export function findTableReflow(before, after) {
  if (before === after) return null;
  const b = before.split('\n');
  const a = after.split('\n');
  if (b.length !== a.length) {
    return `line count changed (${b.length} → ${a.length}) — a stamp adds no lines and drops none`;
  }
  const lead = s => s.match(/^[ \t]*/)[0];
  const trail = s => s.match(/[ \t]*$/)[0];
  for (let i = 0; i < b.length; i++) {
    if (b[i] === a[i]) continue;
    const bc = b[i].split('|');
    const ac = a[i].split('|');
    if (bc.length !== ac.length) {
      return `line ${i + 1}: cell count changed (${bc.length} → ${ac.length}) — the row was rebuilt, not annotated`;
    }
    for (let j = 0; j < bc.length; j++) {
      if (lead(bc[j]) !== lead(ac[j]) || trail(bc[j]) !== trail(ac[j])) {
        return (
          `line ${i + 1}, cell ${j + 1}: authored padding was collapsed ` +
          `(${JSON.stringify(bc[j])} → ${JSON.stringify(ac[j])})`
        );
      }
    }
  }
  return null;
}

// WHY THIS MUST RIDE THE UPGRADE.
// v10.1 adds the typed-citation vocabulary and the §2b admissibility table. Every artifact that
// exists today is legacy-untyped by construction, so every citation site raises CITATION_UNTYPED.P3
// until someone stamps what can be derived. Without a registration the mechanism attaches to
// nothing at all — which is exactly what shipped: `grep` found four registrations, every one of
// them `version: '10.0.0'`.
//
// WHY IT VERIFIES ITS OWN WRITES. An earlier `--stamp-types --write` re-emitted any row it touched
// out of TRIMMED cells, so it collapsed authored column padding — measured across 24 files, an
// authored table coming back as `| a | b | c |` with every alignment gone. The stamp mode now
// splices the type into the one cell and leaves the rest of the line byte-identical, so on the
// current tree this guard never fires. It stays anyway, because the guarantee it makes is one this
// migration owes regardless of who edits the stamper next: a migration asked to ANNOTATE prose is
// not entitled to REFORMAT it, and the artifacts it walks are hand-maintained.
//
// So the stamp runs ONE FILE AT A TIME, and any write that is not a pure in-cell annotation is
// RESTORED byte-for-byte and the migration throws. The effective mode cannot reflow a table: the
// worst case is a file written and instantly put back, followed by a `failed` ledger entry.
//
// Failing is deliberately NOT the same as "skip it and record applied". A silent success would
// retire the stamp from the ledger permanently — the very defect being closed here, one release
// later and harder to see. Recording `failed` keeps it pending, so it applies itself on the first
// run after the stamper is well-behaved again, with no gesture from anyone.
registerMigration({
  id: STAMP_CITATION_TYPES_ID,
  description: 'Stamp derivable citation types into existing project artifacts (§11a typed citations)',
  version: '10.1.0',
  appliesTo: atOrAfter('10.1.0'),
  run: (targetDir) => {
    const script = join(
      targetDir, '.speck', 'scripts', 'validation', 'validators', 'validate-evidence-citations.sh',
    );
    if (!existsSync(script)) {
      // Same reasoning as the rebuild above: a missing script is not a completed migration.
      throw new Error(
        '.speck/scripts/validation/validators/validate-evidence-citations.sh is missing — ' +
          'citations cannot be typed. Re-run `speck upgrade` to restore .speck/scripts/, then ' +
          '`speck migrate --run`.',
      );
    }
    let stamped = 0;
    for (const file of findProjectMarkdown(targetDir)) {
      const before = readFileSync(file, 'utf-8');
      // execFileSync for the same reason as the rebuild above: `file` is an artifact path.
      execFileSync('bash', [script, '--stamp-types', '--write', file], {
        cwd: targetDir,
        encoding: 'utf-8',
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      const after = readFileSync(file, 'utf-8');
      if (after === before) continue;
      const reflow = findTableReflow(before, after);
      if (reflow) {
        writeFileSync(file, before);
        throw new Error(
          `--stamp-types --write did not annotate ${file}, it REWROTE it: ${reflow}. ` +
            'The file has been restored byte-for-byte and this migration stays PENDING — it will ' +
            'apply itself on the first run after the stamp mode splices the type into the cell ' +
            'instead of rebuilding the row from trimmed cells.',
        );
      }
      stamped += 1;
    }
    return stamped;
  },
});

/* ===========================================================================
 * THE v10.3 RIDER — grandfathering the project-analysis gate
 * ===========================================================================
 */

export const ANALYSIS_GATE_GRANDFATHER_ID = 'v10-3-analysis-gate-grandfather';

/** The marker filename, per project. Exported because the gate script and its tests name it too. */
export const ANALYSIS_GATE_GRANDFATHER_MARKER = '.analysis-gate-grandfathered';

/**
 * The marker's contents: what exempted this project, why, and the exact gesture that ends it.
 *
 * A bare touch-file would have been enough for the gate to read. It is not enough for the human who
 * finds it six months from now — "why is this file here and what do I do about it?" is the question
 * an undocumented marker leaves permanently open, and an exemption nobody can date or clear is how a
 * temporary carve-out becomes the permanent state.
 */
function grandfatherMarkerBody(projectId, version) {
  return [
    '# Speck analysis-gate grandfather marker',
    `speck_version: ${version}`,
    'gate: check-epic-prereqs.sh → validate-project-analysis.sh --gate',
    'reason: >-',
    '  This project ran /project-plan before the v10.3 project-analysis gate existed, so it could',
    '  not have satisfied a gate that did not exist. While this marker is present the gate prints a',
    '  repeated NOTICE for this project instead of blocking. Projects planned after v10.3 have no',
    '  marker and DO block — the gate is real forward and advisory backward, by decision.',
    'clears_with: |',
    `  /project-analyze specs/projects/${projectId}`,
    `  rm specs/projects/${projectId}/${ANALYSIS_GATE_GRANDFATHER_MARKER}`,
    '',
  ].join('\n');
}

// WHY THIS RIDES THE UPGRADE, and why the marker is PER-PROJECT.
// v10.3 makes /project-analyze a precondition for epic work (#106). Every project already on disk
// planned its corpus before that gate existed, so on upgrade day every one of them would go from
// green to blocked on work nobody in the project touched — and a gate that is red on arrival across
// an entire estate gets bypassed rather than satisfied. The marker is what makes the asymmetry a
// DISCLOSED design decision instead of a hidden hole: advisory backward, real forward.
//
// Per PROJECT, not in .speck/project.json, because .speck/project.json is workspace-scoped while the
// gap is per-project. A workspace-level flag would exempt a project created tomorrow, in a workspace
// that happened to upgrade today — which is precisely the "real forward" half, lost.
//
// SCOPE — only projects that show evidence /project-plan actually ran (PRD.md AND epics.md) and that
// have no analysis report yet. A project with neither artifact has nothing to grandfather; a project
// that already has a report needs no exemption, and writing one would install a live false-exemption
// that re-arms the moment the report is deleted.
registerMigration({
  id: ANALYSIS_GATE_GRANDFATHER_ID,
  description:
    'Mark pre-v10.3 planned projects as grandfathered against the /project-analyze gate (#106)',
  version: '10.3.0',
  appliesTo: atOrAfter('10.3.0'),
  run: (targetDir, ctx = {}) => {
    const version = ctx.targetVersion || '10.3.0';
    let marked = 0;
    for (const projectPath of findProjects(targetDir)) {
      if (!existsSync(join(projectPath, 'PRD.md'))) continue;
      if (!existsSync(join(projectPath, 'epics.md'))) continue;
      if (existsSync(join(projectPath, 'project-analysis-report.md'))) continue;
      const marker = join(projectPath, ANALYSIS_GATE_GRANDFATHER_MARKER);
      // Check-then-write, so a mid-run crash cannot produce a second, differently-versioned marker
      // on the retry. The ledger stops a second RUN; this stops a partial one from rewriting the
      // exemption date of a project that was already marked.
      //
      // isFile(), not a bare existsSync: check-epic-prereqs.sh honours the marker behind `[[ -f ]]`,
      // so a DIRECTORY at that path is not a marker to the gate. Bare existsSync would call it one,
      // skip the write, and leave the project silently unexempted — the two halves of #106
      // disagreeing about what a marker is. Falling through instead makes writeFileSync raise
      // EISDIR, which is loud, recorded 'failed', and retried.
      if (existsSync(marker) && statSync(marker).isFile()) continue;
      // Deliberately UNGUARDED. A try/catch that returned a count here would record the migration
      // 'applied' for projects whose marker never landed, pendingMigrations() would filter it out
      // forever, and those projects would be BLOCKED on upgrade day with nothing left in the ledger
      // to explain why. Throwing is this lane's failure contract: 'failed', siblings keep running,
      // retried next time — and every marker already written is skipped by the check above.
      writeFileSync(marker, grandfatherMarkerBody(basename(projectPath), version));
      marked += 1;
    }
    // A workspace with zero qualifying projects is a GENUINE no-op, not deferred work: there is no
    // pre-v10.3 corpus to exempt, and anything planned from here on is planned under the gate. So
    // this one honestly records 'applied' rather than staying pending.
    return marked;
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
  // Each line names the release that INTRODUCED the migration. Once the lane is
  // minor-capable that is the actionable fact: "pending" no longer implies "from the last
  // major", and an operator deciding whether to run a hop needs to know whether the work in
  // front of them arrived in 10.1 or in 10.7. Unversioned entries say so rather than
  // borrowing a number — they are also the ones that cannot be ordered in a multi-hop run.
  const introducedBy = v => (v ? `v${String(v).replace(/^v/, '')}` : 'unversioned');
  console.log(`PENDING (${pending.length})`);
  if (pending.length === 0) console.log('  (none)');
  for (const m of pending) {
    console.log(`  • [${introducedBy(migrationVersion(m))}] ${m.id} — ${m.description}`);
  }
  console.log(`\nAPPLIED (${ledger.length})`);
  if (ledger.length === 0) console.log('  (none)');
  for (const e of ledger) {
    const when = e.at ? ` (${String(e.at).slice(0, 10)})` : '';
    const mark = e.status === 'failed' ? '✗ FAILED' : '✓';
    console.log(
      `  ${mark} [${introducedBy(e.version)}] ${e.id}${when}${e.error ? ` — ${e.error}` : ''}`,
    );
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
  // Defense-in-depth (not the primary guard): the only shipped caller is upgrade.js, which
  // invokes this AFTER saveVersion() has already written .speck/VERSION, so targetDir is always
  // a real workspace on that path. But recordMigration() below does
  // `mkdirSync(dirname(p), { recursive: true })` on whatever targetDir it is handed — so any
  // future or direct caller passing a non-workspace dir would silently scaffold a `.speck/`
  // there. Same identity check migrateCommand() applies at its own entry point (line ~569).
  if (!existsSync(join(targetDir, '.speck'))) {
    throw new Error(
      `Not a Speck workspace: ${targetDir} has no .speck/ directory.\n` +
        '   runPostUpgradeMigrations() writes migration state to .speck/project.json, so running\n' +
        '   it here would scaffold state for a project that does not exist.',
    );
  }

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
    } else {
      // The lane ran without a major crossing — a minor-introduced migration, or a
      // previously-failed one being retried. v10.0.0 had no way to report this because it
      // had no way to reach it: `actions` stayed empty while artifacts were being rewritten,
      // so a caller reading the summary saw a no-op upgrade that had in fact edited files.
      summary.actions.push('namedMigrations');
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
