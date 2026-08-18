onerror {quit -f}
vlib work
vmap work work
vlog -quiet src/dma_0.v prj/ip/ram/ram_data_2.v sim/dma_0_tb.v
vsim -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L lpm_ver work.dma_0_tb
add list -decimal /dma_0_u/data_out /dma_0_u/c_state /dma_0_u/gai_c_state /dma_0_u/gai_cnt /dma_0_u/gai_tmp /dma_0_u/wraddr /dma_0_u/wren /dma_0_u/rdaddr /dma_0_u/rden /dma_0_u/rd_scan
run -all
write list list_dma0.lst
quit -f
