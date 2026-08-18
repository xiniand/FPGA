module fpj (
    input       clk         ,
    input       rst         ,
    output  reg clk_out
);

parameter   delay = 3  ;

reg         clk_out_1   ;
reg         clk_out_2   ;
reg [9:0]   cnt_1       ;
/* reg [2:0]   cnt_2       ; */
//上升沿计数
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_1 <= 0;
    else if(cnt_1 == delay - 1)
        cnt_1 <= 0;
    else
        cnt_1 <= cnt_1 + 1;
end
//下降沿计数
/* always @(negedge clk or negedge rst) begin
    if(!rst)
        cnt_2 <= 0;
    else if(cnt_2 == delay - 1)
        cnt_2 <= 0;
    else
        cnt_2 <= cnt_2 + 1;
end */
//上升沿时钟
always @(posedge clk or negedge rst) begin
    if(delay%2==1)begin
        if(!rst)
            clk_out_1 <= 0;
        else if(cnt_1 == (delay-1)/2)
            clk_out_1 <= ~clk_out_1;
        else if(cnt_1 == delay-1)
            clk_out_1 <= ~clk_out_1;
    end
    else if(delay%2 == 0)begin
        if(!rst)
            clk_out <= 0;
        else if(cnt == (delay-1)/2)
            clk_out <= ~clk_out;
        else if(cnt == (delay - 1))
            clk_out <= ~clk_out;
    end
end
//下降沿时钟
always @(negedge clk or negedge rst) begin
    if(delay%2==1)begin
        if(!rst)
            clk_out_2 <= 0;
        else if(cnt_1 == (delay-1)/2)
            clk_out_2 <= ~clk_out_2;
        else if(cnt_1 == delay-1)
            clk_out_2 <= ~clk_out_2;
    end
end

always @(*) begin
    if(delay%2==1)
        clk_out <= clk_out_1 | clk_out_2;
    else if(delay%2 == 0)
        clk_out <= clk_out
end
//偶分频器
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        clk_out <= 0;
    else if(cnt == (delay-1)/2)
        clk_out <= ~clk_out;
    else if(cnt == (delay - 1))
        clk_out <= ~clk_out;
end */

endmodule