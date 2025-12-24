# Feeding Learnings Back Into Speck

Speck is designed to be **self-improving**. When you build products with Speck, you may discover:
- Reusable patterns
- Systemic gotchas
- Missing template sections
- Command ordering improvements
- Automation improvements

## How Feedback Works

After running `/epic-retrospective` or `/project-retrospective`, you'll be asked:

> "Would you like to share any methodology-specific learnings with the Speck repository?"

If you answer **yes**, an issue will be created in the Speck repo with:
- Only the methodology insights (NOT project-specific details)
- Suggested improvements to commands, templates, or patterns
- Evidence of validation (e.g., "appeared in 3+ stories")

## What Gets Shared

**✅ SHARED (Methodology)**:
- "The tasks template should include a setup phase"
- "story-plan should ask about external dependencies earlier"
- "Pattern: PostgreSQL window functions for time overlaps"

**❌ NOT SHARED (Project-Specific)**:
- Your project name, domain, or business logic
- Specific feature implementations
- Performance metrics or user data
- Any content from your specs/

## Manual Feedback

You can also create issues directly in the Speck repo:

https://github.com/telum-ai/speck/issues/new

Include:
- Which command/template needs improvement
- What the issue was
- Your suggested fix (if any)
- Evidence (how many stories/epics encountered this)

## Privacy Guarantee

- No automatic data collection from your projects
- Feedback is always opt-in and reviewed by you before submission
- You control exactly what gets shared
