/**
 * Generate one lean JTBD incubation bet from recent repo context.
 */

import { execSync } from 'child_process';

function sh(cmd, cwd) {
  return execSync(cmd, {
    cwd,
    encoding: 'utf-8',
    stdio: ['ignore', 'pipe', 'ignore'],
  }).trim();
}

function safeSh(cmd, cwd) {
  try {
    return sh(cmd, cwd);
  } catch {
    return '';
  }
}

export async function incubate(targetDir, options = {}) {
  const days = Number.isFinite(options.days) ? options.days : 21;

  const hotFilesRaw = safeSh(
    `git log --since='${days} days ago' --name-only --pretty=format: | sed '/^$/d' | sort | uniq -c | sort -nr | head -n 10`,
    targetDir,
  );

  const hotFiles = hotFilesRaw
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => line.replace(/^\d+\s+/, ''))
    .filter(Boolean)
    .slice(0, 3);

  const todoHits = [];
  for (const file of hotFiles) {
    const hit = safeSh(`grep -nE 'TODO|FIXME|HACK|XXX' '${file}' | head -n 1`, targetDir);
    if (hit) todoHits.push(`${file}: ${hit}`);
  }

  const targetArea = hotFiles[0] || 'project onboarding flow';
  const painSignal = todoHits[0] || 'Repeated edits in the same core files indicate unresolved friction.';

  const output = [
    'Hypothesis:',
    `Teams trying to adopt Speck are hiring for a "what should we build first?" answer; adding a one-command lean JTBD incubator around ${targetArea} will shorten time-to-first-bet and improve activation.`,
    '',
    'Build shipped:',
    `Added \`speck incubate\` (window: ${days} days) to mine recent git churn + TODO/FIXME signals and output one lean bet in this exact format: Hypothesis / Build shipped / Signal to watch / Next bet.`,
    painSignal ? `Pain signal surfaced: ${painSignal}` : '',
    '',
    'Signal to watch:',
    'How many repos run `speck incubate` before first `/speck` workflow, and whether those repos reach first merged story faster than baseline.',
    '',
    'Next bet:',
    'Add `--json` output so incubator can feed dashboards and cron autopilot summaries.',
  ].filter(Boolean);

  console.log(output.join('\n'));
}
