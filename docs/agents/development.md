# Development Guidance

## Change discipline

- Start from the requested behavior and identify the smallest coherent change.
- Preserve existing APIs and behavior unless the task explicitly requires otherwise.
- Prefer existing patterns and utilities over introducing new abstractions.
- Avoid drive-by cleanup, unrelated renames, and broad refactors.

## Workflow

1. Inspect status/diff and relevant code.
2. Read applicable glossary and ADRs.
3. Trace the real boundary being changed.
4. Make the smallest implementation change.
5. Run focused checks while iterating.
6. Run the stage-appropriate canonical Taskfile checks.
7. Review the final diff for scope and accidental changes.

## Taskfiles

Prefer root and component Taskfiles. If a canonical task fails, inspect what it actually runs before substituting a direct command. Never silently replace a required check with an unrelated shortcut.

## Dependencies and compatibility

- Prefer established, well-maintained libraries over custom implementations.
- A new dependency requires user approval.
- Backward compatibility is not a goal within the workspace; update all affected consumers. If external consumers or contracts may be affected, stop and ask.

## Go workspace and generated files

- Do not modify `go.work`, `go.work.sum`, or add or modify `replace` directives without an explicit request.
- Do not hand-edit generated files such as `*.pb.go` or mocks.
- Do not hand-edit `go.sum`; use Go tooling to update it.
- Before committing, run `task sources:prepare` in each changed repository that defines it.
- If generated files need updating and the task is undefined or fails, stop and report rather than improvising.

## Checks and review

- Review the diff before committing and include only intended changes.
- If unintended changes appear (for example, from code generation), stop and report; do not revert or discard them.
- Hooks enforce linters and tests. Run targeted checks directly (for example, `go test ./pkg/foo -run TestBar`) and run any checks the hooks do not cover or fail to run.
- Never claim a check passed unless it ran.
