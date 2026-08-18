module dt_smg (
    input               rst ,
    input               clk ,
    output reg [7:0]    dig ,
    output reg [5:0]    sel
);
parameter delay = 49_999;
parameter TIME  = 500_000;
//闪烁计数器
reg [3:0]   bcd_sel;
reg [15:0]  cnt_delay   ;
//1s计数器
reg [19:0]  cnt_time     ;
wire        add_cnt_time ,
            end_cnt_time ;
reg [3:0] bcd0, bcd1, bcd2, bcd3, bcd4, bcd5;
//时间计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_time <= 0;
    else if(add_cnt_time)begin
        if(end_cnt_time)
            cnt_time <= 0;
        else 
            cnt_time <= cnt_time + 1;
    end
end
assign  add_cnt_time = 1;
assign  end_cnt_time = add_cnt_time &(cnt_time == TIME);
//位数计数器
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        bcd0 <= 0; bcd1 <= 0; bcd2 <= 0;
        bcd3 <= 0; bcd4 <= 0; bcd5 <= 0;
    end 
    else if(end_cnt_time) begin
        if(bcd0 == 9) begin
            bcd0 <= 0;
            if(bcd1 == 9) begin
                bcd1 <= 0;
                if(bcd2 == 9) begin
                    bcd2 <= 0;
                    if(bcd3 == 5) begin
                        bcd3 <= 0;
                        if(bcd4 == 9) begin
                            bcd4 <= 0;
                            if(bcd5 == 5) 
                                 bcd5 <= 0; 
                            else 
                                bcd5 <= bcd5 + 1;
                        end else bcd4 <= bcd4 + 1;
                    end else bcd3 <= bcd3 + 1;
                end else bcd2 <= bcd2 + 1;
            end else bcd1 <= bcd1 + 1;
        end else bcd0 <= bcd0 + 1;
    end
    end
//5ms计数器
always @(posedge clk or negedge rst)
    if(rst == 0)
        cnt_delay <= 0;
    else if(cnt_delay == delay)
        cnt_delay <= 0;
    else
        cnt_delay <= cnt_delay + 1;
//sel变化模块
always @(posedge clk or negedge rst) begin
    if(!rst)
        sel <= 6'b111110;
    else if(cnt_delay == delay)
        sel <= {sel[4:0],sel[5]};
end
//位数选择器
always @(*) begin
    case (sel)
        6'b111110: bcd_sel = bcd0;
        6'b111101: bcd_sel = bcd1;
        6'b111011: bcd_sel = (bcd2+10);
        6'b110111: bcd_sel = bcd3;
        6'b101111: bcd_sel = (bcd4+10);
        6'b011111: bcd_sel = bcd5;
        default:   bcd_sel = bcd0;
    endcase
end
//数字选择器
always @(*) begin
    case (bcd_sel)
        4'd0: dig = 8'b1100_0000;//0
        4'd1: dig = 8'b1111_1001;//1
        4'd2: dig = 8'b1010_0100;//2
        4'd3: dig = 8'b1011_0000;//3
        4'd4: dig = 8'b1001_1001;//4
        4'd5: dig = 8'b1001_0010;//5
        4'd6: dig = 8'b1000_0010;//6
        4'd7: dig = 8'b1111_1000;//7
        4'd8: dig = 8'b1000_0000;//8
        4'd9: dig = 8'b1001_0000;//9
        4'd10: dig = 8'b0100_0000;//0.
        4'd11: dig = 8'b0111_1001;//1.
        4'd12: dig = 8'b0010_0100;//2.
        4'd13: dig = 8'b0011_0000;//3.
        4'd14: dig = 8'b0001_1001;//4.
        4'd15: dig = 8'b0001_0010;//5.
        4'd16: dig = 8'b0000_0010;//6.
        4'd17: dig = 8'b0111_1000;//7.
        4'd18: dig = 8'b0000_0000;//8.
        4'd19: dig = 8'b0001_0000;//9.
        default: dig = 7'b100_0000;//0
    endcase
end
endmodule
/* reg [6:0 ]  dig_0       ;
reg [6:0 ]  dig_1       ;
reg [6:0 ]  dig_2       ;
reg [6:0 ]  dig_3       ;
reg [6:0 ]  dig_4       ;
reg [6:0 ]  dig_5       ; */

/* always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_num <= 0;
    else if(add_cnt_num)begin
        if(end_cnt_num)
            cnt_num <= 0;
        else 
            cnt_num <= cnt_num + 1;
    end
end
assign  add_cnt_num = end_cnt_time;
assign  end_cnt_num = add_cnt_num &(cnt_num == COUNT); */

/* //个位
always @(posedge clk or negedge rst) begin
    if(!rst)
        dig_0 <= 0;
    else if(end_cnt_time)
        case (bcd0)
            0:      dig_0 = 7'b100_0000;//0
            1:      dig_0 = 7'b111_1001;//1
            2:      dig_0 = 7'b010_0100;//2
            3:      dig_0 = 7'b011_0000;//3
            4:      dig_0 = 7'b001_1001;//4
            5:      dig_0 = 7'b001_0010;//5
            6:      dig_0 = 7'b000_0010;//6
            7:      dig_0 = 7'b111_1000;//7 
            8:      dig_0 = 7'b000_0000;//8
            9:      dig_0 = 7'b001_0000;//9  
            default:dig_0 = 7'b100_0000;//0 
        endcase
end
//十位
always @(posedge clk or negedge rst) begin
    if(!rst)
        dig_1 <= 0;
    else if(end_cnt_time)
        case (bcd1)
            0:      dig_1 = 7'b100_0000;//0
            1:      dig_1 = 7'b111_1001;//1
            2:      dig_1 = 7'b010_0100;//2
            3:      dig_1 = 7'b011_0000;//3
            4:      dig_1 = 7'b001_1001;//4
            5:      dig_1 = 7'b001_0010;//5
            6:      dig_1 = 7'b000_0010;//6
            7:      dig_1 = 7'b111_1000;//7 
            8:      dig_1 = 7'b000_0000;//8
            9:      dig_1 = 7'b001_0000;//9  
            default:dig_1 = 7'b100_0000;//0 
        endcase
end
//百位
always @(posedge clk or negedge rst) begin
    if(!rst)
        dig_2 <= 0;
    else if(end_cnt_time)
        case (bcd2)
            0:      dig_2 = 7'b100_0000;//0
            1:      dig_2 = 7'b111_1001;//1
            2:      dig_2 = 7'b010_0100;//2
            3:      dig_2 = 7'b011_0000;//3
            4:      dig_2 = 7'b001_1001;//4
            5:      dig_2 = 7'b001_0010;//5
            6:      dig_2 = 7'b000_0010;//6
            7:      dig_2 = 7'b111_1000;//7 
            8:      dig_2 = 7'b000_0000;//8
            9:      dig_2 = 7'b001_0000;//9  
            default:dig_2 = 7'b100_0000;//0 
        endcase
end
//千位
always @(posedge clk or negedge rst) begin
    if(!rst)
        dig_3 <= 0;
    else if(end_cnt_time)
        case (bcd3)
            0:      dig_3 = 7'b100_0000;//0
            1:      dig_3 = 7'b111_1001;//1
            2:      dig_3 = 7'b010_0100;//2
            3:      dig_3 = 7'b011_0000;//3
            4:      dig_3 = 7'b001_1001;//4
            5:      dig_3 = 7'b001_0010;//5
            6:      dig_3 = 7'b000_0010;//6
            7:      dig_3 = 7'b111_1000;//7 
            8:      dig_3 = 7'b000_0000;//8
            9:      dig_3 = 7'b001_0000;//9  
            default:dig_3 = 7'b100_0000;//0 
        endcase
end
//万位
always @(posedge clk or negedge rst) begin
    if(!rst)
        dig_4 <= 0;
    else if(end_cnt_time)
        case (bcd4)
            0:      dig_4 = 7'b100_0000;//0
            1:      dig_4 = 7'b111_1001;//1
            2:      dig_4 = 7'b010_0100;//2
            3:      dig_4 = 7'b011_0000;//3
            4:      dig_4 = 7'b001_1001;//4
            5:      dig_4 = 7'b001_0010;//5
            6:      dig_4 = 7'b000_0010;//6
            7:      dig_4 = 7'b111_1000;//7 
            8:      dig_4 = 7'b000_0000;//8
            9:      dig_4 = 7'b001_0000;//9  
            default:dig_4 = 7'b100_0000;//0 
        endcase
end
//十万位
always @(posedge clk or negedge rst) begin
    if(!rst)
        dig_5 <= 0;
    else if(end_cnt_time)
        case (bcd5)
            0:      dig_5 = 7'b100_0000;//0
            1:      dig_5 = 7'b111_1001;//1
            2:      dig_5 = 7'b010_0100;//2
            3:      dig_5 = 7'b011_0000;//3
            4:      dig_5 = 7'b001_1001;//4
            5:      dig_5 = 7'b001_0010;//5
            6:      dig_5 = 7'b000_0010;//6
            7:      dig_5 = 7'b111_1000;//7 
            8:      dig_5 = 7'b000_0000;//8
            9:      dig_5 = 7'b001_0000;//9  
            default:dig_5 = 7'b100_0000;//0 
        endcase
end */
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        dig <= 7'b111_1111; 
    else if(sel == 6'b111110)
        dig <= dig_0;
    else if(sel == 6'b111101)
        dig <= dig_1;
    else if(sel == 6'b111011)
        dig <= dig_2;
    else if(sel == 6'b110111)
        dig <= dig_3;
    else if(sel == 6'b101111)
        dig <= dig_4;
    else if(sel == 6'b011111)
        dig <= dig_5;
    else
        dig <= 7'b111_1111;

     case (sel)
        6'b111110:  dig = 7'b100_0000;//0    
        6'b111101:  dig = 7'b111_1001;//1
        6'b111011:  dig = 7'b010_0100;//2
        6'b110111:  dig = 7'b011_0000;//3
        6'b101111:  dig = 7'b001_1001;//4
        6'b011111:  dig = 7'b001_0010;//5
        default:    dig = 7'b111_1111;//0
    endcase 
end */