package my_sequence_item_pkg;

 import uvm_pkg::*;
`include "uvm_macros.svh"

class my_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(my_sequence_item)

   rand logic   [31 : 0]    paddr  ;
   rand logic   [31 : 0]    pwdata ;
        logic   [31 : 0]    prdata ;
   rand logic               pwrite ;
        bit                 psel   ;
        bit                 penable;

   constraint paddr_c {
      paddr inside {'h0, 'h4, 'h8, 'hC, 'h10};
   }

  function new (string name = "my_sequence_item");
    super.new(name);
  endfunction

endclass

endpackage
