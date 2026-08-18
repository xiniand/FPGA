module smg (
    input               rst ,
    input               clk ,
    input       [3:0]   data,
    output reg  [7:0]   dig ,
    output      [5:0]   sel
);

assign  sel = 6'b000_000;

always @(*) begin
    case (data)
          0: dig = 8'b1100_0000;//0
          1: dig = 8'b1111_1001;//1
          2: dig = 8'b1010_0100;//2
          3: dig = 8'b1011_0000;//3
          4: dig = 8'b1001_1001;//4
          5: dig = 8'b1001_0010;//5
          6: dig = 8'b1000_0010;//6
          7: dig = 8'b1111_1000;//7
          8: dig = 8'b1000_0000;//8
          9: dig = 8'b1001_0000;//9
        'hA: dig = 8'b1000_1000;
        'hB: dig = 8'b1000_0011; 
        'hC: dig = 8'b1100_0110; 
        'hD: dig = 8'b1010_0001; 
        'hE: dig = 8'b1000_0110; 
        'hF: dig = 8'b1000_1110; 
        default: dig = 8'b1100_0000;//0
    endcase
end

endmodule