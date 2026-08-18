# SynthPilot_Tutorial 学习笔记

> 来源仓库：<https://github.com/LNC0831/SynthPilot_Tutorial>
>
> 环境：Vivado 2024.2 + Xilinx FPGA + SynthPilot（FPGA 开发 AI 辅助工具集，MCP）
>
> 整理日期：2026-08-10

---

## 一、仓库概况

**SynthPilot** 是 FPGA 开发的 AI 辅助工具集（MCP），本仓库是其系列教程配套资料。共 4 期工程：

| 期号 | 主题 | 芯片 |
| --- | --- | --- |
| 01 | Vivado 基础工程（LED 闪烁 + 按键消抖） | XC7Z010 |
| 02 | I2C 收发器设计与仿真验证 | XC7Z010 |
| 03 | 多时钟域数据采集与串口输出 | XC7Z010 |
| 04 | XDMA + FFT 音乐频谱分析仪 | Kintex UltraScale+ KU3P |

**方法论**：按「任务书 → 分 Phase 子任务书 → RTL/仿真/上位机 → 综合实现 → 下板验证」工程化推进，用 SynthPilot MCP 工具完成 Vivado 全流程（create_project / run_synthesis / generate_bitstream / program_device / 串口工具等）。

---

## 二、项目 03：多时钟域数据采集 + UART 输出（典型 CDC 示例）

### 系统架构

```text
clk_fast(200MHz) ──► data_sampler ──► async_fifo(跨时钟域) ──► uart_tx(50MHz) ──► tx_out
```

### 模块设计

- **data_sampler**（200 MHz 域）：分频计数器每 `SAMPLE_DIV` 拍产生 8-bit 递增数据（0x00~0xFF 循环），FIFO 满反压暂停。
- **async_fifo**：用 **Xilinx FIFO Generator IP**（异步模式、FWFT、Block RAM），不手写 RTL。
- **uart_tx**（50 MHz 域）：8N1 帧格式（1 起始位低 + 8 数据位 LSB 先发 + 1 停止位高），波特率分频产生 bit 时钟，`tx_valid/tx_ready` 握手。
- **board_top**：例化 Clocking Wizard（50MHz 晶振 → 200MHz + 50MHz），`locked` 与按键复位组合成全局复位。

### 关键知识点

- **跨时钟域**：不同速率域必须经异步 FIFO 桥接；用 `wr_rst_busy/rd_rst_busy` 门控读写，避免复位期误操作。
- **吞吐匹配**：UART 115200 每字节约 86.8μs（11520 字节/秒），采样速率须低于此上限，保证 FIFO 不溢出。
- **仿真加速**：TB 用 UART 接收模型自动解码；参数覆盖（BAUD_RATE=1M、SAMPLE_DIV 调小）；`$dumpfile` 存波形。
- **Vivado 分析报告**：
  - `report_utilization`（LUT/FF/BRAM/DSP/IO）
  - `report_timing_summary`（WNS / TNS / WHS / THS）
  - `report_cdc` / `report_cdc_details`（跨时钟域检查）
  - `report_congestion`（拥塞等级 ≥3 需关注）
  - `report_power`（静态 + 动态功耗）
- **综合 vs 实现**：logic delay 几乎不变（由器件 speed file 决定）；**route delay 综合后是估算、实现后是真实布线延迟**。综合后 WNS>0 不等于时序一定满足，需实现后确认。
- **实现策略**：时序紧用 `Performance_Explore`，面积紧用 `Area_Explore`，低功耗 `Power_DefaultOpt`；WNS < -2ns 应改 RTL 而非依赖工具策略。
- **实现流程三段**：opt_design（优化）→ place_design（布局）→ route_design（布线）。

---

## 三、项目 04：XDMA + FFT 音乐频谱分析仪（核心）

### 系统架构（数据流）

```text
MP3 → PCM(16bit/44.1kHz) → PCIe DMA(H2C) → FPGA: FFT(1024点) → |Re|+|Im| → C2H → Flask+WebSocket → Canvas 频谱图
```

### 技术选型

| 组件 | 选型 |
| --- | --- |
| 目标器件 | xcku3p-ffvb676-2-e (Kintex UltraScale+) |
| PCIe DMA | XDMA IP，Gen3 x4，AXI4-Stream 模式，128-bit，1×H2C + 1×C2H |
| FFT | xfft v9.1，1024 点 / Pipelined Streaming / Fixed Point / Scaled / Convergent Rounding / Natural Order |
| 时钟 | Clock Wizard，100MHz 差分 → 100MHz 单端；XDMA 内部 axi_aclk ≈250MHz 封闭在 BD 内不引出 |

> **单时钟域设计**：BD 内用 CDC FIFO 把 AXI-Stream 转到 clk_100m 域，顶层 RTL 所有用户逻辑都在 100MHz，无跨时钟域负担。

### Phase 1：Block Design（XDMA + FIFO）

- XDMA（Gen3 x4，AXI4-Stream，1H2C+1C2H，128-bit）+ 两个 **Independent Clock 模式** AXI-Stream Data FIFO（深度 256）。
- **位宽规律**：XDMA AXI-Stream 位宽由 lane width 决定（x1/x2=64b，x4=128b，x8=256b）。
- Input FIFO：s_axis 接 axi_aclk（写），m_axis 接 clk_100m（读）；Output FIFO 反向。
- `usr_irq_req` 未用 → Constant IP 接 0；BD Wrapper 作为顶层 RTL 子模块例化。

### Phase 2：FFT IP（知识密度最高）

**核心参数**：1024 点，Pipelined Streaming I/O（最高吞吐，DIF 分解，多级 Radix-2 蝶形）。

**Scaling Schedule（缩放调度）**：

- Pipelined Streaming 以 **Radix-2 对**为缩放单位，1024 点 = 10 级 Radix-2 = **5 个缩放级**，SCALE_SCH 仅 **10 bit**（每级 2 bit）。
- 每级 2-bit 编码：`2'b00`=不缩放，`2'b01`=÷2（右移1），`2'b10`=÷4（右移2），`2'b11`=÷8（右移3）。
- 官方推荐 `SCALE_SCH = 10'b10_10_10_10_11`（首级÷8，其余÷4，总缩放 2¹¹=2048，绝对不溢出）。
- 保守方案 `10'b10_10_10_10_10`（总缩放 1024=N，精度最优，满幅值有极小溢出风险）。

**Config 字（16-bit）**：

```text
bit[0]    = FWD_INV (1=FFT, 0=IFFT)
bit[10:1] = SCALE_SCH (5 级 × 2 bit)
bit[15:11]= 未使用，填 0
推荐正变换配置：16'h0557
```

**数据格式**：`tdata[15:0]=Re（实部）`，`tdata[31:16]=Im（虚部）`；纯实数输入 `{16'h0000, pcm_sample}`。

**AXI4-Stream 时序要点**：

- 握手：`tvalid & tready` 同高的时钟上升沿完成一次传输；tvalid 断言后不可撤回、tdata 不可变。
- **Config 必须在帧数据之前或同时发送**（config FIFO 空会阻塞 `s_axis_data_tready`）。
- **每帧都发 config**（Pipelined Streaming 要求），即使配置不变。
- tlast 标记帧边界（输入第 1024 个样本断言；输出帧尾自动断言）。

**常见坑**：

1. **phantom config slot**：上电后 config FIFO 有默认槽位，第一个显式 config 被挤到第二帧 → 第一帧输出错乱（奇谐波/幅度偏差 4×）。解决：先发 warm-up 零帧 + config 消耗 phantom slot。
2. **xsim 与随机 gap 不兼容**：`$urandom_range` 控制 tvalid 会导致 xsim 死循环 → 用确定性 gap（每 4 样本插 2 空闲周期）。
3. 输入 Re/Im 放错位域（Re 在低 16 位）；SCALE_SCH 全零会导致溢出回绕。
4. 延迟：Pipelined Streaming + Natural Order 典型延迟约 N~2N 个时钟周期。

### Phase 3：幅度计算模块 magnitude_calc

- L1 近似：`|X[k]| ≈ |Re| + |Im|`，硬件 = 两个绝对值 + 一个加法器（最大误差 41%，频谱可视化足够）。
- **-32768 边界**：16-bit 取反会溢出（+32768 超范围），必须先**符号扩展为 17-bit** 再取反。
- 结果 18-bit 加法，饱和到 16-bit unsigned（最大 65535）。
- 组合直通设计：`s_axis_tready` 直连 `m_axis_tready`，`tvalid/tlast` 同步传递，零周期延迟。

### Phase 4：顶层集成

- **H2C 位宽适配（128→32）**：取低 16-bit 作 FFT 实部、虚部补零；`{16'b0, tdata[15:0]}`。
- **C2H 位宽适配（16→128）**：零扩展 + `tkeep=16'hFFFF`。
- **Config 驱动状态机**：`SEND_CONFIG → WAIT_FRAME_END → SEND_CONFIG`，`cfg_sent` 标志每帧 tlast 后自动清零重发。
- **帧同步靠 tlast**：PC 单次 DMA 写 16384 字节 → XDMA 自动生成 tlast → FFT 识别帧边界。
- **Plan B**（XDMA 不生成 tlast 时）：10-bit 计数器每 1024 个有效 beat 置 `tlast=1`。
- 仿真不例化 XDMA（PCIe 无法行为仿真），搭**数据通路 TB**（位宽适配 + FFT + config 驱动 + magnitude_calc）。

### Phase 5：约束、综合与实现

- XDC：`create_clock` 主时钟、差分时钟、PCIe 引脚（refclk/rxp/txp/perstn）、LED 状态。
- 实际结果：综合 46s（WNS=1.358ns），实现 WNS=0.631ns / WHS=0.010ns；opt_design 后 LUT -21.5%、FF -8.4%；资源 LUT 9.75%、BRAM 12.5%、GT 25%、PCIE 100%；比特流 DRC 仅 3 Warning 无 Error。

### Phase 6：驱动安装与硬件验证

- `program_device` 烧录 → reboot 完成 PCIe 枚举（Gen3 x4，BDF 01:00.0，Device ID 9034）→ 装 XDMA 驱动 `xdma.ko` → `/dev/xdma0_{h2c,c2h}_0`。
- 端到端测试：单频 bin64 peak=4000；多频 bin64+256 各=2000；静音全零 —— 与仿真一致。

### Phase 7：上位机（Flask + WebSocket）

- 音频管线：MP3 → pydub+ffmpeg → mono/16bit/44.1kHz → 分帧 1024 → 写 `/dev/xdma0_h2c_0`。
- 频谱管线：读 `/dev/xdma0_c2h_0` → 提取 16-bit 幅度 → 归一化 → WebSocket 推 `{bins}` → Canvas 对数频谱。

---

## 四、与当前课程（Altera Quartus）的对照

| 维度 | 当前课程（Quartus/Cyclone IV） | SynthPilot 教程（Vivado/Xilinx） |
| --- | --- | --- |
| 工具链 | Quartus 18.1 + ModelSim | Vivado 2024.2 + xsim |
| 顶层方式 | RTL 全手写 | Block Design + Wrapper（IP 集成） |
| 跨时钟域 | 手动打拍 / 手写 FIFO | 异步 FIFO IP、XDMA CDC FIFO |
| 通信 | UART/IIC 手写状态机 | 手写 + PCIe XDMA、AXI4-Stream |
| 工程管理 | 手写 .qsf | SynthPilot MCP 自动化 + 任务书/Phase 文档 |

**可迁移知识**：AXI4-Stream 握手（tvalid/tready/tlast）、跨时钟域方法论、UART/I2C 状态机、时序分析（WNS/Slack/TNS 与 Quartus 概念一致）、缩放调度/定点思想。

---

## 五、参考资料

- Xilinx PG109 - Fast Fourier Transform v9.1 LogiCORE IP Product Guide
- Xilinx dma_ip_drivers（XDMA Linux 驱动）
- SynthPilot：<https://github.com/SynthPilot>
