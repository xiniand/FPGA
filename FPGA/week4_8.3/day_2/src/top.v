module top (
    input           clk,
    input           rst,
    input  [6:0]    sw,
    output reg      buzzer
);
    
wire    [6:0]   buzzer_out;

buzzer_1 buzzer_1_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw1    (sw[6]          ),
    .buzzer (buzzer_out[0]  )
);

buzzer_2 buzzer_2_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw2    (sw[5]          ),
    .buzzer (buzzer_out[1]  )
);

buzzer_3 buzzer_3_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw3    (sw[4]          ),
    .buzzer (buzzer_out[2]  )
);

buzzer_4 buzzer_4_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw4    (sw[3]          ),
    .buzzer (buzzer_out[3]  )
);

buzzer_5 buzzer_5_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw5    (sw[2]          ),
    .buzzer (buzzer_out[4]  )
);

buzzer_6 buzzer_6_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw6    (sw[1]          ),
    .buzzer (buzzer_out[5]  )
);

buzzer_7 buzzer_7_u(
    .clk    (clk            ),
    .rst    (rst            ),
    .sw7    (sw[0]          ),
    .buzzer (buzzer_out[6]  )
);

always @(*) begin
    case (sw)
        7'b1000000:buzzer = buzzer_out[0]; 
        7'b0100000:buzzer = buzzer_out[1];
        7'b0010000:buzzer = buzzer_out[2];
        7'b0001000:buzzer = buzzer_out[3];
        7'b0000100:buzzer = buzzer_out[4];
        7'b0000010:buzzer = buzzer_out[5];
        7'b0000001:buzzer = buzzer_out[6];
        default: buzzer = 0;
    endcase
end



endmodule