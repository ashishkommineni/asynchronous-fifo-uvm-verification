`timescale 1ns / 1ps
module tb_async_fifo_smoke;
  localparam int DATA_WIDTH = 8, DEPTH = 8;
  logic wr_clk, rd_clk, wr_rst_n, rd_rst_n, wr_en, rd_en;
  logic [DATA_WIDTH-1:0] wr_data, rd_data;
  logic full, empty, rd_valid;
  int checks = 0;
  initial wr_clk = 0;
  always #5 wr_clk = ~wr_clk;
  initial rd_clk = 0;
  always #7 rd_clk = ~rd_clk;
  async_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .*
  );
  async_fifo_sva sva (
      .wr_clk,
      .wr_rst_n,
      .wr_en,
      .full,
      .rd_clk,
      .rd_rst_n,
      .rd_en,
      .rd_valid,
      .empty
  );

  task automatic push(input logic [DATA_WIDTH-1:0] data);
    @(negedge wr_clk);
    wr_en   = 1;
    wr_data = data;
    @(posedge wr_clk);
    #1;
    wr_en = 0;
  endtask
  task automatic pop_check(input logic [DATA_WIDTH-1:0] exp);
    while (empty) @(posedge rd_clk);
    @(negedge rd_clk);
    rd_en = 1;
    @(posedge rd_clk);
    #1;
    if (!rd_valid || rd_data !== exp)
      $fatal(1, "expected=%02h actual=%02h valid=%0b", exp, rd_data, rd_valid);
    checks++;
    rd_en = 0;
  endtask

  initial begin
    wr_rst_n = 0;
    rd_rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = '0;
    repeat (4) @(posedge wr_clk);
    wr_rst_n = 1;
    repeat (3) @(posedge rd_clk);
    rd_rst_n = 1;

    for (int i = 0; i < DEPTH; i++) push(DATA_WIDTH'(8'h40 + i));
    while (!full) @(posedge wr_clk);
    // A full-domain write must not corrupt data.
    push(8'hEE);
    for (int i = 0; i < DEPTH; i++) pop_check(DATA_WIDTH'(8'h40 + i));
    while (!empty) @(posedge rd_clk);
    @(negedge rd_clk);
    rd_en = 1;
    @(posedge rd_clk);
    #1;
    if (rd_valid) $fatal(1, "underflow produced rd_valid");
    rd_en = 0;

    fork
      begin
        for (int i = 0; i < 20; i++) begin
          while (full) @(posedge wr_clk);
          push(DATA_WIDTH'(8'h80 + i));
        end
      end
      begin
        repeat (4) @(posedge rd_clk);
        for (int i = 0; i < 20; i++) pop_check(DATA_WIDTH'(8'h80 + i));
      end
    join
    $display("ASYNC_FIFO_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
