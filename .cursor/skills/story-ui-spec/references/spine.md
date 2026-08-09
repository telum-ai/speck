# story-ui-spec — spine

## Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/story/ui-spec-template.md
```
The template defines required sections and formatting for `ui-spec.md`, including **PROFILE surface impact** (v7.7+), component hierarchy, state matrix, design token usage, and interaction spec.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to Step 1.

Generate precise UI specifications that developers can implement directly.

**When to use this command**:
-  **REQUIRED** for stories that include UI components (forms, pages, interactive elements)
- **REQUIRED** for stories with multiple component states, variants, or animations
- **OPTIONAL** for simple, single-state UI elements that follow existing patterns

If `/story-plan` detected UI requirements, you MUST run this command before `/story-tasks`.
