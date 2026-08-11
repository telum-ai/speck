# epic-architecture / seams

Use this node only when the epic crosses a service, package, team, trust, or external-system boundary.

For every seam, define:

- producer, consumer, and owner;
- request, response, event, or data contract;
- authentication, authorization, tenant, and sensitive-data boundary;
- timeout, rejection, partial-success, duplicate, retry, cancellation, and recovery behavior that applies;
- compatibility and migration expectations;
- observability needed to distinguish success, delay, and terminal failure;
- the executable contract or integration probe that will prove the seam.

Map ordering and consistency explicitly when more than one system mutates state. Prefer the smallest interface that preserves the epic promises. Use a diagram only when it makes component or event relationships clearer than the contract list.

Research external integration behavior through `just-in-time-research` before locking it. Unknown provider behavior stays an open decision; examples must not become invented requirements.

Write the retained seam contracts into `epic-architecture.md`, then ensure `epic-plan` and later story boundaries can trace to them.
