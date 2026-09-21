`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import async_fifo_uvm_pkg::*;
  logic wr_clk = 0, rd_clk = 0;
  always #5ns wr_clk = ~wr_clk;
  always #7ns rd_clk = ~rd_clk;
  async_fifo_if #(
      .DATA_WIDTH(DATA_WIDTH)
  ) vif (
      wr_clk,
      rd_clk
  );
  async_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .wr_clk,
      .wr_rst_n(vif.wr_rst_n),
      .wr_en(vif.wr_en),
      .wr_data(vif.wr_data),
      .full(vif.full),
      .rd_clk,
      .rd_rst_n(vif.rd_rst_n),
      .rd_en(vif.rd_en),
      .rd_data(vif.rd_data),
      .rd_valid(vif.rd_valid),
      .empty(vif.empty)
  );
  async_fifo_sva sva (
      .wr_clk,
      .wr_rst_n(vif.wr_rst_n),
      .wr_en(vif.wr_en),
      .full(vif.full),
      .rd_clk,
      .rd_rst_n(vif.rd_rst_n),
      .rd_en(vif.rd_en),
      .rd_valid(vif.rd_valid),
      .empty(vif.empty)
  );
  initial begin
    vif.wr_rst_n = 0;
    vif.rd_rst_n = 0;
    vif.wr_en = 0;
    vif.rd_en = 0;
    vif.wr_data = '0;
    repeat (4) @(posedge wr_clk);
    vif.wr_rst_n = 1;
    repeat (3) @(posedge rd_clk);
    vif.rd_rst_n = 1;
  end
  initial begin
    uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::set(null, "uvm_test_top.env.*", "vif",
                                                             vif);
    run_test("async_fifo_test");
  end
endmodule
