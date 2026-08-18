module buzzer_du (
    input   clk,
    input   rst,
    input   [6:0]   sw,
    output  buzzer
);

parameter   G1      = 47801 ,
            G2      = 42589 ,
            G3      = 37936 ,
            G4      = 35816 ,
            G5      = 31887 ,
            G6      = 28409 ,
            G7      = 25303 ,
            COUNT   = 6     ;

reg [17:0]  cnt_hz          ;//频率计数器
wire        add_cnt_hz      ,
            end_cnt_hz      ;

reg [2:0]   cnt_count       ;//音符个数计数器
reg [17:0]  hz_rg           ;//频率寄存器
//音频计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_hz <= 0;
    else if(add_cnt_hz)begin
        if(end_cnt_hz)
            cnt_hz <= 0;
        else 
            cnt_hz <= cnt_hz + 1;
    end
end
assign  add_cnt_hz = 1;
assign  end_cnt_hz = add_cnt_hz &&(cnt_hz == hz_rg);

always @(*) begin
    case (sw)
        7'b1000000:hz_rg = G1;
        7'b0100000:hz_rg = G2;
        7'b0010000:hz_rg = G3;
        7'b0001000:hz_rg = G4;
        7'b0000100:hz_rg = G5;
        7'b0000010:hz_rg = G6;
        7'b0000001:hz_rg = G7;
        default:hz_rg = G1;
    endcase
end

assign buzzer = (cnt_hz < (hz_rg >> 1))?0:1;

endmodule