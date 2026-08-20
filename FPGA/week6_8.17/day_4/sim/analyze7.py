import re

lines = open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump.txt", encoding="utf-8", errors="replace").readlines()
seq = []
for ln in lines:
    m = re.match(r"(\d+) ns \| data_tx=([0-9a-f]+) start_tx=(\d) done_tx=(\d) \| pp_state=([01]+) rden1=(\d) rden2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) wr1=([0-9a-f]+) wr2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) \| rom=([0-9a-f]+) tick=(\d) tx_state=([01]+)", ln)
    if m:
        seq.append((int(m.group(1)), int(m.group(2),16), int(m.group(3)), int(m.group(4)),
                    int(m.group(5),2), int(m.group(6)), int(m.group(7)), int(m.group(8),16), int(m.group(9),16),
                    int(m.group(10),16), int(m.group(11),16), int(m.group(12),16), int(m.group(13),16),
                    int(m.group(14),16), int(m.group(15)), int(m.group(16),2)))

# 第一次读事件（W2R1, rden1, rd 0..255）: 每个读 -> data_tx 之后应更新为 q1
# 找 rden1 上升沿
rises1 = []
prev = 0
for row in seq:
    t, dt, st, dn, stt, r1, r2, rd1, rd2, wr1, wr2, q1, q2, rom, tick, txs = row
    if r1 == 1 and prev == 0:
        rises1.append((t, rd1, q1, dt, stt))
    prev = r1

# 对每次读，找到其后 data_tx 稳定后的值（读之后 5 个时钟内应更新）
def value_after(t_read):
    # 从读时刻向后找 data_tx 的下一次变化
    for row in seq:
        t, dt = row[0], row[1]
        if t > t_read + 5:
            break
    # 简化: 取读时刻之后第一次 data_tx 变化的值（若读后 200ns 内无变化则取当前值）
    changed = None
    for row in seq:
        t, dt = row[0], row[1]
        if t > t_read and t <= t_read + 200:
            changed = dt
            break
    return changed

out = []
prev_val = None
for i, (t, rd, q1, dt, stt) in enumerate(rises1[:300]):
    # data_tx 在 rden_d 生效时更新 = 读时刻后 ~2-3 周期（40-60ns）
    new = value_after(t)
    tag = ""
    if new is not None and new != dt:
        tag = f"-> {new}"
    elif new is not None:
        tag = "NO CHANGE"
    out.append(f"read#{i} t={t} rd={rd:3d} q1={q1:3d} data_tx={dt:3d} {tag}")
    prev_val = dt

with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\read_detail.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(out))
print("written read_detail.txt")
# 打印峰值区域附近（rd 45..70）
sel = [l for l in out if 40 <= int(re.search(r"rd=(\d+)", l).group(1)) <= 75]
print("\n".join(sel))
