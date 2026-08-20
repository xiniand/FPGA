import re

sine = {}
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\prj\sine_wave.mif", encoding="utf-8") as f:
    for ln in f:
        m = re.match(r"\s*(\d+)\s*:\s*(\d+);", ln)
        if m:
            sine[int(m.group(1))] = int(m.group(2))

rows = []
for ln in open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump2.txt", encoding="utf-8", errors="replace"):
    m = re.match(r"(\d+) w1=(\d) wr1=([0-9a-f]+) d1=([0-9a-f]+) w2=(\d) wr2=([0-9a-f]+) d2=([0-9a-f]+) r1=(\d) r2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) dt=([0-9a-f]+) st=(\d) dn=(\d) ps=([01]+) ts=([01]+) tick=(\d)", ln)
    if m:
        rows.append((int(m.group(1)), int(m.group(2)), int(m.group(3),16), int(m.group(4),16),
                     int(m.group(5)), int(m.group(6),16), int(m.group(7),16),
                     int(m.group(8)), int(m.group(9)), int(m.group(10),16), int(m.group(11),16),
                     int(m.group(12),16), int(m.group(13),16), int(m.group(14),16),
                     int(m.group(15)), int(m.group(16)), int(m.group(17),2), int(m.group(18),2), int(m.group(19))))

# 找 rden1/rden2 上升沿（读事件），以及每次读后 data_tx 的变化
# 对每个读事件，记录: 时间、rd、该读对应的 q 值（读后2-3周期的 q）、读之前 data_tx、读之后 data_tx
events = []
prev_r1, prev_r2 = 0, 0
prev_dt = None
dt_change_time = None
for i, row in enumerate(rows):
    t, w1, wr1, d1, w2, wr2, d2, r1, r2, rd1, rd2, q1, q2, dt, st, dn, ps, ts, tick = row
    if r1 == 1 and prev_r1 == 0:
        # 读事件: q 值为 2 个周期后的 q1（读结果）
        qval = rows[min(i+2, len(rows)-1)][11]
        events.append((t, 'r1', rd1, qval, dt))
    if r2 == 1 and prev_r2 == 0:
        qval = rows[min(i+2, len(rows)-1)][12]
        events.append((t, 'r2', rd2, qval, dt))
    prev_r1, prev_r2 = r1, r2

print("total read events:", len(events))

# 分组统计: 每次读 -> data_tx 变化？
# 用 data_tx 变化序列
dt_changes = []
prev = None
for row in rows:
    t, dt = row[0], row[13]
    if dt != prev:
        dt_changes.append(t)
        prev = dt

# 对每个读事件，检查其后 6 个周期（120000ns）内是否有 data_tx 变化
out = []
for k, (t, typ, rd, qv, dt_before) in enumerate(events):
    changed = any(tc > t and tc <= t + 120000 for tc in dt_changes)
    out.append(f"ev#{k} t={t} type={typ} rd={rd:3d} q_after={qv:3d} dt_before={dt_before:3d} changed={changed}")

with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\ev_detail.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

# 统计每个周期（256 次读）中 changed=False 的次数
# 找出 period 边界：type 从 r1 变 r2 的位置
n_nochange = 0
cur_type = None
per_period = []
seg = []
for line in out:
    k = int(re.match(r"ev#(\d+)", line).group(1))
    typ = re.search(r"type=(\w+)", line).group(1)
    chg = re.search(r"changed=(\w+)", line).group(1) == "True"
    if typ != cur_type and seg:
        per_period.append((cur_type, len(seg), sum(1 for s in seg if "changed=False" in s)))
        seg = []
    cur_type = typ
    seg.append(line)
per_period.append((cur_type, len(seg), sum(1 for s in seg if "changed=False" in s)))
print("\n每段读统计 (type, 读次数, 无data_tx变化的次数):")
for typ, n, nc in per_period:
    print(f"  {typ}: {n} reads, {nc} no-change")

# 打印第一段（r1 周期1）中所有 changed=False 的读
print("\n第一段(周期1) 无变化的读:")
cnt = 0
for line in out:
    if "type=r1" in line and "changed=False" in line:
        print("  ", line)
        cnt += 1
        if cnt > 40: break
