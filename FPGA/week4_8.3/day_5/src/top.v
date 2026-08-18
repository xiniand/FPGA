module top (
    input               rst ,
    input               clk ,
    input       [1:0]   key ,
    output      [7:0]   dig ,
    output      [5:0]   sel
);
parameter delay_1 = 100_000_0;
parameter delay = 49_999;
parameter TIME  = 499_999;
wire            c0_sig  ,
                c1_sig  ,
                c2_sig  ,
                c3_sig  ,
                c4_sig  ;
wire    [1:0]   flag    ;
reg             clk_rg  ;
reg     [2:0]   cnt;

always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt <=0;
    else if(flag[1])begin
        if(cnt > 3)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
    else if(flag[0])begin
        if(cnt < 1)
            cnt <= 4;
        else
            cnt <= cnt - 1;
    end
end

always @(*) begin
    case (cnt)
        0:clk_rg=c0_sig;
        1:clk_rg=c1_sig;
        2:clk_rg=c2_sig;
        3:clk_rg=c3_sig;
        4:clk_rg=c4_sig; 
        default:clk_rg=clk; 
    endcase
end

clock	clock_inst (
	.areset ( ~rst   ),
	.inclk0 ( clk    ),
	.c0     ( c0_sig ),
	.c1     ( c1_sig ),
	.c2     ( c2_sig ),
	.c3     ( c3_sig ),
	.c4     ( c4_sig )
);

key #(
    .delay_1 (delay_1) 
    )key_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[1] ),
    .flag   (flag[1])
);

key #(
    .delay_1 (delay_1) 
    )key_1_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[0] ),
    .flag   (flag[0])
);

dt_smg #(
    .delay (delay),
    .TIME  (TIME)
) dt_smg_inst(
    .rst    (rst),
    .clk    (clk_rg),
    .dig    (dig),
    .sel    (sel)
);

endmodule