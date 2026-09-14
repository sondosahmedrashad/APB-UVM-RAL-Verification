package my_env_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_agent_pkg::*;
import my_sequence_item_pkg::*;
import my_scoreboard_pkg::*;
import apb_ral_model_pkg::*;
import apb_reg_adapter_pkg::*;


class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_agent      agent;
  my_scoreboard sco;

  apb_reg_block                         regmodel;
  apb_reg_adapter                       adapter;
  uvm_reg_predictor #(my_sequence_item) predictor;

  function new(string name = "my_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info("MY_ENV", "ENVIRONMENT + RAL BUILT", UVM_LOW)

    agent = my_agent::type_id::create("agent", this);
    sco   = my_scoreboard::type_id::create("sco", this);

    // Build the RAL block. The HDL root makes the register-level backdoor paths
    // resolve to top.DUT.<register_name>.
    regmodel = apb_reg_block::type_id::create("regmodel");
    regmodel.configure(null, "");
    regmodel.build();
    regmodel.set_hdl_path_root("top.DUT");
    regmodel.lock_model();
    regmodel.reset();

    adapter   = apb_reg_adapter::type_id::create("adapter");
    predictor = uvm_reg_predictor#(my_sequence_item)::type_id::create("predictor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Existing functional scoreboard connection.
    agent.mon.mon_ap.connect(sco.sco_ap);

    // Frontdoor RAL path:
    // reg -> map -> adapter -> APB sequencer -> APB driver.
    regmodel.default_map.set_sequencer(agent.seqr, adapter);

    // Explicit predictor path:
    // APB monitor -> predictor -> RAL mirror.
    predictor.map     = regmodel.default_map;
    predictor.adapter = adapter;
    agent.mon.mon_ap.connect(predictor.bus_in);

    // Because an explicit predictor is used, do not also auto-predict accesses.
    regmodel.default_map.set_auto_predict(0);
  endfunction

endclass

endpackage
