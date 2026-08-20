onerror {quit -f}
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/src {E:/FPGA/GIT/FPGA/week6_8.17/day_4/src/tx.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/src {E:/FPGA/GIT/FPGA/week6_8.17/day_4/src/top.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/src {E:/FPGA/GIT/FPGA/week6_8.17/day_4/src/rom.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/src {E:/FPGA/GIT/FPGA/week6_8.17/day_4/src/ping_pong.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/src {E:/FPGA/GIT/FPGA/week6_8.17/day_4/src/brg.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/prj/ip/rom {E:/FPGA/GIT/FPGA/week6_8.17/day_4/prj/ip/rom/rom_data.v}
vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/prj/ip/ram {E:/FPGA/GIT/FPGA/week6_8.17/day_4/prj/ip/ram/ram_data.v}

vlog -vlog01compat -work work +incdir+E:/FPGA/GIT/FPGA/week6_8.17/day_4/sim {E:/FPGA/GIT/FPGA/week6_8.17/day_4/sim/test_dump.v}

vsim -c -t 1ps -L altera_mf_ver -L altera_ver -L lpm_ver -L sgate_ver -L altera_lnsim_ver -L cycloneive_ver -L work -voptargs="+acc" test_dump

run -all
quit -f
