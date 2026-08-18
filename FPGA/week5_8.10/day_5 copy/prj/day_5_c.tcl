package require ::quartus::project

#=====================================================================
# AWC_C4 DVK 开发板（Cyclone IV E EP4CE6F17C8）UART 串口回环实验 引脚约束
# 顶层 top：brg + tx + rx（PC串口助手调试，无需LED）
# 使用：Quartus 打开工程后，Tools -> Tcl Scripts -> 运行本文件
#       或 Assignments -> Pin Planner 手动对照填写
#=====================================================================

#---------------- 时钟与复位 ----------------
# 50MHz 有源晶振
set_location_assignment PIN_E1 -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
# 复位（SW10 滑动开关：拨下=高=释放，拨上=低=复位；低有效）
set_location_assignment PIN_N11 -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n

#---------------- UART 串口（USB 转 UART，CP2102）----------------
set_location_assignment PIN_G1 -to tx    ;# UART_TXD：FPGA 发送 -> PC
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx
set_location_assignment PIN_M2 -to rx    ;# UART_RXD：PC -> FPGA 接收
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rx

#---------------- 待发送数据 tx_data[7:0]：拨码开关 SW1~SW8 ----------------
# 注意：滑动开关拨下（靠近板边缘）= 高=1，拨上（远离板边缘）= 低=0
set_location_assignment PIN_M9  -to tx_data[0] ;# SW1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[0]
set_location_assignment PIN_N12 -to tx_data[1] ;# SW2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[1]
set_location_assignment PIN_N9  -to tx_data[2] ;# SW3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[2]
set_location_assignment PIN_P14 -to tx_data[3] ;# SW4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[3]
set_location_assignment PIN_P11 -to tx_data[4] ;# SW5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[4]
set_location_assignment PIN_P6  -to tx_data[5] ;# SW6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[5]
set_location_assignment PIN_L3  -to tx_data[6] ;# SW7
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[6]
set_location_assignment PIN_N13 -to tx_data[7] ;# SW8
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[7]

#---------------- 发送使能 tx_star：KEY1 轻触按键（配合 key 消抖，低有效） ----------------
# 按下（低电平）= 触发发送；每按一次消抖后发送一帧
set_location_assignment PIN_E15 -to tx_star
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_star
