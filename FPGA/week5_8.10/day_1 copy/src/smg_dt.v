module smg_dt(
    input  wire       clk     ,
    input  wire       rst_n   ,
    output      [5:0] sel     ,   //位选
    output reg  [7:0] seg        //段选
);

assign sel = 6'b000_000;

parameter TIME = 24_999_999;
reg  [24:0]  cnt_time;
reg  [3:0 ]  data_cnt;
wire [3:0 ]  data    ;
//时间计数器
always @(posedge clk or negedge rst_n)
    if(rst_n == 0)
        cnt_time <= 0;
    else if(cnt_time == TIME)
        cnt_time <= 0;
    else    
        cnt_time <= cnt_time + 1;

//输入数据变化时间
always @(posedge clk or negedge rst_n)
    if(rst_n == 0)
        data_cnt <= 0;
    else if(cnt_time == TIME) 
        if(data_cnt == 9)
            data_cnt <= 0;
        else    
            data_cnt <= data_cnt + 1;


always @(posedge clk or negedge rst_n)
    if(rst_n == 0)
        seg <= 8'b1100_0000;
    else
        case (data)
              0 : seg <= 8'b1100_0000;   //0
              1 : seg <= 8'b1111_1001;   //1
              2 : seg <= 8'b1010_0100;   //2
              3 : seg <= 8'b1011_0000;   //3
              4 : seg <= 8'b1001_1001;   //4
              5 : seg <= 8'b1001_0010;   //5
              6 : seg <= 8'b1000_0010;   //6
              7 : seg <= 8'b1111_1000;   //7
              8 : seg <= 8'b1000_0000;   //8
              9 : seg <= 8'b1001_0000;   //9 
            'hA : seg <= 8'b1000_1000;   //10
            'hB : seg <= 8'b1000_0011;   //11
            'hC : seg <= 8'b1100_0110;   //12
            'hD : seg <= 8'b1010_0001;   //13
            'hE : seg <= 8'b1000_0110;   //14
            'hF : seg <= 8'b1000_1110;   //15
            default:seg <= 8'b1100_0000;  
        endcase

rom_data	rom_data_inst (
	.address ( data_cnt),       //输入数据变化的时间
	.clock   ( clk     ),       //输入时钟
	.q       ( data    )        //输出数据
	);

endmodule


