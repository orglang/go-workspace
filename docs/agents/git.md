# Git and PR Safety

- Never commit directly to `main` or `trunk`.
- Use a feature/task branch and integrate through a PR.
- Branch from a freshly fetched remote base: `git fetch origin` first, then branch off `origin/<base>` (e.g. `origin/main`), never off a possibly-stale local ref. Confirm with `git rev-parse origin/main; git rev-parse main` — a stale local `main` splits the branch from the wrong tree.
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

## GitHub API-only workflow

- A local checkout is preferred, but its absence is not by itself a blocker. When no local workspace is available, repository inspection and changes may be performed through the GitHub API.
- In API-only work, read the applicable bootstrap files and explicitly activated instructions first; identify the owning repository and its default branch; verify the task branch state; and create a task branch from the default branch when one does not already exist. If a branch already exists, do not overwrite or repurpose it without the user's explicit direction.
- The local `git status --porcelain` check cannot be performed without a local checkout. Do not claim that a local working tree is clean; inspect the remote base and task-branch state and report that the local status check was unavailable.
- GitHub API commits do not run local Git hooks. Do not represent them as having run or as having been bypassed; report the limitation explicitly and rely on repository CI/required checks where available. Never claim checks passed unless their results were observed.
- Keep API-only changes limited to the requested files. Review the resulting commit/diff before proceeding, and report any checks that could not be run.
