import uvm_pkg::*;
`include "uvm_macros.svh"

import my_test_pkg::*;

module top;

APB_If APB_vif();

APB DUT(.paddr   (APB_vif.paddr),
        .pwdata  (APB_vif.pwdata),
        .prdata  (APB_vif.prdata),
        .pwrite  (APB_vif.pwrite),
        .psel    (APB_vif.psel),
        .penable (APB_vif.penable),
        .presetn (APB_vif.presetn),
        .pclk    (APB_vif.pclk));

always #10 APB_vif.pclk = ~APB_vif.pclk;

initial begin
  APB_vif.pclk = 0;
  uvm_config_db#(virtual APB_If)::set(null, "*", "APB_vif", APB_vif);
  run_test("my_test");
end

endmodule
