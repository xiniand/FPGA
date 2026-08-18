module yima9 (
    input       [8:0]   sw      ,   //9 个拨码开关输入
    output  reg         match       //密码匹配指示
);
//9 输入译码器：参考 38 译码器（ziyima3_8）扩展为 9 输入
//当 9 位开关组合等于预设密码 PASSWORD 时，match 输出 1
parameter PASSWORD = 9'b0_1010_1010; //预设 9 位密码（可修改）

always @(*) begin
    if(sw == PASSWORD)
        match = 1'b1;
    else
        match = 1'b0;
end

endmodule
