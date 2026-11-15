# CI and Verification

Component repositories own their Git histories and event-triggered CI. The workspace is a meta-repository; cross-repository checks must use explicit revisions rather than assume a shared checkout or merge-queue candidate.

## Lifecycle stages

Use this working lifecycle model:

```text
specs → sources → binaries → distros → workloads
```

| Stage | Responsibility |
| --- | --- |
| `specs` | Compile TypeSpec and produce or check OpenAPI |
| `sources` | Generate source files and verify reproducibility |
| `binaries` | Test and build executable artifacts from a component revision |
| `distros` | Assemble and verify distribution artifacts, such as runtime images and Helm charts |
| `workloads` | Run and verify the complete application, including related components, in a target environment |

The arrows describe the expected lifecycle flow, not a requirement that every stage consume a persisted artifact from its immediate predecessor. A downstream stage may consume committed generated sources or reproduce them from a pinned revision. Make that choice explicit; avoid hidden generation side effects and undocumented reliance on workflow order.

### Toolchains

A **toolchain** is the software environment required to perform work or execute an output. Define it relative to a stage and purpose:

- **Dev toolchain:** tools and dependencies needed to develop, generate, validate, or build a stage's output. It can include an OS, system libraries, runtimes, SDKs, compilers, generators, linters, CLI tools, and project packages.
- **Run toolchain:** tools and components needed to execute the stage's output. It can span host and container layers, including OS and kernel capabilities, Docker Engine or containerd, container userspace, interpreters, shared libraries, and runtime packages. Components need not be packaged inside the output.

A stage may have a dev toolchain, a run toolchain, both, or neither. They may overlap, but need not. Some dependencies may be statically linked and require no separate runtime installation. The dev/run distinction describes purpose, not physical location. Configuration that selects application behavior is an input, but is not necessarily part of a toolchain.

The product is `app`; its development and runtime forms need not have the same composition. A **distro** is a distributable result that packages or references the runtime app, its run toolchain, and distribution-specific configuration. A runtime image is one possible distro form, not the run toolchain itself. A Helm chart is another: it can package templates and defaults while referencing a runtime image by immutable digest.

### Artifact composition

The lifecycle stages describe relationships between outputs; they do not prescribe the internal layout of artifacts.

- **Sources** include application code, generated code, API/schema specifications, templates, static assets, and infrastructure or deployment definitions. Helm chart source files belong here.
- **Binaries** include executable files and, where needed, shared libraries or other compiled runtime components. A binary artifact may contain one file or several; it is not synonymous with a container image.
- **Distros** may package or reference binaries, run-toolchain components, and distribution metadata/configuration. Examples include runtime images, packaged Helm charts, manifests, checksums, and signatures. References must resolve to pinned, reproducible inputs.
- **Workloads** are the complete application running in a target environment, including its related components. They result from deploying selected distros; they are not another packaged artifact. Credentials and secret values remain external inputs.

For Helm, chart sources flow through `sources`; Helm validates and packages them as part of `distros`; Helm/kubectl deploy the chart and its referenced image as a `workload`. Do not force artifact composition into a strict tree: artifacts can be shared, contained, referenced, or depended on. Qualify dependencies as build-time, deployment-time, or runtime only when that distinction matters.

## Selecting toolchains with mise

Use mise configuration environments for stage-specific toolchains. Keep shared tools and settings in `mise.toml`; put stage-specific tools in environment files, for example:

```text
mise.toml
mise.specs-dev.toml
mise.sources-dev.toml
mise.binaries-dev.toml
mise.distros-dev.toml
mise.workloads-dev.toml
mise.workloads-run.toml
```

Use `-E` or `MISE_ENV` to select environments. The base `mise.toml` is always loaded; selected environment files add to or override it. Multiple environments can be combined. Add a `dev` or `run` environment only when it represents a useful, independently selectable toolchain.

Use `env_sets` in `miserc.toml` to give a frequently used stage combination a short name. For example:

```toml
[env_sets]
specs = ["specs-dev"]
sources = ["sources-dev"]
binaries = ["binaries-dev"]
distros = ["distros-dev"]
workloads = ["workloads-dev", "workloads-run"]
```

Then select a stage with `mise -E binaries`. Sets are aliases for lists of environments, not separate configuration layers; expansion is one level only. Keep a set only when it makes a real workflow or local command simpler.

Use `mise use --env <name> <tool>@<version>` to update an environment file. Keep lockfiles alongside their configurations (`mise.lock` and `mise.<env>.lock`), commit them, and use locked installs in CI.

## Tool responsibilities

- **mise** selects pinned development runtimes and CLI tools, such as Go, Node.js, Task, linters, and generators. It does not by itself define an application's deployed run toolchain.
- **Go modules** are downloaded with `GOWORK=off go mod download` for component-local CI, so the workspace's `go.work` cannot hide module dependency problems.
- **npm** installs TypeSpec packages from `tsp/package-lock.json` with `npm ci`. mise installs Node.js, not project npm packages.
- **Run toolchains** are declared with the stage that owns the executable output or its distribution. They may include packaged components and external execution infrastructure. Docker Engine/BuildKit used to build an image belongs to the relevant dev toolchain; Docker Engine/containerd used to run it belongs to the run toolchain.
- **mise tasks** manage development-toolchain and dependency lifecycle operations, such as `deps:lock`, `deps:install`, and `deps:check`.
- **Task** runs and composes project operations, such as `specs:*`, `sources:*`, tests, binaries, and stack tasks.

Do not expose the same operation through both mise and Task. Run `deps:lock` deliberately; it mutates lockfiles. `deps:install` must be deterministic, and `deps:check` must detect stale manifests or lockfiles without modifying them.

For npm, prefer caching the download cache keyed by lockfile and Node/npm version. Do not cache `node_modules` without measured benefit. Avoid overlapping cache layers with mise; measure before adding another cache.

## Workflow ownership

GitHub delivers events to the repository that owns the workflow file. Component repositories therefore own event-triggered workflows and their stable check contexts.

- **Component repositories** own event adapters (`pull_request`, `merge_group`, `push`, `workflow_dispatch`), required check names, and component-specific commands.
- **Workspace** owns workspace membership and cross-repository coordination. Whether it should also own reusable workflow implementations remains open.
- **Reusable workflows** are an option, not a default. Decide their boundary based on actual reuse, caller complexity, orchestration, revision handling, and required-check stability.

Local `Binaries` and `Distros` workflows in `go-engine` are consistent with component ownership; they do not rule out sharing selected internal steps. Avoid blanket duplication and premature centralization.

## Exact revisions for PR and merge queue

A `merge_group` event provides a synthetic ref and SHA for the candidate in the repository whose queue raised the event. It does not automatically provide matching candidate SHAs for other repositories.

- Test same-repository code and configuration at the merge-group SHA.
- Select cross-repository inputs using immutable revisions pinned by the candidate (for example, in a compatibility manifest), or another explicit coordination mechanism.
- Do not claim to test a simultaneous candidate from another repository unless its revision is explicitly supplied and verified. Do not silently check out `main`.
- For `pull_request`, state whether the check tests the PR merge ref or PR head.

Required merge-queue checks must include `merge_group`. Use least-privilege permissions (normally `contents: read`); grant write access only to narrowly scoped generation workflows that need it. Never pass long-lived credentials as workflow inputs.

## Naming tasks, workflows, and jobs

Keep stage, operation, and toolchain purpose separate. Name project tasks as `stage:action`:

| Stage | Candidate tasks |
| --- | --- |
| `specs` | `specs:check`, `specs:generate` |
| `sources` | `sources:generate`, `sources:verify` |
| `binaries` | `binaries:test`, `binaries:build`, `binaries:verify` |
| `distros` | `distros:build`, `distros:verify` |
| `workloads` | `workloads:deploy`, `workloads:verify` |

Use stage-oriented workflow names and stable job IDs:

| Stage | Workflow file | Workflow name | Job IDs |
| --- | --- | --- | --- |
| `specs` | `specs.yaml` | `Specs` | `specs-check` |
| `sources` | `sources.yaml` | `Sources` | `sources-generate`, `sources-verify` |
| `binaries` | `binaries.yaml` | `Binaries` | `binaries-test`, `binaries-build` |
| `distros` | `distros.yaml` | `Distros` | `distros-build`, `distros-verify` |
| `workloads` | `workloads.yaml` | `Workloads` | `workloads-deploy`, `workloads-verify` |

A CI job prepares the stage's dev toolchain before invoking Task. Do not encode `dev` or `run` in every task or job name; these describe toolchain purpose, not lifecycle stages. Do not create separate workflows solely because a stage has both toolchains.

These are candidate conventions, not an instruction to rename existing checks immediately. Required checks may be tied to workflow/job contexts. Before renaming, inspect branch protection and rulesets, migrate the required contexts, and verify the merge queue. Keep caller-level check contexts stable when moving implementation behind a reusable workflow. Prefer stable, unambiguous displayed names; avoid dynamic matrix names for required checks.

## Triggers and path filters

- Use `pull_request` for proposed changes; deliberately include required activity types such as `opened`, `ready_for_review`, and `synchronize`.
- Decide which fast checks run for draft PRs. Required caller-level checks must still report a deterministic result.
- Use `merge_group` for required merge-queue gates and test its candidate SHA.
- Use `push` for default-branch validation and useful cache warming.
- Use `workflow_dispatch` for deliberate maintenance, generation, and diagnostics.

Do not put path filters on required workflows if they can prevent GitHub from creating a required check. Keep the caller-level check present and let an internal job skip according to an explicit path policy. Changes to workflow definitions, mise/Task configuration, lockfiles, shared stack files, and workspace coordination must trigger affected checks. Test PR, draft/ready, and merge-group behavior, including changes that match no stage-specific paths, before introducing path-based skips.

## Decisions still open

- Which stages publish versioned artifacts, and which only validate or prepare inputs?
- Where should reusable workflow logic live, if it is shared?
- How should cross-repository revisions be coordinated for integration checks and merge queues?
- Which exact checks and path policies are required for each repository?
- What are the concrete inputs and verification contract for running the complete workload in a target environment?
