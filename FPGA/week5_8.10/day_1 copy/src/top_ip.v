module top_ip (
    input        clk      ,
    input        rst_n    ,
    input  [1:0] key      ,
    output [5:0] sel      ,   //位选
    output [7:0] seg          //段选    
);

wire         clk_25   ,    //2分频，40ns一个周期
             clk_150   ,    //正常时钟周期频率，20ns一个周期，改变了90°deg相位移
             clk_100  ,    //2倍频，10ns一个周期
             clk_200  ,    //4倍频，5ns一个周期
             clk_300  ;    //10倍频，2ns一个周期
clock	clock_inst (
	.areset ( ~rst_n ), //异步复位端口，接入扳机复位取反
	.inclk0 ( clk    ), //接入扳机时钟
	.c0     ( clk_25 ), //输出25Mhz 时钟
	.c1     ( clk_100 ), //输出100Mhz 时钟
	.c2     ( clk_150), //输出150Mhz时钟
	.c3     ( clk_200), //输出200Mhz时钟
	.c4     ( clk_300) //输出300Mhz时钟
	);


parameter   TIME_key = 1000000 ,
            TIME     = 24_999_999;

wire [1:0] key_out;
reg  [2:0] key_cnt;
reg       clk_save;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        key_cnt <= 0;
    else if(key_out[0] == 1)begin
        if(key_cnt > 3)
            key_cnt <=  0;
        else
            key_cnt <= key_cnt +1;
    end
    else if(key_out[1] == 1)begin
        if(key_cnt < 1)
            key_cnt <=  4;
        else
            key_cnt <=  key_cnt - 1;
    end
always @(*)
    case (key_cnt)
        0 : clk_save = clk_25;
        1 : clk_save = clk_100;
        2 : clk_save = clk_150;
        3 : clk_save = clk_200;
        4 : clk_save = clk_300;
        default: clk_save = clk_25;
    endcase

key_ip #(
    .TIME_key(TIME_key)
)key_ip_inst0 (   //按键1例化
    .clk    (clk       ),   
    .rst_n  (rst_n     ),
    .key    (key[0]     ),
    .key_out(key_out[0])
);
key_ip #(
    .TIME_key(TIME_key)
)key_ip_inst1 (   //按键2例化
    .clk    (clk       ),  
    .rst_n  (rst_n     ),
    .key    (key[1]     ),
    .key_out(key_out[1])
);

smg_dt #(
    .TIME   (TIME      )
)smg_dt_inst(     //动态数码管例化
    .clk    (clk_save  ),  
    .rst_n  (rst_n     ),
    .sel    (sel       ),  
    .seg    (seg       )   
);

endmodule
