`timescale 1ns / 1ps

package async_fifo_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
`uvm_analysis_imp_decl(_wr)
  `uvm_analysis_imp_decl(_rd)

  localparam int DATA_WIDTH = 8;
  localparam int DEPTH = 16;

  class async_fifo_wr_item extends uvm_sequence_item;
    rand bit                  enable;
    rand bit [DATA_WIDTH-1:0] data;
    bit                       full;
    bit                       accepted;
    constraint c_enable {
      enable dist {
        1 := 8,
        0 := 2
      };
    }
    `uvm_object_utils_begin(async_fifo_wr_item)
      `uvm_field_int(enable, UVM_DEFAULT)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(full, UVM_DEFAULT)
      `uvm_field_int(accepted, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name = "async_fifo_wr_item");
      super.new(name);
    endfunction
  endclass

  class async_fifo_rd_item extends uvm_sequence_item;
    rand bit                  enable;
    bit      [DATA_WIDTH-1:0] data;
    bit                       empty;
    bit                       valid;
    bit                       accepted;
    constraint c_enable {
      enable dist {
        1 := 8,
        0 := 2
      };
    }
    `uvm_object_utils_begin(async_fifo_rd_item)
      `uvm_field_int(enable, UVM_DEFAULT)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(empty, UVM_DEFAULT)
      `uvm_field_int(valid, UVM_DEFAULT)
      `uvm_field_int(accepted, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name = "async_fifo_rd_item");
      super.new(name);
    endfunction
  endclass

  class async_fifo_wr_sequencer extends uvm_sequencer #(async_fifo_wr_item);
    `uvm_component_utils(async_fifo_wr_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class async_fifo_rd_sequencer extends uvm_sequencer #(async_fifo_rd_item);
    `uvm_component_utils(async_fifo_rd_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class async_fifo_wr_driver extends uvm_driver #(async_fifo_wr_item);
    `uvm_component_utils(async_fifo_wr_driver)
    virtual async_fifo_if #(DATA_WIDTH) vif;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "async_fifo_if is missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.wr_drv_cb.wr_en   <= 1'b0;
      vif.wr_drv_cb.wr_data <= '0;
      wait (vif.wr_rst_n === 1'b1);
      forever begin
        seq_item_port.get_next_item(req);
        vif.wr_drv_cb.wr_en   <= req.enable;
        vif.wr_drv_cb.wr_data <= req.data;
        @(vif.wr_drv_cb);
        vif.wr_drv_cb.wr_en <= 1'b0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  class async_fifo_rd_driver extends uvm_driver #(async_fifo_rd_item);
    `uvm_component_utils(async_fifo_rd_driver)
    virtual async_fifo_if #(DATA_WIDTH) vif;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "async_fifo_if is missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.rd_drv_cb.rd_en <= 1'b0;
      wait (vif.rd_rst_n === 1'b1);
      forever begin
        seq_item_port.get_next_item(req);
        vif.rd_drv_cb.rd_en <= req.enable;
        @(vif.rd_drv_cb);
        vif.rd_drv_cb.rd_en <= 1'b0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  class async_fifo_wr_monitor extends uvm_monitor;
    `uvm_component_utils(async_fifo_wr_monitor)
    virtual async_fifo_if #(DATA_WIDTH) vif;
    uvm_analysis_port #(async_fifo_wr_item) ap;
    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "async_fifo_if is missing")
    endfunction
    task run_phase(uvm_phase phase);
      async_fifo_wr_item tr;
      wait (vif.wr_rst_n === 1'b1);
      forever begin
        @(posedge vif.wr_clk);
        tr = async_fifo_wr_item::type_id::create("tr");
        tr.enable = vif.wr_en;
        tr.data = vif.wr_data;
        tr.full = vif.full;
        tr.accepted = vif.wr_en && !vif.full;
        ap.write(tr);
      end
    endtask
  endclass

  class async_fifo_rd_monitor extends uvm_monitor;
    `uvm_component_utils(async_fifo_rd_monitor)
    virtual async_fifo_if #(DATA_WIDTH) vif;
    uvm_analysis_port #(async_fifo_rd_item) ap;
    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual async_fifo_if #(DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "async_fifo_if is missing")
    endfunction
    task run_phase(uvm_phase phase);
      async_fifo_rd_item tr;
      wait (vif.rd_rst_n === 1'b1);
      forever begin
        @(posedge vif.rd_clk);
        tr = async_fifo_rd_item::type_id::create("tr");
        tr.enable = vif.rd_en;
        tr.empty = vif.empty;
        tr.accepted = vif.rd_en && !vif.empty;
        #1ps;
        tr.data  = vif.rd_data;
        tr.valid = vif.rd_valid;
        ap.write(tr);
      end
    endtask
  endclass

  class async_fifo_wr_agent extends uvm_agent;
    `uvm_component_utils(async_fifo_wr_agent)
    async_fifo_wr_sequencer sqr;
    async_fifo_wr_driver drv;
    async_fifo_wr_monitor mon;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sqr = async_fifo_wr_sequencer::type_id::create("sqr", this);
      drv = async_fifo_wr_driver::type_id::create("drv", this);
      mon = async_fifo_wr_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass

  class async_fifo_rd_agent extends uvm_agent;
    `uvm_component_utils(async_fifo_rd_agent)
    async_fifo_rd_sequencer sqr;
    async_fifo_rd_driver drv;
    async_fifo_rd_monitor mon;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sqr = async_fifo_rd_sequencer::type_id::create("sqr", this);
      drv = async_fifo_rd_driver::type_id::create("drv", this);
      mon = async_fifo_rd_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass

  class async_fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(async_fifo_scoreboard)
    uvm_analysis_imp_wr #(async_fifo_wr_item, async_fifo_scoreboard) wr_export;
    uvm_analysis_imp_rd #(async_fifo_rd_item, async_fifo_scoreboard) rd_export;
    bit [DATA_WIDTH-1:0] model_q[$];
    int writes, reads;
    function new(string name, uvm_component parent);
      super.new(name, parent);
      wr_export = new("wr_export", this);
      rd_export = new("rd_export", this);
    endfunction
    function void write_wr(async_fifo_wr_item tr);
      if (tr.accepted) begin
        model_q.push_back(tr.data);
        writes++;
      end
      if (model_q.size() > DEPTH) `uvm_error("OVERFLOW", "Reference queue exceeded FIFO depth")
    endfunction
    function void write_rd(async_fifo_rd_item tr);
      bit [DATA_WIDTH-1:0] expected;
      if (tr.accepted) begin
        if (model_q.size() == 0)
          `uvm_error("MODEL_UDF", "Read accepted before corresponding write reached scoreboard")
        else begin
          expected = model_q.pop_front();
          reads++;
          if (!tr.valid || tr.data !== expected)
            `uvm_error("DATA", $sformatf(
                       "Expected 0x%0h, got 0x%0h valid=%0b", expected, tr.data, tr.valid))
        end
      end else if (tr.valid) `uvm_error("SPURIOUS", "rd_valid asserted without accepted read")
    endfunction
    function void check_phase(uvm_phase phase);
      if (model_q.size() != 0)
        `uvm_error("NOT_EMPTY", $sformatf("%0d model entries remain", model_q.size()))
      if (writes == 0 || reads == 0)
        `uvm_error("NO_TRAFFIC", "Test did not complete both accepted writes and reads")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("ASYNC_FIFO_SUMMARY", $sformatf("Checked writes=%0d reads=%0d", writes, reads),
                UVM_LOW)
    endfunction
  endclass

  class async_fifo_coverage extends uvm_component;
    `uvm_component_utils(async_fifo_coverage)
    uvm_analysis_imp_wr #(async_fifo_wr_item, async_fifo_coverage) wr_export;
    uvm_analysis_imp_rd #(async_fifo_rd_item, async_fifo_coverage) rd_export;
    bit wr_enable, wr_full, rd_enable, rd_empty;
    covergroup wr_cg;
      cp_req: coverpoint wr_enable;
      cp_full: coverpoint wr_full;
      cx: cross cp_req, cp_full;
    endgroup
    covergroup rd_cg;
      cp_req: coverpoint rd_enable;
      cp_empty: coverpoint rd_empty;
      cx: cross cp_req, cp_empty;
    endgroup
    function new(string name, uvm_component parent);
      super.new(name, parent);
      wr_export = new("wr_export", this);
      rd_export = new("rd_export", this);
      wr_cg = new();
      rd_cg = new();
    endfunction
    function void write_wr(async_fifo_wr_item tr);
      wr_enable = tr.enable;
      wr_full   = tr.full;
      wr_cg.sample();
    endfunction
    function void write_rd(async_fifo_rd_item tr);
      rd_enable = tr.enable;
      rd_empty  = tr.empty;
      rd_cg.sample();
    endfunction
  endclass

  class async_fifo_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(async_fifo_virtual_sequencer)
    async_fifo_wr_sequencer wr_sqr;
    async_fifo_rd_sequencer rd_sqr;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class async_fifo_env extends uvm_env;
    `uvm_component_utils(async_fifo_env)
    async_fifo_wr_agent wr_agent;
    async_fifo_rd_agent rd_agent;
    async_fifo_scoreboard sb;
    async_fifo_coverage cov;
    async_fifo_virtual_sequencer vsqr;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      wr_agent = async_fifo_wr_agent::type_id::create("wr_agent", this);
      rd_agent = async_fifo_rd_agent::type_id::create("rd_agent", this);
      sb = async_fifo_scoreboard::type_id::create("sb", this);
      cov = async_fifo_coverage::type_id::create("cov", this);
      vsqr = async_fifo_virtual_sequencer::type_id::create("vsqr", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      wr_agent.mon.ap.connect(sb.wr_export);
      rd_agent.mon.ap.connect(sb.rd_export);
      wr_agent.mon.ap.connect(cov.wr_export);
      rd_agent.mon.ap.connect(cov.rd_export);
      vsqr.wr_sqr = wr_agent.sqr;
      vsqr.rd_sqr = rd_agent.sqr;
    endfunction
  endclass

  class async_fifo_write_sequence extends uvm_sequence #(async_fifo_wr_item);
    `uvm_object_utils(async_fifo_write_sequence)
    int count = 100;
    bit force_enable = 0;
    function new(string name = "async_fifo_write_sequence");
      super.new(name);
    endfunction
    task body();
      repeat (count) begin
        req = async_fifo_wr_item::type_id::create("req");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "write randomization failed")
        if (force_enable) req.enable = 1'b1;
        finish_item(req);
      end
    endtask
  endclass

  class async_fifo_read_sequence extends uvm_sequence #(async_fifo_rd_item);
    `uvm_object_utils(async_fifo_read_sequence)
    int count = 140;
    bit force_enable = 0;
    function new(string name = "async_fifo_read_sequence");
      super.new(name);
    endfunction
    task body();
      repeat (count) begin
        req = async_fifo_rd_item::type_id::create("req");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "read randomization failed")
        if (force_enable) req.enable = 1'b1;
        finish_item(req);
      end
    endtask
  endclass

  class async_fifo_vseq extends uvm_sequence;
    `uvm_object_utils(async_fifo_vseq)
    `uvm_declare_p_sequencer(async_fifo_virtual_sequencer)
    function new(string name = "async_fifo_vseq");
      super.new(name);
    endfunction
    task body();
      async_fifo_write_sequence wr;
      async_fifo_read_sequence  rd;
      wr = async_fifo_write_sequence::type_id::create("initial_wr");
      wr.count = DEPTH;
      wr.force_enable = 1;
      wr.start(p_sequencer.wr_sqr);
      fork
        begin
          wr = async_fifo_write_sequence::type_id::create("random_wr");
          wr.count = 160;
          wr.start(p_sequencer.wr_sqr);
        end
        begin
          rd = async_fifo_read_sequence::type_id::create("random_rd");
          rd.count = 220;
          rd.start(p_sequencer.rd_sqr);
        end
      join
      rd = async_fifo_read_sequence::type_id::create("drain_rd");
      rd.count = DEPTH + 24;
      rd.force_enable = 1;
      rd.start(p_sequencer.rd_sqr);
    endtask
  endclass

  class async_fifo_test extends uvm_test;
    `uvm_component_utils(async_fifo_test)
    async_fifo_env env;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = async_fifo_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      async_fifo_vseq seq;
      phase.raise_objection(this);
      seq = async_fifo_vseq::type_id::create("seq");
      seq.start(env.vsqr);
      repeat (8) @(posedge env.rd_agent.mon.vif.rd_clk);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
