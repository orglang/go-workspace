# CI and Verification

This document captures design questions and candidate conventions for CI. The workspace and component repositories have independent Git histories; CI must preserve those boundaries and test explicit revisions.

## Artifact and dependency model

One candidate model to evaluate is:

```text
             ┌─ specs → sources → binaries ─┐
deps ────────┤                              ├→ distros
             └─ ...                         ┘
```

This is a proposal, not an agreed target architecture. In particular, `deps` is shared by product work and development tooling; it may be a cross-cutting prerequisite rather than a stage in a strictly linear pipeline. The graph should describe real input/output dependencies, not prescribe a GitHub Actions workflow for every node.

Use `toolchain` for the pinned runtimes and CLI tools required to develop, generate, validate, and build the product. Use `project dependencies` for libraries and packages consumed by the product or its generators. Both belong under the broad dependency concern (`deps`), but they have different installation and validation mechanisms. Neither category needs to be drawn as a separate artifact stage unless it produces a versioned, consumed artifact.

Questions to resolve before adopting the model:

- Which stages produce versioned artifacts, and which only prepare or validate inputs?
- Does each stage consume a persisted output from its predecessor, or can it independently reproduce that output from a pinned revision?
- Is `deps` a distinct node, or are toolchain and project dependencies prerequisites declared by each consuming stage?
- Which checks must run independently on PRs and merge-group candidates?

A useful working vocabulary (subject to validation against actual workflows) is:

| Candidate stage | Possible responsibility |
| --- | --- |
| `deps` | Shared dependency concern: validate toolchain pins and project dependency manifests/lockfiles; prepare the required runtimes, CLI tools, Go modules, and npm packages |
| `specs` | Compile TypeSpec and produce/check OpenAPI |
| `sources` | Generate Go sources and verify reproducibility |
| `binaries` | Run relevant tests and build executables from a component revision |
| `distros` | Build and verify distributable images/stacks from pinned component inputs |

Do not infer a strict linear dependency merely from this vocabulary. For example, dependency installation may be shared by multiple stages, and a downstream stage may consume committed generated sources rather than an artifact uploaded by an upstream workflow.

Generated sources should be treated consistently: either the relevant downstream workflow consumes the generated files already present in the exact source revision, or it explicitly owns generation as part of its own contract. Avoid hidden generation side effects and undocumented reliance on workflow execution order.

### Product and development-tooling concerns

The product is `app`. The development environment and tools required to work on, generate, validate, and build it are the `toolchain`. Prefer `toolchain` over `gear`: it is more precise and conventional in CI documentation, while `gear` is informal and ambiguous.

These are not automatically two parallel artifact graphs:

- `deps` is a shared, cross-cutting concern that includes both toolchain requirements and project dependencies.
- `toolchain` covers pinned runtimes and CLI tools (for example Go, Node.js, Task, generators, and linters).
- Project dependencies are fetched using the relevant package manager (for example Go modules and npm packages).
- Product stages such as specs, sources, binaries, and distros describe outputs and validation of the `app`; they should not be duplicated as `toolchain-*` stages merely because the toolchain is needed to run them.

Use a `toolchain-` prefix only for a genuinely toolchain-specific workflow or check. Product workflows should use product/stage names; shared dependency checks should remain unprefixed (for example, `Deps Check`).

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

The workspace is a meta-repository containing `go.work` and workspace-level documentation. Whether it should also own reusable workflow implementations is an open design decision; decide this from actual cross-repository reuse and orchestration needs.

Target ownership:

- **Component repository:** event adapters (`pull_request`, `merge_group`, `push`, `workflow_dispatch`), required check names, and component-specific commands.
- **Workspace repository:** workspace membership and cross-repository coordination. Whether it should also own shared workflow logic remains an open design question.
- **Reusable workflows:** one option, not a predetermined answer. Compare duplication, caller complexity, cross-repository orchestration, revision handling, and required-check stability before deciding which stages (if any) should be reusable.

The partial move to local `Binaries` and `Distros` workflows in `go-engine` is consistent with component ownership, but does not by itself settle whether some internal steps should later be shared. Avoid both blanket duplication and premature centralization.

## Exact revisions for PR and merge queue

This section is independent of whether the product graph is split into subgraphs. Its purpose is reproducibility: a CI result must describe the exact candidate GitHub is evaluating, not a mixture of that candidate and moving default-branch revisions.

Every run must identify the exact revisions it tests:

- component revision under test (PR head for PR checks; merge-group candidate for `merge_group`);
- workspace revision used for workspace files and configuration;

Do not silently substitute `main` for any revision that is part of the candidate being verified. A moving default branch is not a reproducible dependency pin. The mechanism for selecting compatible cross-repository revisions must be explicit (for example a checked-in compatibility manifest or explicit workflow inputs); do not invent a revision-selection rule in an individual workflow.

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

## Implementation sequence

1. Evaluate the candidate artifact/dependency model, including the shared `deps` concern and the distinction between `toolchain` and project dependencies; keep it explicitly provisional until agreed.
2. Decide workflow ownership and the reusable-workflow boundary without treating either full centralization or full decentralization as a default.
3. Define the revision contract for PR and merge-group runs, including how compatible cross-repository inputs are selected.
4. Agree on workflow/job/check naming and inspect required-check configuration before changing any check context.
5. Decide how `Distros` consumes generated sources and whether source validation is independently guaranteed for merge-group candidates.
6. Define triggers and safe path-filter behavior for each required check before adding filters.
7. Evaluate npm download caching against the existing mise cache; add it only if it gives a measurable benefit.
8. Implement accepted decisions in small PRs, preserving existing merge gates.

## Verification after a PR update

After updating a PR:

1. Inspect the actual checks/status.
2. Investigate failures rather than rerunning blindly.
3. Distinguish skipped, unavailable, running, and successful checks.
4. Do not claim verification is complete until the relevant checks are green.
