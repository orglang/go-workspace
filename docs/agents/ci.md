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

The arrows describe the expected lifecycle flow; each stage must declare its actual inputs rather than rely on hidden generation side effects or workflow order. In particular, the `binaries → distros` edge is an explicit artifact dependency: a distro must package or reference the immutable binary artifact produced by the binaries stage, with its artifact identity/digest and source revision. It must not silently rebuild the application from a checkout. Other stage transitions may consume committed generated sources or reproduce them from a pinned revision when that is explicitly documented.

### Toolchains

A **toolchain** is the software environment required to perform work or execute an output. Define it relative to a stage and purpose:

- **Dev toolchain:** tools and dependencies needed to develop, generate, validate, or build a stage's output. It can include an OS, system libraries, runtimes, SDKs, compilers, generators, linters, CLI tools, and project packages.
- **Run toolchain:** tools and components needed to execute the stage's output. It can span host and container layers, including OS and kernel capabilities, Docker Engine or containerd, container userspace, interpreters, shared libraries, and runtime packages. Components need not be packaged inside the output.

A stage may have a dev toolchain, a run toolchain, both, or neither. They may overlap, but need not. Some dependencies may be statically linked and require no separate runtime installation. The dev/run distinction describes purpose, not physical location. Configuration that selects application behavior is an input, but is not necessarily part of a toolchain.

A **distro** is a distributable form of the application that packages or references its runtime components, run toolchain, and distribution-specific configuration. A runtime image is one possible distro form, not the run toolchain itself. A Helm chart is another: it can package templates and defaults while referencing a runtime image by immutable digest.

### Artifact composition

The lifecycle stages describe relationships between outputs; they do not prescribe the internal layout of artifacts.

- **Sources** include application code, generated code, API/schema specifications, templates, static assets, and infrastructure or deployment definitions. Helm chart source files belong here.
- **Binaries** include executable files and, where needed, shared libraries or other compiled runtime components. A binary artifact may contain one file or several; it is not synonymous with a container image.
- **Distros** package or reference the immutable binary output from `binaries`, together with run-toolchain components and distribution metadata/configuration. They do not compile the application again. Examples include runtime images, packaged Helm charts, manifests, checksums, and signatures. Binary and other external references must resolve to pinned, reproducible inputs; preserve the binary artifact identity/digest and source revision in distro provenance.
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

Use **mise** and **Task** as the two orchestration layers, with distinct responsibilities:

- **mise** selects and installs pinned development toolchains and manages their dependency lifecycle (`deps:lock`, `deps:install`, `deps:check`).
- **Task** runs and composes project operations (`specs:*`, `sources:*`, tests, binaries, and stack tasks).

Do not expose the same operation through both. Keep `deps:lock` deliberate and mutating; `deps:install` deterministic; and `deps:check` read-only.

Cache downloaded dependencies and tool distributions where doing so improves CI performance. Key caches by the inputs that determine their contents, such as lockfiles and tool versions. Avoid caching installed dependency trees or duplicating caches across tools without measured benefit.

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
