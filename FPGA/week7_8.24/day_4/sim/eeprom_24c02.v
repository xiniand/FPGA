`timescale 1ns/1ps
// 简化 24C02 EEPROM 行为模型（用于仿真验证）
// 支持：写操作(0xA0+addr+data)、读操作(0xA1 Current Address Read)、ACK/NACK 应答
module eeprom_24c02(
    inout  sda,
    inout  scl
);
reg [7:0] mem [0:255];
reg [7:0] addr;
reg [7:0] shift;
reg [3:0] bitcnt;
reg sda_drv, sda_oe;
reg active, readmode;
reg [1:0] stage;   // 0=控制字节, 1=地址, 2=数据/读

assign sda = sda_oe ? sda_drv : 1'bz;

initial begin
    for (integer i = 0; i < 256; i = i + 1)
        mem[i] = 8'h00;
    mem[8'h00] = 8'h11; mem[8'h01] = 8'h22; mem[8'h02] = 8'h33;
    mem[8'h03] = 8'h44; mem[8'h04] = 8'h55;
    addr = 8'h00; shift = 8'h00; bitcnt = 4'd0;
    sda_drv = 1'b1; sda_oe = 1'b0;
    active = 1'b0; readmode = 1'b0; stage = 2'd0;
end

// START / STOP 检测：SDA 边沿且 SCL 为高
always @(posedge sda or negedge sda) begin
    if (scl == 1'b1) begin
        if (sda == 1'b0) begin          // START
            active <= 1'b1; readmode <= 1'b0;
            stage  <= 2'd0; bitcnt  <= 4'd0;
            sda_oe <= 1'b0;
        end
        else begin                       // STOP
            active <= 1'b0; readmode <= 1'b0; sda_oe <= 1'b0;
        end
    end
end

// SCL 上升沿：主机写方向采样数据位
always @(posedge scl) begin
    if (active && !readmode) begin
        if (bitcnt < 8) begin
            shift <= {shift[6:0], sda};
            bitcnt <= bitcnt + 1;
        end
        else begin
            bitcnt <= 4'd0;
            case (stage)
                2'd0: begin                      // 控制字节
                    if (shift[7] == 1'b1) begin
                        readmode <= 1'b1;        // 0xA1 -> 读
                    end
                    else begin
                        stage <= 2'd1;           // 0xA0 -> 下一字节是地址
                    end
                end
                2'd1: begin addr <= shift; stage <= 2'd2; end
                2'd2: begin mem[addr] <= shift; addr <= addr + 1'b1; end
            endcase
        end
    end
    else if (active && readmode) begin
        if (bitcnt == 8) bitcnt <= 4'd0;
        else bitcnt <= bitcnt + 1;
    end
end

// SCL 下降沿：ACK / 读数据输出
always @(negedge scl) begin
    if (active && !readmode) begin
        if (bitcnt == 8) begin
            sda_oe <= 1'b1; sda_drv <= 1'b0;    // 拉低 SDA = ACK
        end
        else begin
            sda_oe <= 1'b0;                      // 释放 SDA
        end
    end
    else if (active && readmode) begin
        if (bitcnt == 0) begin
            shift <= mem[addr];                  // 装载要读的字节
        end
        if (bitcnt == 8) begin
            sda_oe <= 1'b0;                      // 第9位释放，主机发NACK
            addr <= addr + 1'b1;
        end
        else begin
            sda_oe  <= 1'b1;
            sda_drv <= shift[7];                 // 输出 MSB
            shift   <= {shift[6:0], 1'b0};
        end
    end
end

endmodule
