# Testing Guidance

- Test observable behavior and contracts, not implementation line counts.
- Add a regression test when fixing a bug whose failure mode can be reproduced.
- Keep focused package tests fast during iteration.
- Use integration tests for real component/service boundaries.
- Use e2e tests for system-level behavior and deployment/package boundaries.
- Do not replace meaningful integration/e2e coverage with mocks merely for convenience.
- Do not delete, weaken, skip, or rewrite tests solely to make CI pass.
- Keep tests deterministic and avoid introducing unnecessary external dependencies.

Choose checks according to the development stage; see `ci.md`.
