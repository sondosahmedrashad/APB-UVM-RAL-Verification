package my_test_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_env_pkg::*;
import ral_sequences_pkg::*;


class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_env env;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = my_env::type_id::create("env", this);
    `uvm_info("MY_TEST", "TEST BUILT", UVM_LOW)
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    env.regmodel.print();
  endfunction

  task run_phase(uvm_phase phase);
    ctrl_reg_seq ctrl_seq;
    reg1_reg_seq reg1_seq;
    reg2_reg_seq reg2_seq;
    reg3_reg_seq reg3_seq;
    reg4_reg_seq reg4_seq;

    phase.raise_objection(this);
    `uvm_info("RUN TEST", "Starting five modular APB RAL sequences", UVM_LOW)

    ctrl_seq = ctrl_reg_seq::type_id::create("ctrl_seq");
    ctrl_seq.model = env.regmodel;
    ctrl_seq.start(null);

    reg1_seq = reg1_reg_seq::type_id::create("reg1_seq");
    reg1_seq.model = env.regmodel;
    reg1_seq.start(null);

    reg2_seq = reg2_reg_seq::type_id::create("reg2_seq");
    reg2_seq.model = env.regmodel;
    reg2_seq.start(null);

    reg3_seq = reg3_reg_seq::type_id::create("reg3_seq");
    reg3_seq.model = env.regmodel;
    reg3_seq.start(null);

    reg4_seq = reg4_reg_seq::type_id::create("reg4_seq");
    reg4_seq.model = env.regmodel;
    reg4_seq.start(null);

    `uvm_info("RUN TEST", "All APB RAL sequences completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

endpackage
