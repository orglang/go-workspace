# Organization Language and its Runtime

## Purpose

This file is the repository-wide operating contract for coding agents. Keep it short and stable; detailed guidance lives under `docs/agents/`.

## Repository map

- `.github/`: GitHub Actions and repository automation
- `.opencode/`: OpenCode configuration and skills
- `rationale/`: rationale component
- `sdk/`: SDK component
- `engine/`: runtime component
- `stack/`: system-level definitions
- `docs/adr/`: architecture decisions
- `docs/agents/`: agent-specific guidance
- `GLOSSARY.md`: controlled domain vocabulary
- `taskfile.yaml`: root Taskfile

Related repositories: `github.com/orglang/rationale`, `github.com/orglang/go-sdk`, and `github.com/orglang/go-engine`.

## Instruction hierarchy

- This file applies repository-wide.
- More specific instruction files, when present, apply to their subtree.
- `docs/agents/domain.md` defines how agents consume the glossary and ADRs.
- Task-specific workflows belong in `.opencode/skills/`; do not duplicate them here.

## Before changing code

1. Read `GLOSSARY.md` and the relevant `docs/adr/` entries.
2. Read the applicable guidance under `docs/agents/`.
3. Inspect the current worktree/diff before editing; preserve unrelated user work.
4. Identify the smallest change that satisfies the request.

## Architecture rules

- Preserve the core/adapter boundary and dependency direction.
- Toolkit-agnostic code must not import the SDK or a specific toolkit.
- DTOs and wire concerns belong on adapter/toolkit-specific sides.
- Cross-boundary types are exported as required by ADR 0005.
- Use the repository's model naming conventions: `<model>Ref`, `Spec`, `Rec`, `Mod`, `Snap`.
- Use glossary terminology rather than inventing synonyms.

See `docs/agents/architecture.md` for the detailed boundary and package rules.

## Scope and compatibility

- Make the smallest coherent change; avoid unrelated refactors.
- Do not rename public APIs, update dependencies, regenerate unrelated files, or change CI unless required.
- Preserve existing behavior unless the request explicitly changes it.
- Treat exported Go APIs, SDK DTOs, serialized formats, protocols, database schemas, persisted data, CLI/config interfaces, and cross-component contracts as compatibility-sensitive.
- Breaking changes require explicit justification and, where architectural, an ADR/migration plan.

See `docs/agents/compatibility.md` and `docs/agents/dependencies.md`.

## Testing and generated code

- Test behavior, not changed line count.
- Add regression coverage for bugs.
- Use integration/e2e tests when the real boundary is what matters; do not weaken them merely to simplify the change.
- Never delete or weaken a test just to make CI pass.
- Never edit generated files manually; update the generator/input and regenerate reproducibly.

See `docs/agents/testing.md` and `docs/agents/generated-code.md`.

## Security and destructive operations

- Never expose, copy, commit, or log secrets, tokens, credentials, private keys, or sensitive environment data.
- Do not use production credentials for local development.
- Do not disable security checks to make a change pass.
- Treat database deletion, `docker compose down -v`, `git reset --hard`, `git clean -fd`, force-pushes, resource deletion, and package publication as destructive operations requiring explicit authorization.

See `docs/agents/security.md`.

## Git and PR safety

- Never write directly to `main`/trunk; use a feature/task branch and PR.
- Do not amend, rewrite, squash, force-push, or discard existing work unless explicitly requested.
- Do not modify git config, skip hooks, use interactive `-i` operations, or create empty commits unless explicitly requested.
- Before a commit, inspect status, diff, and relevant history; stage only intended files.
- Do not create commits automatically unless the user explicitly asks for a commit.
- After updating a PR, inspect CI status and report failures/skips rather than assuming success.

See `docs/agents/git.md` and `docs/agents/ci.md`.

## Canonical development commands

Prefer the repository's Taskfiles and stage-appropriate entrypoints:

- `task sources`, `task engine:sources`
- `task binaries`, `task engine:binaries`
- `task engine:tests:unit`, `task engine:tests:it`, `task engine:tests:e2e`
- `task distros`

If no suitable canonical task exists, use the underlying direct command only when safe and explain why. Do not invent a parallel command chain.

## Definition of done

A change is complete when:

1. The requested behavior is implemented.
2. Relevant tests and canonical checks pass, or failures are explicitly reported.
3. Formatting/static-analysis/generation requirements are satisfied.
4. No unrelated files or behavior changed.
5. Architecture/compatibility documentation is updated when the change warrants it.
6. The final diff contains only intended changes.
7. PR/CI state has been checked when applicable.

## Development stages

Use the repository's existing stages as a coordination model:

`modification` → `stabilization` → `verification` → `finalization`.

The detailed CI matrix and stage gates are in `docs/agents/ci.md`.
