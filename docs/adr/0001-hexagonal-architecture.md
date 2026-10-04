# Hexagonal Architecture for Engine and SDK

We choose Hexagonal Architecture (Ports & Adapters) over strict Clean Architecture. Clean Architecture's separate entity/use-case/interactor layering adds ceremony that fights Go's idioms — implicit interfaces, co-located behaviour, composition over inheritance. Hexagonal maps onto what the codebase already does (separating toolkit-agnostic logic from toolkit-specific adapters) while giving those boundaries a name and an automated check.

The boundary rule: a package's agnostic core must not import its toolkit-specific adapters. Adapters may import the core. Verified by static analysis over the import graph, not convention alone.
