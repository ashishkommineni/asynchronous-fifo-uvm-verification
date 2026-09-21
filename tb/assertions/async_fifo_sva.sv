`timescale 1ns / 1ps

module async_fifo_sva (
    input logic wr_clk,
    input logic wr_rst_n,
    input logic wr_en,
    input logic full,
    input logic rd_clk,
    input logic rd_rst_n,
    input logic rd_en,
    input logic rd_valid,
    input logic empty
);
  ap_full_known :
  assert property (@(posedge wr_clk) disable iff (!wr_rst_n) !$isunknown(full));
  ap_empty_known :
  assert property (@(posedge rd_clk) disable iff (!rd_rst_n) !$isunknown(empty));
  ap_underflow_blocked :
  assert property (@(posedge rd_clk) disable iff (!rd_rst_n) (empty && rd_en) |=> !rd_valid);
  cp_overflow_attempt :
  cover property (@(posedge wr_clk) disable iff (!wr_rst_n) full && wr_en);
  cp_underflow_attempt :
  cover property (@(posedge rd_clk) disable iff (!rd_rst_n) empty && rd_en);
endmodule
