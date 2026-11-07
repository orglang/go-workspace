# Tooling Guidance

## Bash

- Do not use redirects (`>`, `>>`, `<`, `2>&1`, heredocs), command chaining (`&&`, `;`, `|`), or subshells. Run one simple command per call.
- Create and edit files with dedicated edit/write tools, never through shell commands.
- Use glob, grep, and read tools instead of `find`, `cat`, or `grep` shell commands.
- Set the repository directory via the tool's `workdir`; do not use `cd` or `git -C`.
- After a permission denial, switch to an appropriate tool or ask the user; never work around the denial.
