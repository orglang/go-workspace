# Architecture Guidance

Use `GLOSSARY.md` and relevant ADRs as the source of truth for domain language and architectural constraints.

## Boundaries

- Keep core/domain logic independent from SDKs and concrete toolkits.
- Primary ports describe inbound application capabilities; primary adapters translate external requests into them.
- Secondary ports describe outbound dependencies; secondary adapters implement them.
- Export types that cross the `core/adapter` boundary.
- Keep wire-format tags and framework-specific DTO concerns in adapters.

ADR 0005 (`docs/adr/0005-ports-cross-boundaries.md`) is authoritative for boundary-crossing exports and placement.

## Package/file conventions

The repository commonly uses:

- `core.go`: domain logic, core models, primary ports, services
- `me.go`: message exchange domain logic
- `ds.go`: storage domain logic and secondary ports
- `iv.go`: input validation
- `cs.go`: config storage
- `tc.go`: domain-to-domain conversion when toolkit-agnostic
- `vp.go`: view DTOs; because of wire tags it is adapter-side
- `*_echo.go`, `*_pgx.go`, `*_resty.go`, `*_fx.go`, `*_ozzo.go`: toolkit-specific adapters

Do not infer architecture from filenames alone; imports and boundary responsibilities decide placement.

## Model conventions

Use the established suffixes consistently:

- `Ref`: machine-readable reference
- `Spec`: creation specification
- `Rec`: retrieval record without sub-abstractions
- `Mod`: modification including sub-abstractions
- `Snap`: retrieval snapshot including sub-abstractions
