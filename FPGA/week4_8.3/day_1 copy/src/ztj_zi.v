module ztj_zi (
    input               clk,
    input               rst,
    output  reg [3:0]   led
);
    
parameter   TIME_STATE      = 199_999_999   ,//4s
            TIME_LED        =  24_999_999   ,//0.5s
            TIME_FAST       =  12_499_999   ,//0.25s
            TIME_ZI_STATE   =  99_999_999   ;//2s
localparam  S0              = 2'b00         ,//流水
            S1              = 2'b01         ,//跑马
            S2              = 2'b10         ;//闪烁
localparam  SLOW         = 2'b01             ,
            FAST         = 2'b11             ;

reg [27:0]  cnt_state                       ;//4s
wire        add_cnt_state                   ,
            end_cnt_state                   ;

reg [24:0]  cnt_led                         ;//0.5s
wire        add_cnt_led                     ,
            end_cnt_led                     ;

reg [24:0]  cnt_s0_led                      ;//0.25s
wire        add_cnt_s0_led                  ,
            end_cnt_s0_led                  ;

reg [26:0]  cnt_s0_state                    ;//2s
wire        add_cnt_s0_state                ,
            end_cnt_s0_state                ;

reg [1:0]   c_state                         ,//现态
            n_state                         ;//次态
reg         s0_c_state                      ,//s0子现态
            s0_n_state                      ;//s0子次态
reg [3:0]   liushui_led                ,
            paoma_led                ,
            shanshuo_led                ;
//0.5s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_led <= 0;
    else if(add_cnt_led)begin
        if(end_cnt_led)
            cnt_led <= 0;
        else 
            cnt_led <= cnt_led + 1;
    end
end
assign  add_cnt_led = 1;
assign  end_cnt_led = add_cnt_led && (cnt_led == TIME_LED);
//4s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_state <= 0;
    else if(add_cnt_state)begin
        if(end_cnt_state)
            cnt_state <= 0;
        else 
            cnt_state <= cnt_state + 1;
    end
end
assign  add_cnt_state = 1;
assign  end_cnt_state = add_cnt_state && (cnt_state == TIME_STATE);
//0.25s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_s0_led <= 0;
    else if(add_cnt_s0_led)begin
        if(end_cnt_s0_led)
            cnt_s0_led <= 0;
        else 
            cnt_s0_led <= cnt_s0_led + 1;
    end
end
assign  add_cnt_s0_led = 1;
assign  end_cnt_s0_led = add_cnt_s0_led && (cnt_s0_led == TIME_FAST);
//2s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_s0_state <= 0;
    else if(add_cnt_s0_state)begin
        if(end_cnt_s0_state)
            cnt_s0_state <= 0;
        else 
            cnt_s0_state <= cnt_s0_state + 1;
    end
end
assign  add_cnt_s0_state = 1;
assign  end_cnt_s0_state = add_cnt_s0_state && (cnt_s0_state == TIME_ZI_STATE);
//两段式状态机
//状态切换
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= S0;
    else
        c_state <= n_state;
end
//状态转移
always @(*) begin
    case (c_state)
        S0:n_state = end_cnt_state ? S1 : S0;
        S1:n_state = end_cnt_state ? S2 : S1;
        S2:n_state = end_cnt_state ? S0 : S2;
        default: n_state = S0;
    endcase
end
//两段式子状态机
//状态切换
always @(posedge clk or negedge rst) begin
    if(!rst)
        s0_c_state <= SLOW;
    else
        s0_c_state <= s0_n_state;
end
//状态转移
always @(*) begin
    case (s0_c_state)
        SLOW:s0_n_state = end_cnt_s0_state ? FAST : SLOW;
        FAST:s0_n_state = end_cnt_s0_state ? SLOW : FAST;
        default: s0_n_state = SLOW;
    endcase
end
//led状态
always @(posedge clk or negedge rst) begin
    if(!rst)   begin
        liushui_led <= 4'b0001;
        paoma_led        <= 4'b0001;
        shanshuo_led     <= 4'b0000;
    end
    else if(c_state == S0)begin
        if((s0_c_state == SLOW) && end_cnt_led)
            liushui_led <= {liushui_led[2:0],liushui_led[3]};
        else if((s0_c_state == FAST) && end_cnt_s0_led)
            liushui_led <= {liushui_led[2:0],liushui_led[3]};
    end
    else if(c_state == S1)begin
        if((s0_c_state == SLOW) && end_cnt_led)
            paoma_led <= {paoma_led[2:0],~paoma_led[3]};
        else if((s0_c_state == FAST) && end_cnt_s0_led)
            paoma_led <= {paoma_led[2:0],~paoma_led[3]};
    end
    else if(c_state == S2)begin
        if((s0_c_state == SLOW) && end_cnt_led)
            shanshuo_led <= ~shanshuo_led;
        else if((s0_c_state == FAST) && end_cnt_s0_led)
            shanshuo_led <= ~shanshuo_led;
    end
end

always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0000;
    else if(c_state == S0)
        led <= liushui_led;
    else if(c_state == S1)
        led <= paoma_led;
    else if(c_state == S2)
        led <= shanshuo_led;
end

endmodule