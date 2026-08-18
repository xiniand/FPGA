`timescale 1ns/1ps
module test ();
    reg                 clk         ;
    reg                 rst_n       ;
    reg                 rx          ;
    wire                rx_done     ;//使能：flag拉高；cnt==5207&&bit(baud_cnt)==9
    wire                parity_error;
    wire    [7:0]       data        ;

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



rx #(
    .CLK_FREQ (CLK_FREQ ),
    .BAUD_RATE(BAUD_RATE)
) rx_u(
    .clk         (clk         ),
    .rst_n       (rst_n       ),
    .rx          (rx          ),
    .rx_done     (rx_done     ),
    .parity_error(parity_error),
    .data        (data        )
);

endmodule