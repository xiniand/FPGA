module bin_to_bcd (
    input               clk             ,
    input               rst_n           ,
    input       [7:0]   data_zs_in      ,//输入待转换的数据
    input       [13:0]  data_xs_in      ,//输入待转换的数据
    output  reg [11:0]  data_bcd_zs     ,//输出转换后的BCD码数据
    output  reg [11:0]  data_bcd_xs      //输出转换后的BCD码数据
);

reg     [19:0]          data_reg_zs     ;//3个数12位 + 8位
reg     [29:0]          data_reg_xs     ;//4个数16位 + 14位
//BCD码转换整数

always @(posedge clk or negedge rst_n)  
    if(!rst_n)
        data_reg_xs = 0;
    else begin
        //寄存和扩编data_ave(扩编16位是根据要得到的4个BCD码数据来判断)
        data_reg_xs = {16'b0,data_xs_in};
        //循环13次判断移位操作(13次是根据data_ave的位宽来判断)
        repeat(14) begin 
            //判断是否大于等于5,是就加3
            if(data_reg_xs[17:14] >= 5)   
                data_reg_xs[17:14] = data_reg_xs[17:14] + 3;

            if(data_reg_xs[21:18] >= 5)  
                data_reg_xs[21:18] = data_reg_xs[21:18] + 3;

            if(data_reg_xs[25:22] >= 5)  
                data_reg_xs[25:22] = data_reg_xs[25:22] + 3;

            if(data_reg_xs[29:26] >= 5)  
                data_reg_xs[29:26] = data_reg_xs[29:26] + 3;
            //判断不大于等于5就进行移位
            data_reg_xs = data_reg_xs << 1;
        end 
    end 
//BCD码转换小数
always @(posedge clk or negedge rst_n)  
    if(!rst_n)
        data_reg_zs = 0;
    else begin
        //寄存和扩编data_ave(扩编16位是根据要得到的4个BCD码数据来判断)
        data_reg_zs = {12'b0,data_zs_in};
        //循环13次判断移位操作(13次是根据data_ave的位宽来判断)
        repeat(8) begin 
            //判断是否大于等于5,是就加3
            if(data_reg_zs[11:8] >= 5)   
                data_reg_zs[11:8] = data_reg_zs[11:8] + 3;

            if(data_reg_zs[15:12] >= 5)  
                data_reg_zs[15:12] = data_reg_zs[15:12] + 3;

            if(data_reg_zs[19:16] >= 5)  
                data_reg_zs[19:16] = data_reg_zs[19:16] + 3;
            //判断不大于等于5就进行移位
            data_reg_zs = data_reg_zs << 1;
        end 
    end 
//输出的8421BCD码
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        data_bcd_xs <= 0;
        data_bcd_zs <= 0;
    end 
    else begin
        data_bcd_xs <= data_reg_xs[29:18];
        data_bcd_zs <= data_reg_zs[19:8];
    end 
end
endmodule