# Core dependency boundaries

The dependency direction between the three aggregates is intentionally asymmetric. `adt` is the upstream shared domain kernel; `proc` and `pool` are independent application aggregates.

## Rules

- **ADT is foundational.** ADT packages own shared domain values, semantic contracts, and contracts for ADT-owned persistence. ADT code may depend on other ADT packages, but never on `proc`, `pool`, or the `prog` composition root.
- **PROC may use ADT and PROC.** Process core may depend on shared ADT domain contracts and other process capabilities. It must not import pool core, adapters, persistence/application contracts, or the `prog` composition root.
- **POOL may use ADT and POOL.** Pool core may depend on shared ADT domain contracts and other pool capabilities. It must not import process core, adapters, persistence/application contracts, or the `prog` composition root.
- **Composition happens outside the aggregates.** The application composition root (for example, `prog` or bootstrap wiring) may assemble both aggregates and connect their ports. It may depend on both aggregates; dependencies must never point back into the composition root.
- **Keep aggregate-local ports local.** A port required by a PROC use case belongs to PROC; a port required by a POOL use case belongs to POOL. ADT-owned ports remain in ADT, but do not move a PROC- or POOL-owned port into ADT, or import another application aggregate's contracts to reuse an interface.

The rules apply to aggregate core packages. They do not prohibit an aggregate from using its own capability packages, or either aggregate from using ADT-owned domain contracts. Existing adapter-direction rules continue to apply independently.

## Dependency matrix

| Source core | ADT | Same aggregate | Other application aggregate |
|---|---:|---:|---:|
| ADT | Allowed | — | Forbidden |
| PROC | Allowed | Allowed | POOL forbidden |
| POOL | Allowed | Allowed | PROC forbidden |

Imports within one aggregate must still form an acyclic Go package graph. Go's compiler detects import cycles; the existing mise source gate runs `go vet` and `depguard` (`mise run sources:gate` from the engine repository).

## Examples

Allowed dependencies:

```go
// internal/proc/typedef/core
import (
    "orglang/go-engine/internal/adt/typesem"
    "orglang/go-engine/internal/proc/typeexp/core"
)

// internal/pool/typedef/core
import (
    "orglang/go-engine/internal/adt/uniqsym"
    "orglang/go-engine/internal/pool/typeexp/core"
)

// internal/prog/core is a composition point and may see both aggregates.
import (
    pooltypedef "orglang/go-engine/internal/pool/typedef/core"
    proctypedef "orglang/go-engine/internal/proc/typedef/core"
)
```

Forbidden dependencies:

```go
// internal/proc/<capability>/core must not import:
import "orglang/go-engine/internal/pool/typedef/core"

// internal/pool/<capability>/core must not import:
import "orglang/go-engine/internal/proc/typedef/core"

// internal/adt/<concept> must not import either application aggregate:
import "orglang/go-engine/internal/proc/typedef/core"
```

The import restrictions are encoded in `engine/.golangci.yml` under `depguard`. Keep the rules here and the linter configuration aligned when aggregate boundaries change.
