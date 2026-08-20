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

# 找 rden1 的上升沿（每次读）和 rden2 的上升沿
reads1 = []  # (time, rd1_at_rise, q1_after, data_tx_after)
prev_r1 = 0
prev_r2 = 0
prev_dt = None
r1_rise_times = []
r2_rise_times = []
for row in seq:
    t, dt, st, dn, stt, r1, r2, rd1, rd2, wr1, wr2, q1, q2, rom, tick, txs = row
    if r1 == 1 and prev_r1 == 0:
        r1_rise_times.append((t, rd1))
    if r2 == 1 and prev_r2 == 0:
        r2_rise_times.append((t, rd2))
    prev_r1, prev_r2 = r1, r2

print("rden1 上升沿次数:", len(r1_rise_times))
print("rden2 上升沿次数:", len(r2_rise_times))

# 统计 rden1 上升沿对应的 rd1 序列，找跳号
rd_seq1 = [rd for _, rd in r1_rise_times]
print("\nrden1 读地址序列(前40):", rd_seq1[:40])
print("rden1 读地址序列(最后20):", rd_seq1[-20:])
# 找非+1递增
print("\nrden1 rd 跳号位置:")
for i in range(1, len(rd_seq1)):
    d = (rd_seq1[i] - rd_seq1[i-1]) % 256
    if d != 1:
        print(f"  第{i}次读: rd {rd_seq1[i-1]} -> {rd_seq1[i]} (delta={d})")

# rden2 同理
rd_seq2 = [rd for _, rd in r2_rise_times]
print("\nrden2 读地址序列(前40):", rd_seq2[:40])
print("\nrden2 rd 跳号位置:")
for i in range(1, len(rd_seq2)):
    d = (rd_seq2[i] - rd_seq2[i-1]) % 256
    if d != 1:
        print(f"  第{i}次读: rd {rd_seq2[i-1]} -> {rd_seq2[i]} (delta={d})")

# 每个周期的读次数
print("\n各段读次数统计:")
# 按 pp_state 变化分段
seg = []
cur_state = None
cur_count = 0
cur_rd = []
for t, rd in r1_rise_times:
    pass
# 简化：直接统计 rden1/rden2 上升沿在时间上的分段
events = [(t, 'r1', rd) for t, rd in r1_rise_times] + [(t, 'r2', rd) for t, rd in r2_rise_times]
events.sort()
print("总读事件:", len(events))
# 打印每 256 次读的起止
for k in range(0, len(events), 256):
    chunk = events[k:k+256]
    types = set(c for _, c, _ in chunk)
    print(f"  读事件[{k}:{k+256}]: 起始@{chunk[0][0]}ns 结束@{chunk[-1][0]}ns 类型={types} 首rd={chunk[0][2]} 末rd={chunk[-1][2]}")
