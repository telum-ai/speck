---
name: speck-migrate
description: Upgrades Speck and repairs compatibility state. Use when an upgrade is requested or engagement finds a legacy marker.
---

# speck-migrate

Cheap keys: explicit upgrade request and the three compatibility markers. Select exactly one stage, oldest prerequisite first:

1. `scaffold`: `.speck/.migration-needs-catchup` or a `<!-- v7 MIGRATION SCAFFOLD -->` remains.
2. `proof`: `.speck/.v8-reprove-needed` remains.
3. `graph`: `.speck/.v9-graph-needed` remains.
4. `upgrade`: the user explicitly requested a Speck upgrade and no repair marker is active.

Load only that stage:

```bash
python3 .speck/scripts/context/speck_context.py speck-migrate \
  --select stage=<scaffold|proof|graph|upgrade>
```

Require exit 0 and `SPECK_CONTEXT_RECEIPT`; follow the loaded procedure. The scaffold stage may also parse its documented `--phase` argument without changing the selected stage. Preserve project artifacts and historical proof. Remove a marker only when its procedure's exit conditions are true, then re-enter this skill until no migration marker remains.
