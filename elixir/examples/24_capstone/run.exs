# 第 24 章驱动脚本：cd examples/24_capstone && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 本章会刻意杀进程；监督报告带 pid，Logger 全静音（与 12–16 章同样处理）。
Logger.configure(level: :none)

alias Ex24Capstone.{Cache, Words}

workspace = Path.join(System.tmp_dir!(), "ex24_#{System.unique_integer([:positive])}")
File.mkdir_p!(workspace)

defmodule Ex24CapstoneDemo do
  @moduledoc false

  # 等待被 :kill 的缓存完成重启；轮询但不打印任何 pid/时序信息。
  def wait_cache(attempts \\ 50)
  def wait_cache(0), do: :timeout

  def wait_cache(n) do
    if Process.whereis(Ex24Capstone.Cache) do
      :restarted
    else
      Process.sleep(20)
      wait_cache(n - 1)
    end
  end

  # 每文件统计去重词数，固定顺序输出
  def file_summary(file_counts) do
    Enum.map(file_counts, fn
      {name, {:ok, counts}} -> {name, map_size(counts)}
      {name, {:error, reason}} -> {name, reason}
    end)
  end
end

IO.puts("==== 24 收官项目：监督树、缓存、并发词频、杀 worker 重试、杀服务自愈 ====")

# ------------------------------------------------------------
# 1. 应用启动即拉起监督树
# ------------------------------------------------------------
IO.puts("\n-- 1. Application 启动根监督树：缓存 + Task.Supervisor --")
IO.puts("  存活子进程 => #{Ex24Capstone.Application.active_children()}")

# ------------------------------------------------------------
# 2. 容错缓存读写
# ------------------------------------------------------------
IO.puts("\n-- 2. Cache GenServer：put/get/delete/keys --")
Cache.put(:a, 1)
Cache.put(:b, 2)
IO.puts("  size => #{Cache.size()}")
IO.puts("  keys => #{inspect(Cache.keys())}")
Cache.delete(:a)
IO.puts("  delete 后 size => #{Cache.size()}")

# ------------------------------------------------------------
# 3. 造固定内容的语料（临时目录，结尾清理）
# ------------------------------------------------------------
IO.puts("\n-- 3. 语料文件：三个 .txt（非 txt 文件会被忽略）--")

files = %{
  "a.txt" => "hello world\nhello beam\n",
  "b.txt" => "world of beam\n",
  "c.txt" => "你好 世界\n世界 beam\n",
  "notes.md" => "不应计入\n"
}

Enum.each(files, fn {name, content} ->
  File.write!(Path.join(workspace, name), content)
end)

IO.puts("  已就绪 => #{inspect(Enum.sort(Map.keys(files)))}")

# ------------------------------------------------------------
# 4. 正常并发统计
# ------------------------------------------------------------
IO.puts("\n-- 4. 每文件一个 Task 并发计数，主线程合并 --")
result = Words.count_dir(workspace)
IO.puts("  每文件词种 => #{inspect(Ex24CapstoneDemo.file_summary(result.file_counts))}")
IO.puts("  全语料 top3 => #{inspect(Ex24Capstone.top_n(result.merged, 3))}")

# ------------------------------------------------------------
# 5. 杀 worker：确定性卡点 → kill → 自动重试，结果不变
# ------------------------------------------------------------
IO.puts("\n-- 5. c.txt 第一轮 worker 被杀；协调方重试同一文件 --")
result2 = Words.count_dir(workspace, kill_first: ["c.txt"])
IO.puts("  kill_tags => #{inspect(result2.kill_tags)}")
IO.puts("  重试后全语料 top3 => #{inspect(Ex24Capstone.top_n(result2.merged, 3))}")
IO.puts("  两次合并一致 => #{result.merged == result2.merged}")

# ------------------------------------------------------------
# 6. 杀缓存：根监督 one_for_one 重启，服务自愈（内存数据丢失是契约）
# ------------------------------------------------------------
IO.puts("\n-- 6. 杀掉 Cache 进程：监督树立即重启，服务继续可用 --")
Process.exit(Process.whereis(Cache), :kill)
tag = Ex24CapstoneDemo.wait_cache()
IO.puts("  重启 => #{tag}")
IO.puts("  重启后 size => #{Cache.size()}")
Cache.put(:restored, true)
IO.puts("  重新写入读取 => #{Cache.get(:restored)}")

File.rm_rf!(workspace)
IO.puts("  临时工作区已清理")

IO.puts("""
-- 收官要点 --
  纯函数核心（分词/合并/排序）无进程无 IO，最好测、最可复用
  并发是组装：Task.Supervisor 管短命 worker，yield 收集、失败显式重试
  容错是分层：GenServer 管状态，根监督 one_for_one 让任一死亡只波及自身
  let-it-crash：被杀即重启；内存态丢失要在设计时接受（持久化交给存储层）
  确定性演示：卡死用 receive 信号、不用 sleep；退出原因归一化成固定 tag
""")

IO.puts("==== 24 结束 ====")
