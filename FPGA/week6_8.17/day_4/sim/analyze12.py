import re

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

# 1) 状态切换时刻
trans = []  # (time, from_state, to_state)
prev_ps = None
for row in rows:
    t, ps = row[0], row[16]
    if prev_ps is not None and ps != prev_ps:
        trans.append((t, prev_ps, ps))
    prev_ps = ps
print("状态切换:")
for t, f, t2 in trans:
    print(f"  {t} ps: {f:03b} -> {t2:03b}")

# 2) 读事件时间（rden1/rden2 上升沿）
rises1, rises2 = [], []
prev_r1, prev_r2 = 0, 0
for row in rows:
    t, r1, r2, rd1, rd2 = row[0], row[7], row[8], row[9], row[10]
    if r1 == 1 and prev_r1 == 0:
        rises1.append((t, rd1))
    if r2 == 1 and prev_r2 == 0:
        rises2.append((t, rd2))
    prev_r1, prev_r2 = r1, r2
print("\nrden1 上升沿:", len(rises1), " rden2 上升沿:", len(rises2))
print("rden1 首次:", rises1[0], " 末次:", rises1[-1])
print("rden2 首次:", rises2[0], " 末次:", rises2[-1])

# 3) 帧间隔（读事件间隔）统计 + mod 256 累计
def frame_stats(rises, name):
    spac = [(rises[i+1][0] - rises[i][0]) for i in range(len(rises)-1)]
    cycles = [s // 20000 for s in spac]  # 每周期 20000ps = 20ns
    print(f"\n{name}: {len(spac)} 个帧间隔, 平均 {sum(cycles)/len(cycles):.3f} cycles")
    print(f"  间隔分布: min={min(cycles)}, max={max(cycles)}")
    # 累计 mod 256
    total = sum(cycles)
    print(f"  总时长 = {total} cycles, mod 256 = {total % 256}")
    # 检查每帧间隔 mod 256 的累计
    cum = 0
    for i, c in enumerate(cycles):
        cum = (cum + c) % 256
    print(f"  256帧累计 mod 256 = {cum}")

frame_stats(rises1, "周期1读取(rden1, W2R1)")
frame_stats(rises2, "周期2读取(rden2, W1R2)")

# 4) W2R1 / W1R2 状态时长（用状态切换时刻）
t_w1_end = trans[0][0] if trans else None
print("\n状态时长:")
for i in range(len(trans)-1):
    dur = (trans[i+1][0] - trans[i][0]) // 20000
    print(f"  {trans[i][2]:03b}(from {trans[i][1]:03b}) 持续 {dur} cycles (mod256={dur%256})")
