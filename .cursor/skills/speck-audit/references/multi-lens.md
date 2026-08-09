# speck-audit / multi-lens

## 2. Role separation (P4)

1. Auditor ≠ implementer (separate subagent / session / model).
2. High-risk default (P0/P1 severity, privacy, security-critical auth/billing): **3+ independent lens auditors** — Security/Privacy · Performance/Scalability · UX/Accessibility.
3. Any lens P0 → BLOCKED. P1 disagreement → majority-refute (2 of 3).
4. Report lists deployed lenses under `## Multi-Lens Audit Team`.

## 14. Compose report + stamp

Write `<dir>/audit-report.md`. Sections: findings by severity (P0/P1/P2/P3), probe results, banned-language, multi-lens roster if used.

```bash
bash .speck/scripts/stamp-truth.sh <dir>/audit-report.md
```
