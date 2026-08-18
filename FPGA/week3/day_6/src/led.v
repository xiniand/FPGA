module led (
    input               rst,
    input               clk,
    input               key,
    output  reg [3:0]   led
);
parameter   delay_1 = 24_999_999    ;//0.5s
/*             delay_2 = 200_000_000   ;//4s */
parameter   FLOW_LED    =   2'b01   ,
            PAOMA_LED   =   2'b11   ,
            SHAN_LED    =   2'b10   ;
reg [24:0]  cnt_led                 ;
wire        add_cnt_led             ,
            end_cnt_led             ;

reg [1:0]  cnt_state               ;
wire        add_cnt_state           ,
            end_cnt_state           ;
            
/* reg [27:0]  cnt_state               ;
wire        add_cnt_state           ,
            end_cnt_state           ; */
reg [1:0]   c_state                 ,
            n_state                 ;
reg [3:0]   flow_led                ,
            paoma_led               ,
            shan_led                ;

//0.5s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_led <=0;
    else if(add_cnt_led)begin
        if(end_cnt_led)
            cnt_led <= 0;
        else
            cnt_led <= cnt_led + 1;
    end
end
assign add_cnt_led = 1;
assign end_cnt_led = add_cnt_led && (cnt_led == delay_1);
//4s计数器
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_state <=0;
    else if(add_cnt_state)begin
        if(end_cnt_state)
            cnt_state <= 0;
        else
            cnt_state <= cnt_state + 1;
    end
end
assign add_cnt_state = 1;
assign end_cnt_state = add_cnt_state && (cnt_state == delay_2); */
//三段式状态机
//状态切换
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <=  FLOW_LED;
    else 
        c_state <= n_state;
end
//状态跳转
always @(*) begin
    case (c_state)
        FLOW_LED    :   n_state = (key)?PAOMA_LED:FLOW_LED;
        PAOMA_LED   :   n_state = (key)?SHAN_LED:PAOMA_LED; 
        SHAN_LED    :   n_state = (key)?FLOW_LED:SHAN_LED ;  
        default: n_state = FLOW_LED; 
    endcase
end
//状态寄存
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        flow_led <= 4'b0001;
        paoma_led <= 4'b0001;
        shan_led <= 4'b0000;
	end
    else if(end_cnt_led) begin
        if(c_state == FLOW_LED)
            flow_led <= {flow_led[2:0],flow_led[3]};
        else if(c_state == PAOMA_LED)
            paoma_led <= {paoma_led[2:0],~paoma_led[3]};
        else if(c_state == SHAN_LED)
            shan_led <= ~shan_led;
	end
end
//输出
always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0001;
    else if(c_state == FLOW_LED)
        led <= flow_led;
    else if(c_state == PAOMA_LED)
        led <= paoma_led;
    else if(c_state == SHAN_LED)
        led <= shan_led;
end

endmodule