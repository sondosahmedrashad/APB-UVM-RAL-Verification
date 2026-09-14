package apb_reg_adapter_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;

class apb_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(apb_reg_adapter)

  function new(string name = "apb_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    // The existing APB driver updates the request item itself and does not send
    // a separate response item back to the sequencer.
    provides_responses = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    my_sequence_item tr;
    tr = my_sequence_item::type_id::create("tr");

    tr.paddr  = rw.addr;
    tr.pwrite = (rw.kind == UVM_WRITE);
    tr.pwdata = rw.data;

    return tr;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);
    my_sequence_item tr;

    if (!$cast(tr, bus_item)) begin
      `uvm_fatal("APB_ADAPTER", "bus_item is not a my_sequence_item")
    end

    rw.kind   = tr.pwrite ? UVM_WRITE : UVM_READ;
    rw.addr   = tr.paddr;
    rw.data   = tr.pwrite ? tr.pwdata : tr.prdata;
    rw.status = UVM_IS_OK;
  endfunction
endclass

endpackage
