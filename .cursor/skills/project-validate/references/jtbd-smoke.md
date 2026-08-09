# project-validate / jtbd-smoke

## 6. JTBD smoke test (required centerpiece)

1. Primary JTBD from `project.md`.
2. Cold-start as new user — no dev headers, UUID fields, terminal/API shortcuts.
3. Record steps, dead ends, confusion.
4. Cross-epic flows: test every dependency arrow in `epics.md` (data/auth/navigation).
5. Multi-platform: core JTBD completable on each supported platform; secondary-only deferrals OK.
6. **Legibility** (5-second test): user articulates what product is, why it matters, primary CTA. Fail → `LEGIBILITY.P1`, cap below `SHIP-RC`.

| JTBD result | Project status |
|-------------|----------------|
| COMPLETE + legibility PASS | GO (if all other gates pass) |
| PARTIAL or LEGIBILITY.P1 | CONDITIONAL — cap below SHIP-RC |
| BLOCKED | NO-GO |

Report section: core journey table, cross-epic flows, platform coherence, dead ends, scaffolding remaining.
