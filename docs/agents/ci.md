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

The arrows describe the lifecycle, not implicit job dependencies. Every operation must declare its actual inputs.

A downstream stage consumes the exact upstream artifact, not a rebuild from a mutable checkout. The engine binary build writes `dist/go-engine` and `dist/go-engine.provenance.json`; the manifest records the source commit, the latest commit that changed the specification inputs, and the binary SHA-256. Distro packaging verifies those values and copies the binary and manifest into the image without compiling the application. The image is tagged with the source commit, and smoke-test and deploy both use that immutable tag.

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

Installing the prepared sources as a Git commit and publishing/pushing it are manual operations. The source commit consumed by `binaries:build` includes the prepared specifications; the binary provenance manifest records both revisions.

### Binaries

- `binaries:unit-test` runs unit tests.
- `binaries:build` builds `dist/go-engine` from the checked-out source commit and writes its provenance manifest.
- `binaries:integration-test` runs integration tests after the build.
- `binaries:gate` runs unit tests, build, then integration tests, in that order.

### Distros

- `distros:package` verifies the binary manifest and packages that exact binary with runtime and migration inputs. It does not compile the application.
- `distros:smoke-test` executes the packaged image and verifies the binary digest inside it.
- `distros:deploy <target>` deploys the commit-tagged image into the selected environment.
- `distros:e2e-test <target>` runs end-to-end tests against that deployment.
- `distros:gate <target>` runs package, smoke-test, deploy, and E2E-test in order, passing the same target to both deployment and E2E testing.

Distro publication and advancement of mutable tags remain outside this lifecycle.

## Verification

The common lifecycle is:

```text
prepare → check1 → install → check2 → [publish]
```

CI runs the Specs and Sources gates, lint, and analysis against the revision under test. It does not perform the manual Git commit/install or publication steps.

For binaries, unit tests run before the build and integration tests after it. Each stage operates on the exact checked-out revision; the binary manifest ties the output to its source and specification commits.

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
