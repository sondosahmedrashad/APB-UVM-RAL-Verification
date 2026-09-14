package my_scoreboard_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;

class my_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(my_scoreboard)

  my_sequence_item seq_item;
  uvm_analysis_export #(my_sequence_item) sco_ap;
  uvm_tlm_analysis_fifo #(my_sequence_item) sb_fifo;

  logic [31:0] Assoc_Array [bit[31:0]];

  function new(string name = "my_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    sco_ap  = new("sco_ap", this);
    sb_fifo = new("sb_fifo", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("MY_SCOREBOARD", "SCOREBOARD BUILT", UVM_LOW)

    // Known reset/default values.
    Assoc_Array[32'h00] = 32'h0000_0000;
    Assoc_Array[32'h04] = 32'h0000_0000;
    Assoc_Array[32'h08] = 32'h0000_0000;
    Assoc_Array[32'h0C] = 32'h0000_0000;
    Assoc_Array[32'h10] = 32'h0000_0000;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sco_ap.connect(sb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      sb_fifo.get(seq_item);

      if (seq_item.pwrite) begin
        // CNTRL implements only bits [3:0]. Its upper 28 bits always read zero.
        if (seq_item.paddr == 32'h00)
          Assoc_Array[seq_item.paddr] = {28'h0, seq_item.pwdata[3:0]};
        else
          Assoc_Array[seq_item.paddr] = seq_item.pwdata;
      end
      else begin
        if (seq_item.prdata === Assoc_Array[seq_item.paddr]) begin
          `uvm_info("RIGHT DATA",
            $sformatf("ADDR=0x%08h RDATA=0x%08h EXPECTED=0x%08h",
                      seq_item.paddr, seq_item.prdata,
                      Assoc_Array[seq_item.paddr]),
            UVM_LOW)
        end
        else begin
          `uvm_error("WRONG DATA",
            $sformatf("ADDR=0x%08h RDATA=0x%08h EXPECTED=0x%08h",
                      seq_item.paddr, seq_item.prdata,
                      Assoc_Array[seq_item.paddr]))
        end
      end
    end
  endtask

endclass
endpackage
