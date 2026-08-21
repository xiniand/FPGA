//有限状态机模板：三段式(现态时序 + 次态组合 + 输出时序)，适合复杂/防毛刺输出
module fsm_template (
    input        clk  ,//系统时钟
    input        rst_n,//低有效复位
    input        a    ,//输入条件1
    input        b    ,//输入条件2
    output  reg  out1 ,//输出1
    output  reg  out2  //输出2
);
localparam  IDLE = 3'b000,
            S1   = 3'b001,
            S2   = 3'b010,
            S3   = 3'b011;
reg [2:0]   c_state ,//现态
            n_state ;//次态

//第一段：现态更新(时序逻辑)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

//第二段：次态计算(组合逻辑)，务必先赋默认值防锁存器
always @(*) begin
    n_state = c_state;//默认保持
    case(c_state)
        IDLE : if(a)      n_state = S1;
        S1   : if(b)      n_state = S2;
               else       n_state = IDLE;
        S2   :            n_state = S3;
        S3   :            n_state = IDLE;
        default:          n_state = IDLE;//非法状态安全复位
    endcase
end

//第三段：输出(时序逻辑)，寄存器输出无毛刺
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out1 <= 0;
        out2 <= 0;
    end
    else begin
        case(c_state)
            IDLE : begin out1 <= 0; out2 <= 0; end
            S1   : begin out1 <= 1; out2 <= 0; end
            S2   : begin out1 <= 0; out2 <= 1; end
            S3   : begin out1 <= 1; out2 <= 1; end
            default: begin out1 <= 0; out2 <= 0; end
        endcase
    end
end
endmodule
