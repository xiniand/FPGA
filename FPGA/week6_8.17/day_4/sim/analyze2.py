import re

lines = open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump.txt", encoding="utf-8", errors="replace").readlines()

seq = []
for ln in lines:
    m = re.match(r"(\d+) ns \| data_tx=([0-9a-f]+) start_tx=(\d) done_tx=(\d) \| pp_state=([01]+) rden1=(\d) rden2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) wr1=([0-9a-f]+) wr2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) \| rom=([0-9a-f]+) tick=(\d) tx_state=([01]+)", ln)
    if m:
        t, dt, st, dn, stt, r1, r2, rd1, rd2, wr1, wr2, q1, q2, rom, tick, txs = m.groups()
        seq.append((int(t), int(dt,16), int(r1), int(r2), int(rd1,16), int(rd2,16), int(q1,16), int(q2,16), int(rom,16), int(txs,2)))

# data_tx 变化序列
changes = []
prev = None
for row in seq:
    t, dt = row[0], row[1]
    if dt != prev:
        changes.append((t, dt))
        prev = dt

# 去掉最开始的复位 0（t=0 的初值），真正的字节从第一次 start_tx 之后的传输开始
# 但简单起见：分析变化序列的增量，找异常
vals = changes
out = []
out.append("idx,time_ns,val,delta,note")
prevv = None
for i, (t, v) in enumerate(vals):
    d = (v - prevv) if prevv is not None else 0
    note = ""
    # 正常正弦相邻差值约为 -3..+3（或 -2,+2 等）；异常则标记
    if prevv is not None and (abs(d) > 5):
        note = "  <<< ANOMALY"
    elif prevv is not None and v == prevv:
        note = "  <<< DUP"
    out.append(f"{i},{t},{v},{d}{note}")
    prevv = v

with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\seq_analysis.csv", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

# 只打印异常点
print("Anomalies (|delta|>5 or dup):")
for line in out[1:]:
    if "<<<" in line:
        print(" ", line)
print("\nFirst 30 changes:")
for line in out[1:31]:
    print(" ", line)
