onbreak {resume}
# 场景1：密码正确 -> 拆除成功（t=10us 处检查）
run 10us
puts "S1 t=[expr [now] / 1000]us state=[examine -radix unsigned /test/top_u/state] sec=[examine -radix unsigned /test/top_u/sec] led=[examine -radix binary /test/led]"
# 场景2：倒计时结束 -> 爆炸（t=105us 处检查）
run 95us
puts "S2 t=[expr [now] / 1000]us state=[examine -radix unsigned /test/top_u/state] sec=[examine -radix unsigned /test/top_u/sec] led=[examine -radix binary /test/led]"
# 场景3：输错密码 -> 爆炸（t=135us 处检查）
run 30us
puts "S3 t=[expr [now] / 1000]us state=[examine -radix unsigned /test/top_u/state] sec=[examine -radix unsigned /test/top_u/sec] led=[examine -radix binary /test/led]"
quit -f
