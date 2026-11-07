# Git and PR Safety

- Before the first edit in a repo, `git status --porcelain` must be empty. Otherwise stop and report; never stash, reset, clean, or overwrite existing work.
- Every task must have a ticket ID. If the user has not supplied one, ask; never invent one.
- Create `<type>/<TICKET-123>-<short-name>` from the default branch (`<type>` as in Conventional Commits). Use the same branch name across related repos. If the branch already exists or the default branch is unclear, stop and ask.
- Commits are allowed by default when they are part of completing the task; ask only when the user has restricted commits or the task context is unclear.
- Commit in the repo that owns the file. Use a single-line English Conventional Commit message with the ticket at the end, e.g. `feat(scope): summary [TICKET-123]`.
- Never commit directly to `main` or `trunk`; integrate through a PR.
- Never push a task branch unless the user explicitly asks for a push or requests an operation (such as creating/updating its PR) that necessarily requires publishing that branch. In the latter case, publish only the relevant task branch.
- Never bypass hooks (`--no-verify`, editing hook config); on failure, fix the cause and retry.
- Never amend, rebase, squash, reset, or force-push existing/published history unless explicitly requested.
- Preserve unrelated worktree changes; never discard user work.
- Inspect `git status`, `git diff`, and relevant history before committing. Stage only files belonging to the task.
- Never commit secrets or generated local credentials.
- Do not modify Git configuration, use interactive `-i` operations, or create empty commits unless explicitly requested.
- If a PR already exists, inspect its state before deciding whether a new branch/PR is appropriate.

## Branch naming

- The ticket ID is mandatory, including for documentation and maintenance tasks.
- Prefer `<type>/<TICKET-123>-<short-description>`, for example `fix/123-ci-workflow-names`.
- Use a short, lowercase, hyphen-separated description.
