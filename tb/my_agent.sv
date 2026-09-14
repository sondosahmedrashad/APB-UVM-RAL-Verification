package my_agent_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequencer_pkg::*;
import my_driver_pkg::*;
import my_monitor_pkg::*;

`define create(type , inst_name)  type::type_id::create(inst_name,this);

class my_agent extends uvm_agent;
  `uvm_component_utils(my_agent)

 
 my_driver driver;
 my_sequencer seqr;
 my_monitor mon;


  function new (string name = "my_agent" , uvm_component parent = null);
     super.new(name , parent);
  endfunction

  
  function void build_phase(uvm_phase phase);
     super.build_phase(phase);

    `uvm_info("MY_AGENT" , "AGENT BUILT" , UVM_LOW);

     driver = `create(my_driver , "driver");
     seqr   = `create(my_sequencer, "seqr");
     mon    = `create(my_monitor,"mon");

  endfunction
  

  function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
        driver.seq_item_port.connect(seqr.seq_item_export);
  endfunction



endclass
endpackage