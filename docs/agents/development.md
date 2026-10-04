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
