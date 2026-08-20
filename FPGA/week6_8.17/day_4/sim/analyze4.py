import re

# 构建正弦表: addr -> value
sine = {}
with open(r"E:\FPGA\GIT\FPGA\week6_8.17\day_4\prj\sine_wave.mif", encoding="utf-8") as f:
    for ln in f:
        m = re.match(r"\s*(\d+)\s*:\s*(\d+);", ln)
        if m:
            sine[int(m.group(1))] = int(m.group(2))
addr_of = {v: k for k, v in sine.items()}  # 只用于近似显示（值有重复）

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
# 理想正弦：从 128 开始循环
ideal = []
i = 0
while len(ideal) < len(body):
    ideal.append(sine[i % 256])
    i += 1

# 对比实际 vs 理想（理想 = 严格 sine[0..255] 循环），打印所有不一致处
print("idx | actual | ideal | delta | note")
mismatch = 0
for i, (a, idl) in enumerate(zip(body, ideal)):
    note = ""
    if a != idl:
        mismatch += 1
        note = "*** MISMATCH"
    if a != idl:
        print(f"{i+1:4d} | {a:3d}    | {idl:3d}  | {a-idl:+d} | {note}")
print(f"\nTotal mismatches vs ideal sine[0..255] cycle: {mismatch}")
