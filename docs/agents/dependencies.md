# Dependency Guidance

- Prefer the standard library and dependencies already present when they solve the problem adequately.
- Add a dependency only when it materially improves correctness, maintainability, or required functionality.
- Consider license, security, maintenance, transitive-dependency, and binary-size implications.
- Keep dependency upgrades separate from functional changes when practical.
- Do not opportunistically upgrade unrelated dependencies while implementing a feature or fix.
- When a dependency is security-sensitive or changes a public/runtime contract, document the reason and relevant compatibility impact.
