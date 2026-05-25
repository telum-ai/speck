/**
 * speck larp-play — autonomous persona-based LARP playback and interactive manual walkthrough
 */

import { existsSync, readdirSync, readFileSync, writeFileSync, mkdirSync, statSync } from 'fs';
import { join, basename, dirname } from 'path';

// Standard node readline
import readline from 'readline';

function askQuestion(query) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => rl.question(query, (ans) => {
    rl.close();
    resolve(ans);
  }));
}

/**
 * Detect projects under specs/projects/
 */
function getProjects(cwd) {
  const specsDir = join(cwd, 'specs', 'projects');
  if (!existsSync(specsDir)) return [];
  try {
    return readdirSync(specsDir).filter(d => {
      const p = join(specsDir, d);
      return statSync(p).isDirectory() && existsSync(join(p, 'project.md'));
    });
  } catch {
    // StatSync fallback using fs
    return readdirSync(specsDir).filter(d => {
      return existsSync(join(specsDir, d, 'project.md'));
    });
  }
}

export async function larpPlay(cwd, options = {}) {
  console.log('🥓 Running Speck Persona LARP Player...\n');

  const projects = getProjects(cwd);
  if (projects.length === 0) {
    console.log('❌ No Speck projects found. Run "speck init" or "/project-specify" first.');
    return;
  }

  // Choose project
  let projectID = projects[0];
  if (projects.length > 1) {
    console.log('Multiple projects detected:');
    projects.forEach((p, idx) => console.log(`  [${idx + 1}] ${p}`));
    const choice = await askQuestion('\nWhich project should we play LARP for? [1]: ');
    const num = parseInt(choice || '1', 10);
    if (num > 0 && num <= projects.length) {
      projectID = projects[num - 1];
    }
  }

  const projectDir = join(cwd, 'specs', 'projects', projectID);
  const personasDir = join(projectDir, 'personas');

  if (!existsSync(personasDir)) {
    console.log(`⚠️  No personas directory found at specs/projects/${projectID}/personas/`);
    console.log('   Creating directory and writing persona-larp-template...');
    mkdirSync(personasDir, { recursive: true });
    const template = readFileSync(join(cwd, '.speck', 'templates', 'story', 'persona-larp-template.md'), 'utf-8');
    writeFileSync(join(personasDir, 'cathrine.md'), template);
    console.log('   Scaffolded template at specs/projects/personas/cathrine.md. Please fill it out first!');
    return;
  }

  const personas = readdirSync(personasDir).filter(f => f.endsWith('.md'));
  if (personas.length === 0) {
    console.log('❌ No persona markdown scripts found in personas/ directory.');
    return;
  }

  let selectedPersonaFile = options.persona ? (options.persona.endsWith('.md') ? options.persona : `${options.persona}.md`) : null;
  if (selectedPersonaFile && !existsSync(join(personasDir, selectedPersonaFile))) {
    console.log(`⚠️  Selected persona "${options.persona}" not found. Available personas:`);
    selectedPersonaFile = null;
  }

  if (!selectedPersonaFile) {
    if (personas.length === 1) {
      selectedPersonaFile = personas[0];
    } else {
      console.log('Available personas:');
      personas.forEach((p, idx) => console.log(`  [${idx + 1}] ${basename(p, '.md')}`));
      const choice = await askQuestion('\nWhich persona script do you want to play? [1]: ');
      const num = parseInt(choice || '1', 10);
      if (num > 0 && num <= personas.length) {
        selectedPersonaFile = personas[num - 1];
      } else {
        selectedPersonaFile = personas[0];
      }
    }
  }

  const personaPath = join(personasDir, selectedPersonaFile);
  const personaId = basename(selectedPersonaFile, '.md');
  console.log(`\n📖 Loading persona script: ${projectID}/personas/${selectedPersonaFile}...`);

  const content = readFileSync(personaPath, 'utf-8');
  const steps = parseLarpSteps(content);

  if (steps.length === 0) {
    console.log('❌ Could not parse any valid LARP steps from the script table.');
    console.log('   Make sure your script contains a markdown table with a columns structure like:');
    console.log('   | Step | Action | Capture | Expected emotional state | PASS if | FAIL if |');
    return;
  }

  console.log(`✅ Loaded ${steps.length} LARP steps.`);
  
  // Create larp-recordings folder under the persona's project
  const recordingsDir = join(projectDir, 'larp-recordings');
  if (!existsSync(recordingsDir)) {
    mkdirSync(recordingsDir, { recursive: true });
  }

  // Check for Playwright
  let playwright;
  try {
    playwright = await import('playwright');
    console.log('📡 Playwright detected! Starting headless browser playback...');
  } catch {
    console.log('⚠️  Playwright is NOT installed in this environment.');
    console.log('   Falling back to a beautiful, guided manual walkthrough. Let\'s step through together!');
  }

  const baseUrl = options.url || 'http://localhost:3000';

  if (playwright) {
    await runPlaywrightPlayback(playwright, steps, baseUrl, recordingsDir, personaId);
  } else {
    await runManualWalkthrough(steps, recordingsDir, personaId);
  }
}

/**
 * Parse Markdown LARP steps table
 */
function parseLarpSteps(markdown) {
  const lines = markdown.split('\n');
  const steps = [];
  let inTable = false;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
      // It's a table row
      const cells = trimmed.split('|').map(c => c.trim()).filter((_, idx, arr) => idx > 0 && idx < arr.length - 1);
      
      // Skip header and dividers
      if (cells.length < 3 || cells[0].toLowerCase().includes('step') || cells[0].includes('---')) {
        continue;
      }

      const stepNum = cells[0];
      const action = cells[1] || '';
      const capture = cells[2] || '';
      const emotion = cells[3] || '';
      const passIf = cells[4] || '';
      const failIf = cells[5] || '';

      if (stepNum && action) {
        steps.push({
          stepNum,
          action,
          capture,
          emotion,
          passIf,
          failIf
        });
      }
    }
  }

  return steps;
}

/**
 * Playwright Autonomous Playback
 */
async function runPlaywrightPlayback(playwright, steps, baseUrl, recordingsDir, personaId) {
  const { chromium } = playwright;
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log(`\n🚀 Initializing Playwright session...`);
  console.log(`   Base URL: ${baseUrl}\n`);

  try {
    for (let i = 0; i < steps.length; i++) {
      const step = steps[i];
      console.log(`[Step ${step.stepNum}] Action: "${step.action}"`);
      if (step.emotion) {
        console.log(`   🎭 Expected emotion: ${step.emotion}`);
      }

      // Try to parse action commands
      const lowerAction = step.action.toLowerCase();
      let matched = false;

      try {
        if (lowerAction.startsWith('navigate') || lowerAction.startsWith('open')) {
          let path = step.action.split(/\s+/)[1] || '/';
          // Clean quotes if present
          path = path.replace(/['"]/g, '');
          const targetUrl = path.startsWith('http') ? path : `${baseUrl}${path}`;
          console.log(`   └─ Navigating to ${targetUrl}...`);
          await page.goto(targetUrl, { waitUntil: 'networkidle' });
          matched = true;
        } else if (lowerAction.startsWith('click')) {
          let selector = step.action.substring(6).trim();
          selector = cleanSelector(selector);
          console.log(`   └─ Clicking: "${selector}"...`);
          await page.click(selector);
          matched = true;
        } else if (lowerAction.startsWith('type') || lowerAction.startsWith('fill')) {
          // Syntax: type selector text OR fill selector text
          const rest = step.action.substring(lowerAction.startsWith('type') ? 5 : 5).trim();
          const parts = splitSelectorAndText(rest);
          if (parts) {
            console.log(`   └─ Filling "${parts.selector}" with value: "${parts.text}"...`);
            await page.fill(parts.selector, parts.text);
            matched = true;
          }
        } else if (lowerAction.startsWith('wait')) {
          const ms = parseInt(step.action.split(/\s+/)[1] || '1000', 10);
          console.log(`   └─ Pausing for ${ms}ms...`);
          await page.waitForTimeout(ms);
          matched = true;
        } else if (lowerAction.startsWith('check')) {
          let selector = step.action.substring(6).trim();
          selector = cleanSelector(selector);
          console.log(`   └─ Checking element: "${selector}"...`);
          await page.check(selector);
          matched = true;
        } else if (lowerAction.startsWith('uncheck')) {
          let selector = step.action.substring(8).trim();
          selector = cleanSelector(selector);
          console.log(`   └─ Unchecking element: "${selector}"...`);
          await page.uncheck(selector);
          matched = true;
        }

        if (!matched) {
          // Fallback to text clicks if it's general prose
          if (step.action.startsWith('[') && step.action.endsWith(']')) {
            const textContent = step.action.slice(1, -1);
            if (textContent.toLowerCase() === 'cold-open app' || textContent.toLowerCase() === 'open app') {
              console.log(`   └─ Navigating to base URL: ${baseUrl}...`);
              await page.goto(baseUrl, { waitUntil: 'networkidle' });
            } else {
              // Attempt to click text matching the bracketed content
              console.log(`   └─ Searching for clickable text: "${textContent}"...`);
              await page.click(`text="${textContent}"`);
            }
          } else {
            console.log(`   ⚠️  Prose action could not be mapped to exact command. Skipping execution.`);
          }
        }

        // Handle screenshot captures
        const captureType = step.capture.toLowerCase();
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const filenamePrefix = `${timestamp}-${personaId}-step-${step.stepNum}`;

        if (captureType.includes('screenshot')) {
          const shotPath = join(recordingsDir, `${filenamePrefix}.png`);
          await page.screenshot({ path: shotPath, fullPage: true });
          console.log(`   📸 Screenshot captured: specs/projects/.../larp-recordings/${basename(shotPath)}`);
        }

        if (captureType.includes('ax') || captureType.includes('accessibility')) {
          const axTree = await page.accessibility.snapshot();
          const axPath = join(recordingsDir, `${filenamePrefix}-ax.json`);
          writeFileSync(axPath, JSON.stringify(axTree, null, 2));
          console.log(`   ♿ Accessibility Tree captured: specs/projects/.../larp-recordings/${basename(axPath)}`);
        }

        console.log(`   🏁 Success criterion: ${step.passIf || 'None'}\n`);

      } catch (stepErr) {
        console.log(`   ❌ Error during step playback: ${stepErr.message}`);
        console.log(`   └─ Criterion failed if: ${step.failIf || 'Default failure'}\n`);
      }
    }
  } finally {
    await browser.close();
    console.log('🏁 Playwright session closed.');
  }
}

/**
 * Console-guided Interactive Walkthrough
 */
async function runManualWalkthrough(steps, recordingsDir, personaId) {
  console.log(`\n🚶 Starting Guided Manual Walkthrough...`);
  console.log(`--------------------------------------------------------------------------------`);

  for (let i = 0; i < steps.length; i++) {
    const step = steps[i];
    console.log(`\n📍 [Step ${step.stepNum} of ${steps.length}]`);
    console.log(`👉 Action to Perform: "${step.action}"`);
    if (step.emotion) {
      console.log(`🎭 Mindset/Emotion:  ${step.emotion}`);
    }
    if (step.capture) {
      console.log(`📸 Capture Request:  ${step.capture}`);
    }
    console.log(`✅ PASS Condition:  ${step.passIf}`);
    console.log(`❌ FAIL Condition:  ${step.failIf}`);

    console.log('\n   [Do the action in your running browser/device]');
    await askQuestion('   Press [ENTER] when action is done to capture step and continue...');
  }

  console.log(`\n🏁 Manual Walkthrough completed! Excellent job walking through your persona's eyes, bro!`);
}

/**
 * Utilities for cleaning selectors and text
 */
function cleanSelector(selector) {
  // If wrapped in quotes, clean them
  return selector.replace(/^['"]|['"]$/g, '').trim();
}

function splitSelectorAndText(input) {
  // Try to parse: selector text (e.g. "input[type=email] bro@speck.dev" or "#name 'Full Name'")
  // We match double quotes, single quotes, or unquoted blocks
  const match = input.match(/^([^\s'"]+|['"][^'"]+['"])\s+([\s\S]+)$/);
  if (!match) return null;
  return {
    selector: cleanSelector(match[1]),
    text: cleanSelector(match[2])
  };
}
