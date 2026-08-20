import re

lines = open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump.txt", encoding="utf-8", errors="replace").readlines()

seq = []
for ln in lines:
    m = re.match(r"(\d+) ns \| data_tx=([0-9a-f]+) start_tx=(\d) done_tx=(\d) \| pp_state=([01]+) rden1=(\d) rden2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) wr1=([0-9a-f]+) wr2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) \| rom=([0-9a-f]+) tick=(\d) tx_state=([01]+)", ln)
    if m:
        t, dt, st, dn, stt, r1, r2, rd1, rd2, wr1, wr2, q1, q2, rom, tick, txs = m.groups()
        seq.append((int(t), int(dt,16), int(r1), int(r2), int(rd1,16), int(rd2,16), int(q1,16), int(q2,16), int(rom,16), int(txs,2)))

changes = []
prev = None
for row in seq:
    t, dt = row[0], row[1]
    if dt != prev:
        changes.append((t, dt))
        prev = dt

vals = [v for _, v in changes]
# 去掉首个复位 0
body = vals[1:]
print("transmitted bytes:", len(body))

# 找周期边界：正弦在 124 (addr255) -> 128 (addr0)。边界处 delta 约为 +4 或异常
# 打印每个边界的上下文：值...值 | 值...
# 规则：若 v[i-1] > v[i] 且之后又开始上升，是峰；若 v[i-1] < v[i] 且之后继续下降，是谷
# 周期边界 = 序列从上升趋势变为重新从 128 上升的位置
out = []
for i in range(1, len(body)):
    d = body[i] - body[i-1]
    out.append(f"{i-1}:{body[i-1]:3d} -> {i}:{body[i]:3d} (d={d:+d})")

with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\seq_deltas.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

# 打印所有 |d| > 4 的位置（正弦正常相邻差 ≤4；124->128 为 +4 是正常回卷）
print("\nAll deltas with |d|>=5 (deltas at wraps around peak/trough are +-3..4 max):")
for i in range(1, len(body)):
    d = body[i] - body[i-1]
    if abs(d) >= 5:
        print(f"  byte {i}: {body[i-1]} -> {body[i]} (d={d:+d})")

# 打印周期边界上下文：找到所有从'较低谷值附近'跳到 128/131 的位置（即新周期起点）
print("\nSuspected period starts (value jumps to >=128 from a low value, or wrap 124->128):")
for i in range(1, len(body)):
    d = body[i] - body[i-1]
    if body[i] >= 128 and body[i-1] <= 128 and d > 0:
        print(f"  byte {i}: {body[i-3:i+4]}")
