module key (
    input   clk ,
    input   rst ,
    input   key ,
    output  flag
);

parameter delay_1 = 99_999_9;

reg [19:0]  cnt;

always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt <= 0;
    else if(key == 0)begin
        if(cnt == delay_1)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;
end

assign flag = (cnt == delay_1 - 1)?1:0;

endmodule