# Migration Template: Splitting an Aggregate into core/ and adapter/

`pool/typedef` is the first aggregate split. This is the worked example the
remaining eighteen copies: the same moves, in the same order, every time.

## The result

```
pool/typedef/core/     core.go        API, models, the service
                       ds.go          Repo, DefRecDS
                       qb.go          QueryBuilder port

pool/typedef/adapter/  di_fx.go       Module
                       ds_pgx.go      NewDaoPgx
                       me_echo.go     newControllerEcho
                       qb.go          descBinds, typeDefs
                       qb_sqlbuilder.go
                       qb_sqlbuilder_test.go
                       tc_goverter.go
                       tc_goverter.gen.go
```

Everything toolkit-specific is in `adapter/`, including `di_fx.go` (ADR 0003)
and the generated conversions, which are wire concerns (ADR 0005). Everything
in `core/` is reachable without pgx, echo, sqlbuilder, fx, or the SDK.

## Order of work

Three steps, green after each. Green in the middle matters: it is what makes the
move provably behaviour-preserving, and it is the whole reason to split one
aggregate at a time.

1. **Create `core/` with the agnostic half.** Both halves coexist. Nothing
   imports the new package yet, so this step cannot break anything.

2. **Move the toolkit-specific files into `adapter/`, importing `core`.** The
   parent's agnostic files are now dead but still compile. Confirm that before
   deleting them: if the tree is green with the parent reduced to its agnostic
   files and nothing importing it, those files were genuinely a move.

3. **Delete the parent's leftovers and repoint consumers.** Only now does the
   original package path stop existing.

## What gets exported, and what does not

Export only what crosses the boundary (ADR 0005):

| Before | After | Crosses because |
|---|---|---|
| `queryBuilder` | `core.QueryBuilder` | the port is declared in core, implemented in adapter |
| `defRecDS` | `core.DefRecDS` | named in the port's method signature |
| `newService` | `core.NewService` | `di_fx.go` provides it |
| `newDaoPgx` | `adapter.NewDaoPgx` | ADR 0005 names the DAO constructor |

Two things people expect to be exported that are not:

- **The query-builder port's methods.** `insertRec` and `selectRecByQN` become
  `InsertRec` and `SelectRecByQN` — not by preference, but because an
  unexported method in an interface cannot be implemented from another package.
- **The sqlbuilder constructor.** It is used only inside `adapter`, so it stays
  `newSQLBuilder`. Export it and revive's `unexported-return` rule fires anyway,
  since `*sqlBuilder` is unexported.

## Constructors return the port, not the concrete type

`NewService` returns `API`, `NewDaoPgx` returns `Repo`. This is forced by the
export rather than chosen: revive's `unexported-return` rule rejects an exported
constructor returning an unexported type, and nothing outside the adapter
consumes either concrete type. The existing `fx.As(...)` annotations then become
redundant but are left in place — the wiring is preserved verbatim, per ADR 0004.

## Imports

The alias is the aggregate's bare name — never the layer — for both halves,
inside the aggregate and out:

```go
import typedef "orglang/go-engine/pool/typedef/core"
```

A prefix appears only to break a collision between two same-named imports:

1. **A same-named SDK package in the same file** takes the `sdk` prefix
   (`sdktypedef`), leaving our half bare (`typedef`).
2. **The same aggregate from both `pool` and `proc` in one file** is prefixed
   on both sides: `pooltypedef`, `proctypedef`. Examples: `app/main.go`,
   `prog/core.go`, `prog/tc.go`, `pool/compexec/core.go`.
3. **A shared-kernel namesake (`adt/<aggregate>`) in the same file** takes the
   `adt` prefix (`adtcompvar`), while the sibling `pool/compvar/core` import
   stays bare `compvar`. Example:
   `pool/compvar/adapter/{ds_pgx,qb_sqlbuilder}.go`.

## goverter

Two consequences follow from conversions living in `adapter/`:

- The generated file follows the declaration into `adapter/`. It is gitignored
  (`*.gen.go`), so moving the declaration and re-running the generator is the
  whole migration.
- Every `// goverter:extend <aggregate>:Msg.*` directive in a *different*
  aggregate must be repointed at the adapter package. Grep for
  `goverter:extend` before assuming the split is contained.

## SQL table names

`descBinds` and `typeDefs` move out of `core/qb.go` into `adapter/qb.go`, and
stay unexported: a table name is a persistence detail (ADR 0006). Four
aggregates hold table names in an agnostic file — `pool/typedef`,
`pool/termdef`, `proc/typedef`, `proc/termdec`.

## Verification

- `task linter:arch` — the boundary check. To confirm it is not vacuous on a
  freshly split aggregate, plant an import from any other agnostic package into
  the new `adapter/` and check the violation is reported by name.
- `go test ./<domain>/<aggregate>/...` — the query-builder test asserts the
  generated SQL, so it is the thing that catches accidental behaviour change.
- `task linter:revive` over the split directories — a split that leaves revive
  findings is not finished.
- `task process` boots the whole fx graph; the aggregate's module registers its
  primary port, secondary port, and any cross-aggregate adapter binding. Read the
  `[Fx] PROVIDE` lines for this aggregate and confirm the bindings are unchanged.
