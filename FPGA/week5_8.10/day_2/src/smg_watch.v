

module smg_watch(
    input                       clk     ,
    input                       rst     ,
    output          [5:0]       sel     ,   //位选
    output  reg     [7:0]       seg         //段选
);
parameter           TIME = 24_999_999;
reg   [24:0]        cnt_time    ;
reg   [3:0]         data_num    ;
wire  [3:0]         data        ;
reg   [3:0]         data_in     ;
reg                 wr_en       ;

assign sel = 6'b000_000;

always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_time <= 0;
    else if(cnt_time == TIME)
        cnt_time <= 0;
    else
        cnt_time <= cnt_time + 1;

always @(posedge clk or negedge rst)
    if(rst == 0)
        data_num <= 0;
    else if(data_num == 9)
        data_num <= 10;              // 写完最后一笔(addr9=8)后进入停止态
    else if(data_num == 10)
        data_num <= data_num;        // 保持停止态，不再写入
    else
        data_num <= data_num + 1;

always @(*)
    if(rst == 0)begin
        data_in = 0;
        wr_en = 0;
    end
    else
        case (data_num)
            0:begin wr_en = 1; data_in = 2;   end
            1:begin wr_en = 1; data_in = 5;   end
            2:begin wr_en = 1; data_in = 7;   end
            3:begin wr_en = 1; data_in = 9;   end
            4:begin wr_en = 1; data_in = 15;  end
            5:begin wr_en = 1; data_in = 10;  end
            6:begin wr_en = 1; data_in = 11;  end
            7:begin wr_en = 1; data_in = 9;   end
            8:begin wr_en = 1; data_in = 7;   end
            9:begin wr_en = 1; data_in = 8;   end   // 最后一笔：写入 addr9=8
            default:begin
                wr_en = 0;                   // 停止态(data_num>=10)关闭写使能
                data_in = 8;
            end
        endcase

always @(posedge clk or negedge rst)
    if(rst == 0)
        seg <= 8'b1100_0000;
    else
        case (data)
            0 : seg <= 8'b1100_0000;
            1 : seg <= 8'b1111_1001;
            2 : seg <= 8'b1010_0100;
            3 : seg <= 8'b1011_0000;
            4 : seg <= 8'b1001_1001; 
            5 : seg <= 8'b1001_0010; 
            6 : seg <= 8'b1000_0010; 
            7 : seg <= 8'b1111_1000; 
            8 : seg <= 8'b1000_0000; 
            9 : seg <= 8'b1001_0000; 
            'hA:seg <= 8'b1000_1000; 
            'hB:seg <= 8'b1000_0011; 
            'hC:seg <= 8'b1100_0110; 
            'hD:seg <= 8'b1010_0001; 
            'hE:seg <= 8'b1000_0110; 
            'hF:seg <= 8'b1000_1110; 
            default:seg <= 8'b1100_0000;
        endcase

reg    [3:0] rd_addr   ;
always @(posedge clk or negedge rst)
    if(rst == 0)
        rd_addr <= 0;
    else if(cnt_time == TIME)
        if(rd_addr == 9)
            rd_addr <= 0;
        else
            rd_addr <= rd_addr + 1;

ram_data2	ram_data2_inst (
	.clock          (clk),
	.data           (data_in),
	.rdaddress      (rd_addr),
	.wraddress      (data_num),
	.wren           (wr_en),
	.q              (data)
);
endmodule