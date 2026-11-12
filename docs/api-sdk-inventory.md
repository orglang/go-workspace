# Go SDK and HTTP API inventory

Tracking issue: [orglang/go-workspace#114](https://github.com/orglang/go-workspace/issues/114)

Status: discovery snapshot for PR 1. This document records the current repository/code evidence and a proposed ownership boundary. It does not define or claim that an OpenAPI contract already exists.

## Executive summary

- No TypeSpec project or OpenAPI document was found in the accessible `orglang` repositories.
- `orglang/go-engine` currently exposes a small HTTP API under `/api/v1` through Echo controllers.
- `orglang/go-sdk` contains public message/DTO models, validation, parser-related API, and handwritten Resty clients. It is not only an HTTP client, and it should not be deleted wholesale as part of generating a client.
- The only in-organization consumer of `github.com/orglang/go-sdk` found by repository-wide code search is `orglang/go-engine`. It uses SDK models in HTTP adapters and Resty clients in E2E tests. Public downstream consumers outside the organization have not been ruled out.
- Proposed initial ownership: keep the TypeSpec source and emitted OpenAPI with `orglang/go-sdk`, and place the generated Go client in a dedicated package in that same module (proposed import path: `github.com/orglang/go-sdk/client`). Keep `go-workspace` as the workspace/documentation coordinator, not the API source repository. This is a proposal to confirm before PR 2.

## Repository inventory

The accessible `orglang` repositories are:

| Repository | Observed responsibility | Relevance to this work |
|---|---|---|
| `go-workspace` | Meta-repository; root `go.work`, workspace docs and coordination | Cross-repository planning and integration only |
| `go-engine` | Runtime and HTTP server; Echo controllers and internal domain/application code | Owns current server implementation and is the only discovered in-org SDK consumer |
| `go-sdk` | Go module `github.com/orglang/go-sdk`; public message models, validators, parser API, Resty adapters | Best current candidate to own the public wire contract and generated Go client |
| `rationale` | OrgLang domain rationale/documentation | Domain background; no TypeSpec/OpenAPI or Go SDK consumer usage found |
| `.github` | Organization profile repository | No API contract or SDK consumer evidence found |
| `.agents` | Private, currently empty repository | No relevant source evidence |

The workspace root `go.work` uses `./engine` and `./sdk`; these are separate Git repositories with independent modules and release lifecycles. The workspace architecture document says source changes to the engine and SDK belong in their respective repositories.

Relevant references:
- [Workspace architecture](architecture.md)
- [Workspace README](../README.md)
- [go-engine README](https://github.com/orglang/go-engine/blob/main/README.md)
- [go-sdk README](https://github.com/orglang/go-sdk/blob/main/README.md)
- [SDK boundary ADR](adr/0008-sdk-out-of-scope.md)

## Existing SDK surface

The SDK module path is `github.com/orglang/go-sdk` (Go 1.27). Its README documents these public package groups:

| Package group | Current purpose |
|---|---|
| `adt/` | Semantic/reference and variable message types |
| `pool/` | Pool component specs, steps, snapshots and related message models |
| `proc/` | Process component specs, steps, snapshots and related message models |
| `prog/` | Program parsing/spec API |
| `lib/rc` | Resty client construction and Fx wiring |

The SDK also contains `iv_ozzo.go` validators and `me_resty.go` HTTP adapters in several `pool` and `proc` packages.

Examples:
- [SDK README](https://github.com/orglang/go-sdk/blob/main/README.md)
- [SDK Resty base client](https://github.com/orglang/go-sdk/blob/main/lib/rc/resty.go)
- [Pool execution Resty adapter](https://github.com/orglang/go-sdk/blob/main/pool/compexec/me_resty.go)
- [Process type-definition Resty adapter](https://github.com/orglang/go-sdk/blob/main/proc/typedef/me_resty.go)

The Resty base client hardcodes `http://localhost:8080/api/v1`. Several client methods are placeholders returning empty values without making requests (for example, pool/process `Incept`, `Retrieve`, `Modify`, and reference-list methods). The pool execution client has a `Retrieve` method that calls `GET /pools/{id}`, but no matching server route was found.

The SDK README describes these packages as public types/specifications/models. The engine's current `.golangci.yml` explicitly calls dependencies on the SDK “wire-format SDK dependencies” and restricts them to inbound/outbound adapters; it also separately says SDK mapping belongs in adapters. Therefore the safe boundary is: generated/wire types at the transport edge, conversions into internal engine types in adapters, and no SDK imports in engine core/domain.

An older workspace ADR (0008) describes the SDK as message DTOs, Resty clients, and validators and raises separation of the wire contract from the Resty client as an open design question. Its statement that the engine module does not require the SDK is stale relative to the current `go-engine/go.mod`, which does require `github.com/orglang/go-sdk`. The ADR is useful as historical context, not as an exact snapshot of current code.

## Current HTTP routes in go-engine

The following routes were found in the Echo controller registrations loaded by `cmd/engine/main.go`. The request/response descriptions below reflect handler code, not a proposed stable API contract.

| Method | Path | Request model/body | Success response |
|---|---|---|---|
| POST | `/api/v1/progs` | Raw program text; parsed with `sdkprog.MsgFromText` | 201, no body |
| POST | `/api/v1/xacts/defs` | `pool/typedef.DefSpec` | 201, `typesem.SemRef` |
| POST | `/api/v1/procs/decs` | `proc/termdec.DecSpec` | 201, `DecSnap` |
| GET | `/api/v1/procs/decs/:id` | Path ID/reference binding | 200, `DecSnap` |
| GET | `/api/v1/procs/:id` | Path ID/reference binding | 200, process `ExecSnap` |
| POST | `/api/v1/procs/:id/steps` | `proc/compstep.StepSpec` | 200, no body |
| POST | `/api/v1/types` | `proc/typedef.DefSpec` | 201, `DefSnap` |
| GET | `/api/v1/types/:id` | Path ID/reference binding | 200, `DefSnap` |
| PATCH | `/api/v1/types/:id` | `proc/typedef.DefSnap` | 200, `DefSnap` |
| POST | `/api/v1/pools/decs` | `pool/termdec.DecSpec` | 201, `termsem.SemRef` |
| POST | `/api/v1/pools/execs` | `pool/compexec.ExecSpec` | 201, `compsem.SemRef` |
| POST | `/api/v1/pools/execs/steps` | `pool/compstep.StepSpec` | 204, no body |
| POST | `/api/v1/pools/execs/spawns` | `pool/compstep.StepSpec` | 201, `compsem.SemRef` |

No list/search endpoints were found in the registered `/api/v1` controllers. The UI presenter routes under `/ssr` are server-rendered web endpoints and are not included in this API inventory.

Relevant controller sources:
- [Program controller](https://github.com/orglang/go-engine/blob/main/internal/prog/adapter/me_echo.go)
- [Process type controller](https://github.com/orglang/go-engine/blob/main/internal/proc/typedef/adapter/me_echo.go)
- [Process declaration controller](https://github.com/orglang/go-engine/blob/main/internal/proc/termdec/adapter/me_echo.go)
- [Process execution controller](https://github.com/orglang/go-engine/blob/main/internal/proc/compexec/adapter/me_echo.go)
- [Pool type-definition controller](https://github.com/orglang/go-engine/blob/main/internal/pool/typedef/adapter/me_echo.go)
- [Pool declaration controller](https://github.com/orglang/go-engine/blob/main/internal/pool/termdef/adapter/me_echo.go)
- [Pool execution controller](https://github.com/orglang/go-engine/blob/main/internal/pool/compexec/adapter/me_echo.go)
- [Engine composition root](https://github.com/orglang/go-engine/blob/main/cmd/engine/main.go)

## Consumers and dependency boundary

Repository-wide search for `github.com/orglang/go-sdk` found references in `orglang/go-engine`, and no other in-organization repository. Search indexing is not enabled for every repository, so this is evidence of the only discovered consumer, not proof that no external or unindexed consumer exists.

The engine uses the SDK in two distinct ways:

1. **Server-side inbound/outbound adapters:** Echo handlers bind SDK DTOs, validate them, convert them to internal engine types, call core APIs, and convert results back to SDK response DTOs.
2. **E2E HTTP client:** `internal/lib/e2e/core.go` constructs the SDK's Resty adapters; `test/e2e/pool_test.go` exercises operations through the HTTP server.

The engine's `go.mod` currently requires `github.com/orglang/go-sdk` at a pseudo-version. The workspace `go.work` connects the local `engine` and `sdk` modules. The module paths are asymmetric: `orglang/go-engine` versus `github.com/orglang/go-sdk`.

References:
- [Engine module dependencies](https://github.com/orglang/go-engine/blob/main/go.mod)
- [E2E API wrappers](https://github.com/orglang/go-engine/blob/main/internal/lib/e2e/core.go)
- [E2E pool tests](https://github.com/orglang/go-engine/blob/main/test/e2e/pool_test.go)
- [Engine import-boundary rules](https://github.com/orglang/go-engine/blob/main/.golangci.yml)

## Gaps and API decisions required before TypeSpec

The current handlers are enough to seed an operation inventory, but not enough to claim a complete public API contract. PR 2 must decide and document at least:

- Whether all 13 current routes are public API, or whether some are internal/experimental.
- Whether `POST /api/v1/progs` should accept raw text or a structured JSON request.
- Stable path and resource naming; the existing route tree mixes `types`, `procs/decs`, `pools/decs`, and `xacts/defs`.
- Whether process/pool execution snapshots and references should share schemas or remain distinct.
- Pagination/list operations and retrieval operations currently absent from the route set.
- Authentication and authorization policy. The inspected Echo setup installs request logging middleware only; no API authentication middleware was found there.
- A stable error response schema and status-code mapping. Handlers return errors to Echo; a public error envelope was not found in the inspected API handlers/setup.
- Versioning and compatibility policy for the public contract.
- Whether the generated client is intended for external users or initially only for in-organization/E2E use.

There are also existing client/server mismatches and incomplete client methods. These should be treated as migration evidence, not silently copied into TypeSpec.

## Proposed repository/package ownership

Based on the current repository boundaries:

- **TypeSpec source and emitted OpenAPI:** propose `orglang/go-sdk`, in a dedicated directory (for example, `tsp/` plus a deterministic OpenAPI output directory). This repository already owns the public wire/message models and handwritten HTTP client surface. There is no existing dedicated API-contract repository.
- **Generated Go client:** propose the same `orglang/go-sdk` module, in a separate generated package (proposed import path `github.com/orglang/go-sdk/client`). This preserves the existing module path while separating generated transport code from legacy message/parser packages.
- **Server implementation and mapping:** `orglang/go-engine`; generated wire models should be consumed only from inbound/outbound adapters, with explicit mapping to internal core/domain types.
- **Workspace coordination:** `orglang/go-workspace`; retain `go.work`, cross-module docs, and integration checks here. It is a meta-repository, not a Go module or service.

This proposal avoids creating another repository before there is a demonstrated need, keeps the public contract beside the Go SDK it describes, and respects the existing engine/SDK repository split. If the intended contract must be owned independently of Go or consumed by multiple language SDKs, a dedicated API-contract repository should be considered instead.

## PR 1 outcome and remaining confirmation

The repository and code inventory is complete for the accessible public `orglang` repositories. The evidence supports `go-engine` as the current server/consumer and `go-sdk` as the current public wire-model/client module. No current TypeSpec/OpenAPI source exists.

The proposed ownership above is a reasoned default, not an irreversible decision. Before PR 2, confirm that the public API contract should be owned by `orglang/go-sdk` and that the generated client should be published from `github.com/orglang/go-sdk/client`. Also confirm the intended public audience and initial API scope.