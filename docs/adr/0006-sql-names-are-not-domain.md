# SQL Table Names Belong to the Adapter

`pool/typedef/qb.go`, `pool/termdef/qb.go`, `proc/typedef/qb.go` and `proc/termdec/qb.go` currently hold SQL table names (`descBinds = "pool_desc_binds "`, `typeDefs = "pool_type_defs "`) inside toolkit-agnostic code.

These move to `adapter/`. A table name is not a domain concept; renaming a table should require editing an adapter, not the core. Leaving them in `core` ties the domain model to the physical schema.

A stronger alternative — treating table names as declared identity of the persistence root, kept in `core` and validated against the Liquibase manifests in `db/` — is arguably more correct but couples the core to migration tooling. Deferred.
