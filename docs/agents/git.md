# Git and PR Safety

- Never commit directly to `main` or `trunk`.
- Use a feature/task branch and integrate through a PR.
- Branch from a freshly fetched remote base: `git fetch origin` first, then branch off `origin/<base>` (e.g. `origin/main`), never off a possibly-stale local ref. Confirm with `git rev-parse origin/main; git rev-parse main` — a stale local `main` splits the branch from the wrong tree.
- Do not create commits unless the user explicitly requests a commit.
- Never amend, rebase, squash, reset, or force-push existing history unless explicitly requested.
- Preserve unrelated worktree changes; never discard user work.
- Inspect `git status`, `git diff`, and relevant history before committing.
- Stage only files belonging to the task.
- Never commit secrets or generated local credentials.
- Do not modify git configuration, skip hooks, use interactive `-i` operations, or create empty commits unless explicitly requested.
- If a PR already exists, inspect its state before deciding whether a new branch/PR is appropriate.

## Branch naming

- When a branch is associated with a GitHub issue, include the issue number in the branch name.
- Prefer `<type>/<issue-number>-<short-description>`, for example `fix/123-ci-workflow-names`.
- Use a short, lowercase, hyphen-separated description.
- When there is no associated issue, use `<type>/<short-description>`, for example `docs/branch-naming`.
