# CI and Verification

This document captures design questions and candidate conventions for CI. The workspace and component repositories have independent Git histories; CI must preserve those boundaries and test explicit revisions.

## Artifact and dependency model

One candidate model to evaluate is:

```text
specs → sources → binaries ─┐
other inputs ───────────────┴→ distros → workloads
```

This is a proposal, not an agreed target architecture. The graph describes candidate product stages and their input/output relationships; it does not prescribe a GitHub Actions workflow for every node. Dependencies are declared per stage and per toolchain. Dependency management is cross-cutting and is not a product stage in this model.

Use `toolchain` as the umbrella term for the software environment required to perform work or execute an output. Describe it relative to a stage and purpose:

- **Dev toolchain:** everything needed to develop, generate, validate, and build that stage's output. This can include an OS, system libraries, language runtimes and SDKs, compilers, generators, linters, CLI tools, and fetched project packages.
- **Run toolchain:** everything needed to execute that stage's output. This can include an OS, interpreters, shared libraries, other executable components, and runtime packages.

A stage may define a dev toolchain, a run toolchain, both, or neither. Either toolchain may be managed as a separate, versioned artifact, or assembled from declared dependencies when needed. The dev and run toolchains may overlap, but need not be identical. Some dependencies may be statically linked into an output and therefore need not be installed in its run toolchain. Configuration that selects application behavior or deployment parameters is related, but is not itself necessarily part of the toolchain.

Use `deps` only as a broad label for dependency management or a task group, not as a claim that all dependencies form one graph node or one linear stage.

Questions to resolve before adopting the model:

- Which stages produce versioned artifacts, and which only prepare or validate inputs?
- Does each stage consume a persisted output from its predecessor, or can it independently reproduce that output from a pinned revision?
- Are each stage's dev/run toolchains and project dependencies declared by that stage, with shared dependency-management operations composed where useful?
- What are the inputs, dev toolchain, run toolchain, and verification contract for `workloads`, which represents an application running in a target environment rather than another distributable artifact?
- Which checks must run independently on PRs and merge-group candidates?

A useful working vocabulary (subject to validation against actual workflows) is:

| Candidate stage | Possible responsibility |
| --- | --- |
| `specs` | Compile TypeSpec and produce/check OpenAPI |
| `sources` | Generate Go sources and verify reproducibility |
| `binaries` | Run relevant tests and build executable files from a component revision |
| `distros` | Assemble and verify distribution artifacts, such as runtime images and Helm charts, from pinned app artifacts, run toolchains, and distribution configuration |
| `workloads` | Run and verify the complete application, including its related components, in a target environment |

Do not infer a strict linear dependency merely from this vocabulary. For example, dependency installation may be shared by multiple stages, and a downstream stage may consume committed generated sources rather than an artifact uploaded by an upstream workflow.

Generated sources should be treated consistently: either the relevant downstream workflow consumes the generated files already present in the exact source revision, or it explicitly owns generation as part of its own contract. Avoid hidden generation side effects and undocumented reliance on workflow execution order.

### Stage-specific dev and run toolchains

The product is `app`, but that name identifies the product—not one identical application layout at every lifecycle stage. Its development form and runtime form may differ in composition, dependencies, configuration, and launch method. A `distro` is the distribution artifact: it packages or references the runtime app together with the run toolchain and distribution-specific configuration. A runtime image is one possible form of a distro, not the run toolchain itself. A Helm chart is another possible distro artifact: it can reference a pinned runtime image and describe how to deploy it without containing the image itself.

- **Development app:** the form used by developers and CI, potentially including source trees, dev servers, hot-reload support, debuggers, test fixtures, and development-only dependencies.
- **Build artifact:** the output produced from a selected source revision, such as an executable binary. It need not contain the development environment.
- **Runtime app:** the form actually executed or deployed, consisting of the selected build artifact plus its runtime configuration and run toolchain.

Treat dev and run toolchains as stage-specific contracts, not as two global toolchains for the entire repository. For example, `sources` may need a dev toolchain containing Go and code generators, while its generated source files have no independent run toolchain. `binaries` may need a Go build toolchain and produce an executable whose run toolchain is an OS plus the shared libraries it uses. `distros` assembles distribution artifacts by packaging or referencing the app binary, its run toolchain, and distribution-specific configuration. A runtime image may bundle these together; a Helm chart may instead reference the image by immutable digest and carry deployment templates and defaults.

The `workloads` stage's **dev toolchain** may include Helm, kubectl, cluster-authentication plugins, and tools for validating rendered manifests. Its inputs include a selected distro (for example, a Helm chart and the image it references), environment-specific values, and target-environment identity/access. The workload is the complete running application in that target environment, not another packaged distro artifact.

These are not parallel artifact graphs. Product stages such as specs, sources, binaries, distros, and workloads describe outputs and validation across the app lifecycle. Each stage declares the toolchains needed to produce/validate its output and, where that output is independently executable, to run it. Do not assume the development app is itself the deployable runtime app, or that the build artifact includes either toolchain in full.

An infrastructure-provisioning stage illustrates the same distinction without requiring a compiled application artifact:

- Ansible playbooks and roles are the stage's source inputs (for example, under an infrastructure or provisioning stage).
- The provisioning stage's **dev toolchain** contains the Ansible executable, its controller-side runtime, required collections, and any supporting CLI tools needed to validate and apply those sources.
- The resulting **run toolchain** is the configured target runtime: its OS, installed packages, shared libraries, services, and other executable components required by the workload.
- The playbook is not itself the target run toolchain. It is an input used by the provisioning stage to create or update that toolchain. Configuration values may be inputs to that operation without becoming toolchain components themselves.

This example also shows that a stage's dev toolchain can execute an operation whose output is another stage's run toolchain; the two contracts describe different sides of the operation.


### Artifact composition

The lifecycle graph describes dependencies between stages. It does not describe the internal composition of each stage's artifacts. Keep these two views separate: an artifact produced by one stage can be composed of multiple parts, and an artifact can become an input to a later stage.

The following is an illustrative composition model, not a required directory layout or a claim that every component has all these parts:

- **Sources** can include application code, generated code, API/schema specifications, templates, static assets, and infrastructure or deployment definitions. These are source inputs regardless of whether they are written by hand or generated. For example, Helm chart source files (`Chart.yaml`, values files, templates, and chart dependency declarations) belong to `sources`; they are not themselves a packaged distro.
- **Binaries** can include executable files and, where needed, shared libraries or other compiled runtime components. A binary artifact may be a single executable or a set of files; it is not synonymous with a container image.
- **Distros** can combine or reference binary artifacts, run-toolchain components, and distribution-specific metadata/configuration. Possible components include runtime images, packaged Helm charts, manifests, checksums, and signatures. A chart package can refer to a runtime image by immutable digest without embedding that image. A distro need not contain every component physically; references must still resolve to pinned, reproducible inputs.
- **Workloads** represent the complete application as deployed in a target environment, including its related components that together make up the application. They are the result of deploying selected distros, not another packaged artifact. Credentials and secret values remain external inputs; do not treat secret material as part of a distro.

For Helm specifically, chart source files flow through `sources`; validation and packaging use a dev toolchain that includes Helm; the packaged chart is a distribution artifact in `distros`; and Helm/kubectl can deploy that chart (and the image it references) as a workload. This illustrates that source, package, and deployment are different lifecycle roles even when they concern the same logical component.

Do not force these compositions into strict trees. Artifacts may be shared by multiple consumers, and one artifact may reference another without containing it. Distinguish containment, reference, and dependency where it matters; qualify a dependency as build-time, deployment-time, or runtime only when the lifecycle distinction is relevant.

## Tool responsibilities

Keep toolchain installation distinct from project dependency installation, while treating both as inputs to the relevant stage's dev or run toolchain:

- **mise** selects pinned development toolchain runtimes and CLI tools from `mise.toml` / `mise.lock` (for example Go, Node.js, Task, linters, and generators). It does not, by itself, define the run toolchain for a deployed app.
- **Go modules** are downloaded with `GOWORK=off go mod download` for component-local CI. Do not let the workspace's local `go.work` hide module dependency problems.
- **npm** installs TypeSpec packages from `tsp/package-lock.json` with `npm ci`. mise installs Node.js; it does not install project npm packages.
- **Run toolchains** should be declared and assembled with the stage that owns the executable output or its distribution (for example Docker base images, OS packages, shared libraries, and runtime services). Docker Engine and BuildKit are build infrastructure used by the dev toolchain to build container images; they are not part of the image's run toolchain. At runtime, Docker Engine, containerd, or a Kubernetes node's container runtime is likewise host-side execution infrastructure, not a component packaged into the distro. The image's user-space OS, libraries, interpreters, and runtime packages are part of the app's run toolchain.
- **mise tasks** own development-toolchain and dependency lifecycle operations such as `deps:lock`, `deps:install`, and `deps:check`, where those commands actually manage the corresponding stage inputs.
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

## Naming tasks, workflows, jobs, and required checks

Keep four concerns separate:

- **Stage** identifies which part of the app lifecycle an operation belongs to: `specs`, `sources`, `binaries`, `distros`, or `workloads`.
- **Task** names the project operation as `stage:action`, for example `sources:generate` or `distros:build`.
- **Workflow** defines the CI event boundary and stable check context for a stage or a deliberate stage operation.
- **Job** names a concrete operation or verification within that workflow.

Do not encode `dev` or `run` in every task, workflow, or job name. These identify the purpose of a toolchain, not another lifecycle stage. A CI job prepares the stage's dev toolchain and then invokes the relevant Task operation. A run toolchain belongs to the executable output or distro being produced/consumed; it is not the environment used to run the CI job. Do not create separate workflows solely because a stage has both dev and run toolchains.

Candidate Task names:

| Stage | Task names |
| --- | --- |
| `specs` | `specs:check`, `specs:generate` |
| `sources` | `sources:generate`, `sources:verify` |
| `binaries` | `binaries:test`, `binaries:build`, `binaries:verify` |
| `distros` | `distros:build`, `distros:verify` |
| `workloads` | `workloads:deploy`, `workloads:verify` |

Candidate workflow and job names:

| Stage | Workflow filename | Workflow name | Job IDs |
| --- | --- | --- | --- |
| `specs` | `specs.yaml` | `Specs` | `specs-check` |
| `sources` | `sources.yaml` | `Sources` | `sources-generate`, `sources-verify` |
| `binaries` | `binaries.yaml` | `Binaries` | `binaries-test`, `binaries-build` |
| `distros` | `distros.yaml` | `Distros` | `distros-build`, `distros-verify` |
| `workloads` | `workloads.yaml` | `Workloads` | `workloads-deploy`, `workloads-verify` |

For example, the `workloads:deploy` task may run in a job whose dev toolchain includes Helm and kubectl, while the selected distro supplies the app's run toolchain. Similarly, the `distros:build` task may use Docker Engine or BuildKit from its dev toolchain to assemble a runtime image; neither tool becomes part of that image's run toolchain.

These names are a proposed convention, not a mandate to rename current files, tasks, or checks immediately. The existing workflow/check mapping below records the current naming shape to account for during migration.

Use lowercase kebab-case workflow filenames, stage-oriented workflow names, and stable job IDs:

| Current operation | Workflow filename | Workflow name | Job ID |
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

1. Evaluate the candidate artifact/dependency model, defining stage-specific dev and run toolchains and keeping the graph explicitly provisional until agreed.
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
