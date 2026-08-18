module ztj_led (
    input   clk         ,
    input   rst         ,
    output  state_en_1  , //流水灯
    output  state_en_2  , //跑马灯
    output  state_en_3    //闪烁

);

parameter   TIME_STATE      =   200_000_000;
parameter   LIUSHUI_LED     =   2'b00,
            PAOMA_LED       =   2'b01,
            SHANSHUO_LED    =   2'b10;
reg [27:0]  cnt_state;
wire        add_cnt_state,
            end_cnt_state;
reg [1:0]   c_state,
            n_state;
//0.5s计数器
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
assign add_cnt_state = 1;
assign end_cnt_state = add_cnt_state && (cnt_state == TIME_STATE);
//状态机
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= LIUSHUI_LED;
    else 
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        LIUSHUI_LED: n_state = end_cnt_state ? PAOMA_LED:LIUSHUI_LED; 
        PAOMA_LED: n_state = end_cnt_state ? SHANSHUO_LED:PAOMA_LED; 
        SHANSHUO_LED: n_state = end_cnt_state ? LIUSHUI_LED:SHANSHUO_LED; 
        default: n_state = LIUSHUI_LED;
    endcase
end
//输出
assign  state_en_1 = (c_state == LIUSHUI_LED    )?1:0;
assign  state_en_2 = (c_state == PAOMA_LED      )?1:0;
assign  state_en_3 = (c_state == SHANSHUO_LED   )?1:0;

endmodule