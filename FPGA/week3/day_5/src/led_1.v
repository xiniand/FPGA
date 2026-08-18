module led (
    input wire        clk  ,
    input wire        rst_n,
    input wire        key  ,
    output wire [3:0] led
);
/*------------按键消抖-----------*/
wire       key_out;       //消抖后按键信号  
parameter delay = 1_000_000;    //按键抖动区间为5~15ms
reg [19:0] cnt_key;       //消抖计数器
//按键消抖
//1：清零；0：计数；MAX：保持；累加
//计数
always @(posedge clk or negedge rst_n)
    if(!rst_n)
        cnt_key <=0;
    else if(key == 0)begin  //按键按下
        if(cnt_key == delay-1)
            cnt_key <=cnt_key;  //保持
        else
            cnt_key <= cnt_key +1;  //计数
    end
    else if(key == 1)
        cnt_key <=0;    //清零
//消抖
assign key_out = (cnt_key == delay-2)? 1 : 0;


/*-------------流水灯--------------*/
parameter TIME =24_999_999;
reg [24:0] cnt_l;
reg [24:0] cnt_m;

reg en;     //使能信号
reg [3:0] led_l,led_m;  //led切换信号


//反转信号控制流水灯开始和暂停
always @(posedge clk or negedge rst_n)
    if(!rst_n)begin
        cnt_l <= 0;
        led_l <= 4'b0001;
    end
    else if(cnt_l == TIME)begin
            cnt_l <= 0;
            led_l <= {led_l[2:0],led_l[3]};
        end
    else
        cnt_l <= cnt_l+1;

//翻转信号控制跑马灯开始和暂停
always @(posedge clk or negedge rst_n)
    if(!rst_n)begin
        cnt_m <= 0;
        led_m <= 4'b0001;
    end
    else if(cnt_m == TIME)begin
            cnt_m <= 0;
            led_m <= {led_m[2:0],~led_m[3]};
        end
    else
        cnt_m <= cnt_m+1;


//消抖信号使使能信号翻转
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        en <= 0;
    else if(key_out == 1)
        en <= ~en;
end  
assign led = (en == 0)? led_l:led_m;     //使能切换led功能
endmodule