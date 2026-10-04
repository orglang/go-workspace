# lib/ is the Framework Layer, Not a Domain

`lib/` (db, kv, lf, te, wp, ws) provides technical capabilities: database access, config loading, logging, templating, worker pools, HTTP server. It is the framework layer — hexagons depend on it, it knows nothing about hexagons.

Two deliberate exceptions:

- `db.Transactor` is a driven port declared in the infrastructure rather than inside a hexagon. It appears in all 24 `Repo` signatures, so declaring it per hexagon would duplicate it 24 times for no gain. We accept the formal violation and record it so a future reader does not "fix" it.
- `lib/e2e` consumes hexagon APIs as an external client — a legitimate driving-adapter position.

The same reasoning applies to cross-aggregate adapter binding. `pool/typedef/adapter` provides `descsem.NewDaoPgx` because that is what the hexagon needs assembled; so does `pool/termdef/adapter`, and `pool/compexec/adapter` provides `implsem` and `compsem` DAOs. Each hexagon declares its own dependencies. This means `pool` and `proc` construct separate `descsem.Repo` instances with different `descBinds` — already true today, and the migration does not change it.
