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
- Toolkit-agnostic code depends only on the standard library and other toolkit-agnostic code (no SDK, no concrete toolkit).
- Keep DTOs and wire-format concerns on adapter/toolkit-specific sides.
- Export types that cross the `core/adapter` boundary as required by ADR 0005.
- Use established glossary terminology and model suffixes (`Ref`, `Spec`, `Rec`, `Mod`, `Snap`).

See `docs/agents/architecture.md`.

## Scope and compatibility

- Make the smallest coherent change; keep unrelated cleanup in its own change.
- Preserve existing behavior unless the task explicitly changes it.
- Treat exported APIs, SDK DTOs, serialized formats, protocols, database/persisted data, CLI/config interfaces, and cross-component contracts as compatibility-sensitive.
- Breaking changes need explicit justification and, when architectural, an ADR or migration plan.

See `docs/agents/compatibility.md` and `docs/agents/dependencies.md`.

## Testing and generated code

- Test observable behavior and contracts.
- Add regression coverage for reproducible bugs.
- Use integration/e2e tests when the real boundary is what matters.
- When CI fails, fix the behavior the test asserts; keep meaningful tests intact.
- Change generated output by editing its source and regenerating reproducibly.

See `docs/agents/testing.md` and `docs/agents/generated-code.md`.

## Security and Git safety

- Load secrets and sensitive environment data at runtime from a secret store or environment; code, commits, and logs reference them by name only.
- Use development credentials for local work; reserve production credentials for production.
- Resolve the issue a security check reports, leaving the control in force.
- Destructive operations require explicit authorization.
- Work through a branch and PR; land changes on `main`/trunk via PR.
- Treat existing history and work as append-only; rewrite history or discard work only when explicitly requested.

See `docs/agents/security.md` and `docs/agents/git.md`.

## Canonical commands

Prefer repository Taskfiles and stage-appropriate entrypoints:

- `task sources`, `task engine:sources`
- `task binaries`, `task engine:binaries`
- `task engine:tests:unit`, `task engine:tests:it`, `task engine:tests:e2e`
- `task distros`

If no suitable canonical task exists, use a direct command only when safe and explain the substitution.

Run commands in another directory via the shell tool's `workdir` parameter, so the line starts with the verb the allow-list matches. Start with the verb and its subcommand: a leading `cd <dir> &&`, `git -C <dir> <sub>`, or `git --no-pager <sub>` puts a flag ahead of the subcommand, which defeats every allow-list entry and forces an approval prompt.

Inspect with `Read`/`Grep`/`Glob` and edit with `Edit`/`Write`; these match the bash allow-list. Shelling out to `cat`, `head`, `tail`, `find`, `sed`, or `perl` sits off the allow-list and forces an approval prompt.

## Done means

A change is complete when the requested behavior is implemented, relevant checks are green or explicitly reported, generation/formatting requirements are satisfied, and the final diff contains only intended changes.

The development stages are:

`modification → stabilization → verification → finalization`.

See `docs/agents/ci.md` for stage semantics and CI gates.
