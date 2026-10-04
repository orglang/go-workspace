# Compatibility Guidance

Treat these as compatibility-sensitive:

- exported Go APIs;
- SDK DTOs and serialized/wire formats;
- public protocols;
- database schemas and persisted data;
- CLI/configuration interfaces;
- cross-component contracts.

Before a potentially breaking change, identify consumers and migration requirements. A breaking architectural or contract change should have an ADR and, where applicable, a migration/rollback plan.

Do not introduce compatibility shims without a concrete reason; avoid speculative abstractions.
