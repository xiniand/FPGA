module ping_pong (
    input                   clk     ,
    input                   rst_n   ,
    input           [7:0]   data_rom,
    input                   done_tx ,
    output  reg     [7:0]   data_tx ,
    output  reg             start_tx
);
    
//ram1
reg     [7:0]   data_1      ; 
reg     [7:0]   rdaddress_1 ; 
reg             rden_1      ; 
reg     [7:0]   wraddress_1 ; 
wire            wren_1      ; 
wire    [7:0]   q_1         ;
//ram2
reg     [7:0]   data_2      ; 
reg     [7:0]   rdaddress_2 ; 
reg             rden_2      ; 
reg     [7:0]   wraddress_2 ; 
wire            wren_2      ; 
wire    [7:0]   q_2         ;
wire            en          ;
assign          en = done_tx?1:(wraddress_2 == 255||wraddress_1 == 255)?0:1;

localparam  W1      = 3'b001,
            W2R1    = 3'b010,  
            W1R2    = 3'b100;
reg [2:0]   c_state ,n_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= W1;
    else
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        W1  :begin
            if(wraddress_1 == 255)
                n_state = W2R1;
            else
                n_state = W1;
        end 
        W2R1:begin
            if(rdaddress_1 == 255 && en && wraddress_2 == 255)
                n_state = W1R2;
            else
                n_state = W2R1;
        end 
        W1R2: begin
            if(rdaddress_2 == 255 && en && wraddress_1 == 255)
                n_state = W2R1;
            else
                n_state = W1R2;
        end 
        default:n_state = W1 ;
    endcase
end
//ram1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        data_1     <= 0;
        rdaddress_1<= 0;
        rden_1     <= 0;
        wraddress_1<= 0;
    end
    else begin
        case (c_state)
            W1  :begin
                data_1  <= data_rom;
                wraddress_1   <= wraddress_1 + 1;
                rdaddress_1   <=0;
                if(wraddress_1 == 255)
                    rden_1  <= 1;
                else
                    rden_1  <= 0;
            end 
            W2R1:begin
                wraddress_1   <= 0;
                if(done_tx) begin
                    if(rdaddress_1 == 255) begin
                        rden_1      <= 0;
                        rdaddress_1 <= 0;
                    end
                    else begin
                        rden_1      <= 1;
                        rdaddress_1 <= rdaddress_1 + 1;
                    end
                end
                else begin
                    rden_1      <= 0;
                    rdaddress_1 <= rdaddress_1;
                end
            end
            W1R2:begin
                data_1     <= data_rom;
                rdaddress_1<= 0;
                wraddress_1<= wraddress_1 + 1;
                if(rdaddress_2 == 255 && done_tx)
                    rden_1 <= 1;
                else
                    rden_1 <= 0;
            end
            default: begin
                data_1     <= 0;
                rdaddress_1<= 0;
                rden_1     <= 0;
                wraddress_1<= 0;
            end 
        endcase
    end 
end


//ram2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        data_2     <= 0;
        rdaddress_2<= 0;
        rden_2     <= 0;
        wraddress_2<= 0;
    end 
    else begin
        case (c_state)
            W1  :begin
                data_2          <= 0;
                wraddress_2     <= 0;
                rdaddress_2     <= 0;
                rden_2          <= 0;
            end 
            W1R2:begin
                wraddress_2   <= 0;
                if(done_tx) begin
                    if(rdaddress_2 == 255) begin
                        rden_2      <= 0;
                        rdaddress_2 <= 0;
                    end
                    else begin
                        rden_2      <= 1;
                        rdaddress_2 <= rdaddress_2 + 1;
                    end
                end
                else begin
                    rden_2      <= 0;
                    rdaddress_2 <= rdaddress_2;
                end
            end
            W2R1:begin
                data_2     <= data_rom;
                rdaddress_2<= 0;
                wraddress_2<= wraddress_2 + 1;
                if(rdaddress_1 == 255 && done_tx)
                    rden_2 <= 1;
                else
                    rden_2 <= 0;
            end
            default: begin
                data_2     <= 0;
                rdaddress_2<= 0;
                rden_2     <= 0;
                wraddress_2<= 0;
            end 
        endcase
    end 
end

reg rden_1_d, rden_2_d;
wire rden_1_rise, rden_2_rise;
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
assign rden_1_rise = rden_1 && !rden_1_d;
assign rden_2_rise = rden_2 && !rden_2_d;

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
endmodule