# Speck Feedback — methodology

**Date**: 2026-05-25
**Speck version (workspace)**: v7.5.2
**Repo HEAD**: `ec47275` on branch `main`
**Workspace**: `flyt`

---

## What I want to share

**Topic**: Speck owns the root `README.md` slot — and that's the wrong place to be standing. Surfaced after a deep Platform foundation pass on the Flyt project (Norwegian Reformer studio management SaaS); the gap was invisible in early phases but became blocking when we hit GitHub repo creation + commits visible at https://github.com/<account>/<repo>.

---

### TL;DR

1. **`speck init` writes Speck-marketing content as the project's root `README.md`.** New project authors get "# Speck 🥓 — Spec-driven development methodology..." as the public face of their product.
2. **Customization detection is a brittle first-line heuristic** in `packages/cli/lib/sync.js#isReadmeCustomized`. If user keeps `# Speck 🥓` as the title (or doesn't realize they need to change it), every `speck upgrade` clobbers the README body. Verified on Flyt: our root README still has the Speck title from `init`, and v7.5.0 + v7.5.1 + v7.5.2 upgrades each silently updated it.
3. **Two `README.md` files (root + `.speck/`) is confusing without being valuable**: the user's first reaction was "should these be symlinked?" — which actually points at the deeper problem that root README has no project-owned purpose.
4. **There's no project-identity surface in Speck.** PROMISE lives in `product-contract.md` (3 levels deep); PROVE lives in `evidence-contract.md` + `project-state.md` (also deep); the README slot — the most-visible artifact on GitHub, on `ls`, in any IDE file tree, in any code-quality scan — is occupied by Speck self-promotion instead of project identity.
5. **The methodology has a taxonomy gap**: PROMISE / BUILD / PROVE doesn't have a category for **PUBLIC FACE / FIRST IMPRESSION** (README + landing-page hero + GitHub repo description + package.json description). This category exists and matters, but Speck has no opinion about it and no skill for it.

---

### The observed Flyt experience

**Session timeline**:

1. `speck init` ran on a fresh `flyt` workspace; created `README.md` at root with content beginning `# Speck 🥓 ... Spec-driven development methodology...`
2. Claude wrote the full Platform foundation: project.md, product-contract.md, evidence-contract.md, context.md, compliance/foundations.md, 4 research artifacts, domain-model.md, ux-strategy.md, constitution.md, architecture.md, design-system.md + primitives.md, PRD.md, epics.md, 9 epic placeholders, 38 DECs. ~10000+ lines of project-specific work.
3. `git init` + first commit + push to `https://github.com/Keegil/flyt` (created via `gh repo create`)
4. **A GitHub visitor lands on the repo and sees: "# Speck 🥓 — Spec-driven development methodology..."** — not a single word about Flyt, the Norwegian Reformer studio management platform, the agentic operator wedge, the pilot timeline, or any of the 10000+ lines of project-specific specification work.

The user (founder Kjetil) caught this immediately when asked to think about Speck cleanliness — surfacing it as the most consequential methodology gap encountered in the session.

**Verified upgrade behavior**: Checked `packages/cli/lib/sync.js` and confirmed `isReadmeCustomized` returns false unless the first line literally differs from the template source first line. The fix to keep one's READMEs is to change `# Speck 🥓` → `# Flyt` (or similar). But that's a fragile lock — any future template-side rename of `# Speck 🥓 v7` or whatever and the check unjams again, possibly silently. And first-time users wouldn't know to change it.

---

### Why "symlink the two READMEs" isn't the right fix

The user's first instinct was: "two READMEs is silly; maybe symlink them?" That fixes the duplication but not the underlying confusion:

- **A symlinked README still says "Speck"** at root — same identity confusion
- **It conflates two different audiences**: root README = "what is this project, for humans landing on GitHub"; `.speck/README.md` = "what is Speck methodology, for AI agents and contributors learning the system"
- **GitHub renders root README on the repo page**; that real estate is precious and product-focused
- **The actual fix is to STOP occupying the root slot**, not to share content with the methodology doc

---

### Recommended fix — three tiers

#### Tier 1 (must-fix): `speck init` should not write Speck content to root README

**Behavior change**:
- `speck init` checks if `README.md` exists at root
  - If exists: NEVER overwrites (current behavior already correct for brownfield)
  - If absent: write a **project-skeleton README**, not Speck self-promotion content
- `speck upgrade` NEVER touches root README.md (current first-line heuristic is unsafe)

**Project-skeleton README content** (what `init` should write when absent):

```markdown
# [Project Name]

> [One-line elevator pitch — what is this product/service/system?]

**Status**: Spec phase · See [project-state.md](specs/projects/PROJECT_ID/project-state.md) for current readiness.

## What is this?

[Project description — placeholder for user to fill]

## Getting started

[How to use / install / contribute — placeholder]

## Architecture

See [architecture.md](specs/projects/PROJECT_ID/architecture.md).

## Promise

See [product-contract.md](specs/projects/PROJECT_ID/product-contract.md).

---

<!-- SPECK:START -->
Built with [Speck 🥓](https://github.com/telum-ai/speck) — evidence-driven specification methodology.
Methodology docs: [.speck/README.md](.speck/README.md) · Project state: [project-state.md](specs/projects/PROJECT_ID/project-state.md) · Decisions: [project-decisions-log.md](specs/projects/PROJECT_ID/project-decisions-log.md)
<!-- SPECK:END -->
```

This gives the user a real project-identity scaffold with sensible cross-references; the SPECK:START..END markers (same pattern as AGENTS.md) let Speck update its small footer block on upgrade without touching user content.

#### Tier 2 (high-value): make project README a first-class Speck artifact

**New skill: `/project-readme`**:
- Generates/refreshes the root README's managed sections from project artifacts
- Pulls from: `product-contract.md` paid promise, `project.md` vision, `project-state.md` current readiness, latest validated epic, key DECs
- Pattern parallel to `regenerate-project-state.sh` — there's a managed envelope and a user-owned envelope
- Could fire as part of `/project-state` regeneration, OR be invokable standalone, OR auto-fire on certain readiness-state transitions

**Why this matters**: the README is the highest-leverage drift surface. A project's identity drifts most visibly when its README and its actual product diverge. Speck's whole game is drift detection between PROMISE and PROVE; the README is where that drift becomes externally embarrassing. Speck without a README skill leaves the most-visible artifact unmanaged.

**Implementation note**: the skill should NOT be aggressive about overwriting. Suggested mechanic: user-owned content (above the managed footer block) is read-only to Speck; managed footer (between SPECK:START..END markers) auto-updates with status badge + cross-references to current truth artifacts.

#### Tier 3 (methodology evolution): name the PUBLIC FACE / FIRST IMPRESSION pillar

**Current Speck taxonomy**:
- PROMISE — `product-contract.md`
- BUILD — `spec.md`, `tasks.md`, `experience-chain.md`
- PROVE — `project-state.md`, `evidence-contract.md`, runtime LARP

**Missing pillar**: there's a fourth category that PROMISE / BUILD / PROVE don't cover — the artifacts that constitute the project's **public face** / **first impression**:

- Root `README.md` (GitHub repo landing)
- `package.json` `description` field
- Landing page hero copy (for products with marketing pages)
- GitHub repo description (the one-liner at the top of the repo page)
- Possibly app store listing copy (for products with native apps)
- Possibly social preview image / Open Graph tags

These are NOT promise (they're how the promise is *presented to outsiders*); not build (they're declarative artifacts, not work-tracking); not prove (they're claims, not evidence). But they're high-leverage drift surfaces because they're the most-visible artifacts a project has.

**Naming candidates**: PRESENT, PROJECT, PROFILE, FACE, FRONT. I'd vote for **PROFILE** — short, evocative, doesn't collide with PROMISE, captures "this is how the project profiles itself to outsiders." But the maintainer team should pick.

**Mental model extension**:

```
PROMISE          BUILD            PROVE
(the contract) → (the work)   →   (the truth)
                       ↑               │
                       └── drift ──────┘
            
                       │
                       ↓
                   PROFILE
              (the public face)
            drift-checks against
            PROMISE + PROVE on
            external surfaces
```

PROFILE artifacts derive from PROMISE (what we promise) + PROVE (what's currently true) and surface them to GitHub visitors / npm browsers / first-time contributors. A PROFILE skill would keep these surfaces in sync.

---

### Brownfield case study

Speck has a `speck-catch-up` skill that handles v6→v7 migration on existing projects. There's a parallel hole for brownfield README handling:

- If a brownfield project (existing real README) does `speck init`, the README is correctly preserved (verified — `isReadmeCustomized` returns true if any content differs)
- BUT: there's no Speck signal saying "your README and your project artifacts may have drifted" — no `/recheck` extension, no Speck-driven badge or freshness signal

A PROFILE-pillar skill would extend `speck-catch-up` to flag README/product-contract drift on brownfield projects.

---

### Concrete action items for maintainers (in priority order)

1. **(P0)** Stop writing Speck-marketing README to root on `speck init`. Either skip entirely or write a project-skeleton README per Tier 1 spec.
2. **(P0)** Remove root `README.md` from the `speck upgrade` smart-merge path (or replace `isReadmeCustomized` first-line heuristic with "always skip if exists" — same effect, less subtle).
3. **(P1)** Document the dual-README distinction explicitly in `.speck/README.md` and in `speck init` output: "Your project's README is your responsibility; Speck's README lives at `.speck/README.md`."
4. **(P2)** Build `/project-readme` skill per Tier 2; include in Platform-level required artifact list.
5. **(P3)** Promote PROFILE (or chosen name) to first-class Speck pillar; extend mental model + AGENTS.md taxonomy.

---

### The Flyt-specific damage

Forgetting hypothetical improvements for a moment: as of right now, https://github.com/Keegil/flyt shows `# Speck 🥓` as the project's identity. The Flyt project just wrote a real Flyt README locally to fix this for the specific case — but every other Speck user is starting from the same anti-pattern and most don't notice it until much later (or at all).

---

### Methodology synchronicity note

This is the SECOND time in this session that a real product-improvement signal surfaced organically:

1. **Earlier**: Claude made the `/project-validate` ordering error (treating it as pre-execution); user caught it; v7.5.1 release notes literally describe fixing this same misunderstanding in skills. Upstream-fix landed before bad-pattern fossilized.
2. **Now**: User catches the root-README ownership issue while doing a "let's clean up everything" pass.

Both signals came from a single thoughtful user doing thorough discipline. The Speck methodology surfaces design issues through use; the feedback loop is working. This is, in itself, validation of the Speck approach — but it's also a strong signal that opinionated upstream defaults (like which file Speck claims at root) deserve repeated scrutiny.

---

## Context (auto-collected, no source code)

### Projects in this workspace

- **001-flyt-ai-first-studio-management-platform**: recipe=`(none)`, play_level=`(unset)`, archetype=`(unset)`, speck_version=`(unstamped)`

### Friction signals detected

_No automatic friction signals — clean state._

---

## Submitting this feedback

Speck does **not** send anything automatically. If you want to share this with the Speck team:

1. **Review the file** — redact anything you don't want public
2. Open a new GitHub issue: https://github.com/telum-ai/speck/issues/new
3. Paste the content of this file
4. Add a title like `Feedback: methodology — <one-line summary>`

Or if you just want this for your own records, keep it locally and commit it (or don't).

---

*Generated by `npx speck feedback` — no network calls were made.*