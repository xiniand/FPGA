module state (
    input               clk                 ,
    input               rst                 ,
    output              state_en_1          ,   //流水灯使能
    output              state_en_2          ,   //跑马灯使能
    output              state_en_3              //闪烁灯使能
);
parameter       LIUSHUI     =   'd1       ,
                PAOMA       =   'd2       ,
                SHANSHUO    =   'd3       ,
                TIME_STATE  =   'hBEBC1FF   ;   //4秒时间参数
reg     [1:0]   c_state,n_state             ;   //现态、次态
reg     [27:0]  cnt_time                    ;   //4秒计数器
//4秒计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_time <= 0;
    else if(cnt_time == TIME_STATE)
        cnt_time <= 0;  
    else
        cnt_time <= cnt_time + 1;

always @(posedge clk or negedge rst)
    if(rst == 0)
        c_state <= LIUSHUI;
    else
        c_state <= n_state;
always @(*)
    case (c_state)
        LIUSHUI  : n_state = (cnt_time == TIME_STATE) ? PAOMA       : LIUSHUI     ;
        PAOMA    : n_state = (cnt_time == TIME_STATE) ? SHANSHUO    : PAOMA    ; 
        SHANSHUO : n_state = (cnt_time == TIME_STATE) ? LIUSHUI     : SHANSHUO  ; 
        default:n_state = LIUSHUI;
    endcase
//输出
assign state_en_1 = (c_state == LIUSHUI) ? 1 : 0;
assign state_en_2 = (c_state == PAOMA) ? 1 : 0; 
assign state_en_3 = (c_state == SHANSHUO) ? 1 : 0; 
endmodule