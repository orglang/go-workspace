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
  └─ ready_for_review
       ↓
    binaries

Merge queue
  └─ merge_group
       ↓
    sources + binaries
```

`sources` is the fast modification-stage check and runs throughout the PR lifecycle. `binaries` is the stabilization-stage check and starts when a PR is ready for review. Both stages are re-evaluated for a merge-group candidate so that the merge queue validates the actual merge result.

A post-merge `binaries` workflow is intentionally not required: the merge-group run is the pre-merge verification of the merge candidate. A separate post-merge workflow should be introduced only when the finalization stage requires checks that are meaningfully different from the merge-queue gates.

## Reusable workflow contract

The reusable workflow is the stable interface between repository-local event adapters and workspace CI.

### Inputs

| Input | Required | Meaning |
| --- | --- | --- |
| `engine_ref` | yes | Exact `go-engine` commit SHA or ref to test. PR and merge-group callers must pass the revision represented by the event. |
| `sdk_ref` | yes | Exact `go-sdk` commit SHA or ref to check out. Defaults are chosen by the caller, not inferred from the engine ref. |
| `workspace_ref` | yes | `go-workspace` revision containing the reusable workflow and Taskfiles. |
| `stage` | — | Reserved for a future unified stage dispatcher. The current stage-specific reusable workflows select their stage by filename (`sources.yaml`, `binaries.yaml`, etc.). |

The caller may pass repository names explicitly when a fork or alternate repository is under test; the default production repositories are `orglang/go-engine` and `orglang/go-sdk`.

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
- **prepare** creates the artifact consumed by check2.
- **check2** is the authoritative verification for that artifact.
- **publish** runs only after all required checks are green.
- **running** is not success; long-running e2e/distros jobs remain pending until completion.
- **skipped** is not silently converted to success. If a skipped job is required for the stage, the stage fails or is reported unavailable.
- **failure** propagates to the originating PR for PR-triggered stages.
- **success** means every required check for that stage completed successfully.

## Existing workflow mapping

The intended `go-engine` workflow mapping is:

| Caller workflow | Events | Stage / command | New contract |
| --- | --- | --- | --- |
| `.github/workflows/sources.yaml` | `opened`, `reopened`, `synchronize`, `ready_for_review` | reusable `sources` stage | Fast PR source checks; also run for the merge-group candidate. |
| `.github/workflows/binaries.yaml` | `ready_for_review`, `merge_group` | reusable `binaries` stage | Stabilization checks before merge and on the merge-group candidate. |
| `.github/workflows/main_proposal.yaml` | PR / `merge_group` | `task stack:commons` | Existing stack/e2e coverage; migrate to reusable `distros` without losing coverage. |

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
