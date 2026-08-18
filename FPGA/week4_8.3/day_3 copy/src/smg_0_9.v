module smg_7_0 (
    input                       clk     ,
    input                       rst     ,
    input                       key_1   ,   //控制加
    input                       key_2   ,   //控制减
    output          [5:0]       sel     ,   //位选
    output  reg     [6:0]       seg         //段选
);
reg     [3:0]   cnt_num ;

//位选
assign sel = 6'b000_000;

always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_num <= 0;
    //按键加
    else if(key_1)
        //if(cnt_num == 9)
        if(cnt_num < 9)
            cnt_num <= cnt_num + 1;
        else
            cnt_num <= 0;
    //按键减
    else if(key_2)
        //if(cnt_num == 0)
        if(cnt_num > 0)
            cnt_num <= cnt_num - 1;
        else 
            cnt_num <= 9;
//段选
always @(posedge clk or negedge rst)
    case (cnt_num)
        0:seg <= 7'b100_0000; 
        1:seg <= 7'b111_1001; 
        2:seg <= 7'b010_0100; 
        3:seg <= 7'b011_0000; 
        4:seg <= 7'b001_1001; 
        5:seg <= 7'b001_0010; 
        6:seg <= 7'b000_0010; 
        7:seg <= 7'b111_1000; 
        8:seg <= 7'b000_0000;
        9:seg <= 7'b001_0000;
        default:seg <= 7'b100_0000;  
    endcase
endmodule