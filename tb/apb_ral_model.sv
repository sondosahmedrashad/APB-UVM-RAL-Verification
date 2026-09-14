package apb_ral_model_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

// -----------------------------------------------------------------------------
// CNTRL @ 0x00
// 32-bit register, only [3:0] are writable. [31:4] are reserved/RO and read 0.
// -----------------------------------------------------------------------------
class cntrl_reg extends uvm_reg;
  `uvm_object_utils(cntrl_reg)

  rand uvm_reg_field CTRL0;
  rand uvm_reg_field CTRL1;
  rand uvm_reg_field CTRL2;
  rand uvm_reg_field CTRL3;
       uvm_reg_field RESERVED;

  bit [3:0] cov_value;
  covergroup reg_cg;
    option.per_instance = 1;
    cp_ctrl : coverpoint cov_value {
      bins ctrl_values[] = {[4'h0:4'hF]};
    }
  endgroup

  function new(string name = "cntrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
    reg_cg = new;
  endfunction

  virtual function void build();
    CTRL0 = uvm_reg_field::type_id::create("CTRL0");
    CTRL1 = uvm_reg_field::type_id::create("CTRL1");
    CTRL2 = uvm_reg_field::type_id::create("CTRL2");
    CTRL3 = uvm_reg_field::type_id::create("CTRL3");
    RESERVED = uvm_reg_field::type_id::create("RESERVED");

    CTRL0.configure(this, 1, 0, "RW", 0, 1'h0, 1, 1, 0);
    CTRL1.configure(this, 1, 1, "RW", 0, 1'h0, 1, 1, 0);
    CTRL2.configure(this, 1, 2, "RW", 0, 1'h0, 1, 1, 0);
    CTRL3.configure(this, 1, 3, "RW", 0, 1'h0, 1, 1, 0);
    RESERVED.configure(this, 28, 4, "RO", 0, 28'h0, 1, 0, 0);
  endfunction

  function void sample_cov(uvm_reg_data_t value);
    cov_value = value[3:0];
    reg_cg.sample();
  endfunction
endclass


// -----------------------------------------------------------------------------
// Common model for REG1..REG4. Each instance is a separate register in the block.
// -----------------------------------------------------------------------------
class data_reg extends uvm_reg;
  `uvm_object_utils(data_reg)

  rand uvm_reg_field DATA;

  bit [31:0] cov_value;
  covergroup reg_cg;
    option.per_instance = 1;
    cp_data : coverpoint cov_value {
      bins zero     = {32'h0000_0000};
      bins low      = {[32'h0000_0001:32'h0000_FFFF]};
      bins high     = {[32'h0001_0000:32'hFFFF_FFFE]};
      bins all_ones = {32'hFFFF_FFFF};
    }
  endgroup

  function new(string name = "data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
    reg_cg = new;
  endfunction

  virtual function void build();
    DATA = uvm_reg_field::type_id::create("DATA");
    DATA.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 0);
  endfunction

  function void sample_cov(uvm_reg_data_t value);
    cov_value = value[31:0];
    reg_cg.sample();
  endfunction
endclass


// -----------------------------------------------------------------------------
// APB register block
// -----------------------------------------------------------------------------
class apb_reg_block extends uvm_reg_block;
  `uvm_object_utils(apb_reg_block)

  rand cntrl_reg cntrl;
  rand data_reg  reg1;
  rand data_reg  reg2;
  rand data_reg  reg3;
  rand data_reg  reg4;

  uvm_reg_map default_map;

  function new(string name = "apb_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    cntrl = cntrl_reg::type_id::create("cntrl");
    cntrl.configure(this, null, "cntrl");
    cntrl.build();

    reg1 = data_reg::type_id::create("reg1");
    reg1.configure(this, null, "reg1");
    reg1.build();

    reg2 = data_reg::type_id::create("reg2");
    reg2.configure(this, null, "reg2");
    reg2.build();

    reg3 = data_reg::type_id::create("reg3");
    reg3.configure(this, null, "reg3");
    reg3.build();

    reg4 = data_reg::type_id::create("reg4");
    reg4.configure(this, null, "reg4");
    reg4.build();

    // APB data bus is 32 bits = 4 bytes. Addresses in this DUT are byte addresses.
    default_map = create_map("default_map", 32'h0, 4, UVM_LITTLE_ENDIAN, 1);
    default_map.add_reg(cntrl, 32'h00, "RW");
    default_map.add_reg(reg1,  32'h04, "RW");
    default_map.add_reg(reg2,  32'h08, "RW");
    default_map.add_reg(reg3,  32'h0C, "RW");
    default_map.add_reg(reg4,  32'h10, "RW");
  endfunction
endclass

endpackage
