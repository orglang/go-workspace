# SDK Is Out of Scope for This Migration

`sdk/` contains no domain logic — only 22 `me.go` message DTO files, 8 `me_resty.go` HTTP clients, and 2 `iv_ozzo.go` validators. It is a client of the engine's driving ports, not a hexagon, and is not restructured here.

Two things surfaced while planning that remain open:

- SDK's DTOs leak inward as conversion targets. Engine imports SDK in 41 files, all `tc_goverter.gen.go`, plus `me_echo.go`, `vp.go` and `tc.go`. Moving `vp.go`/`tc.go` to `adapter/` keeps the leak out of `core/` but does not remove it. Separating the wire contract from the resty client — contract in one place, client in `engine/lib/e2e` where it is already used — deserves its own decision.
- Module paths are inconsistent: `orglang/go-engine` has no domain element, `github.com/orglang/go-sdk` does. They are joined only by `go.work`; engine's go.mod does not require SDK at all. Whether to align them is open.
