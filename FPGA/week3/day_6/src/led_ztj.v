module led_ztj (
    input               clk,
    input               rst,
/*     input               clk_out, */
    output  reg [3:0]   led
);

parameter   TIME_STATE    =   199_999_999;//4s 50_000_000*4
parameter   TIME_LED      =   24_999_999;//0.5s
parameter  /* S0 */  FLOW_LED  =   2'b01;
parameter  /* S1 */  PAOMA_LED =   2'b10;
parameter  /* S2 */  SHANSHUO  =   2'b11;  

reg [1 :0]  c_state         ;//现态
reg [1 :0]  next_state         ;//次态
reg [27:0]  cnt_state       ;//4s计数器
wire        add_cnt_state   ,
            end_cnt_state   ;
reg [24:0]  cnt_led         ;//0.5s计数器
wire        add_cnt_led     ,
            end_cnt_led     ;
reg [3 :0]  flow_led        ,
            paoma_led       ,
            shanshuo        ;

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
//三段式状态机
//状态切换
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= FLOW_LED;
    else
        c_state  <= next_state;
end
//状态跳转
always @(*) begin
    case (c_state)
        FLOW_LED:next_state =  end_cnt_state ? PAOMA_LED:FLOW_LED;
        PAOMA_LED:next_state =  end_cnt_state ? SHANSHUO:PAOMA_LED; 
        SHANSHUO:next_state =  end_cnt_state ? FLOW_LED:SHANSHUO;   
        default: next_state = FLOW_LED; 
    endcase
end
//寄存需要的led灯效果
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        flow_led <= 4'b0001;
        paoma_led<= 4'b0001;
        shanshuo <= 4'b0000;
    end
    else if(c_state == FLOW_LED & end_cnt_led)
        flow_led <= {flow_led[2:0],flow_led[3]};
    else if(c_state == PAOMA_LED & end_cnt_led)
        paoma_led <= {paoma_led[2:0],~paoma_led[3]};
    else if(c_state == SHANSHUO & end_cnt_led)
        shanshuo <= ~shanshuo;
end
//输出
always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0001;
    else if(c_state == FLOW_LED)
        led <= flow_led;
    else if(c_state == PAOMA_LED)
        led <= paoma_led;
    else if(c_state == SHANSHUO)
        led <= shanshuo;
end
endmodule