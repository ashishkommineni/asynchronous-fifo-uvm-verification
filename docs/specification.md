# Asynchronous FIFO Specification

## Functional contract

The FIFO transfers ordered `DATA_WIDTH`-bit words from `wr_clk` to unrelated `rd_clk`. `DEPTH` must be a power of two and at least two.

| Domain event | Acceptance | Result |
|---|---|---|
| Rising `wr_clk` with `wr_en && !full` | Write accepted | Word stored and write pointer advances |
| Rising `wr_clk` with `wr_en && full` | Write rejected | Stored contents unchanged |
| Rising `rd_clk` with `rd_en && !empty` | Read accepted | Oldest word returned; `rd_valid` pulses |
| Rising `rd_clk` with `rd_en && empty` | Read rejected | `rd_valid` remains low |

## CDC architecture

Each domain owns a binary pointer for address arithmetic and converts its next pointer to Gray code. Only Gray pointers cross the boundary, through two flip-flop synchronizers marked `async_reg`. Full is computed in the write domain by comparing the next write Gray pointer with the synchronized read Gray pointer after inverting its two most-significant bits. Empty is computed in the read domain by comparing the next read Gray pointer with the synchronized write Gray pointer.

Because synchronization takes destination-clock cycles, `full` and `empty` are intentionally conservative after activity in the opposite domain. This latency protects against overflow and underflow; it is not a functional error.

## Reset and implementation assumptions

Write and read logic have separate active-low asynchronous resets. System integration must ensure reset release and subsequent traffic do not violate the intended domain-level reset strategy. The array is modeled as dual-clock memory; physical implementation must map it to a technology-supported dual-port structure with appropriate read/write collision behavior.

Simulation verifies ordering and boundary protection, but structural CDC sign-off must separately prove synchronizer recognition, Gray-bus timing assumptions, reset-domain handling, and reconvergence safety.
