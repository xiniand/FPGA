module shanshuo (
    input   clk ,
    input   rst ,
    input   en  ,
    output  reg [3:0]   led
);

parameter   delay = 24_999_999;
reg     [24:0]  cnt_1;
/* reg             en;

 always @(posedge clk or negedge rst) begin
    if(!rst)
        en <= 0;
    else if(key)
        en <= ~en;
end */
//0.5s计数器
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1 <= 0;
    else if(cnt_1 == delay)
        cnt_1 <= 0;
    else 
        cnt_1 <= cnt_1 + 1;
end */
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1 <= 0;
    else if(en == 1) begin
        if(cnt_1 == delay)
            cnt_1 <= 0;
        else 
            cnt_1 <= cnt_1 + 1;
    end
end

always @(posedge clk or negedge rst) begin
    if(!rst)
        led <= 4'b0000;
    else if(cnt_1 == delay)
        led <= ~led;
end

endmodule