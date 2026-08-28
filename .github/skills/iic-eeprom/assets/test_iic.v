`timescale 1ns/1ps
// IIC+EEPROM 顶层仿真测试（UART 帧下发写/读命令）
// 参考: FPGA/week7_8.24/day_5/sim/test_iic.v
module test_iic();
    reg               clk         ;
    reg               rst_n       ;
    reg               rx          ;
    wire              tx          ;
    tri0              sda         ;//数据线总线
    tri0              scl         ;//时钟线

parameter CLK_FREQ  = 50_000_000                    ;// 系统时钟频率
parameter BAUD_RATE = 9_600                         ;// 目标波特率
localparam delay    = CLK_FREQ/BAUD_RATE *20        ;

initial begin
    clk <= 0 ;
end
always #10 clk = ~clk;

initial begin
    rst_n <= 0  ;
    #100
    rst_n <= 1  ;
end

initial begin
    // 第一帧：写 EEPROM
    #500
    send_data(8'hfe);   // 包头
    #500
    send_data(8'h00);   // 写
    #500
    send_data(8'h05);   // 发送字节数
    #500
    send_data(8'h00);   // 接收字节数
    #500
    send_data(8'h21);   // EEPROM 地址
    #500
    send_data(8'hee);   // 数据1
    #500
    send_data(8'hcf);   // 数据2
    #500
    send_data(8'had);   // 数据3
    #500
    send_data(8'hdc);   // 数据4

    // 第二帧：读 EEPROM
    #10000
    send_data(8'hfe);   // 包头
    #500
    send_data(8'h01);   // 读
    #500
    send_data(8'h04);   // 发送字节数(地址1+数据0 => 实际随机读需先写地址)
    #500
    send_data(8'h21);   // 起始地址

end

task send_data;
    input   [7:0] data;
begin
    rx = 1;
    #100
    rx = 0;//起始位
    #delay
    rx = data[0];
    #delay
    rx = data[1];
    #delay
    rx = data[2];
    #delay
    rx = data[3];
    #delay
    rx = data[4];
    #delay
    rx = data[5];
    #delay
    rx = data[6];
    #delay
    rx = data[7];
    #delay
    rx = 1;
    #delay;
end
endtask

top_iic_eeprom top_iic_eeprom_u(
    .clk        (clk  ),
    .rst_n      (rst_n),
    .rx         (rx   ),
    .scl        (scl  ),
    .sda        (sda  ),
    .tx         (tx   )
);

endmodule
