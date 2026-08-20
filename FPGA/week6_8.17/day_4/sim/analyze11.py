import re, sys

sine = {}
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\prj\sine_wave.mif", encoding="utf-8") as f:
    for ln in f:
        m = re.match(r"\s*(\d+)\s*:\s*(\d+);", ln)
        if m:
            sine[int(m.group(1))] = int(m.group(2))

rows = []
for ln in open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump3.txt", encoding="utf-8", errors="replace"):
    m = re.match(r"(\d+) w1=(\d) wr1=([0-9a-f]+) d1=([0-9a-f]+) w2=(\d) wr2=([0-9a-f]+) d2=([0-9a-f]+) r1=(\d) r2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) dt=([0-9a-f]+) st=(\d) dn=(\d) ps=([01]+) ts=([01]+) tick=(\d)", ln)
    if m:
        rows.append((int(m.group(1)), int(m.group(2)), int(m.group(3),16), int(m.group(4),16),
                     int(m.group(5)), int(m.group(6),16), int(m.group(7),16),
                     int(m.group(8)), int(m.group(9)), int(m.group(10),16), int(m.group(11),16),
                     int(m.group(12),16), int(m.group(13),16), int(m.group(14),16),
                     int(m.group(15)), int(m.group(16)), int(m.group(17),2), int(m.group(18),2), int(m.group(19))))
print("rows:", len(rows))

# ---- 1. 各写阶段的 RAM 内容快照 ----
# 写发生: 上一周期 wren=1 时写入 (wr, d)。记录每个 (写阶段) 的最终内容
# 阶段: W1 (ps=001, wren1=1), W2R1 (ps=010, wren2=1), W1R2 (ps=100, wren1=1)
# 我们按时间分段，每段结束时该 RAM 的"当前内容"即下次读取的内容
# 简化: 记录每次 wren1 上升沿开始的连续写入窗口（wraddress 从 0 或任意值连续+1），
#       以及每次 wren2 上升沿开始的窗口

def window_phase(wr_log):
    """wr_log: list of (wr, d)。返回与 sine[(phi+k)%256] 匹配的 phi"""
    mem = {}
    for wr, d in wr_log:
        mem[wr % 256] = d
    best = None
    for phi in range(256):
        match = sum(1 for k in range(256) if mem.get(k) == sine[(phi+k) % 256])
        if best is None or match > best[0]:
            best = (match, phi)
    return best, mem

# 找所有写窗口: wren1 或 wren2 连续为 1 的周期
# 对 RAM1: 写窗口 = W1 和 W1R2 (ps=001 和 ps=100)。对 RAM2: W2R1 (ps=010)
# 但更简单: 把每次"wren 上升沿"到"wren 下降沿"之间收集 (wr,d)，作为一个窗口
win1_logs = []  # 每个窗口的 (wr,d) 列表
win2_logs = []
cur1, cur2 = None, None
prev_w1, prev_w2 = 0, 0
for i, row in enumerate(rows):
    t, w1, wr1, d1, w2, wr2, d2 = row[0], row[1], row[2], row[3], row[4], row[5], row[6]
    if w1 == 1 and prev_w1 == 0:
        cur1 = []
    if w1 == 1 and cur1 is not None:
        cur1.append((wr1, d1))
    if w1 == 0 and prev_w1 == 1 and cur1 is not None:
        win1_logs.append(cur1)
        cur1 = None
    if w2 == 1 and prev_w2 == 0:
        cur2 = []
    if w2 == 1 and cur2 is not None:
        cur2.append((wr2, d2))
    if w2 == 0 and prev_w2 == 1 and cur2 is not None:
        win2_logs.append(cur2)
        cur2 = None
    prev_w1, prev_w2 = w1, w2
if cur1: win1_logs.append(cur1)
if cur2: win2_logs.append(cur2)

print("\nRAM1 写窗口数:", len(win1_logs), " RAM2 写窗口数:", len(win2_logs))
for idx, wl in enumerate(win1_logs[:6]):
    best, mem = window_phase(wl)
    keys = sorted(mem.keys())
    print(f"RAM1 窗口{idx}: {len(wl)} 次写, addr {keys[0]}..{keys[-1]}, 与sine匹配 phi={best[1]} ({best[0]}/256)")
for idx, wl in enumerate(win2_logs[:6]):
    best, mem = window_phase(wl)
    keys = sorted(mem.keys())
    print(f"RAM2 窗口{idx}: {len(wl)} 次写, addr {keys[0]}..{keys[-1]}, 与sine匹配 phi={best[1]} ({best[0]}/256)")

# ---- 2. data_tx 变化序列与异常 ----
dt_changes = []
prev = None
for row in rows:
    t, dt = row[0], row[13]
    if dt != prev:
        dt_changes.append((t, dt))
        prev = dt
body = [v for _, v in dt_changes][1:]
print("\ndata_tx 变化次数:", len(dt_changes), " 传输字节数:", len(body))

# 找 |delta|>5
print("\n异常跳变 (|delta|>5):")
anomalies = []
for i in range(1, len(body)):
    d = body[i] - body[i-1]
    if abs(d) > 5:
        anomalies.append((i, body[i-1], body[i], d))
        print(f"  byte {i}: {body[i-1]} -> {body[i]} (d={d:+d})")
if not anomalies:
    print("  (无)")

# ---- 3. 各周期边界 ----
print("\n周期边界 (124->128 或接近):")
for i in range(1, len(body)):
    if body[i] >= 128 and body[i-1] <= 128 and body[i] > body[i-1]:
        ctx = body[max(0,i-3):i+4]
        print(f"  byte {i}: ...{ctx}")
