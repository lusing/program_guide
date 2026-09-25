# 24 · 收官项目：容错缓存 + 并发词频

> 对应示例：`examples/24_capstone/`（独立 mix 工程，含 Application 监督树、ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

最后一章把前 23 章的零件装进一个完整应用：

```text
Ex24Capstone.Application            根监督树（one_for_one）
├── Ex24Capstone.Cache              GenServer：键值缓存（permanent）
└── Ex24Capstone.WorkerSup          Task.Supervisor：短命词频 worker
        └── Task × N                每文件一个，并发计数
Ex24Capstone.Words                  协调方：派生、收集、重试、合并
Ex24Capstone                        纯函数核心：分词 / 合并 / Top-N
```

两条演示主线：**杀掉一个 worker** 看协调方如何重试完成；**杀掉缓存服务**
看监督树如何原地重启。全程固定语料、固定标签，不出现 pid 与路径。

## 24.1 启动：Application 即监督树

`mix.exs` 的 `mod:` 把应用启动指向 Application 回调（第 16 章），
VM 引导时根监督树随之拉起：

```elixir
def start(_type, _args) do
  children = [
    Ex24Capstone.Cache,
    {Task.Supervisor, name: Ex24Capstone.WorkerSup}
  ]

  Supervisor.start_link(children, strategy: :one_for_one, name: Ex24Capstone.RootSup)
end
```

`Supervisor.count_children/1` 在 1.20 返回 **map**（旧版是 keyword）：

```elixir
def active_children do
  Ex24Capstone.RootSup |> Supervisor.count_children() |> Map.get(:active)
end
```

```text
-- 1. Application 启动根监督树：缓存 + Task.Supervisor --
  存活子进程 => 2
```

`one_for_one` 是刻意选择：缓存崩溃不该连累 worker 池，反之亦然——
默认策略让死亡的爆炸半径最小（策略全览见 16 章）。

## 24.2 容错缓存：GenServer 裸 map

`Cache` 是第 15 章的标准形态：状态是一张 map，API 全部走 call：

```elixir
def put(key, value), do: GenServer.call(__MODULE__, {:put, key, value})
def get(key), do: GenServer.call(__MODULE__, {:get, key})
# delete / size /keys 同理
```

```text
-- 2. Cache GenServer：put/get/delete/keys --
  size => 2
  keys => [:a, :b]
  delete 后 size => 1
```

这里特意不做持久化——**进程内缓存的状态生命周期等于进程生命**。
这个「缺陷」正是 24.6 的教学点。

## 24.3 语料：固定内容、固定文件集

演示数据全部在临时目录现造，结尾删除：

```elixir
files = %{
  "a.txt" => "hello world\nhello beam\n",
  "b.txt" => "world of beam\n",
  "c.txt" => "你好 世界\n世界 beam\n",
  "notes.md" => "不应计入\n"
}
```

```text
-- 3. 语料文件：三个 .txt（非 txt 文件会被忽略）--
  已就绪 => ["a.txt", "b.txt", "c.txt", "notes.md"]
```

## 24.4 并发词频：纯函数核心 + Task 组装

设计的第一步是**把纯逻辑抽离**：分词、合并、排序都不碰进程与文件
（见 `Ex24Capstone`，全部带 doctest）：

```elixir
def tokenize(line) do
  line
  |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true)   # \p{L} 覆盖中文
  |> Enum.map(&String.downcase/1)
end

def merge_counts(a, b), do: Map.merge(a, b, fn _k, x, y -> x + y end)

def top_n(counts, n) do
  counts
  |> Enum.sort_by(fn {word, count} -> {-count, word} end)
  |> Enum.take(n)
end
```

`Words` 只负责组装：每文件派生一个 Task，`Task.yield` 收集，归约时
`merge_counts` 合并：

```elixir
def count_file(path) do
  path
  |> File.stream!(:line)
  |> Enum.reduce(%{}, fn line, acc ->
    line |> Ex24Capstone.tokenize() |> Enum.frequencies()
    |> Ex24Capstone.merge_counts(acc)
  end)
end
```

```text
-- 4. 每文件一个 Task 并发计数，主线程合并 --
  每文件词种 => [{"a.txt", 3}, {"b.txt", 3}, {"c.txt", 3}]
  全语料 top3 => [{"beam", 3}, {"hello", 2}, {"world", 2}]
```

算一下账：beam 三个文件各出现 1 次共 3；hello 都在 a 共 2；world 在
a、b 各 1 共 2；同频 hello<world 按词序排。`File.ls!` 顺序不保证，
一律先 sort；文件过滤扩展名——`notes.md` 不进任务列表。

## 24.5 杀 worker：确定性卡点与显式重试

本节是全章的技术核心。需求是「杀掉某个 worker 并证明任务被重试」，
难点在**怎么确定地杀**。两个错误做法：

- `Process.sleep(50)` 等 worker 跑一半再杀——机器一忙时序就变，
  可能没开始也可能已跑完；
- 杀错进程。

正解：让「将被杀」的 worker 在开工前**等一个信号**（receive 等待，
默认 60 秒）：

```elixir
defp launch(dir, name, stall) do
  Task.Supervisor.async(WorkerSup, fn ->
    if stall do
      receive do
        :cancel -> :cancelled
      after
        60_000 -> :stalled
      end
    end

    count_file(Path.join(dir, name))
  end)
end
```

协调方不需要知道它执行到哪——任务在 `async` 返回时就存在，kill 与
指令位置无关。但有一个关键陷阱：**`Task.Supervisor.async/2` 的任务
仍与调用方相 link**（文档明示）；`:kill` 穿过 link 连调用方一起杀，
而且 `:kill`/`:killed` 是 trap 不住的。所以杀之前先 unlink：

```elixir
for {name, task} <- pairs, name in kill_set do
  Process.unlink(task.pid)      # yield 依赖的是 monitor，unlink 不影响收结果
  Process.exit(task.pid, :kill)
end
```

收集统一走「yield + 超时即 shutdown」，保证不泄漏 worker：

```elixir
defp collect(task) do
  case Task.yield(task, @yield_timeout) || Task.shutdown(task, :brutal_kill) do
    {:ok, value} -> {:ok, value}
    {:exit, reason} -> {:exit, reason}
  end
end
```

拿到 `{:exit, :killed}` 的文件，协调方用**正常 worker 重试一次**，
重试仍失败才落 `{:error, tag}`——整体不因单文件失败而崩。

```text
-- 5. c.txt 第一轮 worker 被杀；协调方重试同一文件 --
  kill_tags => [{:killed, "c.txt", :killed}]
  重试后全语料 top3 => [{"beam", 3}, {"hello", 2}, {"world", 2}]
  两次合并一致 => true
```

原始退出 reason 被 `normalize_reason/1` 归一化（`:killed` 保留、
其余一律 `:abnormal`）——reason 里可能带 pid，不能直接打印。

## 24.6 杀服务：监督重启与状态契约

最后对缓存做同样的事：杀进程，等它回来。

```elixir
Process.exit(Process.whereis(Cache), :kill)
tag = Ex24CapstoneDemo.wait_cache()
```

等待只轮询「名字在不在」，不打印 pid、不碰时序：

```elixir
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
```

```text
-- 6. 杀掉 Cache 进程：监督树立即重启，服务继续可用 --
  重启 => restarted
  重启后 size => 0
  重新写入读取 => true
  临时工作区已清理
```

应用重启只花几毫秒，调用方唯一能观察到的变化是**内存数据没了**。
这不是 bug：缓存本来就是可丢弃层；需要跨重启存活的数据写进数据库/
文件，Cache 只是它们前面的加速带。工程上还要注意 supervisor 的
重启阈值（16 章）——反复崩溃不会无限重启，防止错误数据造成
忙循环。

杀进程产生的监督报告带 pid，本章脚本与崩溃章节同样把
`Logger` 设为 `:none`。

## 24.7 要点小结

```text
  先抽纯函数核心：最好测、最好复用；进程与 IO 都是外层组装
  并发：Task.Supervisor 管短命 worker；yield 收集、超时 shutdown、失败显式重试
  容错：GenServer 管状态，one_for_one 让任一死亡只波及自身
  let-it-crash：worker 被杀即重试，服务被杀即重启；内存态丢失是显式契约
  确定性：receive 信号卡点（不 sleep）；退出原因归一化；list/map 全排序
```

## 24.8 坑位清单

1. **`Task.Supervisor.async` 的任务仍 link 调用方**。想强杀 worker 必须
   先 `Process.unlink/1`，否则 `:kill` 穿过 link 把测试/协调进程一起带走；
   yield 靠 monitor，unlink 不影响收结果。
2. **`:kill` 信号 trap 不住**。链接进程收到的是 `:killed`（not
   trappable）；需要温和停止用 `:normal`（不沿 link 传播）或
   `GenServer.stop`，但那是「商量」不是「强杀」。
3. **别用 sleep 对齐时序**。`sleep 50` 再杀是脆弱测试的经典来源；
   让将停的 worker 卡在 receive，协调方按信号/无条件下手，结果可复现。
4. **重启清空内存态是契约不是事故**。缓存的寿命=进程寿命；跨重启
   的数据放持久层，别指望 supervisor 替你保留。
5. **1.20 `Supervisor.count_children/1` 返回 map**，照旧版写
   `Keyword.get(..., :active)` 会 FunctionClauseError。
6. **Task.yield 超时要 shutdown 收尾**：`yield || Task.shutdown`，
   否则卡住的任务永久挂在监督树下；重试仍失败要降级成
   `{:error, tag}` 而不是让协调方崩。
7. **退出原因不能直接打印**：reason 常含 pid/元组；统一归一化成
   固定原子标签（`:killed`/`:abnormal`），这是第 4、5 层的前提。
8. **文件列表与结果必须排序**：`File.ls!` 顺序不指定，worker 完成
   顺序随调度；按文件名、`{-频次, 词}` 等显式键排，结果才跨环境一致。
9. **分词器要用 Unicode 类**：`[^\p{L}\p{N}]+/u` 才能正确处理中文；
   ASCII-only 的 `\w` 会把整段中文切成一个「非词」。
10. **杀进程演示先关 Logger**：监督报告自带 pid，落进 stdout/stderr
    都破坏确定性；`Logger.configure(level: :none)` 与崩溃章节一致。

---

> 本章曾是收官；第 25–29 章的扩充（函数式思维、闭包、递归进阶、
> 错误单子、地下城建模）接在它后面——纯函数的深层机理，到 29 章
> 与本章的 OTP 世界合流。
