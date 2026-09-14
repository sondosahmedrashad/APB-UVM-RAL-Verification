package my_config_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"


class my_config extends uvm_object;

 `uvm_object_utils(my_config);

 function new(string name = "my_config");
   super.new(name);
 endfunction	

endclass

endpackage
