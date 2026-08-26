`timescale 1ns/1ps
//============================================================================
// tb_iic.v : iic 主机模块仿真
// 从机模型行为：任何字节都应答；收到"读"控制字节(0xA9)后回发一个字节 0x5A
// 测试流程：1) 写操作  0xA8 + 0x00 + 0xA5
//           2) 读操作  0xA8 + 0x00 -> ReSTART -> 0xA9 -> 读回 0x5A
//============================================================================
module tb_iic();

reg         clk;
reg         rst_n;
reg         key;
reg         rw_ctrl;
reg  [7:0]  data_out;
wire [7:0]  data_in;
wire        sda;
wire        scl;

//---------------- DUT 例化 ----------------
iic u_dut(
    .clk      (clk),
    .rst_n    (rst_n),
    .iic_start(1'b0),     // 模块内部没用到，拉低即可
    .rw_ctrl  (rw_ctrl),
    .data_out (data_out),
    .key      (key),
    .sda      (sda),
    .scl      (scl),
    .data_in  (data_in)
);

//---------------- 50MHz 时钟 ----------------
initial clk = 0;
always #10 clk = ~clk;          // 20ns 周期 = 50MHz

//---------------- I2C 总线上拉电阻（开漏总线必须） ----------------
pullup (sda);
pullup (scl);

//============================================================================
// I2C 从机模型（模拟 24AA04 的最小行为）
//============================================================================
reg  sda_slave;                 // 1=释放(高阻) 0=拉低
assign sda = sda_slave ? 1'bz : 1'b0;

reg        started;             // 总线上有 START（含重复 START）
reg  [3:0] bitcnt;              // 当前字节收到第几位
reg  [7:0] rx;                  // 接收移位寄存器
reg  [3:0] byte_idx;            // 本轮 START 后第几个字节(0=控制字节)
reg        tx_mode;             // 从机发送数据模式
reg  [3:0] tx_cnt;              // 已发送位数
reg  [7:0] tx_data;             // 读操作时回发的数据

initial begin
    started = 0;  bitcnt = 0;  rx = 0;
    byte_idx = 0; sda_slave = 1;
    tx_mode = 0;  tx_cnt = 0;  tx_data = 8'h5A;
end

// START / STOP 检测：SCL 高电平期间 SDA 发生跳变
always @(negedge sda) begin
    if (scl === 1'b1) begin
        started  = 1;
        bitcnt   = 0;
        byte_idx = 0;           // 每个 START 后第一个字节一定是控制字节
        tx_mode  = 0;
        tx_cnt   = 0;
        $display("[%0t ns] >>> 检测到 START", $time);
    end
end

always @(posedge sda) begin
    if (scl === 1'b1) begin
        started = 0;
        $display("[%0t ns] <<< 检测到 STOP", $time);
    end
end

// SCL 上升沿：从机采样 SDA
always @(posedge scl) begin
    if (started) begin
        if (!tx_mode) begin
            if (bitcnt < 8) begin
                rx     = {rx[6:0], sda};
                bitcnt = bitcnt + 1;
            end
            else if (bitcnt == 8)
                bitcnt = 9;     // 第 9 个时钟是 ACK，不采数据
        end
        else begin
            if (tx_cnt < 9)
                tx_cnt = tx_cnt + 1;
        end
    end
end

// SCL 下降沿：从机驱动 ACK / 发送数据
always @(negedge scl) begin
    if (!started)
        sda_slave = 1;
    else if (tx_mode) begin
        if (tx_cnt < 8)
            sda_slave = tx_data[7 - tx_cnt];  // 发送数据，MSB 在前
        else
            sda_slave = 1;                    // 8 位发完，释放等主机 NACK
    end
    else if (bitcnt == 8) begin               // 第 9 个时钟：从机应答
        sda_slave = 0;
        $display("[%0t ns]     从机 ACK，字节%0d = 0x%02h", $time, byte_idx, rx);
        if (byte_idx == 0 && rx[0]) begin     // 控制字节 R/W=1：转入发送模式
            tx_mode = 1;
            tx_cnt  = 0;
        end
        byte_idx = byte_idx + 1;
    end
    else if (bitcnt == 9) begin
        bitcnt   = 0;
        sda_slave = 1;
    end
    else
        sda_slave = 1;
end

//============================================================================
// 激励
//============================================================================
initial begin
    rst_n   = 0;
    key     = 0;
    rw_ctrl = 0;
    data_out = 8'hA5;
    #201;
    rst_n = 1;
    #1000;

    //-------- 测试 1：写操作 (0xA8 + 字地址 0x00 + 数据 0xA5) --------
    $display("\n========== 测试 1：写操作 ==========");
    key = 1;  #100;  key = 0;   // 按键脉冲触发一次传输
    #600_000;                    // 等事务完成（约 450us）

    //-------- 测试 2：读操作（期望读回 0x5A）--------
    $display("\n========== 测试 2：读操作 ==========");
    rw_ctrl = 1;
    key = 1;  #100;  key = 0;
    #600_000;

    if (data_in === 8'h5A)
        $display("\n**** PASS：读回数据 = 0x%02h ****\n", data_in);
    else
        $display("\n**** FAIL：读回数据 = 0x%02h，期望 0x5A ****\n", data_in);

    #1000  $finish;
end

endmodule
