`timescale 1ns / 1ps

interface async_fifo_if #(
    parameter int DATA_WIDTH = 8
) (
    input logic wr_clk,
    input logic rd_clk
);
  logic                  wr_rst_n;
  logic                  wr_en;
  logic [DATA_WIDTH-1:0] wr_data;
  logic                  full;
  logic                  rd_rst_n;
  logic                  rd_en;
  logic [DATA_WIDTH-1:0] rd_data;
  logic                  rd_valid;
  logic                  empty;

  clocking wr_drv_cb @(negedge wr_clk);
    output wr_en, wr_data;
    input full;
  endclocking

  clocking rd_drv_cb @(negedge rd_clk);
    output rd_en;
    input rd_data, rd_valid, empty;
  endclocking
endinterface
