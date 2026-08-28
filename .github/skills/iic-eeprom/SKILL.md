---
name: iic-eeprom
description: '设计 IIC(I2C) 通信与 EEPROM 控制。Use for: 实现/调试 IIC 主机时序、SCL/SDA 三态总线、START/STOP/ACK、器件地址、AT24C02 字节/页写、随机/顺序读、多字节读写、与 UART 组帧联调，在 Verilog/FPGA 中完成 EEPROM 读写。'
argument-hint: '描述你的 IIC/EEPROM 需求，例如：系统时钟多少MHz、IIC 速率(100K/400K)、EEPROM 型号(AT24C02/AT24C04)、单字节还是多字节读写、地址几字节、数据来源/去向(UART/按键/数码管)'
---

# IIC 通信协议与 EEPROM 控制（AT24C02）

## 作用
IIC（I²C）是**两线同步串行**总线：**SDA（数据）+ SCL（时钟）**，均为**开漏输出 + 上拉电阻**，支持一主多从。EEPROM（如 AT24C02）通过 IIC 接口实现非易失存储：**掉电数据不丢失**，常用于保存配置、校准参数、用户数据。本 Skill 讲解如何在 Verilog/FPGA 中用**有限状态机**实现 IIC 主机时序并读写 AT24C02。

## 何时使用
- 需要把数据**持久化存储**（EEPROM/Flash），掉电不丢失
- 与其他 IIC 从机（温度传感器、RTC、ADC/DAC、OLED）通信
- 需要与 UART 联调：上位机通过串口下发数据 → FPGA 写入/读出 EEPROM

## 核心步骤

### 1. 三态总线（SDA/SCL 都靠上拉）
开漏结构：主机只能**主动拉低**或**释放（高阻）**，靠外部上拉电阻回高。
```verilog
assign sda    = sda_en ? sda_out : 1'bz;   // sda_en=1 驱动，=0 高阻读入
assign sda_in = sda;
assign scl    = scl_en ? 1'b0    : 1'bz;   // SCL 只由主机拉低/释放
```
> 一定要有上拉电阻（板载通常已有 4.7K），否则总线悬空、无法通信。

### 2. 时序分频（50MHz → 100K）
```
delay = CLK_FREQ / IIC_CLK      // 一个 IIC 位周期对应系统时钟数，如 50M/100K = 500
MID   = delay / 2               // 半周期（SCL 高/低各一半）
Q_MID = delay / 4               // 1/4 周期
TQ_MID= MID + Q_MID             // 3/4 周期
```
- `cnt_time` 从 0 数到 `delay-1` 为一个位周期，共 `delay` 拍。
- SCL 高电平区间 ≈ `[Q_MID, TQ_MID]`（中段），SCL 低电平区间 = 其余。**数据只能在 SCL 低电平期间改变，高电平期间必须保持稳定。**

### 3. 协议要素（START / 数据位 / ACK / STOP）
| 要素 | 时序要求 | 实现要点 |
|------|----------|----------|
| **START** | SCL 高时 SDA 由高→低 | `cnt_time>=delay-1` 拉低 SCL，`cnt_time>=MID-1` 时 `sda_out<=0` |
| **数据位** | SCL 低时准备数据，SCL 高时稳定 | `cnt_time==1` 时 `sda_out<=数据[7-cnt_bit]`；高电平区间不翻转 |
| **ACK 采样** | 第 9 个时钟，主机释放 SDA 读从机应答 | `sda_en<=0`，在 `cnt_time==MID-1` 采 `ack_flag<=sda_in` |
| **STOP** | SCL 高时 SDA 由低→高 | `cnt_time>=Q_MID-1` 拉高 SCL，`cnt_time>=TQ_MID-1` 时 `sda_out<=1` |

- **ACK 含义**：从机应答拉低 SDA = **ACK（0）**；从机不应答保持高 = **NACK（1）**。
  读最后 1 字节前主机要主动发 NACK（告诉从机"够了"），其余字节发 ACK。
- 所有地址/数据 **先发最高位（MSB first）**，一字节 8 位后再跟 1 个 ACK 位（共 9 个时钟）。

### 4. 主机读写状态机（一次完整读写流程）
```
写流程:  IDLE → START_1 → ID_W → ACK1 → WR_DATA → ACK2 → STOP
读流程:  IDLE → START_1 → ID_W → ACK1 → WR_DATA → ACK2 → START_2 → ID_R → ACK3 → RD_DATA → NACK → STOP
```
- `ID_W`：发器件地址 + 写位（`id_w`）
- `ID_R`：发器件地址 + 读位（`id_r`）——**读多字节需先发一个重复起始位 START_2**
- `WR_DATA`：每拍发 1 位，`cnt_bit` 0→7 一字节，然后进 ACK2
- `RD_DATA`：每拍读 1 位，在 **SCL 高电平中点 `cnt_time==MID`** 采 `data_temp[7-cnt_bit]<=sda_in`
- `NACK`：发完一字节后，若还有字节要读则发 ACK，最后一字节发 NACK；**NACK 判定必须在 SCL 低电平（`cnt_time==0`）锁存，禁止在 SCL 高电平期间翻转 sda_out**
- `ack_flag==1`（从机 NACK/无应答）→ 提前跳 STOP，避免死等

### 5. EEPROM 控制（AT24C02）
- **容量**：2Kbit = **256 字节**，每 **8 字节一页**（页写最大 8 字节，跨页要分页写）。
- **器件地址**：`1010 A2 A1 A0 R/W`，本工程 A0-A2 接地 → 写地址 `8'b1010_0000`(0xA0)，读地址 `8'b1010_0001`(0xA1)。
- **写操作**：`START + 器件写地址 + 字节地址 + 数据...`（页内地址自动递增）
- **读操作**：
  - **当前地址读**：`START + 器件读地址 + 读数据`
  - **随机读**：`START + 器件写地址 + 字节地址 + 重复START + 器件读地址 + 读数据`（本工程采用）
  - **顺序读**：连续读，前 N-1 字节发 ACK，最后 1 字节发 NACK
- **写周期 tWR ≈ 5ms**：写完一页后需等待内部擦写完成，期间不应发起新操作。

### 6. 多字节读写 + UART 组帧（eeprom_rw 控制层）
IIC 时序层（`iic_0`）只管"按 rw_ctrl/sendnum/recvnum 完成一串字节收发"，**控制层**（`eeprom_rw`）负责解析命令并驱动它。常用 UART 帧协议：
```
包头0xFE | 读写标志(0写1读) | 发送字节数 | 接收字节数 | EEPROM地址 | 数据... | 帧尾
```
- 控制层状态机：`IDLE(等包头) → WORR → SENDNUM → RECVNUM → ADDR → DATA → STOP(发iic_start，等iic_done回IDLE)`
- 多字节写：UART 收的数据先暂存 `databuf[0:15]`，再逐个喂给 IIC；`sendnum_cnt` 计已切到总线的字节数。
- **每帧都要从 `databuf[0]` 重新取数**（帧间清零 `send_idx`）——这是多字节读写最常见的 bug 源：上一帧残留地址导致本帧错位。

## 参考实现
- 完整 IIC 主机时序：[assets/iic_0.v](./assets/iic_0.v)（三段式状态机 + 位周期计数器，支持读写、多字节、ACK 检测）
- EEPROM 控制/组帧层：[assets/eeprom_rw.v](./assets/eeprom_rw.v)（UART 帧解析 + 多字节缓冲）
- 顶层例化：[assets/top_iic_eeprom.v](./assets/top_iic_eeprom.v)（UART 收 → eeprom_rw 解析 → iic_0 时序 → 读回数据入 FIFO 经 UART 回传）
- 仿真测试：[assets/test_iic.v](./assets/test_iic.v)（task 模拟 UART 帧下发写/读命令，`tri0` 模拟 SDA/SCL 上拉）
- 协议时序详解：[references/iic-protocol.md](./references/iic-protocol.md)

## 注意事项
- **时序核心**：数据在 SCL **低**电平变，SCL **高**电平采/稳；SCL 高电平期间 SDA 不能跳变（否则被当成 START/STOP）。
- **采样点**：ACK 在 SCL 高电平中点（`MID-1`）采样；读数据在 `cnt_time==MID` 采样。采样太早/太晚都会读到错误值。
- **读缓冲清零**：`RD_DATA` 中 `data_temp` 只在每字节开头（`cnt_bit==0 && cnt_time==0`）清一次，**禁止每拍清零**，否则丢数据。
- **NACK 锁存时机**：在 SCL 低电平（`cnt_time==0`）判定并锁存 `sda_out`，高电平期间禁止翻转。
- **ACK 方向**：ACK/NACK 的"谁应答"要分清——地址/数据阶段是**从机应答**主机；读多字节的中间字节是**主机应答**从机，最后一字节主机 NACK。
- **页写边界**：AT24C02 一页 8 字节，跨页地址需分页写，否则地址回绕覆盖。
- **上电/复位**：总线空闲态 SDA/SCL 都应保持高（`sda_out<=1`、`scl_en<=0`），否则从机误判 START。
- **调试技巧**：用 SignalTap 抓 `scl/sda/c_state/cnt_time` 对照协议波形逐状态核对；重点看 START 沿、ACK 采样点、NACK 翻转时机。
