# CI and Verification

The repository models delivery as:

`check1 → prepare → check2 → publish`

and development as:

`modification → stabilization → verification → finalization`.

## Stage intent

- **modification**: sources, formatting, static analysis, generation, focused unit tests.
- **stabilization**: compilation/linking plus unit/integration verification.
- **verification**: packaging and system/e2e verification.
- **finalization**: full acceptance after merge.

Prefer canonical Taskfile entrypoints matching the stage. Do not assume that a local pass means CI will pass.

After pushing/updating a PR:

- inspect the PR checks/status;
- investigate failures instead of rerunning blindly;
- report skipped or unavailable checks explicitly;
- do not declare success until the relevant checks are actually green.

For long-running e2e/distros checks, distinguish “still running” from “passed”.
