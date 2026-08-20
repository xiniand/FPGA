import re

sine = {}
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\prj\sine_wave.mif", encoding="utf-8") as f:
    for ln in f:
        m = re.match(r"\s*(\d+)\s*:\s*(\d+);", ln)
        if m:
            sine[int(m.group(1))] = int(m.group(2))

full = [sine[i] for i in range(256)]

# 去掉相邻重复值后的"理想输出"
collapsed = []
for v in full:
    if not collapsed or collapsed[-1] != v:
        collapsed.append(v)
print("sine full len:", len(full), " collapsed len:", len(collapsed))

lines = open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\sim\dump.txt", encoding="utf-8", errors="replace").readlines()
seq = []
for ln in lines:
    m = re.match(r"(\d+) ns \| data_tx=([0-9a-f]+)", ln)
    if m:
        seq.append((int(m.group(1)), int(m.group(2),16)))
changes = []
prev = None
for t, dt in seq:
    if dt != prev:
        changes.append((t, dt))
        prev = dt
body = [v for _, v in changes][1:]

print("actual body len:", len(body))
print("\nactual first 30:", body[:30])
print("collapsed first 30:", collapsed[:30])
print("\nactual around wrap1 (220-235):", body[219:235])
print("collapsed around its wrap:", collapsed[-10:], collapsed[:5])
