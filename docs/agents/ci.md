# CI and Verification

This document separates the observed implementation from the target model. The workspace and component repositories have independent Git histories; CI must preserve those boundaries and test explicit revisions.

## Artifact graph

The target dependency path is:

```text
deps → specs → sources → binaries → distros
```

`deps` is a prerequisite, not a distributable artifact. It establishes the toolchain and project dependencies required by downstream stages. The artifact-producing stages are:

| Stage | Inputs | Output / guarantee |
| --- | --- | --- |
| `deps` | mise config and lock, Go module manifests, npm lock | Pinned runtimes/tools and installed Go/npm dependencies |
| `specs` | TypeSpec sources and npm dependencies | OpenAPI specification, compiled and checked for drift |
| `sources` | OpenAPI plus generator tools and handwritten Go | Reproducible generated Go sources |
| `binaries` | Exact component revision with committed generated sources | Tested and built executables |
| `distros` | Exact workspace/component revisions and binaries/build inputs | Built and verified distributable images/stacks |

The dependency edges mean that a consumer must have its prerequisites available; they do not require every stage to be implemented as a separate GitHub Actions workflow. A stage may be an explicit job, a task, or a prerequisite step, depending on where it is reused and what artifact boundary it owns.

Generated sources are source-controlled inputs to `binaries` and `distros`. Downstream stages must not silently regenerate or modify them. Generation and reproducibility checks belong to `sources`.

## Tool responsibilities

Keep toolchain installation distinct from project dependency installation:

- **mise** selects pinned runtimes and CLI tools from `mise.toml` / `mise.lock` (for example Go, Node.js, Task, linters, and generators).
- **Go modules** are downloaded with `GOWORK=off go mod download` for component-local CI. Do not let the workspace's local `go.work` hide module dependency problems.
- **npm** installs TypeSpec project packages from `tsp/package-lock.json` with `npm ci`. mise installs Node.js; it does not install project npm packages.
- **mise tasks** own toolchain and dependency lifecycle operations such as `deps:lock`, `deps:install`, and `deps:check`.
- **Task** owns project operations and their composition: `specs:*`, `sources:*`, tests, binaries, and stack tasks.

Do not add a second entry point for the same operation. If a command is a toolchain/dependency lifecycle operation, expose it through mise; if it is a project operation or composes project tasks, expose it through Task.

`deps:lock` is mutating and should be run deliberately (locally or in an explicitly invoked generation/update workflow), not as an incidental side effect of ordinary verification. `deps:install` is the deterministic install operation. `deps:check` must fail when manifests or lockfiles are stale; keep its observable result read-only from the caller's perspective.

For npm caching, prefer caching the npm download cache keyed by the lockfile and Node/npm version. Do not cache `node_modules` unless measurements show a material benefit and the cache can be invalidated safely. Avoid overlapping cache layers with mise-action; measure before adding another cache.

## Workflow ownership

GitHub events are delivered to the repository that owns the workflow file. Therefore component repositories own event-triggered workflows and their stable check contexts.

The workspace is a meta-repository containing `go.work` and workspace-level documentation. It does not currently contain a `workflow_call` implementation for the component artifact stages. Do not describe it as the owner of reusable artifact workflows unless such workflows are actually added.

Target ownership:

- **Component repository:** event adapters (`pull_request`, `merge_group`, `push`, `workflow_dispatch`), required check names, component-specific commands, and the exact component revision under test.
- **Workspace repository:** workspace membership and cross-repository coordination contracts; it may host genuinely shared workflow logic only after a real shared boundary is demonstrated.
- **Reusable workflows:** optional implementation detail, not the default architecture. Extract a reusable workflow only when multiple components need the same stable operation and the contract can carry exact revisions, permissions, and event-independent inputs. Keep event policy and required-check adapters in each component repository.

The partial move to local `Binaries` and `Distros` workflows in `go-engine` is consistent with component ownership, but does not by itself settle whether some internal steps should later be shared. Avoid both blanket duplication and premature centralization.

## Revision and merge-queue contract

Every run must identify the exact revisions it tests:

- component revision under test (PR head for PR checks; merge-group candidate for `merge_group`);
- workspace revision used for workspace files and configuration;
- SDK revision consumed by the component.

Do not silently substitute `main` for any revision that is part of the candidate being verified. A moving default branch is not a reproducible dependency pin. The mechanism for selecting a compatible SDK/workspace revision must be explicit (for example a checked-in compatibility manifest or explicit workflow inputs); do not invent a revision-selection rule in an individual workflow.

For `merge_group`, verify the merge candidate and the corresponding compatible dependency revisions. Do not use a PR head SHA in place of the merge-group SHA. Keep permissions least-privilege (normally `contents: read`); grant write access only to a narrowly scoped generation workflow that needs to commit generated files. Never pass long-lived credentials as workflow inputs.

## Naming and required checks

Use lowercase kebab-case workflow filenames, stage-oriented workflow names, and stable job IDs:

| Stage | Workflow filename | Workflow name | Job ID |
| --- | --- | --- | --- |
| Sources generation | `sources-generate.yaml` | `Sources Generate` | `sources-generate` |
| Sources verification | `sources-verify.yaml` | `Sources Verify` | `sources-verify` |
| Specs verification | `specs-check.yaml` | `Specs Check` | `specs-check` |
| Binary verification/build | `binaries.yaml` | `Binaries` | `binaries` |
| Distribution verification | `distros.yaml` | `Distros` | `distros` |

This is a vocabulary proposal, not permission to rename existing checks blindly. GitHub required checks can be tied to workflow/job contexts. Before any rename, inspect branch protection and repository rulesets, record the old and new contexts, migrate the rules, and verify the merge queue before removing the old context. Keep a caller-level job/check stable when moving its implementation behind a reusable workflow.

Prefer workflow `name` and job `name` values that are stable and unambiguous. Job IDs are machine-facing identifiers; displayed names are human-facing. Do not use matrix-generated or dynamically changing names for required checks.

## Triggers, drafts, and path filters

Choose triggers by purpose:

- `pull_request`: validation of proposed changes; include the required PR activity types (`opened`, `ready_for_review`, and `synchronize`) deliberately.
- Draft PRs: decide explicitly which fast checks run while a PR is draft. Do not accidentally make a required check disappear; a stable caller-level check must still report a deterministic result.
- `merge_group`: required merge-queue gates must run against the merge-group candidate.
- `push`: default-branch validation and cache warming where useful.
- `workflow_dispatch`: deliberate maintenance/generation operations and diagnostics.

Do not put path filters on a required workflow in a way that prevents GitHub from creating its required check. If a stage is irrelevant to a change, keep the caller-level check present and let an internal job decide to skip based on a reviewed path policy. Changes to workflow definitions, mise/Task configuration, lockfiles, shared stack files, and workspace coordination must trigger every affected check.

Before introducing path-based skips, test PR, draft/ready, and merge-group behavior, including no-relevant-path changes. A skipped internal job must not leave the merge queue waiting for a missing required context.

## Observed implementation (2026-11-14)

The following observations are from the current default branches inspected for issue #118:

- `go-engine` has local `Binaries`, `Distros`, `Sources Generate`, and `Sources Verify` workflows. The workspace repository has no reusable `workflow_call` artifact workflow at present.
- `Binaries` checks PRs, merge groups, and manual runs. Its job-level draft condition skips the job for draft PRs.
- `Sources Verify` checks pushes to `main`, PRs, and manual runs. Its job-level draft condition also skips draft PRs.
- `Distros` declares PR, merge-group, and manual triggers, but its job currently runs only for `merge_group`.
- The current `Distros` workflow checks out workspace `main` and SDK `main`, checks out the engine candidate, installs dependencies, and then regenerates engine sources before building. The moving workspace/SDK refs and source generation are inconsistent with the exact-revision and stage-boundary goals above.
- `Sources Generate` is a manual, write-enabled workflow that locks dependencies, installs them, generates specs and sources, then commits changes to the selected branch.
- `go-engine/mise.toml` defines `deps:lock`, `deps:install`, and `deps:check`. It installs Go/Node and Go CLI tools via mise; `deps:install` separately downloads Go modules and runs `npm ci` for TypeSpec.

These are observations, not claims that the target design is already implemented across all components. The SDK repository still needs a separate CI audit before this model can be called workspace-wide.

## Implementation sequence

1. Agree on the graph, ownership, revision contract, and naming vocabulary in this document.
2. Audit every component's current workflows, tasks, rulesets/required checks, and dependency pins; record the actual check contexts before changing names.
3. Fix `Distros` to consume committed generated sources and exact workspace/engine/SDK revisions.
4. Define stable caller-level checks for PR, draft/ready, and merge-group runs; migrate required-check rules only after observing the real contexts.
5. Decide which shared operations, if any, justify reusable workflows. Add them only with explicit revision and permission contracts.
6. Add safe path-based internal skips and npm download caching only after trigger behavior and cache benefit are verified.
7. Split implementation across small component PRs; verify each PR's actual checks and merge-queue behavior before proceeding.

## Verification after a PR update

After updating a PR:

1. Inspect the actual checks/status.
2. Investigate failures rather than rerunning blindly.
3. Distinguish skipped, unavailable, running, and successful checks.
4. Do not claim verification is complete until the relevant checks are green.
