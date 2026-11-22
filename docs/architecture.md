# Workspace Architecture

## Repository Purpose

`go-workspace` is a meta-repository for coordinating Orglang development. It contains cross-repository documentation and automation; it is not a Go module and does not own application source code.

```text
go-workspace/
├── AGENTS.md
├── README.md
├── docs/
└── engine/   # separate Git repository: orglang/go-engine
```

The application source, its `go.mod`, history, CI configuration, and release lifecycle belong to `orglang/go-engine`. The meta-repository coordinates development and integration workflows without introducing a Go workspace or a second module boundary.

## Application Responsibility

- **engine** — the Orglang runtime, domain model, HTTP API, and process execution.
- **go-workspace** — cross-repository coordination, integration automation, and development documentation.

Changes to application source code belong in `orglang/go-engine`. The root repository should contain only changes that concern coordination, shared automation, or documentation.

## Engine Architecture

The `engine` layout is organized around business capabilities and keeps core logic separate from adapters. Preserve this structure rather than adding generic `domain/`, `application/`, and `infrastructure/` layers on top of the existing packages.

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
6. Enforce dependency boundaries with `depguard` so core/domain packages cannot import transport or infrastructure implementations.
7. Update capability documentation after each migration is complete.

## Working with the Application

From the workspace root:

```bash
# Test the application
(cd engine && go test ./...)
```

Run tests from the application repository as well, so validation uses its own module configuration and does not rely on an external workspace.
