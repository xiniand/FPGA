# 交通灯控制系统

## 功能概述

基于 FPGA 的双向路口交通灯控制器，实现南北(NS)和东西(EW)两个方向的红绿灯控制与倒计时显示。

## 工作周期

| 阶段 | NS方向 | EW方向 | 持续时间 |
|------|--------|--------|----------|
| NS_GREEN | 绿灯 | 红灯 | 30秒 |
| NS_YELLOW | 黄灯 | 红灯 | 5秒 |
| EW_GREEN | 红灯 | 绿灯 | 20秒 |
| EW_YELLOW | 红灯 | 黄灯 | 5秒 |

完整周期：60秒

## 模块结构

```
top
├── clk_div          # 时钟分频 (50MHz → 1Hz, 1kHz)
├── traffic_fsm      # 交通灯状态机
└── seg_driver       # 数码管动态扫描驱动
```

## 硬件平台

- **开发板**：AWC_C4 DVK
- **主控芯片**：EP4CE6F17C8 (Cyclone IV E, F256 BGA)
- **板载时钟**：50MHz (PIN_E1)
- **数码管**：6位7段共阳极（低有效），本工程使用前4位

## 引脚分配

| 信号 | 引脚 | 说明 |
|------|------|------|
| `clk_50M` | PIN_E1 | 50MHz 板载晶振 |
| `rst_n` | PIN_F8 | 复位按键（低有效） |
| `emergency` | PIN_E15 | 紧急按钮（低有效） |
| `seg[0]` (a) | PIN_B7 | 数码管段码 |
| `seg[1]` (b) | PIN_A8 | 数码管段码 |
| `seg[2]` (c) | PIN_A6 | 数码管段码 |
| `seg[3]` (d) | PIN_B5 | 数码管段码 |
| `seg[4]` (e) | PIN_B6 | 数码管段码 |
| `seg[5]` (f) | PIN_A7 | 数码管段码 |
| `seg[6]` (g) | PIN_B8 | 数码管段码 |
| `seg[7]` (dp) | PIN_A5 | 数码管小数点 |
| `dig[0]` | PIN_A4 (SEL0) | 位选 — EW个位 |
| `dig[1]` | PIN_B4 (SEL1) | 位选 — EW十位 |
| `dig[2]` | PIN_A3 (SEL2) | 位选 — NS个位 |
| `dig[3]` | PIN_B3 (SEL3) | 位选 — NS十位 |

## 使用说明

1. 用 Quartus Prime 打开 `prj/day_1_ai.qpf`
2. 确认设备型号为 **EP4CE6F17C8**
3. 运行综合与布局布线
4. 下载 bit 流至 FPGA 开发板

## 参数调整

- **时钟频率**：若板载时钟不是 50MHz，修改 `clk_div.v` 中的 `CNT_1HZ` 和 `CNT_1KHZ`
- **倒计时初值**：修改 `traffic_fsm.v` 中的 `T_NS_GREEN`、`T_NS_YELLOW`、`T_EW_GREEN`、`T_EW_YELLOW`
- **数码管极性**：已在 `seg_driver.v` 中适配共阳极（低有效）
- **紧急有效电平**：`traffic_fsm.v` 中 `emergency` 为高有效，`top.v` 中通过按键低有效取反接入

## 仿真

```bash
# ModelSim 仿真
vlib work
vlog ../src/*.v ../sim/tb_top.v
vsim -voptargs=+acc work.tb_top
add wave -r /*
run -all
```
