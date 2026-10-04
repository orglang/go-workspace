# Thin Hexagon: One core/ and One adapter/ Package Per Aggregate

Each aggregate gets two packages:

```
pool/typedef/core/      toolkit-agnostic: models, ports, behaviour, query-builder port
pool/typedef/adapter/   toolkit-specific: ds_pgx, qb_sqlbuilder, me_echo, iv_ozzo,
                                tc_goverter, and di_fx (the fx module)
```

We start thin rather than canonical (Cockburn's five packages: domain / ports / usecase / adapters-in / adapters-out) because the thin form captures the entire architectural guarantee — one checkable boundary — at a fraction of the migration cost. The canonical split remains available later as a refinement that subdivides `core/` and `adapter/`, without changing the boundary rule.

Aggregates with no driving port (pool/compvar, pool/termexp, pool/typeexp, proc/termexp, proc/typeexp, proc/commturn, proc/commexch, pool/compstep, proc/compstep) need only `core/` + `adapter/`; there is no use-case layer to speak of.

`di_fx.go` lives in `adapter/`, giving two packages per aggregate rather than three. Wiring is an adapter to the DI framework, and this keeps the hexagon thin. `app/main.go` then lists hexagon-level modules instead of twenty domain modules.
