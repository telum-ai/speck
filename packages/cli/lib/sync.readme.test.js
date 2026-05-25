/**
 * Tests for project README sync helpers (v7.6.0)
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  isSpeckMarketingReadme,
  mergeReadme,
  extractReadmeFooter,
} from './sync.js';

const TEMPLATE = `# [Project Name]

> [One-line elevator pitch — what is this product/service/system?]

**Status**: Spec phase

---

<!-- SPECK:START -->
Built with [Speck 🥓](https://github.com/telum-ai/speck) — evidence-driven specification methodology.
Methodology docs: [.speck/README.md](.speck/README.md)
<!-- SPECK:END -->
`;

const SPECK_MARKETING = `# Speck 🥓

**Spec-driven development methodology** for building digital products.

\`\`\`bash
npx github:telum-ai/speck init
\`\`\`
`;

test('isSpeckMarketingReadme detects legacy Speck marketing README', () => {
  assert.equal(isSpeckMarketingReadme(SPECK_MARKETING), true);
  assert.equal(isSpeckMarketingReadme('# Flyt\n\nStudio management platform.'), false);
  assert.equal(isSpeckMarketingReadme('# Speck 🥓\n\nCustom project about fitness.'), false);
});

test('extractReadmeFooter returns managed block', () => {
  const footer = extractReadmeFooter(TEMPLATE);
  assert.ok(footer);
  assert.match(footer, /<!-- SPECK:START -->/);
  assert.match(footer, /<!-- SPECK:END -->/);
});

test('mergeReadme preserves user body and updates footer', () => {
  const userReadme = `# Flyt

> Norwegian Reformer studio management platform.

Custom getting started notes.

<!-- SPECK:START -->
Old footer content
<!-- SPECK:END -->
`;

  const result = mergeReadme(TEMPLATE, userReadme);
  assert.equal(result.action, 'merge');
  assert.match(result.content, /^# Flyt/);
  assert.match(result.content, /Custom getting started notes/);
  assert.match(result.content, /Built with \[Speck 🥓\]/);
  assert.doesNotMatch(result.content, /Old footer content/);
});

test('mergeReadme creates from template when target absent', () => {
  const result = mergeReadme(TEMPLATE, null);
  assert.equal(result.action, 'create');
  assert.equal(result.content, TEMPLATE);
});

test('user-customized README without Speck fingerprint is not marketing', () => {
  const custom = '# Speck-inspired Tool\n\nA tool for teams using Speck methodology internally.';
  assert.equal(isSpeckMarketingReadme(custom), false);
});
