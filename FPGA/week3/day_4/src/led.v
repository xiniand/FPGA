module led (
    input   clk,
    input   rst,
    input   key,
    output  reg [3:0]   led
);

parameter   delay = 24_999_999;
/* parameter   NUM = 3;  */
reg     [24:0]  cnt_1;
/* reg[1:0]    cnt_2; */
/* reg     [1:0]   sw_in       ;   //对SW进行寄存,得到SW的下降沿
wire            sw_negedge  ;   //SW的下降沿 */
reg             en;
//开关控制
/* always@(posedge clk)
    if(rst == 0)
        sw_in <= 0;
    else    
        sw_in <= {sw_in[0],key};
assign sw_posedge = ~sw_in[1] & sw_in[0]; */
always @(posedge clk or negedge rst) begin
    if(!rst)
        en <= 0;
    else if(key)
        en <= ~en;
end
//0.5s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1 <= 0;
    else if(cnt_1 == delay)
        cnt_1 <= 0;
    else if(en == 1)
        cnt_1 <= cnt_1 + 1;
end

always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0001;
        /* cnt_2 <= 0; */
    else if(cnt_1 == delay)
            led <= {led[2:0],~led[3]};
        /* if(cnt_2 == NUM)
            cnt_2 <= 0;
        else 
            cnt_2 <= cnt_2 + 1; */
end

/* always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0001;
    else begin
        case (cnt_2)
            2'd0:led <= 4'b0001;
            2'd1:led <= 4'b0010;
            2'd2:led <= 4'b0100;
            2'd3:led <= 4'b1000;
            default: ;
        endcase
    end
end */
endmodule