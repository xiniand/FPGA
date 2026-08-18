module bin_to_bcd (
    input               clk             ,
    input               rst             ,
    input       [12:0]  data_in         ,   //输入待转换的数据
    output      [15:0]  data_bcd            //输出转换后的BCD码数据
);
reg     [28:0]          data_reg        ;   //寄存和扩编data_in
//BCD码转换
always @(posedge clk or negedge rst)  
    if(!rst)
        data_reg = 0;
    else begin
        //寄存和扩编data_ave(扩编16位是根据要得到的4个BCD码数据来判断)
        data_reg = {16'b0,data_in};
        //循环13次判断移位操作(13次是根据data_ave的位宽来判断)
        repeat(13) begin 
            //判断是否大于等于5,是就加3
            if(data_reg[16:13] >= 5)   
                data_reg[16:13] = data_reg[16:13] + 3;
                
            if(data_reg[20:17] >= 5)  
                data_reg[20:17] = data_reg[20:17] + 3;
            
            if(data_reg[24:21] >= 5)  
                data_reg[24:21] = data_reg[24:21] + 3;
            
            if(data_reg[28:25] >= 5)  
                data_reg[28:25] = data_reg[28:25] + 3;
            //判断不大于等于5就进行移位
            data_reg = data_reg << 1;
        end 
    end 
//输出的8421BCD码
assign data_bcd = data_reg[28:13];
endmodule