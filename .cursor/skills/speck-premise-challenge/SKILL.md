---
name: speck-premise-challenge
description: Challenges the assumptions and value behind a commitment. Use before a high-impact lock or when evidence undermines it.
---

# speck-premise-challenge

Challenge whether the proposed commitment should exist before optimizing how to build it. This applies to product behavior, technical architecture, data collection, integrations, operations, pricing, and high-impact UI.

## Run the challenge

1. Name the promised outcome, affected user or operator, and the assumption that makes this commitment necessary.
2. Test the do-nothing case and the cheapest credible substitute. For commercial promises, include general-purpose AI, spreadsheets, manual service, and free tiers.
3. Ask what mechanism causes the outcome, what evidence would falsify the premise, and whether that evidence already exists.
4. Surface costs and externalities: user friction, lock-in, privacy, maintenance, reversibility, failure blast radius, and opportunity cost.
5. Separate a wrong premise from a sound premise with a weak implementation.

If the premise fails, stop the lock or downstream work and route the affected scope through `adjust` at story, epic, or project level. If the premise holds only because of a real constraint, record the constraint and alternatives with `speck-decision-log`.

`speck-premise-challenge` tests whether the commitment is worth pursuing. `speck-skeptical-review` compares viable alternatives after that. `speck-audit` attacks the implementation after it exists.
