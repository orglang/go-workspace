# Migration Order: adapter/ First, Then core/, One Aggregate at a Time

Migration is incremental, one aggregate at a time, with the build green at every step.

Within an aggregate, `adapter/` is created first. Everything toolkit-specific moves there, and the table names from `qb.go` move with it. After that step the boundary is already checkable, because `core` is still in place and by construction does not import `adapter`. Exporting the shared identifiers (`QueryBuilder`, `DefRecDS`) happens in the same step. What remains then moves into `core/`.

Pilot: `pool/typedef` — smallest aggregate with a complete set of concerns (primary port, secondary port, service, query-builder port, pgx adapter, echo adapter, fx module, generated conversions). Then `pool/termdef` and `proc/typedef`, then the aggregates with no primary port, then `pool/compexec` last: it imports 20 internal packages, so it cannot move until everything it depends on has moved.

We do not attempt a big-bang move of all 19 packages / 144 files. It would concentrate every compile break into one unreviewable change.

Engine first, as the reference implementation. SDK afterwards.
