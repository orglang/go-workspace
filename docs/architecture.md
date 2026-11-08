# Workspace Architecture

## Repository Purpose

`go-workspace` is a meta-repository for developing Orglang modules together. It is not a single Go module and does not own the engine source code.

```text
go-workspace/
├── AGENTS.md
├── README.md
├── go.work
├── engine/   # separate Git repository: orglang/go-engine
└── sdk/      # separate Git repository: orglang/go-sdk
```

The root `go.work` brings the local modules together:

```go
go 1.27.0

use (
    ./engine
    ./sdk
)
```

Each nested repository keeps its own `.git` directory, `go.mod`, history, CI configuration, and release lifecycle. The workspace provides a shared local development context without erasing those repository boundaries.

## Module Responsibilities

- **engine** — runtime, domain model, and process execution.
- **sdk** — public types and APIs intended for engine consumers.
- **go-workspace** — coordination of local module development, workspace configuration, and documentation for working across modules.

Changes to engine source code belong in `orglang/go-engine`; SDK source changes belong in `orglang/go-sdk`. The root repository should contain only changes that concern the workspace as a whole.

## Engine Architecture

The current `engine` layout is organized around business capabilities and keeps core logic separate from adapters. Preserve this structure rather than adding generic `domain/`, `application/`, and `infrastructure/` layers on top of the existing packages.

```text
engine/
├── adt/
│   └── <concept>/              # domain types, values, and semantic models
│       └── adapter/            # persistence and other concrete integrations
│
├── proc/
│   └── <capability>/
│       ├── core/               # use cases, services, and required ports
│       └── adapter/            # port implementations, HTTP/controller/presenter
│
├── pool/
│   └── <capability>/
│       ├── core/               # capability services and ports
│       └── adapter/            # persistence and other integrations
│
├── lib/
│   ├── tx/                     # shared transaction/connection contract
│   └── <technical-area>/
│       └── adapter/            # concrete technical implementation
│
└── app/
    ├── main.go                 # composition root
    └── web/                    # inbound HTTP adapter
```

### Package Responsibilities

| Area | Responsibility | Allowed dependencies |
|---|---|---|
| `adt/<concept>` | Domain types, invariants, and value conversions | Standard library and other domain packages |
| `proc/<capability>/core` | Application use cases and orchestration | `adt`, required ports, and shared contracts from `lib` |
| `pool/<capability>/core` | Capability services and their contracts | `adt` and other core packages through their ports |
| `*/adapter` | PostgreSQL, HTTP, serialization, and external systems | Corresponding core/domain packages and concrete drivers |
| `lib/tx` | Minimal technical transaction contract | Must not depend on a concrete driver |
| `lib/*/adapter` | Implementations of shared technical contracts | Concrete libraries and infrastructure |
| `app` | Application construction and implementation wiring | Concrete adapters and the DI container |

### Dependency Direction Rules

1. Domain models must not import transport packages, database drivers, DI frameworks, or concrete adapters.
2. Each `core` package declares the interfaces required by its use cases. Do not move an interface into a shared package solely for reuse.
3. An adapter implements a port and depends on the package that declares that port. The reverse dependency is forbidden.
4. The transactor owns transaction and connection lifetimes. Repositories receive `tx.Conn` from the callback and must not acquire connections or start transactions themselves.
5. Only the composition root knows concrete implementations and wires them to ports.
6. Do not introduce a separate layer or package without a real boundary or an independent reason to change.
7. Enforce core and domain dependency boundaries with the `depguard` rules in `engine/.depguard.yml`, invoked by the `linter:arch` Taskfile task.

## Current State and Migration

The `engine` module already has the main elements of the target architecture:

- `proc/*/core` and `pool/*/core` contain services and repository interfaces;
- `proc/*/adapter` and `pool/*/adapter` contain pgx-backed implementations and inbound adapters;
- `lib/tx` defines the transaction contract, while `lib/db/adapter` implements it using pgx;
- `app/main.go` assembles the application with Fx, and `app/web` provides the HTTP entry point.

The ADT PostgreSQL implementations for `compsem`, `descsem`, `implsem`, and `typesem` have been moved into their respective `adapter` subpackages. Domain types, DTOs, conversion functions, and repository ports remain in the domain packages. Fx wiring now references the adapter constructors.

The migration is intended to proceed in small vertical steps:

1. Capture existing contracts and behavior with tests.
2. Move one concrete driver implementation at a time from core/domain into its `adapter` package.
3. Update only the wiring; avoid changing public contracts unless necessary.
4. Run unit/integration tests and build checks.
5. Repeat for the next capability.
6. Enforce dependency boundaries with `depguard` so core/domain packages cannot import drivers, SDK packages, or concrete adapters.
7. Update capability documentation after each migration is complete.

## Working with the Workspace

From the workspace root:

```bash
# Inspect the selected workspace
go env GOWORK

# Synchronize dependencies across workspace modules
go work sync

# Test each module independently
(cd engine && go test ./...)
(cd sdk && go test ./...)
```

Testing modules independently is important: the presence of `go.work` must not hide invalid dependencies that would be unavailable to consumers of a published module.
