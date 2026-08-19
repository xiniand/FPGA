//按键消抖模块：同步打拍 + 计数消抖 + 下降沿(按下)脉冲输出
module key_debounce (
    input           clk     ,//系统时钟
    input           rst_n   ,//低有效复位
    input           key     ,//按键输入(按下为0，低有效)
    output  reg     flag     //消抖后按下产生的单周期脉冲
);
parameter   DELAY = 1_000_000 ;//消抖时间(周期数)，默认约20ms@50MHz

reg [19:0]  cnt             ;//消抖计数器
reg [1:0]   key_in          ;//同步打拍信号
reg         key_d           ;//消抖后电平打拍(用于边沿检测)
reg         key_debounced   ;//消抖后的按键电平

//1. 同步打拍：消除亚稳态（低有效按键初始化为1）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key_in <= 2'b11;
    else
        key_in <= {key_in[0], key};
end

//2. 计数消抖：电平稳定超过 DELAY 周期才翻转输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt         <= 0;
        key_debounced <= 1'b1;
    end
    else if(key_in[1] != key_debounced) begin//电平有变化，开始计数
        if(cnt == DELAY - 1)
            key_debounced <= key_in[1];//稳定，更新输出电平
        else
            cnt <= cnt + 1;
    end
    else
        cnt <= 0;//电平一致，清零
end

//3. 边沿检测：下降沿(按下)产生单周期脉冲
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key_d <= 1'b1;
    else
        key_d <= key_debounced;
end
//按下瞬间 key_debounced 由1变0：key_d(上一拍)=1，~key_debounced=1 -> flag=1
assign flag = key_d & ~key_debounced;

endmodule
