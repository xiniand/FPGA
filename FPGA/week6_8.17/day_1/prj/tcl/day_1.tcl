# Copyright (C) 2018  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details.

# Quartus Prime Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition
# File: E:\FPGA\shiyan\week6_8.17\day_1\prj\tcl\day_1.tcl
# Generated on: Tue Aug 18 08:54:06 2026

package require ::quartus::project

set_location_assignment PIN_G1 -to tx
set_location_assignment PIN_N11 -to rst_n
set_location_assignment PIN_E1 -to clk
set_location_assignment PIN_N13 -to tx_data[0]
set_location_assignment PIN_L3 -to tx_data[1]
set_location_assignment PIN_P6 -to tx_data[2]
set_location_assignment PIN_P11 -to tx_data[3]
set_location_assignment PIN_P14 -to tx_data[4]
set_location_assignment PIN_N9 -to tx_data[5]
set_location_assignment PIN_N12 -to tx_data[6]
set_location_assignment PIN_M9 -to tx_data[7]
set_location_assignment PIN_E15 -to tx_star
set_location_assignment PIN_A4 -to sel[5]
set_location_assignment PIN_B4 -to sel[4]
set_location_assignment PIN_A3 -to sel[3]
set_location_assignment PIN_B3 -to sel[2]
set_location_assignment PIN_A2 -to sel[1]
set_location_assignment PIN_B1 -to sel[0]
set_location_assignment PIN_A5 -to dig[7]
set_location_assignment PIN_B8 -to dig[6]
set_location_assignment PIN_A7 -to dig[5]
set_location_assignment PIN_B6 -to dig[4]
set_location_assignment PIN_B5 -to dig[3]
set_location_assignment PIN_A6 -to dig[2]
set_location_assignment PIN_A8 -to dig[1]
set_location_assignment PIN_B7 -to dig[0]
set_location_assignment PIN_G15 -to led
set_location_assignment PIN_M2 -to rx
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_star
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx_data[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sel[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sel[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sel[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sel[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sel[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sel[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to dig[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rx
