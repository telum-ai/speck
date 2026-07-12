/**
 * Speck CLI — feedback command
 *
 * Collects structured feedback about a Speck session (catch-up, upgrade,
 * methodology, recipe coverage, etc.) into a local feedback.md the user
 * can review, redact, and submit as a GitHub issue.
 *
 * No network calls. No telemetry. The user is in control of whether to
 * submit. This is intentional — Speck's relationship with users is the
 * opposite of "we ship telemetry by default."
 *
 * Usage:
 *   npx github:telum-ai/speck feedback
 *   npx github:telum-ai/speck feedback --message "Short note"
 *   npx github:telum-ai/speck feedback --auto      (writes file without prompting)
 *   npx github:telum-ai/speck feedback --topic catchup
 */

import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { execSync } from 'child_process';
import { isSpeckMarketingReadme } from '../sync.js';

const FEEDBACK_TOPICS = ['catchup', 'migration', 'recipe', 'methodology', 'cli', 'docs', 'other'];

function readJsonSafe(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf-8'));
  } catch {
    return null;
  }
}

function gitMeta(cwd) {
  try {
    const sha = execSync('git rev-parse --short HEAD', { cwd, stdio: ['ignore', 'pipe', 'ignore'] })
      .toString().trim();
    const branch = execSync('git rev-parse --abbrev-ref HEAD', { cwd, stdio: ['ignore', 'pipe', 'ignore'] })
      .toString().trim();
    return { sha, branch };
  } catch {
    return { sha: 'unknown', branch: 'unknown' };
  }
}

function detectProjects(cwd) {
  const workspacePj = readJsonSafe(path.join(cwd, '.speck', 'project.json')) || {};
  const workspaceVersion = readWorkspaceVersion(cwd);
  const specsDir = path.join(cwd, 'specs', 'projects');
  if (!fs.existsSync(specsDir)) return [];
  return fs.readdirSync(specsDir)
    .filter(d => fs.statSync(path.join(specsDir, d)).isDirectory())
    .map(d => ({
      id: d,
      path: path.join('specs', 'projects', d),
      recipe: workspacePj._active_recipe || workspacePj.recipe || null,
      play_level: workspacePj.play_level || null,
      project_archetype: workspacePj.project_archetype || null,
      speck_version: workspacePj.speck_version || workspaceVersion,
    }));
}

function readWorkspaceVersion(cwd) {
  const v = path.join(cwd, '.speck', 'VERSION');
  if (fs.existsSync(v)) return fs.readFileSync(v, 'utf-8').trim();
  const pj = readJsonSafe(path.join(cwd, '.speck', 'project.json'));
  return pj?.speck_version || 'unknown';
}

function frictionSignals(cwd, projects) {
  const signals = [];

  if (fs.existsSync(path.join(cwd, '.speck', '.migration-needs-catchup'))) {
    signals.push('migration-needs-catchup marker present (catch-up not yet run after upgrade)');
  }

  const readmePath = path.join(cwd, 'README.md');
  if (fs.existsSync(readmePath)) {
    const readme = fs.readFileSync(readmePath, 'utf-8');
    if (isSpeckMarketingReadme(readme)) {
      signals.push('PROFILE: root README.md still has legacy Speck marketing content (run speck upgrade or /project-readme)');
    } else if (!readme.includes('<!-- SPECK:START -->')) {
      signals.push('PROFILE: root README.md lacks SPECK markers (footer not managed by Speck)');
    } else if (fs.existsSync(path.join(cwd, '.speck/scripts/profile-drift-check.sh'))) {
      try {
        const drift = execSync('bash .speck/scripts/profile-drift-check.sh', {
          cwd,
          encoding: 'utf-8',
          stdio: ['ignore', 'pipe', 'ignore'],
        });
        if (drift.includes('PROFILE_DRIFT.P1')) {
          signals.push('PROFILE: README one-liner drift P1 vs product-contract (SHIP-RC blocker)');
        } else if (drift.includes('PROFILE_DRIFT.P2')) {
          signals.push('PROFILE: README one-liner partial drift P2 — run /project-readme');
        }
      } catch {
        signals.push('PROFILE: profile-drift-check failed or P1 drift detected');
      }
    }
  }

  if (fs.existsSync(path.join(cwd, '.speck/scripts/settings-drift-check.sh'))) {
    try {
      execSync('bash .speck/scripts/settings-drift-check.sh', {
        cwd,
        encoding: 'utf-8',
        stdio: ['ignore', 'pipe', 'ignore'],
      });
    } catch (err) {
      const out = err.stdout?.toString?.() || '';
      if (out.includes('SETTINGS_DRIFT.P0') || err.status === 1) {
        signals.push('SETTINGS: Claude settings drift P0 — run `npx github:telum-ai/speck reconcile-settings`');
      }
    }
  }

  for (const p of projects) {
    const projectPath = path.join(cwd, p.path);

    const productContract = path.join(projectPath, 'product-contract.md');
    if (fs.existsSync(productContract)) {
      const content = fs.readFileSync(productContract, 'utf-8');
      if (content.includes('<!-- v7 MIGRATION SCAFFOLD -->')) {
        signals.push(`${p.id}: product-contract.md still in scaffold state`);
      }
      const replaceCount = (content.match(/REPLACE_BEFORE_SHIP:/g) || []).length;
      if (replaceCount > 0) {
        signals.push(`${p.id}: ${replaceCount} REPLACE_BEFORE_SHIP token(s) in product-contract.md`);
      }
      const reviewCount = (content.match(/\[NEEDS USER REVIEW\]/g) || []).length;
      if (reviewCount > 0) {
        signals.push(`${p.id}: ${reviewCount} [NEEDS USER REVIEW] marker(s) in product-contract.md`);
      }
    }

    const catchUpPlan = path.join(projectPath, 'project-catch-up-plan.md');
    if (fs.existsSync(catchUpPlan)) {
      const content = fs.readFileSync(catchUpPlan, 'utf-8');
      const p0Count = (content.match(/^- \[ \] .+/gm) || []).length;
      if (p0Count > 5) {
        signals.push(`${p.id}: large catch-up plan (${p0Count}+ unchecked items)`);
      }
    }
  }

  return signals;
}

function summarizeProject(p) {
  const r = p.recipe || '(none)';
  const pl = p.play_level || '(unset)';
  const pa = p.project_archetype || '(unset)';
  const v = p.speck_version || '(unstamped)';
  return `- **${p.id}**: recipe=\`${r}\`, play_level=\`${pl}\`, archetype=\`${pa}\`, speck_version=\`${v}\``;
}

function generateFeedbackBody({ cwd, topic, message, projects, signals, workspaceVersion, git }) {
  const date = new Date().toISOString().split('T')[0];
  const fc = path.basename(cwd);

  return `# Speck Feedback — ${topic}

**Date**: ${date}
**Speck version (workspace)**: ${workspaceVersion}
**Repo HEAD**: \`${git.sha}\` on branch \`${git.branch}\`
**Workspace**: \`${fc}\`

> Structure guide: \`.speck/templates/feedback/template.md\` (symptom + reproduction + patch + proposal format)

---

## What I want to share

${message || '<!-- Add your feedback here. Be specific. What worked? What didn\'t? What would have helped? -->'}

---

## Context (auto-collected, no source code)

### Projects in this workspace

${projects.length === 0 ? '_No Speck projects detected._' : projects.map(summarizeProject).join('\n')}

### Friction signals detected

${signals.length === 0 ? '_No automatic friction signals — clean state._' : signals.map(s => `- ${s}`).join('\n')}

---

## Submitting this feedback

Speck does **not** send anything automatically. If you want to share this with the Speck team:

1. **Review the file** — redact anything you don't want public
2. Open a new GitHub issue: https://github.com/telum-ai/speck/issues/new
3. Paste the content of this file
4. Add a title like \`Feedback: ${topic} — <one-line summary>\`

Or if you just want this for your own records, keep it locally and commit it (or don't).

---

*Generated by \`npx speck feedback\` — no network calls were made.*
`;
}

function prompt(rl, q) {
  return new Promise(resolve => rl.question(q, ans => resolve(ans)));
}

export async function feedback(cwd, options = {}) {
  const args = options._args || [];

  // Parse --topic
  const topicIdx = args.indexOf('--topic');
  let topic = topicIdx !== -1 ? args[topicIdx + 1] : null;

  // Parse --message
  const msgIdx = args.indexOf('--message');
  let message = msgIdx !== -1 ? args[msgIdx + 1] : null;

  const auto = args.includes('--auto') || options.auto;

  const projects = detectProjects(cwd);
  const signals = frictionSignals(cwd, projects);
  const workspaceVersion = readWorkspaceVersion(cwd);
  const git = gitMeta(cwd);

  // Interactive prompts when not in --auto mode and missing inputs
  if (!auto && process.stdin.isTTY) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    try {
      if (!topic) {
        console.log('\n🥓 Speck feedback — pick a topic:');
        FEEDBACK_TOPICS.forEach((t, i) => console.log(`  ${i + 1}. ${t}`));
        const ans = await prompt(rl, '\nNumber or topic name: ');
        const n = parseInt(ans, 10);
        topic = (!Number.isNaN(n) && n >= 1 && n <= FEEDBACK_TOPICS.length)
          ? FEEDBACK_TOPICS[n - 1]
          : (FEEDBACK_TOPICS.includes(ans.trim()) ? ans.trim() : 'other');
      }
      if (!message) {
        console.log('\nShort message (1-2 sentences; you can expand in the file later).');
        message = await prompt(rl, 'Message: ');
      }
    } finally {
      rl.close();
    }
  }

  topic = topic || 'other';
  if (!FEEDBACK_TOPICS.includes(topic)) {
    console.warn(`⚠️  Unknown topic '${topic}' — using 'other'. Valid: ${FEEDBACK_TOPICS.join(', ')}`);
    topic = 'other';
  }

  const date = new Date().toISOString().split('T')[0];
  const outDir = path.join(cwd, '.speck', 'feedback');
  fs.mkdirSync(outDir, { recursive: true });
  const fileName = `${date}-${topic}.md`;
  const outPath = path.join(outDir, fileName);

  const body = generateFeedbackBody({
    cwd, topic, message, projects, signals, workspaceVersion, git,
  });

  fs.writeFileSync(outPath, body, 'utf-8');

  console.log(`
🥓 Feedback drafted: ${path.relative(cwd, outPath)}

Auto-collected context:
  • Workspace version: ${workspaceVersion}
  • Repo HEAD:         ${git.sha} (${git.branch})
  • Projects detected: ${projects.length}
  • Friction signals:  ${signals.length}

Next:
  1. Open the file and write your real feedback in the "What I want to share" section
  2. Redact anything you don't want public
  3. Open a new GitHub issue and paste it: https://github.com/telum-ai/speck/issues/new

Speck did NOT send anything. No telemetry. The file is yours.
`);
}
