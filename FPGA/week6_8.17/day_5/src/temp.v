module temp (
    input               clk         ,
    input               rst_n       ,
    input       [15:0]  temp_shift  ,
    input               data_T      ,
    output  reg [7:0]   temp_smg_zs  ,
    output  reg [13:0]  temp_smg_xs 
);
    
reg [15:0]      temp_rg         ;
reg [7:0]       temp_smg_zs_rg  ;//整数位未转化寄存
reg [13:0]      temp_smg_xs_rg  ;//小数位未转化寄存
reg [23:0]      temp_smg_rg     ;    
reg             en              ;//开始信号
always @(posedge clk or negedge rst_n)
    if(!rst_n)
        en <= 0;
    else if(data_T)
        en <= 1;
    else
        en <= en;
//判断正负
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        temp_rg <= 0;
    end 
    else if(data_T) begin
        if(temp_shift [15:12] == 4'b1111)begin
            temp_rg <= ~temp_shift + 1;
        end 
        else if(temp_shift [15:12] == 4'b0000)begin
            temp_rg <= temp_shift;
        end 
    end 
end 
//提取整数小数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        temp_smg_zs_rg <= 0;
        temp_smg_xs_rg <= 0;
        temp_smg_rg     <=0;
    end 
    else if(en )begin
        temp_smg_xs_rg <= temp_rg[3:0]*625;
        temp_smg_zs_rg <= temp_rg[11:4];
    end
end 
//按下一次开关smg切换显示一次
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        temp_smg_zs <= 0;
        temp_smg_xs <= 0;
    end
    else if(en )begin
        temp_smg_zs <= temp_smg_xs_rg;
        temp_smg_xs <= temp_smg_zs_rg;
    end 
end

endmodule