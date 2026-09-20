# Verification results

Validation date: 2026-09-20

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint` completed with Verilator |
| Executable RTL smoke test | PASS | `ASYNC_FIFO_SMOKE_PASS checks=28` |
| UVM source compile/elaboration lint | PASS | `sim/files.f`, assertions, and UVM package compiled against Accellera UVM core commit `78c0654` |

The smoke test uses unrelated write/read clocks and covers fill, drain, full/empty protection, concurrent traffic, pointer wraparound, and end-to-end ordering.

## Sign-off boundary

Cadence Xcelium was not installed in the validation environment, so no Xcelium runtime result is claimed. Run `make uvm` or `make regress` on a licensed host. RTL simulation also does not replace structural CDC analysis; production sign-off must check synchronizers, reset assumptions, Gray-pointer constraints, and reconvergence in a dedicated CDC tool.
