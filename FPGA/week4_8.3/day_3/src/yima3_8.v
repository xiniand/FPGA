module ziyima3_8 (
    input   rst ,
    input   clk ,
    input   [2:0]   sw,
    output reg [6:0]   dig,
    output reg [5:0]   sel
);
    
parameter TIME = 50_000_0000;

/* assign  sel = 6'b000_000; */

always @(posedge clk or negedge rst) begin
    case (sw)
        3'b000:     begin dig = 7'b100_0000; sel = 6'b000_000;end//0    
        3'b001:     begin dig = 7'b111_1001; sel = 6'b000_001;end//1
        3'b010:     begin dig = 7'b010_0100; sel = 6'b000_011;end//2
        3'b011:     begin dig = 7'b011_0000; sel = 6'b000_111;end//3
        3'b100:     begin dig = 7'b001_1001; sel = 6'b001_111;end//4
        3'b101:     begin dig = 7'b001_0010; sel = 6'b011_111;end//5
        3'b110:     begin dig = 7'b000_0010; sel = 6'b100_000;end//6
        3'b111:     begin dig = 7'b111_1000; sel = 6'b110_000;end//7
        default:    begin dig = 7'b100_0000; sel = 6'b000_000;end//0
    endcase
end


endmodule