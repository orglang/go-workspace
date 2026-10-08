# CI and Verification

CI has two related models:

- development stages: `modification → stabilization → verification → finalization`;
- delivery stages: `prepare → check1 → install → check2 → publish`.

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

The general artifact delivery model is:

- **prepare**: create/build the artifact.
- **check1**: lightweight validation or smoke of the artifact in isolation; it must not require the target environment.
- **install**: materialize/deploy the artifact into the target local environment.
- **check2**: E2E verification of the installed artifact in that environment.
- **publish**: optionally publish the verified artifact to an external destination.

Each artifact maps these stages to its own concrete commands and storage mechanism. The lifecycle is the common interface; the implementation is artifact-specific.

For `go-engine`, the source delivery mapping is:

| Delivery stage | go-engine |
| --- | --- |
| prepare | `sources:prepare` — format and generate the source artifact |
| check1 | `sources:check` — `pre-commit` runs the linters during `git commit` |
| install | `git add + git commit` |
| check2 | `sources:verify` — `pre-push` runs unit tests |
| publish | `git push` |

Hooks are installed with `task hooks:install`. `task sources:generate` performs goverter generation without changing the Git index.

Source delivery is a Git workflow, not a separate reusable GitHub Actions workflow in `go-workspace`.

## Repository ownership

`go-workspace` owns reusable artifact workflow orchestration because it knows the workspace graph and the `sources → binaries → distros` path.

The repository containing the change owns the GitHub event adapter. For `go-engine`:

- the caller workflows own `pull_request` and `merge_group` events;
- caller workflows invoke reusable artifact workflows from `go-workspace`;
- callers pass the exact engine revision under test;
- reusable workflows must not silently replace that revision with `main`.

GitHub Actions events are scoped to the repository containing the workflow, so event-specific logic cannot be moved into `go-workspace` alone.

## PR and merge-queue flow

CI retains a protective Sources Check on `pull_request.opened`, including draft PRs. It checks formatting and unit tests and serves as an early signal for source changes.

For merge candidates, required Binaries and Distros caller checks remain the delivery gates. The merge-group run verifies the actual merge candidate.

## Stable required checks

Caller jobs for reusable workflows must keep their check name stable across events.

Do not skip the caller job itself with an event-specific `if`:

```yaml
jobs:
  binaries:
    if: ...
    uses: orglang/go-workspace/.github/workflows/binaries.yaml@main
```

Instead, invoke the reusable workflow and pass an explicit boolean `run` input. The internal workflow job owns the `if: inputs.run` condition. This prevents GitHub from producing different caller-level and called-job check names.

## Reusable-workflow contract

The artifact workflows are the interface between repository-local event adapters and workspace CI.

Required inputs:

| Input | Meaning |
| --- | --- |
| `engine_ref` | Exact `go-engine` revision to test. |
| `sdk_ref` | Exact `go-sdk` revision to use. |
| `workspace_ref` | Workspace revision containing the workflow and Taskfiles. |
| `run` | Whether the workflow's internal job should execute; defaults to `true`. |

Callers must not parse log text to determine success. Use GitHub's workflow/job result. A richer result interface may be added later without changing the caller's semantic contract.

Keep workflow permissions least-privilege. Prefer `contents: read`; request additional permissions only when a stage genuinely needs them. Do not pass long-lived credentials through workflow inputs.

## Stage-specific invariants

- The artifact graph is `sources → binaries → distros`.
- Every artifact delivery is described through `prepare → check1 → install → check2 → publish`.
- `check1` is lightweight and isolated; `check2` is E2E against the installed artifact.
- Each artifact maps the common lifecycle to concrete commands and storage operations.
- Source delivery remains a Git workflow rather than a reusable source workflow.
- Required checks keep stable caller-level names while their implementation moves.
- Event-specific policy is expressed through caller inputs.
- CI tests the exact revisions intended for merge.

## Verification after a PR update

After updating a PR:

1. Inspect the actual checks/status.
2. Investigate failures rather than rerunning blindly.
3. Distinguish skipped, unavailable, running, and successful checks.
4. Do not claim verification is complete until the relevant checks are green.

See `development.md` for the change workflow and the component Taskfiles for concrete commands.
