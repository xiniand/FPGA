module rom (
    input       clk,
    input       rst_n,
    output      [7:0]   data_rom
);
reg     [7:0]   address;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        address <= 0;
    else 
        address <= address + 1;
end

rom_data	rom_data_inst (
	.aclr       ( ~rst_n    ),
	.address    ( address   ),
	.clock      ( clk       ),
	.q          ( data_rom  )
);

endmodule