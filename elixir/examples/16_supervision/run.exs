# 第 16 章驱动脚本：cd examples/16_supervision && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 本章故意让 worker 反复崩溃；关闭崩溃报告，保证输出确定性。
Logger.configure(level: :none)

alias Ex16Supervision

IO.puts("==== 16 Supervisor 与 Application：监督策略、child_spec、重启阈值、应用回调 ====")

# ------------------------------------------------------------
# 1. child_spec：监督者与子进程之间的契约
# ------------------------------------------------------------
IO.puts("\n-- 1. use GenServer 生成的默认 spec 只有 id/start；默认值启动时补入 --")
IO.puts("  原始 spec => #{inspect(Ex16Supervision.child_spec_summary())}")
IO.puts("  覆盖 id/restart => #{inspect(Ex16Supervision.override_spec())}")

# ------------------------------------------------------------
# 2. one_for_one：崩谁重启谁
# ------------------------------------------------------------
IO.puts("\n-- 2. one_for_one：只有崩掉的那个被重启 --")
IO.puts("  {初始启动, 撞崩 w1 后} => #{inspect(Ex16Supervision.one_for_one_demo())}")

# ------------------------------------------------------------
# 3. one_for_all：一崩全重启
# ------------------------------------------------------------
IO.puts("\n-- 3. one_for_all：一个崩，整组按 spec 顺序全部重启 --")
IO.puts("  {初始启动, 撞崩 w2 后} => #{inspect(Ex16Supervision.one_for_all_demo())}")

# ------------------------------------------------------------
# 4. rest_for_one：崩点之后的重启
# ------------------------------------------------------------
IO.puts("\n-- 4. rest_for_one：崩的是第 k 个，它和它之后的重启 --")
IO.puts("  {撞 w2 后, 撞 w1 后} => #{inspect(Ex16Supervision.rest_for_one_demo())}")

# ------------------------------------------------------------
# 5. 重启强度：max_restarts / max_seconds
# ------------------------------------------------------------
IO.puts("\n-- 5. 重启超阈值（2 次/5 秒），监督者自己以 :shutdown 退出 --")
IO.puts("  {启动事件总数, 监督者死因} => #{inspect(Ex16Supervision.intensity_demo())}")

# ------------------------------------------------------------
# 6. restart：:permanent / :temporary / :transient
# ------------------------------------------------------------
IO.puts("\n-- 6. restart 策略决定「什么退出算需要重启」 --")
IO.puts("  实测四种情形 => #{inspect(Ex16Supervision.restart_policies_demo())}")

# ------------------------------------------------------------
# 7. Application 回调：把树交给 VM 生命周期管理
# ------------------------------------------------------------
IO.puts("\n-- 7. Application.start/2 声明整棵树；children 按列表顺序启动 --")
IO.puts("  应用树规模与策略 => #{inspect(Ex16Supervision.application_tree_demo())}")

IO.puts("""
-- 监督树设计要点 --
  children 列表即启动顺序；依赖方排在被依赖方后面
  互不相关的叶子       -> one_for_one（最常用，重启面最小）
  强耦合、必须同生共死 -> one_for_all
  有明确依赖链         -> rest_for_one（崩点之前的不动）
  崩了不重启           -> restart: :temporary；只在异常时重启 -> :transient
  反复崩溃说明不是闪断 -> 阈值兜底，监督者自杀，交给上层监督者处置
  手动 start_link 用于测试/脚本；生产由 Application 回调在 VM 启动时拉起
""")

IO.puts("==== 16 结束 ====")
