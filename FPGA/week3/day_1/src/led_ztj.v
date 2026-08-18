module led_ztj (
    input               clk,
    input               rst,
    input               clk_out,
    output  reg [3:0]   led
);

parameter   TIME_STATE    =   199_999_999;//4s 50_000_000*4
parameter   TIME_LED      =   24_999_999;//0.5s
localparam  S0  =   2'b01;
localparam  S1  =   2'b10;
localparam  S2  =   2'b11;

reg [1:0]   state       ;//现态
reg [1:0]   next_state  ;//次态
reg [27:0]  cnt_state   ;//4s计数器
wire        add_cnt_state,
            end_cnt_state;
reg [24:0]  cnt_led     ;//0.5s计数器
wire        add_cnt_led,
            end_cnt_led;

//0.5s计数器
always @(posedge clk) begin
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
always @(posedge clk) begin
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

//状态切换
always @(posedge clk) begin
    if(!rst)
        state <= S0;
    else
        state  <= next_state;
end
//状态跳转
always @(*) begin
    case (state)
        S0:next_state =  end_cnt_state ? S1:S0;
        S1:next_state =  end_cnt_state ? S2:S1; 
        S2:next_state =  end_cnt_state ? S0:S2;   
        default: next_state = S0;
    endcase
end

always @(posedge clk) begin
    if(!rst)
        led <= 4'b0000;
    else 
end


endmodule