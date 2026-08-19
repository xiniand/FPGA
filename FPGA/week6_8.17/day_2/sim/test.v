`timescale 1ns/1ps
module test ();
    reg                 clk         ;
    reg                 rst_n       ;
    reg                 rx          ;
    wire                tx          ;
    wire    [7:0]       data        ;
    wire                led         ;
    wire      [7:0]     dig         ;
    wire      [5:0]     sel         ;

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
    send_data(9'b1_0101_1000);
    #500
    send_data(9'b0_0111_1000);
    #500
    send_data(9'b1_0101_1110);
    #500
    send_data(9'b1_0101_1111);//错误
end

task send_data;
    input   [8:0] data;
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
    rx = data[8];
    #delay
    rx = 1;
    #delay;
end
endtask



top_uart_jf #(
    .MODE      (2           ),
    .TIME      (25_000_000  ),
    .CLK_FREQ  (CLK_FREQ    ),
    .BAUD_RATE (BAUD_RATE   )
) top_uart_jf_u(
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .rx         ( rx        ),//接受的数据
    .tx         ( tx        ),//发送信号
    .led        ( led       ),//偶校验错误时led亮起，正确时灭的
    .dig        ( dig       ),
    .sel        ( sel       )
);

endmodule