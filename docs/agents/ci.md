# CI and Verification

The repository models delivery as:

`check1 → prepare → check2 → publish`

and development as:

`modification → stabilization → verification → finalization`.

## Ownership and event model

`go-workspace` owns the reusable CI orchestration because it knows the workspace graph and the canonical `sources → binaries → distros` delivery path.

The repository containing the change owns the GitHub event adapter:

- `go-engine` owns `pull_request` and `merge_group` triggers;
- its caller workflows invoke the reusable stage workflows from `go-workspace`;
- the caller passes the **exact engine revision under test**;
- the reusable workflow must never silently substitute `main` for the supplied engine revision.

This split is required because GitHub Actions events are scoped to the repository containing the workflow. A workflow stored only in `go-workspace` cannot directly receive a `pull_request` or `merge_group` event from `go-engine`.

### PR and merge-queue flow

The intended `go-engine` event flow is:

```
Draft PR
  └─ opened / synchronize
       ↓
    sources

Ready for review
  └─ ready_for_review / synchronize
       ↓
    binaries

Merge queue
  └─ merge_group
       ↓
    sources + binaries + distros
```

`sources` is the fast modification-stage check and runs throughout the PR lifecycle. `binaries` is the stabilization-stage check and starts when a PR is ready for review. `distros` is the verification-stage gate for the merge-group candidate.

The merge queue validates the actual merge result, so `sources`, `binaries`, and `distros` are required checks for the merge candidate.

A post-merge `binaries` workflow is intentionally not required: the merge-group run is the pre-merge verification of the merge candidate.

## Required-check and reusable-workflow naming

Required checks must have stable names on both PR and merge-group events.

Do not put an event-specific skip condition on the caller job:

```yaml
jobs:
  binaries:
    if: ...
    uses: orglang/go-workspace/.github/workflows/binaries.yaml@main
```

When the caller job itself is skipped, GitHub reports only the caller-level check (for example `CI / binaries`). When the reusable workflow runs, the check includes the called job (for example `CI / binaries / binaries`). Those are different check names.

Instead, the caller always invokes the reusable workflow and passes an explicit boolean `run` input. The reusable workflow owns the `if: inputs.run` condition on its internal job. This pattern is used by both `binaries` and `distros`.

This keeps the check hierarchy stable and allows required checks such as `distros / distros` to be satisfied consistently.

## Reusable workflow contract

The reusable workflow is the stable interface between repository-local event adapters and workspace CI.

### Inputs

| Input | Required | Meaning |
| --- | --- | --- |
| `engine_ref` | yes | Exact `go-engine` commit SHA or ref to test. |
| `sdk_ref` | yes | Exact `go-sdk` commit SHA or ref to check out. |
| `workspace_ref` | yes | `go-workspace` revision containing the reusable workflow and Taskfiles. |
| `run` | no | Boolean controlling whether the internal stage job executes. Defaults to `true`; event-specific skip policy belongs in the caller input expression, not on the caller job. |

Stage-specific reusable workflows select their stage by filename (`sources.yaml`, `binaries.yaml`, `distros.yaml`, etc.).

### Outputs

Stage-specific workflows currently use the workflow/job result reported by GitHub Actions itself. A unified result interface (`result`, `stage`, `engine_sha`) remains a target for the reusable-workflow contract; callers must not parse log text to determine success.

### Permissions and secrets

Default permissions are read-only:

- `contents: read`;
- `checks: read` only when inspection is required.

A stage may request additional permissions only when its implementation needs them, and that requirement must be documented in the stage ticket.

No long-lived credential is passed through workflow inputs. Repository/org secrets remain owned by the repository whose event triggered the run.

## Artifact and stage contract

The artifact graph is:

`sources → binaries → distros`.

The CI matrix maps to the development stages as follows:

| Artifact | Development stage | check1 | prepare | check2 | publish |
| --- | --- | --- | --- | --- | --- |
| `app/sources` | modification | lint/static analysis | generation/formatting | focused unit tests | — |
| `app/binaries` | stabilization | mocks/stubs | compile/link | real-service integration | — |
| `app/distros` | verification | lightweight e2e | packaging | heavyweight e2e + backward compatibility against `gear:latest` | — |
| finalization | finalization | full acceptance | — | required gates | publish `latest` |

The `gear` pipeline follows the same artifact vocabulary where a corresponding stage exists. It is not a blocker edge on the `app` migration chain.

## Stage semantics

- **check1** is the fast precondition check for the artifact.
- **prepare** creates the artifact or runtime state consumed by check2.
- **check2** is the authoritative verification for that artifact.
- **publish** runs only after all required checks are green.
- **running** is not success; long-running e2e/distros jobs remain pending until completion.
- **skipped internal stage jobs** are intentional when the caller passes `run: false`. The caller workflow must still execute so that the reusable-workflow check keeps its stable name.
- **failure** propagates to the originating PR or merge-group candidate.
- **success** means every required check for that stage completed successfully.

## Existing workflow mapping

The intended `go-engine` workflow mapping is:

| Caller workflow | Events | Stage / command | New contract |
| --- | --- | --- | --- |
| `.github/workflows/sources.yaml` | `opened`, `reopened`, `synchronize`, `ready_for_review` | reusable `sources` stage | Fast PR source checks; also run for the merge-group candidate. |
| `.github/workflows/binaries.yaml` | `opened`, `ready_for_review`, `synchronize`, `merge_group` | reusable `binaries` stage | Caller always invokes reusable workflow; draft PRs pass `run: false`. |
| `.github/workflows/distros.yaml` | PR update events, `merge_group` | reusable `distros` stage | Caller always invokes reusable workflow; merge-group candidates pass `run: true` and execute `check1 → prepare → check2`. |

There is intentionally no `main_revision.yaml` binary gate in the target design. Post-merge finalization is a separate concern and should not duplicate the merge-group `binaries` check.

The migration must not delete an existing check merely because its implementation moves. Every retired caller workflow must have an explicit replacement in the new matrix.

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
