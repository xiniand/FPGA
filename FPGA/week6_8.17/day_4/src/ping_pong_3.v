module ping_pong_3 (
    input                   clk     ,
    input                   rst_n   ,
    input           [7:0]   data_rom,
    input                   done_tx ,
    output  reg     [7:0]   data_tx ,
    output  reg             start_tx
);
    
//ram1
reg     [7:0]   data_1     ; 
reg     [7:0]   rdaddress_1; 
reg             rden_1     ; 
reg     [7:0]   wraddress_1; 
wire            wren_1     ; 
wire    [7:0]   q_1        ;
//ram2
reg     [7:0]   data_2     ; 
reg     [7:0]   rdaddress_2; 
reg             rden_2     ; 
reg     [7:0]   wraddress_2; 
wire            wren_2     ; 
wire    [7:0]   q_2        ;
//ram3
reg     [7:0]   data_3     ; 
reg     [7:0]   rdaddress_3; 
reg             rden_3     ; 
reg     [7:0]   wraddress_3; 
wire            wren_3     ; 
wire    [7:0]   q_3        ;

localparam  W1 = 6'b1,
            R1 = 6'b10,
            R2 = 6'b100,
            R3 = 6'b1000,

reg [2:0]   c_state ,n_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= W1;
    else
        c_state <= n_state;
end



reg rden_1_d, rden_2_d;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rden_1_d <= 0;
        rden_2_d <= 0;
    end
    else begin
        rden_1_d <= rden_1;
        rden_2_d <= rden_2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_tx <= 0;
    else if(rden_1_d)
        data_tx <= q_1;
    else if(rden_2_d)
        data_tx <= q_2;
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        start_tx <= 0;
    else if(rden_1_d || rden_2_d)
        start_tx <= 1;
    else
        start_tx <= 0;
end
assign wren_1 = (c_state == W1)   || (c_state == W1R2);
assign wren_2 = (c_state == W2R1);

ram_data	ram_data_inst_1 (
	.aclr       ( ~rst_n        ),
	.clock      ( clk           ),
	.data       ( data_1        ),
	.rdaddress  ( rdaddress_1   ),
	.rden       ( rden_1        ),
	.wraddress  ( wraddress_1   ),
	.wren       ( wren_1        ),
	.q          ( q_1           )
);

ram_data	ram_data_inst_2 (
	.aclr       ( ~rst_n        ),
	.clock      ( clk           ),
	.data       ( data_2        ),
	.rdaddress  ( rdaddress_2   ),
	.rden       ( rden_2        ),
	.wraddress  ( wraddress_2   ),
	.wren       ( wren_2        ),
	.q          ( q_2           )
);

ram_data	ram_data_inst_3 (
	.aclr       ( ~rst_n        ),
	.clock      ( clk           ),
	.data       ( data_3        ),
	.rdaddress  ( rdaddress_3   ),
	.rden       ( rden_3        ),
	.wraddress  ( wraddress_3   ),
	.wren       ( wren_3        ),
	.q          ( q_3           )
);
endmodule