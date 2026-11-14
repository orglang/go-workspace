# CI and Verification

This document captures design questions and candidate conventions for CI. The workspace and component repositories have independent Git histories; CI must preserve those boundaries and test explicit revisions.

## Artifact and dependency model

One candidate model to evaluate is:

```text
             ┌─ specs → sources → binaries ─┐
deps ────────┤                              ├→ distros
             └─ ...                         ┘
```

This is a proposal, not an agreed target architecture. Dependencies are a cross-cutting concern, not necessarily a stage in a strictly linear pipeline. The graph should describe real input/output dependencies, not prescribe a GitHub Actions workflow for every node.

Avoid using `toolchain` as an umbrella for everything needed by the software. Distinguish at least:

- **Build toolchain:** pinned SDKs, runtimes, compilers, generators, linters, and build tools needed to develop, validate, and build the product.
- **Build-time dependencies:** libraries and packages fetched to compile or generate the product (for example Go modules and TypeSpec npm packages).
- **Runtime requirements:** interpreters, shared libraries, OS packages, base images, and external services required to run the built product.

These categories have different owners and lifecycles. The build toolchain belongs to the development/CI environment; runtime requirements belong to the app's runtime and distribution contract. Some project libraries may be linked into the binary and therefore not require a separate runtime installation. Do not assume every dependency is a separately deployable artifact.

Use `deps` only as a broad label for dependency management or a task group, not as a claim that all dependencies form one graph node or one linear stage.

Questions to resolve before adopting the model:

- Which stages produce versioned artifacts, and which only prepare or validate inputs?
- Does each stage consume a persisted output from its predecessor, or can it independently reproduce that output from a pinned revision?
- Is `deps` a distinct node, or are toolchain and project dependencies prerequisites declared by each consuming stage?
- Which checks must run independently on PRs and merge-group candidates?

A useful working vocabulary (subject to validation against actual workflows) is:

| Candidate stage | Possible responsibility |
| --- | --- |
| `deps` | Broad dependency-management concern; distinguish build-toolchain pins, build-time package dependencies, and app runtime requirements |
| `specs` | Compile TypeSpec and produce/check OpenAPI |
| `sources` | Generate Go sources and verify reproducibility |
| `binaries` | Run relevant tests and build executables from a component revision |
| `distros` | Build and verify distributable images/stacks from pinned component inputs |

Do not infer a strict linear dependency merely from this vocabulary. For example, dependency installation may be shared by multiple stages, and a downstream stage may consume committed generated sources rather than an artifact uploaded by an upstream workflow.

Generated sources should be treated consistently: either the relevant downstream workflow consumes the generated files already present in the exact source revision, or it explicitly owns generation as part of its own contract. Avoid hidden generation side effects and undocumented reliance on workflow execution order.

### Product, build-toolchain, and runtime concerns

The product is `app`. Its development/build environment and its production runtime are distinct concerns:

- Use `build-toolchain` (or `toolchain` where the context is unambiguous) for pinned SDKs and developer/CI tools.
- Use `runtime` / `runtime-image` for the environment needed to execute the built app.
- Use `build-deps` for packages fetched to generate or compile the app, where a name is needed to distinguish them from runtime requirements.
- Keep `deps` as a broad task/documentation grouping only when it is useful; do not model it as a single artifact stage merely because these concerns are all dependencies.

These are not two parallel artifact graphs. Product stages such as specs, sources, binaries, and distros describe outputs and validation of the `app`. Runtime requirements should become visible where the app is packaged or deployed; build-toolchain requirements are prerequisites for the CI jobs that produce or validate those outputs.

## Tool responsibilities

Keep toolchain installation distinct from project dependency installation:

- **mise** selects pinned build-toolchain runtimes and CLI tools from `mise.toml` / `mise.lock` (for example Go, Node.js, Task, linters, and generators). It does not define the production runtime contract by itself.
- **Go modules** are downloaded with `GOWORK=off go mod download` for component-local CI. Do not let the workspace's local `go.work` hide module dependency problems.
- **npm** installs TypeSpec build-time packages from `tsp/package-lock.json` with `npm ci`. mise installs Node.js; it does not install project npm packages.
- **Runtime requirements** should be declared and assembled with the app/distribution (for example Docker base images, OS packages, and runtime services), not hidden in the developer toolchain.
- **mise tasks** own build-toolchain and dependency lifecycle operations such as `deps:lock`, `deps:install`, and `deps:check`, where those commands actually manage the corresponding development/build inputs.
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

This section is independent of the product graph. It describes what a repository's own merge queue can and cannot guarantee.

For a `merge_group` run, GitHub provides a synthetic merge-group ref and SHA for the candidate in the repository whose queue raised the event. Checking out the event's default ref/SHA tests that candidate (including the queued PR changes and the target branch state represented by the merge group). GitHub's merge-group event does **not** automatically provide matching candidate SHAs for other repositories.

Therefore:

- For same-repository code and configuration, test the merge-group candidate SHA.
- For cross-repository inputs, use immutable revisions explicitly pinned by the candidate under test (for example in a checked-in compatibility manifest), or another deliberately designed coordination mechanism.
- Do not claim that a component merge queue tests a simultaneous candidate from the workspace or another component unless such a candidate mapping is explicitly supplied and verified.
- If cross-repository compatibility cannot be represented reproducibly, state that limitation and choose a separate integration strategy; do not silently check out `main`.

For `pull_request`, be explicit whether the check tests GitHub's PR merge ref or the PR head. For required merge-queue checks, include the `merge_group` trigger and test the merge-group SHA. Keep permissions least-privilege (normally `contents: read`); grant write access only to a narrowly scoped generation workflow that needs to commit generated files. Never pass long-lived credentials as workflow inputs.

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

1. Evaluate the candidate artifact/dependency model, distinguishing build toolchain, build-time dependencies, and app runtime requirements; keep it explicitly provisional until agreed.
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
