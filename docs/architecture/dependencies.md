# Core dependency boundaries

The dependency direction between the three aggregates is intentionally asymmetric. `adt` is the upstream shared domain kernel; `proc` and `pool` are independent application aggregates.

## Rules

- **ADT is foundational.** ADT packages own shared domain values and semantic contracts. ADT code may depend on other ADT packages, but never on `proc` or `pool`.
- **PROC may use ADT and PROC.** Process core may depend on shared ADT domain contracts and other process capabilities. It must not import pool core, adapters, or persistence/application contracts.
- **POOL may use ADT and POOL.** Pool core may depend on shared ADT domain contracts and other pool capabilities. It must not import process core, adapters, or persistence/application contracts.
- **Composition happens outside the aggregates.** The application composition root (for example, `prog` or bootstrap wiring) may assemble both aggregates and connect their ports. This is the only place that should know both sides of the integration.
- **Keep aggregate-local ports local.** A port required by a PROC use case belongs to PROC; a port required by a POOL use case belongs to POOL. Do not import another aggregate's application or persistence contract to reuse an interface.

The rules apply to aggregate core packages. They do not prohibit an aggregate from using its own capability packages, or either aggregate from using ADT-owned domain contracts. Existing adapter-direction rules continue to apply independently.

## Dependency matrix

| Source core | ADT | Same aggregate | Other application aggregate |
|---|---:|---:|---:|
| ADT | Allowed | — | Forbidden |
| PROC | Allowed | Allowed | POOL forbidden |
| POOL | Allowed | Allowed | PROC forbidden |

Imports within one aggregate must still form an acyclic Go package graph. Go's compiler detects import cycles; the regular source analysis task runs `go vet` and `depguard`.

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
