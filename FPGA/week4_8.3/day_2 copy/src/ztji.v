module ztji(
    input  wire clk  ,
    input  wire rst_n,
    output wire led_s_en,
    output wire led_l_en,
    output wire led_m_en
);
    parameter   TIME_ztji = 199_999_999,   //4s状态参数
                       S0 = 2'b01,          //状态机编码，S0，S1，S2使用的都是二进制编码
                       S1 = 2'b10,          
                       S2 = 2'b11;
    reg [27:0] cnt_ztji;                    //状态机计数器
    reg [1:0 ] ztji_n;                      //现态
    reg [1:0 ] ztji_c;                      //次态

//第一个always块，状态切换，现态(当前状态)，次态(跳转的下一个状态)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ztji_n <= S0;
    else
        ztji_n <= ztji_c;                   //状态切换
end

//第二个always块，状态切换的条件,使用组合逻辑编写
always @(*) begin
    case(ztji_n)                            //条件满足切换状态
         S0 : ztji_c = (cnt_ztji == TIME_ztji)? S1 : S0;        //三个不同的状态切换的条件
         S1 : ztji_c = (cnt_ztji == TIME_ztji)? S2 : S1;        
         S2 : ztji_c = (cnt_ztji == TIME_ztji)? S0 : S2;        
    default : ztji_c = S0; 
    endcase
end

//第三个always块
assign led_s_en = (ztji_n == S0)? 1 : 0;
assign led_l_en = (ztji_n == S1)? 1 : 0;
assign led_m_en = (ztji_n == S2)? 1 : 0;
endmodule


/* else if(ztji_n == S0)
        led_s <= ~led_s;
    else if(ztji_n == S1)
        led_l <= {led_l[2:0], led_l[3]}
    else if(ztji_n == S2)
        led_s <= {led_s[2:0],~led_s[3]} */