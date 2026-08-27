`timescale 1ns/1ps
module test_iic_m();
    reg               clk         ;
    reg               rst_n       ;
    reg               rx          ;
    wire              tx          ;
    tri1              sda         ;//数据线总线（弱上拉，模拟 IIC 上拉电阻）
    tri1              scl         ;//时钟线

parameter CLK_FREQ  = 50_000_000                    ;// 系统时钟频率 
parameter BAUD_RATE = 9_600                         ;// 目标波特率
localparam delay    = CLK_FREQ/BAUD_RATE *20        ;

// 挂 EEPROM 行为模型
eeprom_24c02 eeprom_24c02_u(
    .sda (sda),
    .scl (scl)
);

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
    #500
    // 命令1：写 1 字节（rw=0, sendnum=1, recvnum=0, addr=0x00, data=0xAA）
    send_data(8'hfe);
    #500
    send_data(8'h00);
    #500
    send_data(8'h01);
    #500
    send_data(8'h00);
    #500
    send_data(8'h00);
    #500
    send_data(8'haa);
    #500
    send_data(8'hee);

    #10000
    // 命令2：读 1 字节（rw=1, sendnum=0, recvnum=1）
    send_data(8'hfe);
    #500
    send_data(8'h01);
    #500
    send_data(8'h00);
    #500
    send_data(8'h01);
    #500
    send_data(8'hee);
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
