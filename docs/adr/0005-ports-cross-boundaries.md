# Everything Crossing the core/adapter Boundary Is Exported

Splitting a package in two forces every identifier used by both halves into the public API. We export rather than restructure: `queryBuilder` becomes `QueryBuilder`, `defRecDS` becomes `DefRecDS`, `newService` becomes `NewService`, `newDaoPgx` becomes `NewDaoPgx`. We verified across all 19 aggregates that no export collides with an existing exported name.

The alternative — keeping data-record structs unexported inside `adapter/` and widening core's ports to take primitives instead — is architecturally tidier (a `db:"..."` struct is a persistence detail, not a domain concept) but rewrites the signature of `QueryBuilder.insertRec` and therefore all 15 `qb_sqlbuilder.go` files. That is affordable for a pilot and expensive at scale, so it is deferred to a later refinement if the export count proves painful.

`vp.go` and `tc.go` move to `adapter/`, not `core/`. Both are wire concerns: `vp.go` holds view models with `form:`/`json:` tags, and `tc.go` converts core models to SDK DTOs. Both import `github.com/orglang/go-sdk`, which would otherwise make `core` depend on an external module and void the boundary rule on day one.
