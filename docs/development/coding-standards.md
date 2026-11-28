# Coding Standards

These standards apply to Go source code in the `orglang/go-engine` repository. They complement the architecture documented in [Workspace Architecture](../architecture.md).

## Naming

- Name a file for its primary responsibility, not merely for the types it happens to contain.
- Avoid local or unexplained abbreviations. Use established project vocabulary consistently.
- Include a technology name only when it distinguishes concrete implementations of the same responsibility.
- In a shared `adapter` package, order filename parts as **component → role → technology**; omit the component when the package already makes it clear (for example, `expr_model.go`, `expr_repo_ent.go`, `user_controller_echo.go`, `user_presenter_echo.go`). Put the technology last, and include it only when it distinguishes implementations of the same responsibility.
- When a technology-specific subpackage is justified, the package name already identifies the technology; omit it from filenames inside that package.
- Use `repo` rather than `repository`, `converter` rather than `conversion`, and `wirer` rather than `di`.
- Use agent nouns (`-er`, `-or`) for components that perform an operation (for example, `converter`, `parser`, or `serializer`). Use action or process nouns (`-tion`, `-ing`) for the operation or its logic (for example, `validation`, `serialization`, or `parsing`). Choose the term that matches the file's responsibility; do not force artificial pairs or apply suffixes mechanically.
- Name generated files consistently with their generator directive and output role. Keep generated and source files in sync when renaming.

Do not mechanically expand every short name. A short name is appropriate when it is established and unambiguous in its package (for example, `tx`, `dto`, or `api`). The package context should make the responsibility clear.

## Core file organization

Do not create a `core.go` file whose only purpose is to repeat the package name. Group core files by responsibility:

- `contract.go` — ports, interfaces, and types directly associated with those contracts.
- `<name>_model.go` — a domain model and its closely related definitions or methods (for example, `expr_model.go`).
- `service.go` — service type and constructor.
- `service_<operation>.go` — implementation of one public service operation (for example, `service_create.go`).
- `converter.go` — core conversions when they form a distinct responsibility.
- `error.go` — errors shared across the package when a separate file improves navigation.
- `<domain>_error.go` — errors belonging to one domain (for example, `expr_error.go` or `typedef_error.go`).

Use the same responsibility-first order in core and adapters: component or operation first, role second. Keep each domain model and each public service operation in its own file, even when small. Put the role before the operation in service filenames (`service_create.go`, `service_modify.go`). Methods of one type may be declared across files in the same package. Keep private helpers beside the implementation they support; small, tightly related types may remain together.

Do not introduce `core/model` or `core/service` subpackages merely to split files. Create a subpackage only when it establishes a real API, encapsulation, or dependency boundary. Do not add a speculative `query.go`; keep operation parameters beside their contract or implementation until query types form a distinct group.

## Adapter file organization

Start with a single `adapter` package and responsibility-first filenames, appending technology when needed:

```text
adapter/
├── repo_ent.go
├── definition_model_ent.go
├── create_repo_ent.go
├── user_controller_echo.go
├── request_model_echo.go
├── create_controller_echo.go
├── user_presenter_echo.go
├── converter_goverter.go
└── do_wirer.go
```

Move to technology-specific subpackages (such as `adapter/ent` or `adapter/echo`) when an adapter grows enough to benefit from independent encapsulation, navigation, or reuse. In such a package, use responsibility-based names such as `definition_model.go`, `create_repo.go`, and `user_controller.go`; do not repeat the technology suffix.

Keep each adapter model (DTOs, request/response structures, view models) and each public adapter operation in its own file. Closely related helpers may stay beside the implementation. A directory is not automatically a package boundary: subpackages have separate visibility and imports.

Adapters may depend on the core packages whose ports they implement. Core packages must not import adapters.

## File boundaries

Choose file boundaries by cohesive responsibility and by what is likely to change together, not by mechanically matching one file to one type.

- Split a file when it combines independently understandable responsibilities that can be navigated, changed, or tested separately (for example: model declarations, conversion, persistence, serialization, and validation).
- Keep closely related types, methods, and small helpers together. Do not split solely because a file is long or because it contains several types.
- In a shared adapter package, use **`[<component>_]<role>[_<technology>].go`**. Keep the component (when needed) and role first; append a technology only when it distinguishes a concrete implementation (for example, `expr_model.go`, `expr_converter.go`, `expr_repo_ent.go`, `expr_model_ent.go`, and `expr_converter_goverter.go`). This keeps the filename readable by responsibility before implementation detail.
- Name persistence models, converters, and repositories separately when they represent distinct responsibilities. Avoid vague suffixes such as `ds` when the file is actually a model, converter, or repository.
- In core, use `<component>_<role>.go` for domain-specific files (for example, `expr_model.go`); reserve generic names such as `contract.go`, `service.go`, and `error.go` for package-wide responsibilities. Name serialization and validation by their behavior (for example, `expr_json.go` and `expr_validation.go`), not as converters unless they actually convert between representations.

## Visibility

Go has no private or public files. Visibility is determined by identifier capitalization and package boundaries, not filenames.

### Core

- Export only the API required by other packages to use the capability: public domain models, ports/contracts, public operation input/output types, services, and required constructors.
- Keep scenario implementation details, helpers, intermediate types, and internal conversions unexported.
- Do not export symbols solely to make tests easier.
- If an adapter needs an internal core type, first verify whether that type belongs in the core contract and whether the package boundary is correct.

### Adapter

- Keep adapter implementations, internal types, and helpers unexported by default.
- Export only what the composition root or another package needs to assemble the application.
- Do not expose implementation details for consistency's sake or hypothetical reuse.

## Dependency and change discipline

- Keep dependencies pointing inward: core owns the ports; adapters implement them.
- Do not change architecture or public APIs merely to make filenames uniform.
- Do not retain obsolete files or create formal replacements for integrations that have been removed. In particular, after the Uber Fx migration, do not add an Fx-named wiring file; name the remaining composition responsibility (for example, `do_wirer.go`) only where a distinct wirer file is useful.
- When renaming generated-code inputs, update generator configuration and regenerate outputs rather than editing generated code by hand.
- Prefer small, behavior-preserving renames. Run `gofmt`, the affected module's tests, and the relevant build/CI checks after changes.
