# Organization Language and its Runtime

## Purpose

This is the repository-wide operating contract for coding agents. Keep it short and stable; task-specific guidance lives under `docs/agents/`, and procedural workflows live in `.opencode/skills/`.

## Start here

Before changing code:

1. Inspect the current worktree/diff and preserve unrelated work.
2. Read `GLOSSARY.md` (or `GLOSSARY-MAP.md` where present) and relevant ADRs.
3. Read `docs/agents/development.md` and the guidance relevant to the change.
4. Identify the smallest coherent change that satisfies the request.

## Repository map

- `.github/`: GitHub Actions and automation
- `.opencode/`: agent configuration and skills
- `rationale/`, `sdk/`, `engine/`, `stack/`: repository components
- `docs/adr/`: architecture decisions
- `docs/agents/`: stable agent guidance
- `GLOSSARY.md`: controlled domain vocabulary
- `taskfile.yaml`: root Taskfile

Related repositories: `github.com/orglang/rationale`, `github.com/orglang/go-sdk`, and `github.com/orglang/go-engine`.

## Non-negotiable architecture rules

- Preserve the core/adapter boundary and dependency direction.
- Toolkit-agnostic code must not import the SDK or a concrete toolkit.
- Keep DTOs and wire-format concerns on adapter/toolkit-specific sides.
- Export types that cross the `core/adapter` boundary as required by ADR 0005.
- Use established glossary terminology and model suffixes (`Ref`, `Spec`, `Rec`, `Mod`, `Snap`).

See `docs/agents/architecture.md`.

## Scope and compatibility

- Prefer the smallest coherent change; avoid unrelated cleanup.
- Preserve existing behavior unless the task explicitly changes it.
- Treat exported APIs, SDK DTOs, serialized formats, protocols, database/persisted data, CLI/config interfaces, and cross-component contracts as compatibility-sensitive.
- Breaking changes need explicit justification and, when architectural, an ADR or migration plan.

See `docs/agents/compatibility.md` and `docs/agents/dependencies.md`.

## Testing and generated code

- Test observable behavior and contracts.
- Add regression coverage for reproducible bugs.
- Use integration/e2e tests when the real boundary is what matters.
- Do not weaken meaningful tests merely to make CI pass.
- Never hand-edit generated output; update its source and regenerate reproducibly.

See `docs/agents/testing.md` and `docs/agents/generated-code.md`.

## Security and Git safety

- Never expose, copy, commit, or log secrets or sensitive environment data.
- Do not use production credentials for local development.
- Do not disable security controls merely to make a check pass.
- Destructive operations require explicit authorization.
- Work through a branch and PR; do not write directly to `main`/trunk.
- Do not rewrite existing history or discard existing work unless explicitly requested.

See `docs/agents/security.md` and `docs/agents/git.md`.

## Canonical commands

Prefer repository Taskfiles and stage-appropriate entrypoints:

- `task sources`, `task engine:sources`
- `task binaries`, `task engine:binaries`
- `task engine:tests:unit`, `task engine:tests:it`, `task engine:tests:e2e`
- `task distros`

If no suitable canonical task exists, use a direct command only when safe and explain the substitution.

## Done means

A change is complete when the requested behavior is implemented, relevant checks are green or explicitly reported, generation/formatting requirements are satisfied, and the final diff contains only intended changes.

The development stages are:

`modification → stabilization → verification → finalization`.

See `docs/agents/ci.md` for stage semantics and CI gates.
