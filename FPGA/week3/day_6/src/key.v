module key (
    input   clk,
    input   rst,
    input   key,
    output  key_out
);

parameter delay = 999_999;

reg [19:0]  cnt;

always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt <= 0;
    else if(key == 0)begin
        if(cnt == delay)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;
end

assign key_out = (cnt == delay-1)?1:0;

endmodule