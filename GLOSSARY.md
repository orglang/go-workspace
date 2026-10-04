# OrgLang

OrgLang is a language and runtime for organizations: constraints expressed as
declarations, executed as processes over pools of definitions.

An `_Avoid_` list exists only to separate two words that genuinely compete for
one concept. It does not exist to keep an agent away from a word it already
knows. Where a familiar industry term and a house term name the same thing, the
familiar one wins: `primary port`, `secondary adapter`, `DTO`, `DAO`,
`controller`. A house term survives only where it is the name in the code
(`core/`, `adapter/`, `valkey`) or where the familiar term merges two things
this codebase keeps apart. When you add a term, ask whether the word you are
banning is one an agent would reach for unprompted — if yes, the definition
needs work, not the ban.

## Architecture

**Root domain**:
The largest meaningful boundary of the language, owning a coherent set of
abstractions. There are exactly three: `pool`, `proc`, `prog`.
_Avoid_: bounded context (borrowed term with different baggage)

**Aggregate**:
The unit of persistence within a root domain. Exactly one aggregate maps to
exactly one secondary port (`Repo`) and one table family. Aggregates reference
each other by reference (`SemRef`), never by object graph.
_Avoid_: entity, root entity

**Shared kernel**:
Abstractions used by every root domain with no behaviour of their own.
`adt` is the shared kernel. It is not a root domain.
_Avoid_: common library, utils

**Hexagon**:
One root domain together with its adapters. The hexagon's inside is
toolkit-agnostic; its outside is toolkit-specific.
_Avoid_: module, service, bounded context

**Core**:
The toolkit-agnostic inside of a hexagon: models, ports, behaviour.
_Avoid_: domain (overloaded here — "domain" is used at root-domain level too)

**Adapter**:
Toolkit-specific code at a hexagon's edge, translating between the outside
world and the core. Present in `pool`, `proc`, `prog` but absent from `adt`.
_Avoid_: infrastructure, plugin

**Framework layer**:
Cross-cutting technical capability with no domain meaning: database access,
logging, config, templating, worker pools, HTTP server. Lives in `lib`.
Hexagons depend on the framework layer; it knows nothing of hexagons.
_Avoid_: shared kernel (different: framework layer has behaviour, kernel has types)

**Primary port**:
The interface through which outside callers invoke a hexagon's behaviour.
Named `API` in this codebase.
_Avoid_: input port, use case

**Secondary port**:
The interface a hexagon requires from storage or an external service. Named
`Repo` in this codebase.
_Avoid_: output port, gateway

**Primary adapter**:
Code that receives external requests and calls a primary port: HTTP
controllers, presenters, message consumers.
_Avoid_: handler

**Secondary adapter**:
Code that implements a secondary port against a concrete toolkit: pgx DAOs,
query builders, REST clients.
_Avoid_: repository implementation, gateway

**Agnostic core**:
A hexagon's core package, which imports only other cores, the shared kernel,
and the framework layer. It never imports an adapter. Lives in `core/`.
_Avoid_: pure, clean, inner layer

**DTO**:
A representation shaped for crossing a boundary — tagged for JSON or form
encoding, or mirroring the SDK's DTOs. Distinct from the model the core
reasons about, and always produced by an adapter.
_Avoid_: edge model, wire model

**Conversion**:
The mapping between a model and its DTO, or between a model and its persisted
form. An adapter's responsibility.
_Avoid_: mapping, marshalling

**Message**:
The DTO crossing a hexagon's boundary. Distinct from the model the core reasons
about; conversion between the two is the adapter's job.
_Avoid_: entity, model

## Language

**Pool**:
A named set of definitions that executions draw on. The `pool` root domain.
_Avoid_: collection, set, workspace

**Process**:
A running instance created from a declaration, executing computation steps
against a pool. The `proc` root domain.
_Avoid_: service, job, task, worker

**Program**:
The top-level artifact that turns declarations into pools. The `prog` root
domain.
_Avoid_: program (as in source code), binary, build

**Declaration**:
A statement of constraints to be satisfied. The unit a process is created from.
_Avoid_: spec, config, definition

**Definition**:
A named, already-elaborated constraint. Pool-level definitions are refined
versions of declarations.
_Avoid_: spec, record, declaration

**Expression**:
A term in the constraint language, evaluated to yield a value.
_Avoid_: term (term is the broader category including types)

**Semantic**:
The referent an expression points at — a type, description, implementation,
or computation. Carried by `SemRef` across aggregates.
_Avoid_: semantic value (redundant), symbol

**Unique symbol**:
A fully-qualified, stable name identifying a definition within its domain.
_Avoid_: qualified name, QN (abbreviation only, never the canonical term)

**Value key**:
A content-derived digest identifying an expression by what it contains, not by
who defined it. Lets aggregates deduplicate definitions without knowing each
other.
_Avoid_: hash, checksum, fingerprint

**Variable**:
A named slot a computation binds and reads. Has a liability side and an asset
side recording what it owes and what it holds.
_Avoid_: field, attribute, parameter

**Step**:
One unit of computation within an execution. Executed by a pool, consumed by a
process.
_Avoid_: task, operation, instruction

**Exchange**:
A communication between processes within a turn.
_Avoid_: message (message is the DTO, exchange is the domain concept)

**Turn**:
A round of computation: a step plus the exchanges it produces.
_Avoid_: round, cycle, tick

**Execution**:
A process created from a declaration, running against a pool, binding variables
over time.
_Avoid_: process (execution is pool-side, process is proc-side — they are
distinct views of the same thing), run, job
