# CI Architecture

## Pipeline

The workspace pipeline is:

```text
specs → sources → binaries → distros → workloads
```

| Stage | Responsibility |
| --- | --- |
| `specs` | Generate and verify API/schema outputs. |
| `sources` | Generate and verify source files. |
| `binaries` | Test and build executable artifacts. |
| `distros` | Package binaries with the required runtime and distribution inputs. |
| `workloads` | Deploy and verify the application in a target environment. |

The arrows describe the lifecycle, not implicit dependencies between independent workflow runs. Every operation must declare its actual inputs.

For the initial implementation, the Distros gate invokes the Engine Binaries gate in the same workflow execution before running the Workspace packaging and deployment tasks. The current Docker Bake configuration still uses the source-build Dockerfile and the mutable `latest` image tag; replacing that with binary-copy packaging and immutable artifact identity is deferred to [#129](https://github.com/orglang/go-workspace/issues/129). The smoke-test task is currently an explicit no-op placeholder until a container-level check is defined. Provenance metadata and supply-chain attestations are tracked separately in [#126](https://github.com/orglang/go-workspace/issues/126).

## Stage task interfaces

### Specs

- `specs:prepare` generates OpenAPI and refreshes the TypeSpec toolchain and npm lockfiles.
- `specs:gate` verifies formatting, generated OpenAPI, and lockfile freshness.
- `specs:lint` checks formatting without modifying files.
- `specs:analyze` compiles the TypeSpec project without emitting artifacts.

Installing the prepared specification as a Git commit and publishing/pushing it are manual operations. That commit is the specification revision consumed by `sources:prepare`.

### Sources

- `sources:prepare` generates source files, refreshes source toolchain locks, and formats handwritten Go.
- `sources:gate` verifies generated sources, lockfiles, and formatting.
- `sources:lint` runs Go linting without modifying files.
- `sources:analyze` runs `go vet` and the architecture rules enforced by `depguard`.

Installing the prepared sources as a Git commit and publishing/pushing them are manual operations. The source commit consumed by `binaries:build` includes the prepared specifications.

### Binaries

- `binaries:unit-test` runs unit tests.
- `binaries:build` builds `dist/go-engine` from the checked-out source commit.
- `binaries:integration-test` runs integration tests after the build.
- `binaries:gate` runs unit tests, build, then integration tests, in that order.

### Distros

- `distros:package` currently invokes Docker Bake using the existing source-build Dockerfile. Switching to packaging the Binaries gate output without recompiling is deferred to [#129](https://github.com/orglang/go-workspace/issues/129).
- `distros:smoke-test` is a placeholder pending a defined container-level smoke-test contract.
- `distros:deploy <target>` starts the Compose stack for the selected target using the image configured by Docker Compose.
- `distros:e2e-test <target>` runs end-to-end tests against that deployment.
- `distros:gate <target>` runs package, smoke-test, deploy, and E2E-test in order, passing the same target to both deployment and E2E testing.

Distro publication and advancement of mutable tags remain outside this lifecycle.

## Verification

The common lifecycle is:

```text
prepare → check1 → install → check2 → [publish]
```

CI runs the Specs and Sources gates, lint, and analysis against the revision under test. It does not perform the manual Git commit/install or publication steps.

For binaries, unit tests run before the build and integration tests after it. In the current Distros execution, the Binaries gate builds the binary and packaging consumes that output in the same workflow run. Cross-run artifact transfer and reuse are deferred to [#129](https://github.com/orglang/go-workspace/issues/129).

## Tooling

- **mise** selects and installs pinned development toolchains.
- **Task** runs and composes project operations.

Keep these responsibilities separate: toolchain management belongs to mise; project operations belong to Task. Use locked toolchain installs in CI.

## Workflow ownership and revisions

- Component repositories own event-triggered workflows and required check contexts.
- The workspace owns workspace membership and cross-repository coordination.
- Test same-repository pull request and merge-queue candidates at the exact revision supplied by GitHub. For pull requests, make clear whether a check tests the PR head or merge ref.
- A merge-queue SHA applies only to the repository whose queue raised the event. Cross-repository inputs must be pinned to explicit immutable revisions; never silently check out `main`.
- Required checks must run for `merge_group`. Avoid workflow-level path filters that prevent required checks from being created.
- Use least-privilege workflow permissions, normally `contents: read`.

Keep required check names stable. Before renaming or moving their implementation, verify branch protection/rulesets and merge-queue behavior.
