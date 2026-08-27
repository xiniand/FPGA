`timescale 1ns/1ps
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
    #500
    send_data(8'hfe);
    #500
    send_data(8'h00);
    #500
    send_data(8'h02);
    #500
    send_data(8'h01);
    #500
    send_data(8'h11);
    #500
    send_data(8'haa);//错误
    #500
    send_data(8'hee);

    #1000
    send_data(8'hfe);
    #500
    send_data(8'h01);
    #500
    send_data(8'h00);
    #500
    send_data(8'h01);//错误
    #500
    send_data(8'hee);

    #1000
    send_data(8'hfe);
    #500
    send_data(8'h00);
    #500
    send_data(8'h01);
    #500
    send_data(8'h01);//错误
    #500
    send_data(8'h11);//错误
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