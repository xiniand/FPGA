module top (
    input               rst ,
    input               clk ,
    input       [4:0]   key ,
    output      [7:0]   dig ,
    output      [5:0]   sel
);

parameter delay_1 = 100_000_0;
parameter   TIME    = 24_999_999    ;
wire            c0_sig  ,
                c1_sig  ,
                c2_sig  ,
                c3_sig  ,
                c4_sig  ;
wire    [4:0]   flag    ;
reg             clk_rg  ;
reg     [2:0]   cnt     ;
wire    [3:0]   data_out;  


/* assign  re_en = sw?1:0; */
//时钟切换
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
	.areset ( ~rst ),
	.inclk0 ( clk ),
	.c0 ( c0_sig ),
	.c1 ( c1_sig ),
	.c2 ( c2_sig ),
	.c3 ( c3_sig ),
	.c4 ( c4_sig )
);

key #(
    .delay_1 (delay_1) 
    )key_4_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[4] ),
    .flag   (flag[4])
);

key #(
    .delay_1 (delay_1) 
    )key_3_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[3] ),
    .flag   (flag[3])
);

key #(
    .delay_1 (delay_1) 
    )key_2_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[2] ),
    .flag   (flag[2])
);

key #(
    .delay_1 (delay_1) 
    )key_1_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[1] ),
    .flag   (flag[1])
);

key #(
    .delay_1 (delay_1) 
    )key_0_u(
    .clk    (clk ),
    .rst    (rst ),
    .key    (key[0] ),
    .flag   (flag[0])
);

smg  smg_inst(
    .rst    (rst        ),
    .clk    (clk        ),
    .dig    (dig        ),
    .data   (data_out   ),
    .sel    (sel        )
);

dma_0 #(
    .TIME    (TIME)    
) dma_0_inst(
    .clk     (clk       ),
    .rst     (rst       ),
    .clk_rg  (clk_rg    ),
    .key     (flag[4:2] ),
    .data_out(data_out  )
);





endmodule