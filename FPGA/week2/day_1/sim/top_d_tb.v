`timescale 1ns/1ps
module top_d_tb ();


    reg    clk     ;
    reg    rst     ;
    reg    D       ;
    wire    Q       ;   

initial begin
    clk = 0;//初值
    rst = 1;
    D   = 0;//初值

    #40//延时40ns
    rst = 0;//开始复位，停止工作
    #50     //延时50ns
    rst = 1;//停止复位，开始工作

    repeat(20)begin
        D = {$random};
        #50;
    end
end

always  #10 clk = ~clk;



top_d   top_d_u(
.clk     (clk),
.rst     (rst),
.D       (D  ),
.Q       (Q  )  
);
    
endmodule