# Go client generator comparison

Tracking: [go-workspace#114](https://github.com/orglang/go-workspace/issues/114)

## Input contract

The prototype downloads the committed OpenAPI document from
`orglang/go-engine` at merge commit
`6f4adf576dd62d34d34c3d19e569966f81a59143`. The input is therefore fixed
and identical for both generators.

Contract profile (OpenAPI 3.1.0):

| Feature | Observed in contract |
|---|---:|
| Paths / operations | 19 / 21 |
| Component schemas | 60 |
| `oneOf` with explicit discriminator | 4 |
| Optional query parameters | 8 |
| Path parameters | 13 |
| Header parameters | 0 |
| Nullable fields / enums | 0 / 0 |
| Security schemes | 0 |
| Success response codes | 200, 201, 204 |

The important differentiator in this contract is the four discriminated
`oneOf` expression models. Authentication, error envelopes, nullable fields,
and enums are not currently represented in the contract; their absence is not
evidence that a generator supports those features.

## Reproducible prototype

The workflow pins:

- `ogen v1.24.0`
- `oapi-codegen v2.8.1`
- Go `1.27.0`

It generates a client-only package from the same immutable OpenAPI revision
with each tool, runs `go mod tidy` and `go test ./...` in each output, records
generated source size and module dependencies, and uploads both outputs as a
14-day workflow artifact.

The workflow is deliberately isolated from the workspace's Go modules. No
generated source is committed and neither prototype is wired into a consumer.

## Evaluation criteria

The result must be reviewed against:

1. Whether both generators parse OpenAPI 3.1 and generate all 21 operations.
2. Whether the four discriminated unions are represented as usable typed Go
   sum types, including JSON decoding/encoding of each variant.
3. Whether optional `rn` query and path parameters are exposed ergonomically.
4. Whether the generated client supports a caller-supplied `net/http`
   transport, request context/cancellation, and typed response/status errors.
5. Whether generated packages compile from a clean module and what runtime
   dependencies they add.
6. Generated source size, regeneration determinism, and configuration burden.

No winner is selected from feature marketing or release notes alone. The
generator decision remains open until the workflow has run successfully and
the generated APIs have been inspected against a representative consumer.

## Current status

The contract profile is statically inspected. The pinned generation/compile
prototype is executable in GitHub Actions; its output and metrics are the
evidence required to complete the comparison. This document intentionally
does not claim that either generator has already passed against this contract.
