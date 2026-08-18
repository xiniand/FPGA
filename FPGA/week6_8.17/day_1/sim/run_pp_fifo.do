transcript on
if {[file exists work]} {
	vdel -lib work -all
}
vlib work
vmap work work

vlog -vlog01compat -work work +incdir+E:/FPGA/shiyan/week6_8.17/day_1/prj/ip {E:/FPGA/shiyan/week6_8.17/day_1/prj/ip/fifo_data.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/shiyan/week6_8.17/day_1/src {E:/FPGA/shiyan/week6_8.17/day_1/src/pp_fifo.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/shiyan/week6_8.17/day_1/sim {E:/FPGA/shiyan/week6_8.17/day_1/sim/test_pp_fifo.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L work -voptargs="+acc"  test_pp_fifo

add wave *
view structure
view signals
run -all
quit -f
