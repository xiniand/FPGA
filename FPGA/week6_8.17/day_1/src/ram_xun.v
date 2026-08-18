module ram_xun (
    input           clk     			,
    input           rst_n   			,
    input  	[7:0]   data_in 			,
    input           rden   				,
    input           wren   				,
    output  [7:0]   data_out
);
localparam	SHEN = 255;

reg[8:0]	cnt_rdaddress			,//读地址
			cnt_wraddress			;//写地址
wire[8:0]	rdaddress				,//读地址
			wraddress				;//写地址
wire        add_cnt_rdaddress       ,
            end_cnt_rdaddress       ;
wire        add_cnt_wraddress       ,
            end_cnt_wraddress       ;
//读地址计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_rdaddress <= 0;
    else if(add_cnt_rdaddress)begin
        if(end_cnt_rdaddress)
            cnt_rdaddress <= 0;
        else 
            cnt_rdaddress <= cnt_rdaddress + 1;
    end 
end
assign  add_cnt_rdaddress = rden;
assign  end_cnt_rdaddress = add_cnt_rdaddress && (cnt_rdaddress == wraddress-1);
assign	rdaddress = cnt_rdaddress;
//写地址计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_wraddress <= 0;
    else if(add_cnt_wraddress)begin
        if(end_cnt_wraddress)
            cnt_wraddress <= 0;
        else 
            cnt_wraddress <= cnt_wraddress + 1;
    end 
end
assign  add_cnt_wraddress = wren;
assign  end_cnt_wraddress = add_cnt_wraddress && (cnt_wraddress == SHEN);
assign	wraddress = cnt_wraddress;

ram_data	ram_data_inst (
	.aclr 			( ~rst_n	 	),
	.clock 			( clk			),
	.data 			( data_in	 	),
	.rdaddress 		( rdaddress		),
	.rden 			( rden	 		),
	.wraddress 		( wraddress		),
	.wren 			( wren	 		),
	.q 				( data_out	 	)
);


endmodule