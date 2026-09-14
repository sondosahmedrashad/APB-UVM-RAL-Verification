onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top/APB_vif/paddr
add wave -noupdate /top/APB_vif/pwdata
add wave -noupdate /top/APB_vif/prdata
add wave -noupdate /top/APB_vif/pwrite
add wave -noupdate /top/APB_vif/psel
add wave -noupdate /top/APB_vif/penable
add wave -noupdate /top/APB_vif/presetn
add wave -noupdate /top/APB_vif/pclk
add wave -noupdate /top/DUT/pclk
add wave -noupdate /top/DUT/presetn
add wave -noupdate /top/DUT/paddr
add wave -noupdate /top/DUT/pwdata
add wave -noupdate /top/DUT/psel
add wave -noupdate /top/DUT/pwrite
add wave -noupdate /top/DUT/penable
add wave -noupdate /top/DUT/prdata
add wave -noupdate -color Yellow /top/DUT/cntrl
add wave -noupdate -color Yellow /top/DUT/reg1
add wave -noupdate -color Yellow /top/DUT/reg2
add wave -noupdate -color Yellow /top/DUT/reg3
add wave -noupdate -color Yellow /top/DUT/reg4
add wave -noupdate /top/DUT/rdata_tmp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {5975 ns}
