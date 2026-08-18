`timescale 1ns/1ns
module test();
    reg             clk             ;
    reg             rst             ;
    reg             a_1             ;
    reg             a_2             ;
    wire              a_1_posedge   ;   //上升沿检测
    wire              a_1_negedge   ;   //下降沿检测
    wire              a_1_n         ;  //双边沿检测
    wire              a_2_posedge   ;   //上升沿检测
    wire              a_2_negedge   ;   //下降沿检测
    wire              a_2_n         ; //双边沿检测     
    wire [3:0]      A               ;

//产生50MHz
always #10 clk = ~clk;

//产生激励
initial begin
    clk = 0;
    rst = 0;
    a_1 = 0;
    a_2 = 0;
    #20
    rst = 1;
    #20
    a_1 = 1;
    a_2 = 1;
    #40
    repeat(20)begin
    a_1 = {$random};
    a_2 = {$random};
    #40;
    end

    $stop;
end

//例化
dc2_4 dc2_4_u(
    .clk             (clk        ),
    .rst             (rst        ),
    .a_1             (a_1        ),
    .a_2             (a_2        ),
    .a_1_posedge     (a_1_posedge),   //上升沿检测
    .a_1_negedge     (a_1_negedge),   //下降沿检测
    .a_1_n           (a_1_n      ),  //双边沿检测
    .a_2_posedge     (a_2_posedge),   //上升沿检测
    .a_2_negedge     (a_2_negedge),   //下降沿检测
    .a_2_n           (a_2_n      ),//双边沿检测
    .A               (A          )
);
endmodule