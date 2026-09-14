package ral_sequences_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;
import apb_ral_model_pkg::*;

// Base sequence shared by the five modular register sequences.
class ral_base_seq extends uvm_sequence #(my_sequence_item);
  `uvm_object_utils(ral_base_seq)

  apb_reg_block model;

  function new(string name = "ral_base_seq");
    super.new(name);
  endfunction

  function void report_state(string tag,
                             string operation,
                             uvm_reg rg,
                             uvm_reg_data_t design_value);
    `uvm_info(tag,
      $sformatf("%s | DESIGN=0x%08h DESIRED=0x%08h MIRRORED=0x%08h",
                operation,
                design_value,
                rg.get(),
                rg.get_mirrored_value()),
      UVM_LOW)
  endfunction

  function void report_model_only(string tag,
                                  string operation,
                                  uvm_reg rg);
    `uvm_info(tag,
      $sformatf("%s | DESIRED=0x%08h MIRRORED=0x%08h",
                operation,
                rg.get(),
                rg.get_mirrored_value()),
      UVM_LOW)
  endfunction

  task exercise_reg(uvm_reg rg,
                    uvm_reg_data_t first_value,
                    uvm_reg_data_t second_value,
                    string tag,
                    output uvm_reg_data_t sample_a,
                    output uvm_reg_data_t sample_b);
    uvm_status_e status;
    uvm_reg_data_t fd_value;
    uvm_reg_data_t bd_value;

    if (model == null)
      `uvm_fatal(tag, "RAL model handle was not assigned to the sequence")

    // 1) Set only changes the desired value. It does not touch the DUT.
    rg.set(first_value);
    report_model_only(tag, "After set()", rg);

    // 2) update() notices desired != mirrored and performs a frontdoor APB write.
    rg.update(status, UVM_FRONTDOOR, model.default_map, this);
    if (status != UVM_IS_OK)
      `uvm_error(tag, "Frontdoor update() failed")

    // 3) Backdoor peek reads the design directly through the HDL path.
    rg.peek(status, bd_value, "", this);
    if (status != UVM_IS_OK)
      `uvm_error(tag, "Backdoor peek() failed")
    report_state(tag, "After frontdoor update() + backdoor peek()", rg, bd_value);
    sample_a = bd_value;

    // 4) Frontdoor read goes RAL -> map -> adapter -> sequencer -> driver -> DUT.
    rg.read(status, fd_value, UVM_FRONTDOOR, model.default_map, this);
    if (status != UVM_IS_OK)
      `uvm_error(tag, "Frontdoor read() failed")
    report_state(tag, "After frontdoor read()", rg, fd_value);

    // 5) Direct frontdoor write with another value.
    rg.write(status, second_value, UVM_FRONTDOOR, model.default_map, this);
    if (status != UVM_IS_OK)
      `uvm_error(tag, "Frontdoor write() failed")

    // 6) Backdoor read verifies the physical design value without APB activity.
    rg.read(status, bd_value, UVM_BACKDOOR, null, this);
    if (status != UVM_IS_OK)
      `uvm_error(tag, "Backdoor read() failed")
    report_state(tag, "After frontdoor write() + backdoor read()", rg, bd_value);
    sample_b = bd_value;
  endtask
endclass


class ctrl_reg_seq extends ral_base_seq;
  `uvm_object_utils(ctrl_reg_seq)
  function new(string name = "ctrl_reg_seq"); super.new(name); endfunction

  virtual task body();
    uvm_reg_data_t a, b;
    `uvm_info("CTRL_SEQ", "Starting CNTRL register sequence", UVM_LOW)
    exercise_reg(model.cntrl, 32'h0000_0005, 32'h0000_000A,
                 "CTRL_SEQ", a, b);
    model.cntrl.sample_cov(a);
    model.cntrl.sample_cov(b);
  endtask
endclass


class reg1_reg_seq extends ral_base_seq;
  `uvm_object_utils(reg1_reg_seq)
  function new(string name = "reg1_reg_seq"); super.new(name); endfunction

  virtual task body();
    uvm_reg_data_t a, b;
    `uvm_info("REG1_SEQ", "Starting REG1 sequence", UVM_LOW)
    exercise_reg(model.reg1, 32'h1111_0001, 32'hA5A5_0001,
                 "REG1_SEQ", a, b);
    model.reg1.sample_cov(a);
    model.reg1.sample_cov(b);
  endtask
endclass


class reg2_reg_seq extends ral_base_seq;
  `uvm_object_utils(reg2_reg_seq)
  function new(string name = "reg2_reg_seq"); super.new(name); endfunction

  virtual task body();
    uvm_reg_data_t a, b;
    `uvm_info("REG2_SEQ", "Starting REG2 sequence", UVM_LOW)
    exercise_reg(model.reg2, 32'h2222_0002, 32'h5A5A_0002,
                 "REG2_SEQ", a, b);
    model.reg2.sample_cov(a);
    model.reg2.sample_cov(b);
  endtask
endclass


class reg3_reg_seq extends ral_base_seq;
  `uvm_object_utils(reg3_reg_seq)
  function new(string name = "reg3_reg_seq"); super.new(name); endfunction

  virtual task body();
    uvm_reg_data_t a, b;
    `uvm_info("REG3_SEQ", "Starting REG3 sequence", UVM_LOW)
    exercise_reg(model.reg3, 32'h3333_0003, 32'hDEAD_BEEF,
                 "REG3_SEQ", a, b);
    model.reg3.sample_cov(a);
    model.reg3.sample_cov(b);
  endtask
endclass


class reg4_reg_seq extends ral_base_seq;
  `uvm_object_utils(reg4_reg_seq)
  function new(string name = "reg4_reg_seq"); super.new(name); endfunction

  virtual task body();
    uvm_reg_data_t a, b;
    `uvm_info("REG4_SEQ", "Starting REG4 sequence", UVM_LOW)
    exercise_reg(model.reg4, 32'h4444_0004, 32'h1234_5678,
                 "REG4_SEQ", a, b);
    model.reg4.sample_cov(a);
    model.reg4.sample_cov(b);
  endtask
endclass

endpackage
