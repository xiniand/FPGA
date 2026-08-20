import re

sine = {}
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\prj\sine_wave.mif", encoding="utf-8") as f:
    for ln in f:
        m = re.match(r"\s*(\d+)\s*:\s*(\d+);", ln)
        if m:
            sine[int(m.group(1))] = int(m.group(2))

lines = open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump.txt", encoding="utf-8", errors="replace").readlines()
seq = []
for ln in lines:
    m = re.match(r"(\d+) ns \| data_tx=([0-9a-f]+) start_tx=(\d) done_tx=(\d) \| pp_state=([01]+) rden1=(\d) rden2=(\d) rd1=([0-9a-f]+) rd2=([0-9a-f]+) wr1=([0-9a-f]+) wr2=([0-9a-f]+) q1=([0-9a-f]+) q2=([0-9a-f]+) \| rom=([0-9a-f]+) tick=(\d) tx_state=([01]+)", ln)
    if m:
        seq.append((int(m.group(1)), int(m.group(2),16)))

changes = []
prev = None
for t, dt in seq:
    if dt != prev:
        changes.append((t, dt))
        prev = dt
body = [v for _, v in changes][1:]

# 从 body[1]=128 出发，用连续性推导每个字节的 ROM 地址（值重复时选与上一地址连续的）
addr_seq = []
prev_addr = None
for v in body:
    if prev_addr is None:
        # 128 -> addr 0 或 128，取 0
        cand = [a for a in range(256) if sine[a] == v]
        a = cand[0] if cand else 0
    else:
        want = (prev_addr + 1) % 256
        if sine[want] == v:
            a = want
        else:
            # 找最接近 want 的候选
            cands = [a for a in range(256) if sine[a] == v]
            a = min(cands, key=lambda x: min((x - want) % 256, (want - x) % 256))
    addr_seq.append(a)
    prev_addr = a

out = []
for i, (v, a) in enumerate(zip(body, addr_seq)):
    out.append(f"{i+1:4d}: val={v:3d} romaddr={a:3d}")
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\addr_seq.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

# 找 romaddr 跳变（非 +1）的位置
print("addr 非+1 递增的位置:")
for i in range(1, len(addr_seq)):
    d = (addr_seq[i] - addr_seq[i-1]) % 256
    if d != 1:
        print(f"  byte {i+1}: addr {addr_seq[i-1]} -> {addr_seq[i]} (delta={d}, val {body[i-1]}->{body[i]})")
