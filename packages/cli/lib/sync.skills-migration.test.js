/**
 * Regression for the .agents/skills data-loss finding (PR #127, v11-subtraction):
 * `smartSync` newly symlinks `.agents/skills -> ../.cursor/skills` (Codex discovery), routing
 * it through `symlinkCursorDir`, which used to `rmSync` whatever sat at the destination
 * unconditionally. That silently destroyed a pre-existing REAL `.agents/skills` directory
 * (the AGENTS.md-ecosystem convention for a project's own skills) with no migration and no
 * entry in `results.removed`. The same unconditional-removal path also used `existsSync`,
 * which follows symlinks and reports false for a DANGLING one — so a broken skills symlink
 * survived the removal check and made the subsequent `symlinkSync` throw EEXIST.
 *
 * smartSync must:
 *   - migrate a real directory's content into `.cursor/skills` (shipped names win) before
 *     replacing it with the symlink, never just delete it,
 *   - leave an untouched sibling real directory (e.g. `.agents/rules`) alone,
 *   - refuse (report an error) rather than destroy a plain FILE sitting at the symlink path,
 *   - repair a dangling symlink at `.claude/skills` and `.agents/skills` instead of throwing
 *     EEXIST.
 *
 * Round 2 (adversarial review of the fix above found it re-introduced data loss in four
 * shapes, all sharing one root cause: migrating straight into the shared `.cursor/skills`
 * treats that directory as a safe landing spot, but step 6 of smartSync (REMOVE_FILES) prunes
 * ~40 retired Speck skill names from exactly that directory a few steps later, and a
 * same-named collision from a second runtime dir or from Speck's own shipped skills has no
 * "these differ" check. The fix here classifies every top-level entry as safe or unsafe
 * BEFORE touching anything, and refuses (reports an error, leaves the real directory in
 * place, migrates nothing) the instant any entry is unsafe:
 *   - unsafe: name matches a RETIRED Speck skill (would be deleted by REMOVE_FILES next),
 *   - unsafe: name matches something already shipped in .cursor/skills with DIFFERENT
 *     content (whether from this sync's own template copy, or from an earlier runtime dir's
 *     migration in this same run),
 *   - safe (skip, not an error): name matches something shipped with IDENTICAL content,
 *   - safe (migrate): anything else.
 * Migration itself also switched from `statSync` (follows symlinks, throws ENOENT on a
 * dangling one) to `lstatSync` throughout, so a broken symlink anywhere in the tree being
 * migrated is copied as a symlink instead of aborting the migration partway through.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  mkdtempSync,
  mkdirSync,
  writeFileSync,
  symlinkSync,
  existsSync,
  lstatSync,
  readFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { smartSync } from './sync.js';

function freshDirs(prefix) {
  const source = mkdtempSync(join(tmpdir(), `speck-skmig-src-${prefix}-`));
  const target = mkdtempSync(join(tmpdir(), `speck-skmig-tgt-${prefix}-`));
  mkdirSync(join(source, '.cursor/skills/speck'), { recursive: true });
  writeFileSync(join(source, '.cursor/skills/speck/SKILL.md'), 'shipped-speck-skill');
  return { source, target };
}

test('a real pre-existing .agents/skills directory is migrated, not deleted', () => {
  const { source, target } = freshDirs('real-dir');
  mkdirSync(join(target, '.agents/skills/my-company-skill'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/my-company-skill/SKILL.md'), 'MY OWN SKILL CONTENT');

  const results = smartSync(source, target);

  const migratedPath = join(target, '.cursor/skills/my-company-skill/SKILL.md');
  assert.ok(existsSync(migratedPath), 'user skill was migrated into .cursor/skills');
  assert.equal(
    readFileSync(migratedPath, 'utf-8'),
    'MY OWN SKILL CONTENT',
    'migrated file CONTENT matches the original (not merely a same-named survivor)',
  );

  assert.ok(lstatSync(join(target, '.agents/skills')).isSymbolicLink(), '.agents/skills is now a symlink');
  assert.equal(
    readFileSync(join(target, '.agents/skills/my-company-skill/SKILL.md'), 'utf-8'),
    'MY OWN SKILL CONTENT',
    'the symlink resolves to the migrated content',
  );

  assert.ok(
    results.errors.every(e => e.file !== '.agents/skills'),
    'no error was recorded for the migration',
  );
});

test('a real pre-existing .claude/skills directory is migrated, not deleted', () => {
  const { source, target } = freshDirs('real-dir-claude');
  mkdirSync(join(target, '.claude/skills/team-skill'), { recursive: true });
  writeFileSync(join(target, '.claude/skills/team-skill/SKILL.md'), 'TEAM SKILL CONTENT');

  smartSync(source, target);

  const migratedPath = join(target, '.cursor/skills/team-skill/SKILL.md');
  assert.equal(readFileSync(migratedPath, 'utf-8'), 'TEAM SKILL CONTENT');
  assert.ok(lstatSync(join(target, '.claude/skills')).isSymbolicLink());
});

test('a shipped skill name wins over a same-named user directory', () => {
  const { source, target } = freshDirs('shipped-wins');
  mkdirSync(join(target, '.agents/skills/speck'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/speck/SKILL.md'), 'user tried to override the shipped skill');

  smartSync(source, target);

  assert.equal(
    readFileSync(join(target, '.cursor/skills/speck/SKILL.md'), 'utf-8'),
    'shipped-speck-skill',
    'the source-shipped skill is authoritative for names Speck itself ships',
  );
});

test('a shipped skill name wins over IDENTICAL user content without an error (safe dedup)', () => {
  const { source, target } = freshDirs('shipped-identical');
  mkdirSync(join(target, '.agents/skills/speck'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/speck/SKILL.md'), 'shipped-speck-skill'); // byte-identical

  const results = smartSync(source, target);

  assert.ok(lstatSync(join(target, '.agents/skills')).isSymbolicLink(), 'identical content is not a real conflict');
  assert.ok(results.errors.every(e => e.file !== '.agents/skills'), 'no error for a no-op dedup');
});

test('a shipped-name collision with DIFFERING content is set aside, never destroyed, and the upgrade still completes', () => {
  // Round-2 finding 3: migration was per-top-level-entry, so a shipped-name collision
  // skipped the WHOLE user directory (including files Speck never ships) and then the
  // caller's rmSync destroyed it — the lane's own test only asserted the shipped file won,
  // never that the destroyed user content mattered.
  const { source, target } = freshDirs('shipped-collision-extra-file');
  mkdirSync(join(target, '.agents/skills/speck'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/speck/SKILL.md'), 'MY OWN speck NOTES - IRREPLACEABLE');
  writeFileSync(join(target, '.agents/skills/speck/extra-notes.md'), 'ALSO MINE');

  const results = smartSync(source, target);

  assert.ok(
    lstatSync(join(target, '.agents/skills')).isSymbolicLink(),
    'the upgrade completes — a colliding copy must not strand the project on a dead catalog',
  );
  assert.equal(
    readFileSync(join(target, '.agents/skills.superseded/speck/SKILL.md'), 'utf-8'),
    'MY OWN speck NOTES - IRREPLACEABLE',
    'the user SKILL.md is set aside intact, never destroyed',
  );
  assert.equal(
    readFileSync(join(target, '.agents/skills.superseded/speck/extra-notes.md'), 'utf-8'),
    'ALSO MINE',
    'the extra file (which has no shipped counterpart) is set aside too',
  );
  assert.ok(
    !results.errors.some(e => e.file === '.agents/skills'),
    'setting a copy aside is not an error condition',
  );
});

test('a user skill named after a RETIRED Speck skill (e.g. gdpr-compliance) survives, is never laundered into the cleanup step', () => {
  // Round-2 finding 1 [BLOCKER]: migrating a same-named real directory into .cursor/skills
  // put it directly in the path of REMOVE_FILES (smartSync step 6), which prunes ~40 retired
  // skill names — including gdpr-compliance — from .cursor/skills a few lines later. The
  // upgrade printed "migrated 1 pre-existing item(s)" immediately before deleting it.
  const { source, target } = freshDirs('retired-name-gdpr');
  mkdirSync(join(target, '.agents/skills/gdpr-compliance'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/gdpr-compliance/SKILL.md'), 'OUR COMPANY GDPR PLAYBOOK');

  const results = smartSync(source, target);

  assert.ok(
    lstatSync(join(target, '.agents/skills')).isSymbolicLink(),
    'the upgrade still completes — a name collision must not strand the project on a stale catalog',
  );
  assert.equal(
    readFileSync(join(target, '.agents/skills.superseded/gdpr-compliance/SKILL.md'), 'utf-8'),
    'OUR COMPANY GDPR PLAYBOOK',
    'the user content is set aside intact — never migrated into the directory REMOVE_FILES prunes',
  );
  assert.ok(
    !existsSync(join(target, '.cursor/skills/gdpr-compliance')),
    'nothing was laundered into .cursor/skills where it would be indistinguishable from a retired Speck skill',
  );
  assert.ok(
    results.removed.every(r => !r.includes('gdpr-compliance')),
    'results.removed carries no laundered-then-cleaned-up entry for it',
  );
});

test('a user skill named after a DIFFERENT retired name (docker-containerization) also survives', () => {
  // Neighbouring input for finding 1 — the reviewer named gdpr-compliance as one of ~21
  // generic retired names; this proves the fix is general (derived from REMOVE_FILES itself)
  // rather than special-cased to the one name the reviewer tested.
  const { source, target } = freshDirs('retired-name-docker');
  mkdirSync(join(target, '.claude/skills/docker-containerization'), { recursive: true });
  writeFileSync(join(target, '.claude/skills/docker-containerization/SKILL.md'), 'OUR DOCKER NOTES');

  const results = smartSync(source, target);

  assert.equal(
    readFileSync(join(target, '.claude/skills.superseded/docker-containerization/SKILL.md'), 'utf-8'),
    'OUR DOCKER NOTES',
  );
  assert.ok(lstatSync(join(target, '.claude/skills')).isSymbolicLink(), 'the upgrade completes');
});

test('a retired name buried INSIDE a normal user skill (not a top-level collision) still migrates fine', () => {
  // Neighbouring input for finding 1 — only a top-level directory NAME collision with a
  // retired skill is dangerous (REMOVE_FILES only ever deletes .cursor/skills/<name> at that
  // exact depth); a file or subdirectory that happens to share the string somewhere inside a
  // differently-named skill must not be treated as unsafe.
  const { source, target } = freshDirs('retired-name-nested');
  mkdirSync(join(target, '.claude/skills/my-real-skill/gdpr-compliance'), { recursive: true });
  writeFileSync(join(target, '.claude/skills/my-real-skill/gdpr-compliance/notes.md'), 'nested, not a top-level name');

  const results = smartSync(source, target);

  assert.ok(lstatSync(join(target, '.claude/skills')).isSymbolicLink(), 'not a real collision — migrates normally');
  assert.equal(
    readFileSync(join(target, '.cursor/skills/my-real-skill/gdpr-compliance/notes.md'), 'utf-8'),
    'nested, not a top-level name',
  );
  assert.ok(results.errors.every(e => e.file !== '.claude/skills'));
});

test('the same skill name in TWO runtime dirs with different content: the second is set aside, not silently destroyed', () => {
  // Round-2 finding 2 [MAJOR]: the runtime-dir loop is ['.claude', '.codex', '.agents']. The
  // first real dir migrates its copy of the name into .cursor/skills, which joins the
  // "shipped" set for the next dir's check — so the second dir's differently-content skill of
  // the same name used to be silently skipped by the migration and then destroyed by rmSync,
  // with no entry in results.removed or results.errors.
  const { source, target } = freshDirs('two-runtime-dirs-collide');
  mkdirSync(join(target, '.claude/skills/my-skill'), { recursive: true });
  writeFileSync(join(target, '.claude/skills/my-skill/SKILL.md'), 'CLAUDE VARIANT');
  mkdirSync(join(target, '.agents/skills/my-skill'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/my-skill/SKILL.md'), 'AGENTS VARIANT (different content)');

  const results = smartSync(source, target);

  assert.ok(lstatSync(join(target, '.claude/skills')).isSymbolicLink(), 'the first dir (no prior collision) migrates fine');
  assert.equal(readFileSync(join(target, '.cursor/skills/my-skill/SKILL.md'), 'utf-8'), 'CLAUDE VARIANT');

  assert.ok(
    lstatSync(join(target, '.agents/skills')).isSymbolicLink(),
    'the second dir still completes its swap',
  );
  assert.equal(
    readFileSync(join(target, '.agents/skills.superseded/my-skill/SKILL.md'), 'utf-8'),
    'AGENTS VARIANT (different content)',
    'the AGENTS variant is set aside — it exists nowhere else, so it must not be destroyed',
  );
});

test('three runtime dirs sharing a name (neighbouring input: .claude + .codex + .agents all collide)', () => {
  const { source, target } = freshDirs('three-runtime-dirs-collide');
  for (const [dir, content] of [['.claude', 'CLAUDE V'], ['.codex', 'CODEX V'], ['.agents', 'AGENTS V']]) {
    mkdirSync(join(target, dir, 'skills/tri-skill'), { recursive: true });
    writeFileSync(join(target, dir, 'skills/tri-skill/SKILL.md'), content);
  }

  const results = smartSync(source, target);

  // The first dir's copy becomes the live catalog entry; the two later, differing copies are
  // each set aside under their own runtime dir. Every variant remains readable somewhere.
  assert.equal(readFileSync(join(target, '.cursor/skills/tri-skill/SKILL.md'), 'utf-8'), 'CLAUDE V', 'first dir wins the migration');
  assert.equal(readFileSync(join(target, '.codex/skills.superseded/tri-skill/SKILL.md'), 'utf-8'), 'CODEX V', 'second variant is set aside');
  assert.equal(readFileSync(join(target, '.agents/skills.superseded/tri-skill/SKILL.md'), 'utf-8'), 'AGENTS V', 'third variant is set aside');
  for (const dir of ['.claude', '.codex', '.agents']) {
    assert.ok(lstatSync(join(target, dir, 'skills')).isSymbolicLink(), `${dir}/skills completes its swap`);
  }
});

test('a broken symlink inside a real pre-existing skills dir migrates cleanly instead of throwing ENOENT mid-migration', () => {
  // Round-2 finding 4 [MAJOR]: migrateUnknownEntries used statSync, which follows symlinks
  // and throws ENOENT for a dangling one. The exception escaped mid-migration, leaving
  // entries already copied as orphaned duplicates in .cursor/skills, destDir never removed,
  // and never symlinked — the same "undiscoverable under .agents/" end state as finding 2,
  // despite an apparently successful upgrade log.
  const { source, target } = freshDirs('broken-symlink-inside');
  mkdirSync(join(target, '.agents/skills/a-good'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/a-good/SKILL.md'), 'A GOOD');
  symlinkSync(join('.', 'nowhere'), join(target, '.agents/skills/m-broken'));
  mkdirSync(join(target, '.agents/skills/z-good'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/z-good/SKILL.md'), 'Z GOOD');

  const results = smartSync(source, target);

  assert.ok(lstatSync(join(target, '.agents/skills')).isSymbolicLink(), 'migration completed and the symlink was created');
  assert.equal(readFileSync(join(target, '.cursor/skills/a-good/SKILL.md'), 'utf-8'), 'A GOOD');
  assert.equal(readFileSync(join(target, '.cursor/skills/z-good/SKILL.md'), 'utf-8'), 'Z GOOD', 'the entry AFTER the broken symlink still migrated');
  assert.ok(
    lstatSync(join(target, '.cursor/skills/m-broken')).isSymbolicLink(),
    'the broken symlink itself was preserved as a symlink, not followed',
  );
  assert.ok(results.errors.every(e => e.file !== '.agents/skills'), 'no ENOENT surfaced');
});

test('a broken symlink nested inside a subdirectory (neighbouring input) also migrates cleanly', () => {
  const { source, target } = freshDirs('broken-symlink-nested');
  mkdirSync(join(target, '.agents/skills/wrapper'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/wrapper/SKILL.md'), 'WRAPPER');
  symlinkSync(join('.', 'gone'), join(target, '.agents/skills/wrapper/nested-broken'));

  const results = smartSync(source, target);

  assert.ok(lstatSync(join(target, '.agents/skills')).isSymbolicLink());
  assert.equal(readFileSync(join(target, '.cursor/skills/wrapper/SKILL.md'), 'utf-8'), 'WRAPPER');
  assert.ok(lstatSync(join(target, '.cursor/skills/wrapper/nested-broken')).isSymbolicLink());
  assert.ok(results.errors.every(e => e.file !== '.agents/skills'));
});

test('a sibling real directory outside skills/ is left completely untouched', () => {
  const { source, target } = freshDirs('sibling');
  mkdirSync(join(target, '.agents/skills/my-skill'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/my-skill/SKILL.md'), 'MINE');
  mkdirSync(join(target, '.agents/rules'), { recursive: true });
  writeFileSync(join(target, '.agents/rules/house.md'), 'HOUSE RULES');

  smartSync(source, target);

  assert.ok(!lstatSync(join(target, '.agents/rules')).isSymbolicLink(), '.agents/rules stayed a real directory');
  assert.equal(
    readFileSync(join(target, '.agents/rules/house.md'), 'utf-8'),
    'HOUSE RULES',
    '.agents/rules content is untouched by the .agents/skills symlink migration',
  );
});

test('a plain file at .agents/skills is refused, not destroyed', () => {
  const { source, target } = freshDirs('plain-file-agents');
  mkdirSync(join(target, '.agents'), { recursive: true });
  writeFileSync(join(target, '.agents/skills'), 'I AM A FILE, NOT A DIRECTORY');

  const results = smartSync(source, target);

  assert.ok(existsSync(join(target, '.agents/skills')), '.agents/skills still exists');
  assert.ok(!lstatSync(join(target, '.agents/skills')).isSymbolicLink(), 'it was not replaced by a symlink');
  assert.equal(
    readFileSync(join(target, '.agents/skills'), 'utf-8'),
    'I AM A FILE, NOT A DIRECTORY',
    'file content is untouched',
  );
  assert.ok(
    results.errors.some(e => e.file === '.agents/skills'),
    'the refusal is reported in results.errors',
  );
});

test('a dangling .claude/skills symlink is repaired, not left as EEXIST', () => {
  const { source, target } = freshDirs('dangling-claude');
  mkdirSync(join(target, '.claude'), { recursive: true });
  symlinkSync(join('..', '.cursor', 'skills-old'), join(target, '.claude/skills'));

  const results = smartSync(source, target);

  assert.ok(
    results.errors.every(e => e.file !== '.claude/skills'),
    'no EEXIST error for .claude/skills',
  );
  assert.ok(lstatSync(join(target, '.claude/skills')).isSymbolicLink());
  assert.equal(
    readFileSync(join(target, '.claude/skills/speck/SKILL.md'), 'utf-8'),
    'shipped-speck-skill',
    'the repaired symlink resolves into the real .cursor/skills',
  );
});

test('a dangling .agents/skills symlink is repaired, not left as EEXIST', () => {
  const { source, target } = freshDirs('dangling-agents');
  mkdirSync(join(target, '.agents'), { recursive: true });
  symlinkSync(join('..', '.cursor', 'skills-old'), join(target, '.agents/skills'));

  const results = smartSync(source, target);

  assert.ok(
    results.errors.every(e => e.file !== '.agents/skills'),
    'no EEXIST error for .agents/skills',
  );
  assert.ok(lstatSync(join(target, '.agents/skills')).isSymbolicLink());
  assert.equal(
    readFileSync(join(target, '.agents/skills/speck/SKILL.md'), 'utf-8'),
    'shipped-speck-skill',
    'the repaired symlink resolves into the real .cursor/skills',
  );
});

test('a stale Speck catalog left by an older version does not block the upgrade (the real Streb/Flyt shape)', () => {
  // Found by dry-running the upgrade against real v9.5 and v7.16 project copies. Older Speck
  // versions POPULATED .agents/skills instead of symlinking it, so a real upgrade meets a
  // directory holding dozens of stale Speck skills — many under names v11 retired. Refusing on
  // those stranded the project on a dead catalog while telling the user to move 77 directories
  // by hand. The user's OWN skills sit in the same directory and must still come across.
  const { source, target } = freshDirs('stale-speck-catalog');
  mkdirSync(join(target, '.agents/skills/gdpr-compliance'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/gdpr-compliance/SKILL.md'), 'stale v9 speck skill');
  mkdirSync(join(target, '.agents/skills/speck'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/speck/SKILL.md'), 'stale v9 copy of a shipped skill');
  mkdirSync(join(target, '.agents/skills/axe'), { recursive: true });
  writeFileSync(join(target, '.agents/skills/axe/SKILL.md'), 'MY OWN axe SKILL');

  const results = smartSync(source, target);

  assert.ok(lstatSync(join(target, '.agents/skills')).isSymbolicLink(), 'the upgrade completes');
  assert.equal(
    readFileSync(join(target, '.cursor/skills/axe/SKILL.md'), 'utf-8'),
    'MY OWN axe SKILL',
    'a genuinely project-owned skill is carried into the live catalog',
  );
  assert.ok(existsSync(join(target, '.agents/skills.superseded/gdpr-compliance/SKILL.md')), 'the retired-name copy is kept, not deleted');
  assert.ok(existsSync(join(target, '.agents/skills.superseded/speck/SKILL.md')), 'the stale shipped-name copy is kept too');
  assert.ok(
    !results.errors.some(e => e.file === '.agents/skills'),
    'a stale catalog is an ordinary upgrade, not an error the user must hand-resolve',
  );
});
