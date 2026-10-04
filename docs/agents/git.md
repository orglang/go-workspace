# Git and PR Safety

- Never commit directly to `main` or `trunk`.
- Use a feature/task branch and integrate through a PR.
- Do not create commits unless the user explicitly requests a commit.
- Never amend, rebase, squash, reset, or force-push existing history unless explicitly requested.
- Preserve unrelated worktree changes; never discard user work.
- Inspect `git status`, `git diff`, and relevant history before committing.
- Stage only files belonging to the task.
- Never commit secrets or generated local credentials.
- Do not modify git configuration, skip hooks, use interactive `-i` operations, or create empty commits unless explicitly requested.
- If a PR already exists, inspect its state before deciding whether a new branch/PR is appropriate.
