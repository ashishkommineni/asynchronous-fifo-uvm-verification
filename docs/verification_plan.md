# Verification Plan

| Goal | Method |
|---|---|
| Ordered CDC transfer | Dual-agent traffic and shared queue scoreboard |
| Independent clock rates | 100 MHz write clock, ~71.4 MHz read clock |
| Full/empty behavior | Directed fill/drain plus assertion coverage |
| Overflow/underflow blocking | Requests while full/empty |
| Concurrent traffic | Forked write and read sequences |
| Pointer wraparound | Hundreds of accepted operations |
| Reset values | Domain-local assertions and startup checks |

## Environment and constraints

Separate active write and read agents are required because neither clock can safely schedule the other domain. Each item weights enable high to maintain traffic while still creating idle cycles. The write monitor publishes only operations accepted with `!full`; the read monitor publishes accepted reads plus `rd_valid` and returned data. Their shared queue scoreboard checks order, detects overflow/spurious-valid behavior, and must finish empty with both read and write activity observed.

Functional coverage independently crosses write request with `full` and read request with `empty`. SVA checks known flags and blocks `rd_valid` after an underflow request; cover properties target explicit overflow and underflow attempts.

## Closure and sign-off boundary

Closure requires zero UVM errors/fatals, passing SVA, both request/status crosses hit, and `ASYNC_FIFO_SMOKE_PASS` from the unrelated-clock portable test. RTL simulation is not CDC sign-off: synchronizer recognition, Gray-bus skew constraints, reset-domain assumptions, and reconvergence still require a structural CDC tool.
