`timescale 1ns / 1ps

module async_fifo #(
    parameter  int unsigned DATA_WIDTH = 8,
    parameter  int unsigned DEPTH      = 16,
    localparam int unsigned ADDR_WIDTH = $clog2(DEPTH),
    localparam int unsigned PTR_WIDTH  = ADDR_WIDTH + 1
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  rd_valid,
    output logic                  empty
);

  initial begin
    if (DEPTH < 2 || (DEPTH & (DEPTH - 1)) != 0)
      $fatal(1, "DEPTH must be a power of two and at least 2");
  end

  logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];

  logic [PTR_WIDTH-1:0] wr_bin_q, wr_bin_next;
  logic [PTR_WIDTH-1:0] wr_gray_q, wr_gray_next;
  logic [PTR_WIDTH-1:0] rd_bin_q, rd_bin_next;
  logic [PTR_WIDTH-1:0] rd_gray_q, rd_gray_next;

  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] rd_gray_sync1_q, rd_gray_sync2_q;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] wr_gray_sync1_q, wr_gray_sync2_q;

  logic [PTR_WIDTH-1:0] rd_gray_full_compare;
  logic                 wr_accept;
  logic                 rd_accept;
  logic                 full_next;
  logic                 empty_next;

  assign wr_accept = wr_en && !full;
  assign rd_accept = rd_en && !empty;

  assign wr_bin_next = wr_bin_q + wr_accept;
  assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
  assign rd_bin_next = rd_bin_q + rd_accept;
  assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

  // Standard asynchronous-FIFO full test: compare the next write Gray pointer
  // with the synchronized read pointer after inverting its two MSBs.
  always_comb begin
    rd_gray_full_compare = rd_gray_sync2_q;
    rd_gray_full_compare[PTR_WIDTH-1-:2] = ~rd_gray_sync2_q[PTR_WIDTH-1-:2];
  end

  assign full_next  = (wr_gray_next == rd_gray_full_compare);
  assign empty_next = (rd_gray_next == wr_gray_sync2_q);

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_bin_q  <= '0;
      wr_gray_q <= '0;
      full      <= 1'b0;
    end else begin
      wr_bin_q  <= wr_bin_next;
      wr_gray_q <= wr_gray_next;
      full      <= full_next;
      if (wr_accept) mem[wr_bin_q[ADDR_WIDTH-1:0]] <= wr_data;
    end
  end

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_bin_q  <= '0;
      rd_gray_q <= '0;
      rd_data   <= '0;
      rd_valid  <= 1'b0;
      empty     <= 1'b1;
    end else begin
      rd_bin_q  <= rd_bin_next;
      rd_gray_q <= rd_gray_next;
      empty     <= empty_next;
      rd_valid  <= rd_accept;
      if (rd_accept) rd_data <= mem[rd_bin_q[ADDR_WIDTH-1:0]];
    end
  end

  // Read pointer synchronization into write clock domain.
  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      rd_gray_sync1_q <= '0;
      rd_gray_sync2_q <= '0;
    end else begin
      rd_gray_sync1_q <= rd_gray_q;
      rd_gray_sync2_q <= rd_gray_sync1_q;
    end
  end

  // Write pointer synchronization into read clock domain.
  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      wr_gray_sync1_q <= '0;
      wr_gray_sync2_q <= '0;
    end else begin
      wr_gray_sync1_q <= wr_gray_q;
      wr_gray_sync2_q <= wr_gray_sync1_q;
    end
  end

endmodule
