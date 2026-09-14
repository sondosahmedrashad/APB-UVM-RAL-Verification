package my_driver_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;

class my_driver extends uvm_driver #(my_sequence_item);
  `uvm_component_utils(my_driver)

  my_sequence_item req;
  virtual APB_If APB_vif;

  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info("MY_DRIVER", "DRIVER BUILT", UVM_LOW)
    req = my_sequence_item::type_id::create("req", this);

    if (!(uvm_config_db#(virtual APB_If)::get(this, "", "APB_vif", APB_vif))) begin
      `uvm_fatal("DRIVER", "FAILED GETTING INTERFACE")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    // The original environment does not have a reset sequence. The DUT itself
    // initializes all registers to zero, and the interface is kept out of a
    // transfer until the first RAL item arrives.
    APB_vif.presetn <= 1'b1;
    APB_vif.psel    <= 1'b0;
    APB_vif.penable <= 1'b0;
    APB_vif.pwrite  <= 1'b0;
    APB_vif.paddr   <= '0;
    APB_vif.pwdata  <= '0;

    forever begin
      seq_item_port.get_next_item(req);
      if (req.pwrite)
        write();
      else
        read();
      seq_item_port.item_done();
    end
  endtask

  // APB write: setup phase -> access phase -> complete.
  virtual task write();
    @(posedge APB_vif.pclk);
    APB_vif.paddr   <= req.paddr;
    APB_vif.pwdata  <= req.pwdata;
    APB_vif.pwrite  <= 1'b1;
    APB_vif.psel    <= 1'b1;
    APB_vif.penable <= 1'b0;

    @(posedge APB_vif.pclk);
    APB_vif.penable <= 1'b1;

    // At this next rising edge the DUT observes PSEL && PENABLE and performs
    // the transfer. Keep the access signals stable until the falling edge so
    // the monitor/predictor can sample the completed transfer reliably.
    @(posedge APB_vif.pclk);
    `uvm_info("DRV",
      $sformatf("Mode: WRITE WDATA=0x%08h ADDR=0x%08h",
                req.pwdata, req.paddr),
      UVM_LOW)

    @(negedge APB_vif.pclk);
    APB_vif.psel    <= 1'b0;
    APB_vif.penable <= 1'b0;
  endtask

  // APB read. PRDATA is sampled after the DUT updates rdata_tmp on the access
  // edge, avoiding the stale-read race in the original provided driver.
  virtual task read();
    @(posedge APB_vif.pclk);
    APB_vif.paddr   <= req.paddr;
    APB_vif.pwrite  <= 1'b0;
    APB_vif.psel    <= 1'b1;
    APB_vif.penable <= 1'b0;

    @(posedge APB_vif.pclk);
    APB_vif.penable <= 1'b1;

    @(posedge APB_vif.pclk);
    #1;
    req.prdata = APB_vif.prdata;
    `uvm_info("DRV",
      $sformatf("Mode: READ ADDR=0x%08h RDATA=0x%08h",
                req.paddr, req.prdata),
      UVM_LOW)

    @(negedge APB_vif.pclk);
    APB_vif.psel    <= 1'b0;
    APB_vif.penable <= 1'b0;
  endtask

endclass
endpackage
