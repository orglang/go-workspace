# CI and Verification

CI has two related models:

- development stages: `modification → stabilization → verification → finalization`;
- delivery stages: `sources:prepare → commit → sources:verify → publish`.

The canonical artifact path is:

`sources → binaries → distros`.

## Development stages

| Stage | Intent | Typical checks |
| --- | --- | --- |
| modification | Validate source changes quickly | formatting, generation, static analysis, focused unit tests |
| stabilization | Validate buildable artifacts and real dependencies | compile/link, integration tests |
| verification | Validate the packaged system | e2e, packaging, backward compatibility |
| finalization | Accept and publish the merged result | full acceptance, required gates, publish |

Prefer the repository Taskfiles that correspond to the stage. A local pass does not by itself establish that CI will pass.

## Delivery stages

For `go-engine`, source delivery is enforced locally by versioned Git hooks:

- **sources:prepare**: `pre-commit → task sources:prepare`; format/fix and stage source changes, generate source artifacts and stage them, then run static analysis.
- **commit**: create the source artifact with `git commit`.
- **sources:verify**: `pre-push → task sources:verify`; verify the current HEAD with unit tests.
- **publish**: `git push`.

The hooks are installed explicitly with `task hooks:install`. Installation is never automatic. Repositories may still bypass hooks with normal Git mechanisms; the delivery model does not require special `--no-verify` handling.

`task sources:generate` performs only goverter generation and does not modify the Git index.

A running job is not a success. A skipped internal stage job can be intentional when its caller passes `run: false`.

## Repository ownership

`go-workspace` owns reusable CI orchestration because it knows the workspace graph and the `sources → binaries → distros` path.

The repository containing the change owns the GitHub event adapter. For `go-engine`:

- the caller workflows own `pull_request` and `merge_group` events;
- caller workflows invoke reusable stages from `go-workspace`;
- callers pass the exact engine revision under test;
- reusable workflows must not silently replace that revision with `main`.

GitHub Actions events are scoped to the repository containing the workflow, so event-specific logic cannot be moved into `go-workspace` alone.

## PR and merge-queue flow

The source artifact delivery flow is:

```
modify
  ↓
sources:prepare — pre-commit
  ↓
commit — git commit
  ↓
sources:verify — pre-push
  ↓
publish — git push
```

CI retains a protective, non-required Sources Check on `pull_request.opened`, including draft PRs. It checks formatting and unit tests only. It does not run on `synchronize`, `reopened`, `ready_for_review`, or `merge_group`.

The full Sources CI stage is not part of the `go-engine` PR or merge-queue delivery flow.

For merge candidates, required Binaries and Distros caller checks remain the delivery gates. `merge_group` does not expect a removed Sources check.

The merge-group run verifies the actual merge candidate. Do not add a redundant post-merge binary gate merely to repeat that verification.

## Stable required checks

Caller jobs for reusable workflows must keep their check name stable across events.

Do not skip the caller job itself with an event-specific `if`:

```yaml
jobs:
  binaries:
    if: ...
    uses: orglang/go-workspace/.github/workflows/binaries.yaml@main
```

Instead, invoke the reusable workflow and pass an explicit boolean `run` input. The internal stage job owns the `if: inputs.run` condition. This prevents GitHub from producing different caller-level and called-job check names.

## Reusable-workflow contract

Stage workflows are the interface between repository-local event adapters and workspace CI.

Required inputs:

| Input | Meaning |
| --- | --- |
| `engine_ref` | Exact `go-engine` revision to test. |
| `sdk_ref` | Exact `go-sdk` revision to use. |
| `workspace_ref` | Workspace revision containing the workflow and Taskfiles. |
| `run` | Whether the internal stage job should execute; defaults to `true`. |

Callers must not parse log text to determine success. Use GitHub's workflow/job result. A richer result interface may be added later without changing the caller's semantic contract.

Keep workflow permissions least-privilege. Prefer `contents: read`; request additional permissions only when a stage genuinely needs them. Do not pass long-lived credentials through workflow inputs.

## Stage-specific invariants

- The artifact graph remains `sources → binaries → distros`.
- Source delivery is gated locally by `sources:prepare` and `sources:verify`.
- The protective PR-opened Sources Check is non-required and does not replace the local delivery gate.
- Required checks must remain stable while their implementation moves.
- Moving a workflow must not silently remove an existing required check; provide an explicit replacement.
- Event-specific policy belongs in caller inputs, not in caller-job skipping.
- CI should test the exact revisions that the candidate is intended to merge.
- Multi-ref push handling is outside the `check2` contract.

## Verification after a PR update

After updating a PR:

1. Inspect the actual checks/status.
2. Investigate failures rather than rerunning blindly.
3. Distinguish skipped, unavailable, running, and successful checks.
4. Do not claim verification is complete until the relevant checks are green.

See `development.md` for the change workflow and the component Taskfiles for concrete commands.
