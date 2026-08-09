# epic-breakdown / deps

- Configuration stories

   **Quality Stories**
   - Testing stories
   - Documentation stories
   - Performance validation stories
   - Security review stories

4. Generate epic breakdown:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/breakdown-template.md
   ```

   Write output to: `[EPIC_DIR]/epic-breakdown.md`

5. Create story directories with placeholder specs:

   **Subagent Parallelization** - Spawn speck-scribe for each story spec:
   ```
   ├── [Parallel] speck-scribe: Draft S001 spec.md (Draft state) from epic-tech-spec.md
   ├── [Parallel] speck-scribe: Draft S002 spec.md (Draft state) from epic-tech-spec.md
   ├── [Parallel] speck-scribe: Draft S003 spec.md (Draft state) from epic-tech-spec.md
   └── [Wait] → Create all story directories with drafted specs
   ```

   Each speck-scribe receives:
   - Story requirements from epic-breakdown.md
   - Technical context from epic-tech-spec.md
   - Template from .speck/templates/story/story-template.md
   - **Dependencies from epic-breakdown.md** (for YAML frontmatter)

   **Speedup**: Nx (where N = number of stories)

   **IMPORTANT**: Placeholder specs are saved as `spec.md` with lifecycle state `Draft (Placeholder)`.
   The **lifecycle state** — not the filename — is what signals that `/story-specify` still needs to run.
   This eliminates the `spec-draft.md` vs `spec.md` confusion: there is always exactly one file.

   **CRITICAL — Lifecycle state for placeholder spec.md files**:
   Set `**Current State**: Draft (Placeholder)` and mark lifecycle checkboxes as:
   ```
   - [x] **Draft** - Placeholder spec.md created by `/epic-breakdown` (not yet specified)
   - [ ] **Specified** - spec.md enhanced by `/story-specify`
   ```
   **NEVER set `**Current State**: Specified` in a placeholder** — that falsely signals
   that `/story-specify` has already been run and can be skipped.

   **CRITICAL**: Include dependencies in YAML frontmatter:
   ```yaml
   ---
   depends_on: [S004]  # From "Depends on" in epic-breakdown.md
   blocks: [S006]      # From Inter-Story Dependencies table
