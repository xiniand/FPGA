module top (
    input               rst ,
    input               clk ,
    input       [1:0]   key ,
    input               sw  ,
    output      [7:0]   dig ,
    output      [5:0]   sel
);

parameter delay_1 = 100_000_0;
parameter TIME  = 24_999_999;
reg [24:0]  cnt_time; 
wire            c0_sig  ,
                c1_sig  ,
                c2_sig  ,
                c3_sig  ,
                c4_sig  ;
wire    [1:0]   flag    ;
reg             clk_rg  ;
reg     [2:0]   cnt     ;
reg    [3:0]   data    ;
reg		[3:0]  data_num;
wire     [3:0]    data_out;
wire            re_en      ;
wire            wr_en      ;
assign  re_en = sw?1:0;

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


always @(posedge clk or negedge rst) begin
    if(!rst)
        data_num<= 0;
    else if(data_num == 10)
        data_num <= data_num;
    else
        data_num <= data_num + 1;
end

always @(*) begin
    case (data_num)
        0:data = 2;
        1:data = 4;
        2:data = 6;
        3:data = 8;
        4:data = 10;
        5:data = 12;
        6:data = 14;
        7:data = 7; 
        8:data = 9;
        9:data = 5;
        default: data = 5;
    endcase
end

always @(posedge clk_rg or negedge rst) begin
    if(!rst)
        cnt_time<= 0;
    else if(re_en)
        if(cnt_time == TIME )
            cnt_time <= 0;
        else
            cnt_time <= cnt_time + 1;
end

reg [3:0] rd_addr;
always @(posedge clk_rg or negedge rst) begin
    if(!rst)
        rd_addr <= 0;
    else if((cnt_time == TIME)&&re_en )
        if(rd_addr == 9)
            rd_addr <= 0;
        else
            rd_addr <= rd_addr + 1;
end

/* assign  re_en = (cnt_time == TIME)?1:0; */
assign  wr_en = (data_num == 10)?0:1;

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

smg  smg_inst(
    .rst    (rst        ),
    .clk    (clk        ),
    .dig    (dig        ),
    .data   (data_out   ),
    .sel    (sel        )
);

/* ram_data_2	ram_data_2_inst (
	.data       (data     ),
	.inclock    (clk      ),
	.outclock   (clk_rg   ),
	.rdaddress  (rd_addr  ),
	.wraddress  (data_num ),
	.wren       (1        ),
	.q          (data_out )
); */
ram_data_2	ram_data_2_inst (
	.data       ( data      ),
	.inclock    ( clk       ),
	.outclock   ( clk_rg    ),
	.rdaddress  ( rd_addr   ),
	.rden       ( re_en     ),
	.wraddress  ( data_num  ),
	.wren       ( wr_en     ),
	.q          ( data_out  )
);


endmodule