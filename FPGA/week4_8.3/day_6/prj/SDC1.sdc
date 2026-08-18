# 50MHz 系统时钟约束
create_clock -name clk -period 20.0 [get_ports clk]

# 输出延迟约束（数码管、LED）
set_output_delay -max 2.0 -clock clk [get_ports {sel dig led}]
set_output_delay -min 1.0 -clock clk [get_ports {sel dig led}]

# 输入延迟约束（按键、拨码开关）
set_input_delay -max 2.0 -clock clk [get_ports {key sw}]
set_input_delay -min 1.0 -clock clk [get_ports {key sw}]

# 复位输入延迟约束
set_input_delay -max 2.0 -clock clk [get_ports rst*]
set_input_delay -min 1.0 -clock clk [get_ports rst*]
