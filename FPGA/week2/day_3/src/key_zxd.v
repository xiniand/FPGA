module key_zxd (
    input   key,
    input   clk,
    input   rst,
    output  flag
);

parameter   delay   =   100_000_0;
reg [19:0]  cnt;

always @(posedge) begin
    if(!rst)
        cnt<=0;
    else if(key==0) begin
        if(cnt == delay-1)
            cnt <= cnt;
        else    
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;
end

assign  flag = (cnt == delay-2) ? 1:0;

endmodule