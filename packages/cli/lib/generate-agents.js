/**
 * generate-agents.js — the single source of truth for Speck's per-harness agent defs.
 *
 * WHY THIS EXISTS: Claude Code, Cursor, and Codex each read a DIFFERENT agent-file grammar
 * and a DIFFERENT model vocabulary, so one shared file (the old `.claude`/`.codex` symlinks
 * into `.cursor/agents`) cannot be valid for all three:
 *   - Claude Code: `.md` + YAML frontmatter, model = bare alias (opus|sonnet|haiku)
 *   - Cursor:      `.md` + YAML frontmatter, model = a Cursor slug (no Sonnet/Haiku exist there)
 *   - Codex:       `.toml`, `developer_instructions` string, model = a GPT slug
 *
 * SOURCE OF TRUTH: `.cursor/agents/speck-*.md` owns each role body;
 * `.speck/reference/agent-dispatch.json` owns the roster, tier, independence, and skill routes.
 * This generator derives every harness model from the dispatch tier. Run it after editing either:
 *
 *     node packages/cli/lib/generate-agents.js      # or: npm run gen-agents
 *
 * The tier -> model maps are verified against `cursor-agent --list-models` and ~/.codex
 * (2026-07-21). Retune a tier by editing TIER below and re-running — nothing else.
 */

import { readdirSync, readFileSync, writeFileSync, unlinkSync, existsSync, lstatSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const SRC_DIR = join(REPO_ROOT, '.cursor', 'agents');
const CLAUDE_DIR = join(REPO_ROOT, '.claude', 'agents');
const CODEX_DIR = join(REPO_ROOT, '.codex', 'agents');
const DISPATCH_PATH = join(REPO_ROOT, '.speck', 'reference', 'agent-dispatch.json');
const DISPATCH = JSON.parse(readFileSync(DISPATCH_PATH, 'utf-8'));

// Canonical role -> tier. Frontier = decompose/design/audit; mid = build;
// mechanical = extract/discover.
export const ROLE_TIER = Object.fromEntries(
  Object.entries(DISPATCH.roles || {}).map(([name, role]) => [name, role.tier]),
);

// Per-harness model per tier. Each harness has its own vocabulary (verified 2026-07-21).
// Cursor has NO Sonnet/Haiku — Composer 2.5 is its worker tier.
export const TIER = {
  claude: { frontier: 'opus', mid: 'sonnet', mechanical: 'haiku' },
  cursor: {
    frontier: 'claude-opus-4-8-thinking-high',
    mid: 'composer-2.5',
    mechanical: 'composer-2.5',
  },
  codex: {
    frontier: { model: 'gpt-5.6-sol', effort: 'high' },
    mid: { model: 'gpt-5.6-terra', effort: 'medium' },
    mechanical: { model: 'gpt-5.6-luna', effort: 'low' },
  },
};

const LEGACY_ALIAS_TIER = { opus: 'frontier', sonnet: 'mid', haiku: 'mechanical' };

// ---- parsing / emitting helpers -------------------------------------------------

function parseFrontmatter(md) {
  const m = md.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  if (!m) throw new Error('missing YAML frontmatter');
  const fm = {};
  const order = [];
  for (const line of m[1].split('\n')) {
    if (!line.trim()) continue;
    const i = line.indexOf(':');
    if (i < 0) continue;
    const key = line.slice(0, i).trim();
    fm[key] = line.slice(i + 1).trim();
    order.push(key);
  }
  return { fm, order, body: m[2] };
}

function stripQuotes(v) {
  if (v == null) return v;
  const t = v.trim();
  if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
    return t.slice(1, -1);
  }
  return t;
}

// Always double-quote for YAML frontmatter (safe for values with colons/commas/parens).
function yamlQuote(v) {
  return `"${String(v).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

function tomlQuote(v) {
  return `"${String(v).replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

// TOML multiline basic string for the role body. Escape backslashes and any literal
// triple-quote so the body can't terminate the string early.
function tomlMultiline(body) {
  const escaped = body.replace(/\\/g, '\\\\').replace(/"""/g, '\\"\\"\\"');
  return `"""\n${escaped.replace(/^\n+/, '').replace(/\n+$/, '')}\n"""`;
}

function needsWrite(toolsStr) {
  return /\b(Write|Bash|StrReplace|Edit)\b/.test(toolsStr || '');
}

// Removes files in `dir` that match `pattern` but are no longer in `keepFiles` — e.g. a
// generated agent whose `.cursor/agents` source (and agent-dispatch.json role) was deleted.
// Without this, retired agents survive forever in .claude/agents and .codex/agents, both of
// which are copied wholesale downstream (sync.js ALWAYS_OVERWRITE, export-template-repo.sh).
export function pruneStale(dir, keepFiles, pattern) {
  if (!existsSync(dir)) return;
  for (const f of readdirSync(dir)) {
    if (pattern.test(f) && !keepFiles.has(f)) unlinkSync(join(dir, f));
  }
}

// ---- emitters (stable field order for idempotency) ------------------------------

function emitCursor(name, tier, fm, body) {
  const lines = ['---'];
  lines.push(`name: ${name}`);
  lines.push(`description: ${yamlQuote(stripQuotes(fm.description))}`);
  lines.push(`tier: ${tier}`);
  lines.push(`model: ${TIER.cursor[tier]}`);
  if (fm.tools) lines.push(`tools: ${fm.tools}`);
  if (fm.isolation) lines.push(`isolation: ${fm.isolation}`);
  if (fm.color) lines.push(`color: ${fm.color}`);
  lines.push('---');
  return `${lines.join('\n')}\n${body.replace(/^\n+/, '')}`;
}

function emitClaude(name, tier, fm, body) {
  const lines = ['---'];
  lines.push(`name: ${name}`);
  lines.push(`description: ${yamlQuote(stripQuotes(fm.description))}`);
  if (fm.tools) lines.push(`tools: ${fm.tools}`);
  lines.push(`model: ${TIER.claude[tier]}`);
  if (fm.isolation) lines.push(`isolation: ${fm.isolation}`);
  if (fm.color) lines.push(`color: ${fm.color}`);
  lines.push('---');
  return `${lines.join('\n')}\n${body.replace(/^\n+/, '')}`;
}

function emitCodex(name, tier, fm, body) {
  const cfg = TIER.codex[tier];
  const lines = [];
  lines.push(`name = ${tomlQuote(name)}`);
  lines.push(`description = ${tomlQuote(stripQuotes(fm.description))}`);
  lines.push(`model = ${tomlQuote(cfg.model)}`);
  lines.push(`model_reasoning_effort = ${tomlQuote(cfg.effort)}`);
  lines.push(`sandbox_mode = ${tomlQuote(needsWrite(fm.tools) ? 'workspace-write' : 'read-only')}`);
  lines.push(`developer_instructions = ${tomlMultiline(body)}`);
  return `${lines.join('\n')}\n`;
}

// ---- main -----------------------------------------------------------------------

export function generateAgents({ write = true } = {}) {
  const files = readdirSync(SRC_DIR).filter((f) => /^speck-.*\.md$/.test(f));
  const outputs = { cursor: {}, claude: {}, codex: {} };

  for (const file of files) {
    const name = file.replace(/\.md$/, '');
    const { fm, body } = parseFrontmatter(readFileSync(join(SRC_DIR, file), 'utf-8'));
    const declaredTier = fm.tier || LEGACY_ALIAS_TIER[stripQuotes(fm.model)];
    const tier = ROLE_TIER[name];
    if (!tier || !TIER.claude[tier]) {
      throw new Error(`${name}: agent-dispatch.json requires tier frontier|mid|mechanical`);
    }
    // A source file that declares a different tier than dispatch is an unresolved conflict
    // between two humans' intent, not something to silently overwrite.
    if (declaredTier !== tier) {
      throw new Error(`${name}: source tier ${declaredTier} != dispatch tier ${tier}`);
    }
    outputs.cursor[`${name}.md`] = emitCursor(name, tier, fm, body);
    outputs.claude[`${name}.md`] = emitClaude(name, tier, fm, body);
    outputs.codex[`${name}.toml`] = emitCodex(name, tier, fm, body);
  }

  if (write) {
    // .claude/agents and .codex/agents may still be legacy SYMLINKS into .cursor — replace
    // with real directories. Guard against empty paths (never rm a bare dir).
    for (const dir of [CLAUDE_DIR, CODEX_DIR]) {
      if (existsSync(dir) && lstatSync(dir).isSymbolicLink()) unlinkSync(dir);
    }
    mkdirSync(CLAUDE_DIR, { recursive: true });
    mkdirSync(CODEX_DIR, { recursive: true });
    pruneStale(CLAUDE_DIR, new Set(Object.keys(outputs.claude)), /^speck-.*\.md$/);
    pruneStale(CODEX_DIR, new Set(Object.keys(outputs.codex)), /^speck-.*\.toml$/);
    for (const [f, content] of Object.entries(outputs.cursor)) writeFileSync(join(SRC_DIR, f), content);
    for (const [f, content] of Object.entries(outputs.claude)) writeFileSync(join(CLAUDE_DIR, f), content);
    for (const [f, content] of Object.entries(outputs.codex)) writeFileSync(join(CODEX_DIR, f), content);
  }

  return outputs;
}

// Run directly: node packages/cli/lib/generate-agents.js
if (import.meta.url === `file://${process.argv[1]}`) {
  const out = generateAgents({ write: true });
  const n = Object.keys(out.claude).length;
  console.log(`✅ generated ${n} agents × 3 harnesses (.cursor/.claude .md + .codex .toml)`);
}
