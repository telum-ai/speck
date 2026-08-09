# INTEGRATION-GREEN

When §7 services or DB-backed:
- One real round-trip per §7 service (not mock-only); capture logs/traces.
- DB-backed + `DATABASE_URL`: `validate-schema-drift.sh --live --strict --target "$DATABASE_URL"` + real write path.
- No `DATABASE_URL` → do NOT ✅ schema; deferral `evidence-pending`.
- No §7 and not DB-backed → auto-pass INTEGRATION-GREEN.

Deferrals: every row needs `Cap Status` = `evidence-pending` | `implementation-pending`.
`implementation-pending` → cap `NO-SHIP`.
Named infra blocker for INTEGRATION-GREEN cap → logged reproduced LARP failure (P3).
