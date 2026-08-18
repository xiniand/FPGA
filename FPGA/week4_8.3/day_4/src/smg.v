module smg  ( 
    input                       clk     ,
    input                       rst     ,
    input           [22:0]      shua    ,
    output  reg     [5:0]       sel     ,   //位选
    output  reg     [6:0]       seg         //段选
);
reg         [22:0]  cnt_time                    ;
wire        [22:0]  shua_rg                    ;

assign  shua_rg = shua;
//刷新率计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_time <= 0;
    else if(cnt_time >= shua_rg)
        cnt_time <= 0;
    else
        cnt_time <= cnt_time + 1;
//位选
always @(posedge clk or negedge rst)
    if(!rst)
        sel <= 6'b111_110;
    else if(cnt_time == shua_rg)
        sel <= {sel[4:0],sel[5]};
//段选
always @(posedge clk or negedge rst)
    if(!rst)
        seg <= 7'b100_0000;
    else begin
        case (sel)
            6'b111_110:seg <= 7'b100_0000; 
            6'b111_101:seg <= 7'b111_1001; 
            6'b111_011:seg <= 7'b010_0100; 
            6'b110_111:seg <= 7'b011_0000; 
            6'b101_111:seg <= 7'b001_1001; 
            6'b011_111:seg <= 7'b001_0010; 
            default:seg <= 7'b100_0000;  
        endcase
    end
endmodule