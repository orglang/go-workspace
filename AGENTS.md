# Organization Language and its Runtime 

## Project Repositories 

- `github.com/orglang/rationale`: Theoretical and practical rationale
- `github.com/orglang/go-workspace`: Go development workspace
- `github.com/orglang/go-engine`: Runtime implementation
- `github.com/orglang/go-sdk`: SDK implementation

## Project Structure 

- `.github`: GitHub Actions
- `.opencode`: Opencode configuration
- `rationale`: Rationale (from `github.com/orglang/rationale`)
- `sdk`: SDK component (from `github.com/orglang/go-sdk`)
- `engine`: Runtime component (from `github.com/orglang/go-engine`)
- `stack`: System-level definitions
- `docs/adr`: Architecture Decision Records (ADR)
- `docs/agents`: Agent context
- `GLOSSARY.md`: Controlled vocabulary
- `taskfile.yaml`: Root project Taskfile 

## Where and When to Look 

For guidance on reading ADRs and GLOSSARY, see `docs/agents/domain.md`. When working across boundaries or naming concepts, follow its rules. 

## Component Structure 

This is the most complete general structure of component packages. A specific component may include only part of these packages.

- `app`: Runnable program 
  - `web`: Web application 
- `adt`: Reusable abstract data types 
  - `commsem`: Communication semantics 
  - `compsem`: Computation semantics 
  - `compvar`: Computation variable 
  - `identity`: Identification value 
  - `option`: Optional value 
  - `polarity`: Polarization value 
  - `seqnum`: Sequential number 
  - `symbol`: Atomic symbol 
  - `uniqsym`: Unique (namespaced) symbol 
  - `valkey`: Content-based key
- `pool`: Pool abstract data types 
  - `commexch`: Communication exchange 
  - `commturn`: Communication turn 
  - `compexec`: Computation execution 
  - `compstep`: Computation step 
  - `compvar`: Computation variable 
  - `termdef`: Term definition 
  - `termexp`: Term expression 
  - `typedef`: Type definition 
  - `typeexp`: Type expression 
- `proc`: Process abstract data types 
  - `commexch`: Communication exchange 
  - `commturn`: Communication turn 
  - `compexec`: Computation execution 
  - `compstep`: Computation step 
  - `termdec`: Term declaration 
  - `termdef`: Term definition 
  - `termexp`: Term expression 
  - `typedef`: Type definition 
  - `typeexp`: Type expression 
- `lib`: Reusable abstract behavior types 
  - `db`, `kv`, `lf`, `te`, `wp`, `ws` (drivers/harnesses)
- `db`: Storage schema 
  - `postgres`
- `proto`: Prototypes
- `test`: Test harness 
  - `e2e` 

## Package Structure 

### Toolkit-agnostic 

A file is agnostic if and only if it does not import either the SDK (`github.com/orglang/go-sdk`) or any specific toolkit. The filename itself does not determine this: `tc.go` in `adt/identity` is agnostic, while `tc.go` in `pool/typeexp` is not.

- `core.go`: Pure domain logic 
  - Domain models (core models) 
  - API interfaces (primary ports) 
  - Service structs (core behaviors) 
- `me.go`: Pure message exchange (ME) logic 
  - Message-related DTOs 
- `ds.go`: Pure data storage (DS) logic 
  - Data-related records 
  - Repository interfaces (secondary ports) 
- `iv.go`: Pure input validation (IV) logic 
  - Message-related validation 
  - Config-related validation 
- `cs.go`: Pure config storage (CS) logic 
  - Config-related DTOs 
- `tc.go`: Pure type conversion (TC) logic 
  - Domain-to-domain conversions 

`vp.go` is not included in this list: view models carry `form:`/`json:` tags, which means they are DTOs and therefore belong to the toolkit-specific side. Domain-to-domain conversions in `tc.go` are agnostic; conversions to/from SDK DTOs are not.

### Toolkit-specific 

- `di_fx.go`: Fx (dependency injection library) specific component definitions
- `me_echo.go`: Echo (web framework) specific controller definitions (primary adapters)
- `vp.go`: View presentation (VP) logic — view models with `form:`/`json:` tags
- `vp_echo.go`: Echo (web framework) specific presenter definitions (primary adapters)
- `me_resty.go`: Resty (HTTP library) specific client definitions (secondary adapters for external use)
- `ds_pgx.go`: pgx (PostgreSQL driver and toolkit) specific DAO definitions (secondary adapters for internal use)
- `iv_ozzo.go`: Ozzo (validation library) specific validation definitions
- `tc.go`: Type conversion (TC) logic for models that are converted to/from SDK DTOs
- `tc_goverter.go`: Goverter (type conversion tool) specific conversion definitions
- `vp/bs5/*.html`: Go's built-in `html/template` and Bootstrap 5 (frontend toolkit) specific presentation definitions

Verifiable proof: all seven files below import `github.com/orglang/go-sdk`, so they belong to the toolkit-specific side of the boundary:

```
pool/typeexp/tc.go    proc/typeexp/tc.go    pool/termexp/tc.go
proc/termexp/tc.go    prog/tc.go            proc/typedef/vp.go
proc/termdec/vp.go
```

When splitting a package into `core/` and `adapter/`, `vp.go` and such `tc.go` files move to `adapter/` — see ADR 0005 `docs/adr/0005-ports-cross-boundaries.md`.

## Model Structure 

- `<model>Ref`: Machine-readable pointer to an abstraction 
- `<model>Spec`: Specification to create an abstraction 
- `<model>Rec`: Record for abstraction retrieval (excluding sub-abstractions) 
- `<model>Mod`: Modification to change an abstraction (including sub-abstractions) 
- `<model>Snap`: Snapshot for abstraction retrieval (including sub-abstractions) 

## Artifact Structure 

Artifacts are prepared in a local repository and then published to a remote repository.

`check1` ⟶ `prepare` ⟶ `check2` ⟶ `publish`

### Artifact groups 

- `app`: Everything related to the application
- `gear`: Everything related to the pipeline, including harnesses for rollout

### Artifact types 

- `sources`: Source code (including generated)
- `binaries`: Binaries produced by compilation/linking
- `distros`: Distribution-ready packages

`sources` ⟶ `binaries` ⟶ `distros`

### Tests

- `unit`, `integration`, `e2e`

### CI Job Matrix 

| CI job | `check1`  | `prepare` | `check2`  |
|-----|--------------------------|-----------|----------------------------|
| `app/sources` | linting, static analysis | code generation, formatting | unit tests |
| `gear/sources` | linting, validation | formatting | unit tests (if present) |
| `app/binaries` | integration tests against mocks/stubs etc. | compilation, linking | integration tests against real services |
| `gear/binaries` | — | — | — |
| `app/distros` | lightweight e2e tests | packaging | 1. heavyweight e2e tests<br>2. backward compatibility check against `gear:latest` |
| `gear/distros` | dry-run of rollout | packaging | 1. full rollout<br>2. backward compatibility check against `app:latest` |

## Development Process 

### Task Stages 

1. `modification` : Active code modification stage. Only `sources` checks run in CI.
1. `stabilization` : Stabilization of system components and environment components. Only `binaries` checks run in CI.
1. `verification` : Verification/coordination of the system as a whole. Only `distros` checks run in CI.
1. `finalization` : Final acceptance of code. All CI jobs run, then the tag `latest` is applied.

### Transitions Between Stages 

1. [*] ⟶ `modification` : Pull request does not exist or is in `closed(unmerged)`.
1. [*] ⟶ `stabilization` : Pull request is created or in `draft`.
1. [*] ⟶ `verification` : Pull request is created or in `ready_for_review`.
1. [*] ⟶ `finalization` : Pull request is in `closed(merged)`.

`modification` ⟶ `stabilization` ⟶ `verification` ⟶ `finalization`

## Git Workflow 

- **Commits**: The agent does not create commits automatically. Commits are allowed only on feature/task branches (non-`main`/`trunk`) and only when explicitly requested by the user and when necessary. Examples: "commit these changes", "stage and commit with message X", "prepare a commit". Vague requests do not imply permission. **Never** commit directly to `main`/`trunk` — integration happens exclusively via pull requests (PRs).
- **PR-oriented flow**: All substantive changes follow the PR flow according to the stages above. Local exploration is allowed during `modification` (with or without a PR). Transitions between stages are driven by PR state (`draft` / `ready_for_review` / `merged`).
- **Safety**: Do not force-push, modify git config, skip hooks, use interactive `-i` mode, or create empty commits unless explicitly requested. Before committing, inspect `git status`, `git diff`, and relevant history; stage only intended files and never commit secrets.
- **CI failure detection**: After pushing or updating a PR, inspect CI status with `gh` (`gh pr checks <pr-number>`, `gh pr view <pr-number> --json statusCheckRollup`, or `gh pr checks --watch`). Use `gh run list --branch <branch>` / `gh run view <run-id>` for logs. Any failing check blocks progression to the next stage; report failures with links to runs/logs. Never assume success after pushing. For long-running checks (especially e2e/distros), consult the user about whether to wait (with timeout/polling), continue other independent work, or check back later (user-driven).

## Taskfiles Usage 

- **Prefer canonical tasks**: Use canonical tasks defined in `taskfile.yaml` (and sub-Taskfiles in `engine/`, `sdk/`) for verification and common workflows. Preferred examples: `task sources` / `task engine:sources`, `task binaries` / `task engine:binaries`, `task engine:tests:unit|it|e2e`, `task distros`, as well as specific linter/generator tasks where appropriate.
- **Hybrid approach**: If a suitable canonical task is defined, prefer it. If no suitable task exists, fall back to direct Bash commands only when appropriate and safe (per the configured permissions). Do not invent alternative command chains that duplicate existing canonical checks.
- **Stage alignment**: Use tasks that match the current stage — primarily `sources`-related checks during `modification`, `binaries`-related checks during `stabilization`, and `distros`-related checks during `verification`.
- **Preferred entrypoints**: Treat canonical tasks as the preferred entrypoints. This aligns with the permissions defined in `.opencode/opencode.json`.

## Verification Gates by Stage 

### `modification` — no PR, or PR in `closed(unmerged)`

- **Local:** Run `sources` checks via canonical tasks (`gofmt -s -l`, linters: `vet`, `revive`, `errcheck`, `critic`, `consistent`, `staticcheck`, `arch`). Optionally run unit tests scoped to affected packages; skip heavy checks. **Do not push if local sources checks fail.**
- **CI:** `app/sources` checks per matrix — linting, static analysis, codegen, formatting validation, unit tests.

### `stabilization` — PR in `draft`

- **Local:** Ensure unit tests pass for changed code; run relevant sanity checks locally. Fix issues locally before pushing.
- **CI:** `app/binaries` checks per matrix — unit tests + integration tests (against mocks/stubs; against real services as applicable), compilation/linking.

### `verification` — PR in `ready_for_review`

- **Local:** Light smoke checks only. Avoid running full e2e locally unless explicitly requested. Ensure the branch is up to date with the base branch.
- **CI:** `app/distros` checks per matrix — lightweight e2e, packaging. As applicable for `gear/distros`, full e2e and backward compatibility checks against `gear:latest`/`app:latest`.

### `finalization` — PR in `closed(merged)`

- **Local:** None required after merge.
- **CI:** All jobs run; tag `latest` is applied.
