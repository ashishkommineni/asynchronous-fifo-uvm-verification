# Asynchronous FIFO Specification

The FIFO transfers ordered `DATA_WIDTH`-bit words from `wr_clk` to unrelated `rd_clk`. `DEPTH` is a power of two. Each domain owns and resets its local binary/Gray pointer and status flag.

- A write is accepted only when `wr_en && !full` at a rising `wr_clk` edge.
- A read is accepted only when `rd_en && !empty` at a rising `rd_clk` edge.
- Accepted reads pulse `rd_valid` for one `rd_clk` cycle and return the oldest word.
- Gray pointers cross the clock boundary through two flip-flop synchronizers marked with `async_reg` attributes.
- Full/empty may change a few destination-clock cycles after remote activity; this conservative latency is intentional CDC behavior.

Binary pointers address memory and perform arithmetic. Only Gray pointers cross clock domains because consecutive Gray values differ by one bit, limiting incoherent multi-bit sampling risk.
