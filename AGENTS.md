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
- Read `docs/agents/` guidance relevant to the task; start with `development.md`.
- Task-specific workflows belong in `.opencode/skills/`; do not duplicate them here.

## Before changing code

1. Inspect the current worktree/diff and preserve unrelated work.
2. Read `GLOSSARY.md` (or `GLOSSARY-MAP.md` where present) and relevant ADRs.
3. Read the applicable guidance under `docs/agents/`.
4. Identify the smallest coherent change that satisfies the request.

## Non-negotiable architecture rules

- Preserve the core/adapter boundary and dependency direction.
- Toolkit-agnostic code must not import the SDK or a specific toolkit.
- DTOs and wire concerns belong on adapter/toolkit-specific sides.
- Types crossing the `core/adapter` boundary are exported as required by ADR 0005.
- Use established model suffixes (`Ref`, `Spec`, `Rec`, `Mod`, `Snap`) and glossary terminology.

See `docs/agents/architecture.md`.

## Scope and compatibility

- Make the smallest coherent change; avoid unrelated refactors.
- Do not rename public APIs, update dependencies, regenerate unrelated files, or change CI unless required.
- Preserve existing behavior unless the request explicitly changes it.
- Treat exported Go APIs, SDK DTOs, serialized formats, protocols, database schemas, persisted data, CLI/config interfaces, and cross-component contracts as compatibility-sensitive.
- Breaking changes require explicit justification and, where architectural, an ADR/migration plan.

See `docs/agents/compatibility.md` and `docs/agents/dependencies.md`.

## Testing and generated code

- Test behavior and contracts, not changed line count.
- Add regression coverage for reproducible bugs.
- Use integration/e2e tests when the real boundary is what matters.
- Do not weaken meaningful tests merely to make CI pass.
- Never hand-edit generated output; update its generator/input and regenerate reproducibly.

See `docs/agents/testing.md` and `docs/agents/generated-code.md`.

## Security and Git safety

- Never expose, copy, commit, or log secrets or sensitive environment data.
- Do not use production credentials for local development.
- Do not disable security checks to make a change pass.
- Destructive operations require explicit authorization.
- Never write directly to `main`/trunk; use a branch and PR.
- Do not amend, rewrite, squash, force-push, or discard existing work unless explicitly requested.
- Do not create commits automatically unless the user explicitly asks for one.

See `docs/agents/security.md` and `docs/agents/git.md`.

## Canonical development commands

Prefer repository Taskfiles and stage-appropriate entrypoints:

- `task sources`, `task engine:sources`
- `task binaries`, `task engine:binaries`
- `task engine:tests:unit`, `task engine:tests:it`, `task engine:tests:e2e`
- `task distros`

If no suitable canonical task exists, use the underlying direct command only when safe and explain why.

## Definition of done

A change is complete when:

1. The requested behavior is implemented.
2. Relevant tests and canonical checks pass, or failures are explicitly reported.
3. Formatting/static-analysis/generation requirements are satisfied.
4. No unrelated files or behavior changed.
5. Documentation is updated when the change warrants it.
6. The final diff contains only intended changes.
7. PR/CI state is checked when applicable.

The development coordination model is:

`modification` → `stabilization` → `verification` → `finalization`.

See `docs/agents/ci.md` for stage gates and CI details.
