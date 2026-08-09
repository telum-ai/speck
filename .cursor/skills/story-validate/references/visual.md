# Visual / UX

SKIP when `visual_testing.platform` is `api` or `cli`.

Load recipe `_active_recipe` → `.speck/recipes/[recipe]/recipe.yaml` → `visual_testing:`.
Then Read exactly one host: `.cursor/skills/visual-testing/references/<host>.md`.
Also load: `design-system.md`, `ux-strategy.md`, `ui-spec.md`, epic `wireframes.md` if present.

Scope: 1–3 impacted screens; default + loading + empty + error + one interaction.
`NEEDS_WORK`/`UGLY` → cap at `IMPL-GREEN`.
Multimodal: `Read` screenshots — judge pixels, not code alone.
