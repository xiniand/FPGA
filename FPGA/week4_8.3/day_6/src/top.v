module top (
    input               rst     ,
    input               clk     ,
    input               key     ,   //确认密码按键
    input       [8:0]   sw      ,   //9 个拨码开关（密码/译码器输入）
    output      [7:0]   dig     ,   //数码管段码
    output      [5:0]   sel     ,   //数码管位选
    output      [3:0]   led         //LED（爆炸闪烁/成功指示）
);
parameter delay_1   = 100_000_0;    //按键消抖 20ms
parameter TIME_1S   = 50_000_000;   //1s 倒计时计数
parameter delay     = 49_999;       //数码管扫描 5ms
parameter BOOM_TIME = 25_000_000;   //LED 爆炸闪烁周期 0.5s
parameter START_SEC = 8'd40;        //倒计时初值 40s
parameter PASSWORD  = 9'b0_1010_1010; //预设 9 位密码

wire            key_flag ;  //按键消抖脉冲
wire            key_match;  //密码匹配
wire    [3:0]   boom_led ;  //爆炸闪烁 LED
reg     [1:0]   state    ;  //状态：00 倒计时/01 成功/10 爆炸
reg     [7:0]   sec      ;  //剩余秒数
reg     [25:0]  cnt_1s   ;  //1s 计数（需容纳 TIME_1S-1=49_999_999，需 26 位）
reg     [3:0]   bcd0, bcd1 ;//BCD 个位/十位

//==================== 1s 计数 ====================
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1s <= 0;
    else if(state == 2'b00) begin
        if(cnt_1s == TIME_1S - 1)
            cnt_1s <= 0;
        else
            cnt_1s <= cnt_1s + 1;
    end
    else
        cnt_1s <= 0;
end

//==================== 倒计时秒数递减 ====================
always @(posedge clk or negedge rst) begin
    if(!rst)
        sec <= START_SEC;
    else if(state == 2'b00 && cnt_1s == TIME_1S - 1 && sec != 0)
        sec <= sec - 1;
end

//==================== 秒数拆分 BCD ====================
always @(*) begin
    bcd0 = sec % 10;
    bcd1 = sec / 10;
end

//==================== 状态机 ====================
//00 倒计时中 / 01 密码正确（拆除成功）/ 10 爆炸（输错密码或时间到）
always @(posedge clk or negedge rst) begin
    if(!rst)
        state <= 2'b00;
    else begin
        case (state)
            2'b00: begin
                if(key_flag) begin
                    if(key_match)
                        state <= 2'b01; //密码正确，拆除成功
                    else
                        state <= 2'b10; //输错密码，爆炸
                end
                else if(sec == 0 && cnt_1s == TIME_1S - 1)
                    state <= 2'b10;     //倒计时结束，爆炸
            end
            2'b01: state <= 2'b01;      //成功保持
            2'b10: state <= 2'b10;      //爆炸保持
            default: state <= 2'b00;
        endcase
    end
end

//==================== LED 输出：成功全亮 / 爆炸闪烁 / 其余熄灭 ====================
assign led = (state == 2'b01) ? 4'b1111 : boom_led;

//==================== 模块例化 ====================
key #(
    .delay_1 (delay_1)
) key_u(
    .clk    (clk     ),
    .rst    (rst     ),
    .key    (key     ),
    .flag   (key_flag)
);

yima9 #(
    .PASSWORD (PASSWORD)
) yima9_u(
    .sw     (sw      ),
    .match  (key_match)
);

led_boom #(
    .TIME (BOOM_TIME)
) led_boom_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .boom   (state == 2'b10),
    .led    (boom_led       )
);

dt_smg #(
    .delay (delay)
) dt_smg_inst(
    .rst    (rst  ),
    .clk    (clk  ),
    .bcd0   (bcd0 ),
    .bcd1   (bcd1 ),
    .bcd2   (4'd15),
    .bcd3   (4'd15),
    .bcd4   (4'd15),
    .bcd5   (4'd15),
    .dig    (dig  ),
    .sel    (sel  )
);

endmodule
