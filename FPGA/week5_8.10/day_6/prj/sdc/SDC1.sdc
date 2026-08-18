
create_clock -name clk -period 20.0 [get_ports clk]

set_output_delay -max 2.0 -clock clk [get_ports {tx led dig[*] sel[*] rx_done}]
set_output_delay -min 1.0 -clock clk [get_ports {tx led dig[*] sel[*] rx_done}]

set_input_delay -max 2.0 -clock clk [get_ports {rx tx_data[*] tx_star rst_n}]
set_input_delay -min 1.0 -clock clk [get_ports {rx tx_data[*] tx_star rst_n}]