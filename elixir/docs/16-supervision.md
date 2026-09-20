# 16 · Supervisor 与 Application

> 对应示例：`examples/16_supervision/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

第 12 章我们学会了 link：进程崩了，牵连的进程一起死。光会「一起死」没用，
还得有人负责**重新拉起**。这个角色就是 **Supervisor（监督者）**——它本身也是
一个进程，唯一的工作是按一份子进程清单（children）启动、监视、重启子进程，
自己几乎不写业务逻辑。把第 13 章的 Task、第 14 章的 Agent、第 15 章的
GenServer 挂到监督者下面，就得到一棵崩溃后能自愈的**监督树**。

本章所有实验都围绕一个设计：叶子 `Worker` 每次启动（包括被重启）都在 `init/1`
里给收集器 `BootLog` 发一条 `{:boot, tag}`。于是「谁在什么时候被（重新）启动」
可以像读日志一样读出来，而不用打印任何 pid 或时间戳：

```elixir
@impl true
def init(opts) do
  if opts[:sub], do: send(opts[:sub], {:boot, opts[:tag]})
  {:ok, %__MODULE__{tag: opts[:tag], sub: opts[:sub]}}
end

def die(server, reason \\ :boom), do: GenServer.stop(server, reason)
```

`die/2` 用任意退出原因停掉 worker——`:normal` 算正常退出，`:boom` 算异常，
两种原因在后面的 restart 策略里待遇不同。

## 16.1 child_spec：监督者与子进程之间的契约

监督者需要知道每一个孩子的四件事：**唯一 id、怎么启动、崩了怎么办、关停多久算超时**。
这份说明书叫 **child spec**，三种等价写法：

```elixir
Worker                                 # 简写一：模块名 -> Worker.child_spec(:no_arg) ... 实为 child_spec([])
{Worker, tag: :w1}                     # 简写二：{模块, 参数} -> Worker.start_link(tag: :w1)
%{id: :w1, start: {Worker, :start_link, [[tag: :w1]]},
  restart: :permanent}                 # 完整 map：id + start MFA + 可选项
```

`use GenServer`（以及 Agent、Task.Supervisor）会自动生成 `child_spec/1`。
一个容易踩的实测细节：**现代 Elixir 生成的 spec 只有 `:id` 和 `:start` 两个键**，
`restart: :permanent`、`type: :worker`、`shutdown: 5000` 这些默认值由监督者在
真正拉起子进程时补入，map 里看不到也 `Map.fetch!` 不到：

```text
-- 1. use GenServer 生成的默认 spec 只有 id/start；默认值启动时补入 --
  原始 spec => %{id: Ex16Supervision.Worker, start: {Ex16Supervision.Worker, :start_link, [[tag: :ignored]]}}
  覆盖 id/restart => %{id: :custom_id, restart: :temporary}
```

想改默认值，用 `Supervisor.child_spec/2` 包一层（本例覆盖了 `:id` 与 `:restart`）：

```elixir
Worker
|> Supervisor.child_spec(id: :custom_id, restart: :temporary)
|> Map.take([:id, :restart])
# => %{id: :custom_id, restart: :temporary}
```

`:id` 只在**监督者内部簿记**里用（同一监督者下 id 不能重复）；进程注册名是另一回事，
仍要在启动参数里传 `name:`。

## 16.2 启动一棵树：Supervisor.start_link/2

有了清单，启动只需一行。本章的内部工具 `start_tree/2` 给每个 worker 造一个
完整 map spec，再交给监督者：

```elixir
children =
  Enum.map(tags, fn tag ->
    %{
      id: tag,
      start: {Worker, :start_link, [[name: worker_name(unique, tag), tag: tag, sub: log]]},
      restart: :permanent
    }
  end)

{:ok, sup} = Supervisor.start_link(children, strategy: strategy)
```

两个要点：

1. **children 列表的顺序就是启动顺序**（关停时反过来）。有依赖关系时，被依赖方
   排在前面——监督者保证前一个起来了再起下一个。
2. `Supervisor.start_link/2` 返回的监督者进程与调用方 **link**。脚本/测试里手动
   起的树，结束要 `Supervisor.stop(sup)` 收尾；生产里它自己挂在上层监督者下面。

等待子进程启动不能靠 `Process.sleep/1` 拍脑袋——本章的 `BootLog` 提供
`{:wait, n}` 阻塞调用：事件不够时把 `from` 存进状态、不回复，事件到齐再用
`GenServer.reply/2` 补答（第 15 章延迟回复的实际用途）。

## 16.3 one_for_one：崩谁重启谁

默认策略 `:one_for_one` 下，每个子进程互不相干：w1 崩了，只重启 w1，w2 纹丝不动。

```elixir
def one_for_one_demo do
  {:ok, log, sup, unique} = start_tree([:w1, :w2], :one_for_one)
  initial = wait_tags(log, 2)
  :ok = GenServer.call(log, :reset)

  Worker.die(worker_name(unique, :w1), :boom)
  restarted = wait_tags(log, 1)

  teardown(sup, log)
  {initial, restarted}
end
```

```text
-- 2. one_for_one：只有崩掉的那个被重启 --
  {初始启动, 撞崩 w1 后} => {[:w1, :w2], [:w1]}
```

这是最常用的策略：重启面最小，互不相关的叶子（请求 worker、连接池成员）都用它。

## 16.4 one_for_all 与 rest_for_one：成组重启

当子进程强耦合、必须同生共死时用 `:one_for_all`：**任何一个**崩掉，监督者先把
其余活着的全部停掉，再按 spec 顺序把整组重新拉起。撞的是 w2，重启的却是
`w1, w2, w3` 三个：

```text
-- 3. one_for_all：一个崩，整组按 spec 顺序全部重启 --
  {初始启动, 撞崩 w2 后} => {[:w1, :w2, :w3], [:w1, :w2, :w3]}
```

`:rest_for_one` 介于两者之间：把 children 看成一条依赖链，**崩的是第 k 个，
则第 k 个和它之后的全部重启，它之前的不动**。同一棵树连撞两次看得最清楚：

```text
-- 4. rest_for_one：崩的是第 k 个，它和它之后的重启 --
  {撞 w2 后, 撞 w1 后} => {[:w2, :w3], [:w1, :w2, :w3]}
```

撞 w2：w2、w3 重启，w1 不动；再撞 w1：w1 是链头，于是整链三个全重启。
典型场景：w1 持有共享数据库连接，w2、w3 依赖它——w1 没了，w2、w3 拿着死连接
也没有存在意义。

## 16.5 重启强度：监督者也会自杀

重启不是无限快的。`Supervisor.start_link/2` 接受两个闸门：

```elixir
Supervisor.start_link([spec],
  strategy: :one_for_one,
  max_restarts: 2,     # 默认 3
  max_seconds: 5)      # 默认 5
```

在 `max_seconds` 秒内重启次数超过 `max_restarts`，说明这不是偶发闪断而是
**必然崩溃**（启动即崩），再拉起只会浪费资源、刷屏日志。此时监督者放弃治疗：
**它自己以 `:shutdown` 退出**，把问题交给上一层监督者处置。本章把阈值调到
2 次/5 秒，连撞三次，在一个 `trap_exit` 的 runner 里用 monitor 等它的死讯：

```text
-- 5. 重启超阈值（2 次/5 秒），监督者自己以 :shutdown 退出 --
  {启动事件总数, 监督者死因} => {3, :shutdown}
```

`3` = 初始 1 次 + 超限前的 2 次重启；监督者的死因归一化后是固定的 `:shutdown`
（不打印原始 reason，避免 pid 等噪声）。这正是监督树要**分层**的原因：叶子的
监督者自杀后，它的上层监督者可以按自己的策略决定是否把整棵子树重新拉起。

## 16.6 restart：什么退出算「需要重启」

spec 的 `:restart` 键决定监督者如何看待一次退出，三种取值：

| 取值 | 异常退出（`:boom`、raise、:kill） | 正常退出（`:normal`、`:shutdown`） |
|---|---|---|
| `:permanent`（默认） | 重启 | 重启 |
| `:temporary` | 不重启，直接移除 | 不重启，直接移除 |
| `:transient` | 重启 | 不重启，直接移除 |

四种组合逐一实测（worker 崩掉后轮询一小段时间，看有没有新的 `{:boot}` 事件）：

```text
-- 6. restart 策略决定「什么退出算需要重启」 --
  实测四种情形 => %{permanent_abnormal: :restarted, temporary_abnormal: :not_restarted, transient_abnormal: :restarted, transient_normal: :not_restarted}
```

注意 `:transient` 的语义是「只在**异常**时重启」——Task 跑完正常收工用 transient
正合适；任务抛了才算事故。判定正常退出的原因是 `:normal` 与 `:shutdown`
（以及 `{:shutdown, term}`），其余一律算异常。`:temporary` 子进程死后在监督者
簿记里被移除，`Supervisor.count_children/1` 的 `:active` 会少一个。

## 16.7 Application：把树交给 VM 生命周期

脚本里手动 `start_link` 的树，脚本退出树就没了。真实程序（第 22 章的 release）
由 VM 启动：VM 在启动你的应用时调用其 **Application 回调**模块的 `start/2`，
你在里面返回顶层监督者：

```elixir
defmodule Ex16Supervision.Application do
  use Application

  # 注意：alias 不跨模块继承，这里必须再次别名（或写全限定名）。
  alias Ex16Supervision.{BootLog, Worker}

  @impl true
  def start(_type, prefix) do
    children = [
      {BootLog, name: :"ex16_boot_log_#{prefix}"},
      %{id: :cache,    start: {Worker, :start_link, [[name: :"ex16_cache_#{prefix}", ...]]}},
      %{id: :worker_a, start: {Worker, :start_link, [[name: :"ex16_worker_a_#{prefix}", ...]]}}
    ]

    Supervisor.start_link(children, strategy: strategy(), name: :"ex16_sup_#{prefix}")
  end

  def strategy, do: :one_for_one
end
```

回调把「程序启动时该有哪些常驻进程」声明成数据：一个 BootLog 加两个 worker，
策略 one_for_one。VM 负责启动它、VM 关停时按反序优雅关停整棵树。本章手动调用
一次 `start/2` 验证树的内容（`Supervisor.count_children/1` 返回 active 计数等）：

```text
-- 7. Application.start/2 声明整棵树；children 按列表顺序启动 --
  应用树规模与策略 => %{active: 3, strategy: :one_for_one}
```

完整工程里回调模块在 `mix.exs` 的 `mod: {App.Application, []}` 登记；
第二个元素就是传给 `start/2` 的参数（本章为了多次实验传入唯一前缀，
避免注册名互相撞车）。

## 16.8 设计要点小结

```text
-- 监督树设计要点 --
  children 列表即启动顺序；依赖方排在被依赖方后面
  互不相关的叶子       -> one_for_one（最常用，重启面最小）
  强耦合、必须同生共死 -> one_for_all
  有明确依赖链         -> rest_for_one（崩点之前的不动）
  崩了不重启           -> restart: :temporary；只在异常时重启 -> :transient
  反复崩溃说明不是闪断 -> 阈值兜底，监督者自杀，交给上层监督者处置
  手动 start_link 用于测试/脚本；生产由 Application 回调在 VM 启动时拉起
```

还有一条贯穿性的事实要和第 14 章连起来：监督者重启的是**子规范**——用初始参数
重新跑一遍 `start_link/init`，**旧状态不带走**。所以真正不能丢的状态要放在
崩不到的地方（持久化、上层服务、状态在自己也被监督的独立进程里），
不能指望「重启后内存还在」。

## 16.9 坑位清单

1. **alias 不跨模块继承**。在 `Ex16Supervision` 里 `alias ...Worker` 不影响
   `Ex16Supervision.Application`；后者直接写裸 `Worker` 会报
   `The module Worker was given as a child ... but it does not exist`。每个模块
   各写各的 alias，或用全限定名。
2. **生成的 child_spec 只有 `:id`/`:start`**。`restart :permanent`、`type :worker`、
   `shutdown 5000` 是监督者启动时补的默认值，别在 spec map 上 `Map.fetch!(:restart)`；
   要观察行为差异就像 16.6 一样真的撞一次。
3. **三种 child 写法别混错参数层级**。`{Mod, arg}` 等价于调用
   `Mod.start_link(arg)`；map 写法的 `:start` 是完整 MFA
   `{Mod, :fun, [参数列表]}`——`start_link(kw)` 对应的是
   `start: {Mod, :start_link, [[kw]]}`，多一层方括号是本章真实修过的 bug。
4. **`:id` 不是注册名**。同一监督者下两个相同 id 会冲突，但那只是监督者的簿记键；
   要按名字访问进程仍需在启动参数里传 `name:`，且名字全局唯一（本章用
   `unique_integer` 造名，测试才能并发跑）。
5. **one_for_all 的重启顺序是 spec 顺序，不是崩溃顺序**；rest_for_one 只重启
   崩点及其之后——设计 children 列表时顺序就是依赖声明，不能随手排。
6. **重启超限时监督者自己以 `:shutdown` 死**，不会无限重启。顶层监督者自杀等于
   应用停机；要兜底就得有上一层监督者。默认阈值 3 次/5 秒，启动即死的死循环
   靠它截断。
7. **`:transient` 的「正常退出」只认 `:normal`/`:shutdown`**。`GenServer.stop/1`
   默认原因就是 `:normal`——transient 子进程被你 `stop` 掉不会回来；异常路径才会。
   想让 transient 重启，退出原因必须是异常（raise 或非正常 reason）。
8. **监督者只重启进程、不恢复内存状态**。重启 = 用初始参数重跑 init，计数器归零
   （第 14 章已实测）。状态持久化要自己设计。
9. **观测重启要用事件同步，别用固定 sleep**。本章用「启动事件收集器 + 阻塞 wait」
   与「轮询注册名 `wait_up`」两种方式；sleep 100ms 在忙机器上既可能不够又浪费
   时间，还是时序相关输出的来源。
10. **观察监督者自杀要 `trap_exit` + monitor 并隔离 runner**。监督者与启动方 link，
    直接在测试进程里等它死会被连坐带走（第 12、13 章同款手法）；崩溃报告带时间戳，
    所以本章 `run.exs`/`test_helper.exs` 照例 `Logger.configure(level: :none)`。

---

下一章离开进程世界，回到数据本身的深水区：[17 · 正则与二进制模式深入](17-regex-binaries.md)
——`~r` 捕获、命名分组，以及位串模式的 `size`/`unit`，手写一个二进制帧解析器。
