# project-promote / spine

1. Read `.speck/project.json`; missing `play_level` means Platform. Inventory existing PROMISE/BUILD/PROVE artifacts and current readiness.
2. Infer target from explicit request; otherwise Sprint→Build, Build→Platform, and ask before any downgrade.
3. Surface current→target plus artifacts created, requirements activated, and work preserved. Get owner confirmation because play-level changes alter the product process contract.
4. Never delete prior artifacts on downgrade; mark them retained while reducing required depth.
5. After the selected transition, update `play_level`, `promoted_from`, and `promoted_at`; regenerate project state and report ordered next actions.
