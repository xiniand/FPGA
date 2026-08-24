module temp (
    input               clk         ,
    input               rst_n       ,
    input       [15:0]  temp_shift  ,
    output  reg [7:0]   temp_smg_zs  ,
    output  reg [13:0]  temp_smg_xs 
);
reg	en;
reg [15:0]      temp_rg         ;
reg [7:0]       temp_smg_zs_rg  ;//整数位未转化寄存
reg [13:0]      temp_smg_xs_rg  ;//小数位未转化寄存
reg [23:0]      temp_smg_rg     ;    

//判断正负
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        temp_rg <= 0;
    end 
    else if(temp_shift [15:12] == 4'b1111)begin
        temp_rg <= ~temp_shift + 1;
    end 
    else if(temp_shift [15:12] == 4'b0000)begin
        temp_rg <= temp_shift;
    end 
end 
//提取整数小数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        temp_smg_zs <= 0;
        temp_smg_xs <= 0;
        temp_smg_rg     <=0;
    end 
    else begin
        temp_smg_xs <= temp_rg[3:0]*625;
        temp_smg_zs <= temp_rg[11:4];
    end
end 


endmodule