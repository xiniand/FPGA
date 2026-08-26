# ModelSim/Questa 运行脚本：在 sim 目录下执行  do run.do
vlib work
vlog ../src/iic.v
vlog tb_iic.v
vsim -c work.tb_iic
run 1.5ms
quit -f
