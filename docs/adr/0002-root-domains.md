# Root Domains: pool, proc, prog

Three root domains, each becoming one hexagon:

- **pool** — the set of pools; owns pool-level aggregates (typedef, termdef, compexec, commturn, commexch, compvar, compstep, termexp, typeexp)
- **proc** — a running process; owns process-level aggregates (termdec, termdef, compexec, commturn, commexch, compstep, termexp, typeexp)
- **prog** — the top-level program that creates pools from declarations

`adt` is explicitly NOT a root domain: it is the shared kernel of primitives (valkey, uniqsym, symbol, identity, polarity, option, seqnum) plus lookup tables (compsem, descsem, implsem, typesem, termsem, termvar, compvar, commsem). It has no driving port of its own and no external callers.

We leave `adt/` untouched. Restructuring 17 packages would move 35+ files for no architectural gain, since `adt` already has no toolkit-specific logic to isolate. This is a deliberate "no": if `adt` later grows toolkit-specific code, it gets the same treatment as any other hexagon.

Within a root domain, the persistence root is the aggregate: one `Repo` per aggregate.
