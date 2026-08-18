module zxd_key (
    input   clk,
    input   rst,
    input   key,
    output  flag
);

parameter   delay = 100_000_0;
reg     cnt;


always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(key == 0)
        if(cnt == delay - 1)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    else
        cnt <= 0;
end

endmodule