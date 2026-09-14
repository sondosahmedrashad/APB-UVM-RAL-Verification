transcript file ral_simulation.log
vlib work
vlog -f files.txt +cover
vsim -voptargs=+acc work.top -cover
run 0
do wave.do
run -all
coverage save apb_ral.ucdb
