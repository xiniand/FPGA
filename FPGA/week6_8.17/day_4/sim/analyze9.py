import re, sys

sine = {}
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\prj\sine_wave.mif", encoding="utf-8") as f:
    for ln in f:
        m = re.match(r"\s*(\d+)\s*:\s*(\d+);", ln)
        if m:
            sine[int(m.group(1))] = int(m.group(2))

# 逐周期: time w1 wr1 d1 w2 wr2 d2 r1 r2 rd1 rd2 q1 q2 dt st dn ps ts tick
rows = []
for ln in open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump2.txt", encoding="utf-8", errors="replace"):
    m = re.match(r"(\d+) w1=(\d) wr1=([0-9a-f]+) d1=([0-9a-f]+) w2=(\d) wr2=([0-9a-f]+) d2=([0-9a-f]+) r1=(\d) r2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) dt=([0-9a-f]+) st=(\d) dn=(\d) ps=([01]+) ts=([01]+) tick=(\d)", ln)
    if m:
        rows.append((int(m.group(1)), int(m.group(2)), int(m.group(3),16), int(m.group(4),16),
                     int(m.group(5)), int(m.group(6),16), int(m.group(7),16),
                     int(m.group(8)), int(m.group(9)), int(m.group(10),16), int(m.group(11),16),
                     int(m.group(12),16), int(m.group(13),16), int(m.group(14),16),
                     int(m.group(15)), int(m.group(16)), int(m.group(17),2), int(m.group(18),2), int(m.group(19))))
print("rows:", len(rows))

# ---- 1. 重建 RAM1 内容：写发生在 posedge P 时用上一周期的 (wr1, d1)；wren=1 表示写使能
mem1 = {}
for i in range(1, len(rows)):
    t, w1, wr1, d1, w2, wr2, d2, r1, r2, rd1, rd2, q1, q2, dt, st, dn, ps, ts, tick = rows[i]
    pt, pw1, pwr1, pd1 = rows[i-1][0], rows[i-1][1], rows[i-1][2], rows[i-1][3]
    if pw1 == 1:   # 上一周期 wren=1
        mem1[pwr1] = pd1   # 写入地址 pwr1，数据 pd1
print("RAM1 写入次数:", len(mem1))
keys1 = sorted(mem1.keys())
print("RAM1 地址范围:", keys1[0], "..", keys1[-1], " 连续:", keys1 == list(range(256)) if len(keys1)==256 else keys1[:10], "...")

# 打印 RAM1 内容（前 20 和后 20）
vals1 = [mem1.get(k, -1) for k in range(256)]
print("\nRAM1[0..15]:", vals1[:16])
print("RAM1[240..255]:", vals1[240:])

# 与理想窗口对比: 找 ROM 相位 φ 使 mem1[k] = sine[(φ+k) mod 256]
best = None
for phi in range(256):
    match = sum(1 for k in range(256) if mem1.get(k) == sine[(phi+k) % 256])
    if best is None or match > best[0]:
        best = (match, phi)
print("RAM1 与 sine[φ+k] 最大匹配:", best[0], "phi =", best[1], "/256")
phi1 = best[1]
print("RAM1[0..15]  vs sine[phi+k]:")
print("  mem1 :", vals1[:16])
print("  sine :", [sine[(phi1+k) % 256] for k in range(16)])
# 不匹配位置
mm = [k for k in range(256) if mem1.get(k) != sine[(phi1+k) % 256]]
print("RAM1 不匹配位置数:", len(mm), mm[:30])

# ---- 2. RAM2 内容（W2R1 期间写，取最后一次写入）
mem2 = {}
for i in range(1, len(rows)):
    t, w1, wr1, d1, w2, wr2, d2, r1, r2, rd1, rd2, q1, q2, dt, st, dn, ps, ts, tick = rows[i]
    pt, pw2, pwr2, pd2 = rows[i-1][0], rows[i-1][4], rows[i-1][5], rows[i-1][6]
    if pw2 == 1:
        mem2[pwr2] = pd2
vals2 = [mem2.get(k, -1) for k in range(256)]
best2 = None
for phi in range(256):
    match = sum(1 for k in range(256) if mem2.get(k) == sine[(phi+k) % 256])
    if best2 is None or match > best2[0]:
        best2 = (match, phi)
print("\nRAM2 与 sine[φ+k] 最大匹配:", best2[0], "phi =", best2[1], "/256")
mm2 = [k for k in range(256) if mem2.get(k) != sine[(best2[1]+k) % 256]]
print("RAM2 不匹配位置数:", len(mm2), mm2[:30])
print("RAM2[0..15]:", vals2[:16])
print("RAM2[240..255]:", vals2[240:])
