import re, sys

lines = open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump.txt", encoding="utf-8", errors="replace").readlines()

# 解析每一行: time | data_tx | start_tx | done_tx | pp_state ... 等
seq = []  # (time_ns, data_tx, pp_state, rd1, rd2, rden1, rden2)
for ln in lines:
    m = re.match(r"(\d+) ns \| data_tx=([0-9a-f]+) start_tx=(\d) done_tx=(\d) \| pp_state=([01]+) rden1=(\d) rden2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) wr1=([0-9a-f]+) wr2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) \| rom=([0-9a-f]+) tick=(\d) tx_state=([01]+)", ln)
    if m:
        t, dt, st, dn, stt, r1, r2, rd1, rd2, wr1, wr2, q1, q2, rom, tick, txs = m.groups()
        seq.append((int(t), int(dt,16), int(r1), int(r2), int(rd1,16), int(rd2,16), int(q1,16), int(q2,16), int(rom,16), int(txs,2)))

# 提取 data_tx 变化序列
changes = []
prev = None
for row in seq:
    t, dt = row[0], row[1]
    if dt != prev:
        changes.append((t, dt))
        prev = dt

print("data_tx 变化序列长度:", len(changes))
print("\n前 40 个变化点:")
for t, dt in changes[:40]:
    print(f"  {t:>8} ns -> {dt:#04x} ({dt})")

# 打印完整字节序列（跳过起始 0），按 256 分组
vals = [dt for _, dt in changes]
print("\n总字节数:", len(vals))
for p in range(0, min(len(vals), 1024), 256):
    chunk = vals[p:p+256]
    print(f"\n--- 段 {p//256} (字节 {p}..{p+255}) ---")
    # 打印前 12 个和后 12 个
    print("  前12:", [f"{v:3d}" for v in chunk[:12]])
    print("  后12:", [f"{v:3d}" for v in chunk[-12:]])
