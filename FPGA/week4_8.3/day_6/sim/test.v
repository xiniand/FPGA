`timescale 1ns/1ns
module test;
reg             clk ;
reg             rst ;
reg             key ;
reg     [8:0]   sw  ;
wire    [7:0]   dig ;
wire    [5:0]   sel ;
wire    [3:0]   led ;

initial begin
    clk <= 0;
    rst <= 0;
    key <= 1;
    sw  <= 0;
    #20 rst <= 1;

    //================ 场景1：密码正确 -> 拆除成功（LED 全亮） ================
    sw <= 9'b0_1010_1010;   //与 PASSWORD 一致
    #500;
    key <= 0;               //按下确认
    #3000;                  //保持足够长以触发消抖
    key <= 1;               //释放
    #5000;
    $display("场景1: 密码正确 -> state=%0d sec=%0d led=%b (期望 state=01 led=1111)",
             top_u.state, top_u.sec, led);

    //================ 场景2：倒计时到 0 -> 爆炸（LED 闪烁） ================
    rst <= 0; #20; rst <= 1;
    sw  <= 0;               //错误密码
    #2000;
    //倒计时 40s（TIME_1S=100clk=2us），共 80us
    #100_000;
    $display("场景2: 倒计时结束 -> state=%0d sec=%0d led=%b (期望 state=10, led 闪烁)",
             top_u.state, top_u.sec, led);

    //================ 场景3：输错密码 -> 爆炸（LED 闪烁） ================
    rst <= 0; #20; rst <= 1;
    sw  <= 9'b0_0000_0000;  //与 PASSWORD 不符
    #500;
    key <= 0;               //按下确认（错误密码）
    #3000;
    key <= 1;
    #10000;
    $display("场景3: 输错密码 -> state=%0d sec=%0d led=%b (期望 state=10, led 闪烁)",
             top_u.state, top_u.sec, led);

    $stop;
end

always #10 clk = ~clk;

top #(
    .delay_1   (100            ),
    .TIME_1S   (100            ),
    .delay     (20             ),
    .BOOM_TIME (100            ),
    .START_SEC (8'd40          ),
    .PASSWORD  (9'b0_1010_1010 )
) top_u(
    .rst  (rst ),
    .clk  (clk ),
    .key  (key ),
    .sw   (sw  ),
    .dig  (dig ),
    .sel  (sel ),
    .led  (led )
);

endmodule
