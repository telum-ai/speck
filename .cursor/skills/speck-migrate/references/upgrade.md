# Version upgrade

1. Read the installed and target versions, release notes, and `docs/history/migrations.md` for retained compatibility behavior.
2. Run the supported CLI upgrade. Inspect its diff and migration ledger; never replace project-owned artifacts wholesale.
3. Run repository validators and `speck-recheck`.
4. If the upgrade creates a compatibility marker, stop this stage and re-enter `speck-migrate`; the marker stages own semantic repair.
