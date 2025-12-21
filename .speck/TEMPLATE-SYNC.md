# Template Sync (actions-template-sync)

Speck is designed to be **reused as a GitHub template repository** and kept up-to-date across many product repos.

This repo includes a ready-to-use sync workflow:
- `.github/workflows/template-sync.yml`
- `.templatesyncignore`

Related (optional): **Template feedback intake**
- `.speck/TEMPLATE-FEEDBACK.md`
- `.github/workflows/speck-template-feedback.yml` (runs in product repos to open issues in the template repo)

## How it works

In each product repository (created from the template):
1. A scheduled GitHub Action runs (monthly by default)
2. It pulls updates from the template repo
3. It opens a PR in the product repo with the changes

Sync behavior is controlled by `.templatesyncignore` (ignore patterns).

## Setup in a product repo

1. **Enable the workflow** (it is already included via the template).
2. Add repository secret:
   - **`TEMPLATE_SYNC_SOURCE_REPO`**: `<owner>/<template-repo>`
3. Optional secret:
   - **`TEMPLATE_SYNC_UPSTREAM_BRANCH`**: defaults to `main`

Then either wait for the schedule or run the workflow manually via **Actions → Template Sync (Speck)**.

## Recommended sync boundaries (default)

Treat these as **template-managed** (synced):
- `.speck/**`
- `.cursor/**` (except project-managed paths listed below)
- `AGENTS.md`
- `.github/workflows/speck-validation.yml`
- `.github/workflows/template-sync.yml`
- `.templatesyncignore`

Treat these as **product-managed** (ignored from sync by default):
- `specs/**` (project artifacts)
- common code directories like `backend/**`, `frontend/**`, `apps/**`, `src/**`
- product CI workflows (`.github/workflows/ci.yml`, `.github/workflows/ui.yml`)
- project Cursor rules (`.cursor/rules/**`)
- project hook extensions (`.cursor/hooks/hooks/hooks.d/**`)
- team-shared MCP overlay (`.cursor/mcp.project.json.example`)

## Local override strategy

If you need to change a template-managed file:
- **Preferred**: make the change in the template repo and let it sync everywhere.
- **Escape hatch**: add that file path to `.templatesyncignore` in the product repo.
  - Trade-off: you stop receiving template updates for that file.


