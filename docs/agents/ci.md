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

A downstream stage must consume the exact upstream artifact, not rebuild it from a mutable checkout. In particular, `distros` consumes the binary artifact produced by `binaries`; preserve its immutable identity/digest and source revision. A distro may package or reference that binary together with runtime components and distribution configuration. A workload is the deployed application, not another packaged artifact.

## Verification

The common lifecycle from [#43](https://github.com/orglang/go-workspace/issues/43) is:

```text
prepare → check1 → install → check2 → [publish]
```

For sources, the full lifecycle applies to local development and source-artifact creation. CI does not run the source `prepare`, `install`, or `publish` steps; it runs only `check1` and `check2` against the revision under test.

- `sources.check1` is the fast artifact-consistency gate: verify that required generated sources and lockfiles are present and up to date. It must not be treated as the full source quality suite.
- `sources.check2` is the full source verification: run formatting, lint, and the remaining source checks against a clean checkout of the exact revision. In local development, this is the commit created by `sources.install`; in CI, it is the checked-out revision under test.

For binaries, `check1` runs unit tests and `check2` runs integration tests. Each CI check must verify the artifact or revision assigned to its stage and must not silently substitute a rebuilt output.

## Tooling

- **mise** selects and installs pinned development toolchains.
- **Task** runs and composes project operations.

Keep these responsibilities separate: toolchain management belongs to mise; project operations belong to Task. Use locked toolchain installs in CI.

## Workflow ownership and revisions

- Component repositories own their event-triggered workflows and required check contexts.
- The workspace owns workspace membership and cross-repository coordination.
- Test same-repository pull request and merge-queue candidates at the exact revision supplied by GitHub. For pull requests, make clear whether a check tests the PR head or merge ref.
- A merge-queue SHA applies only to the repository whose queue raised the event. Cross-repository inputs must be pinned to explicit immutable revisions; never silently check out `main`.
- Required checks must run for `merge_group`. Avoid workflow-level path filters that prevent required checks from being created.
- Use least-privilege workflow permissions, normally `contents: read`.

Keep required check names stable. Before renaming or moving their implementation, verify branch protection/rulesets and merge-queue behavior.
