# 15 · GenServer

> 对应示例：`examples/15_genservers/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Agent 是「只有 get/set 词汇表的特殊服务器」。当服务要理解自定义消息
（`:checkout`、`:rotate`、`:bump`）、需要定时器、要在不同消息间安排流程时，
通用服务器 **GenServer** 登场。它是 OTP 最经典的行为（第 10 章讲过 behaviour
契约）：你 `use GenServer` 并实现几个回调，OTP 负责消息分发、监控接口与启动生命周期。

本章的载体是 `Ex15Genservers.KeyStore`——一个带「闲置自动清空」的键值存储。

## 15.1 两段式结构与 init

GenServer 模块永远分成两段，**执行在不同进程里**：

- **客户端 API**：普通函数，运行在**调用方**进程，只做参数整理和发消息；
- **服务端回调**：`init/1`、`handle_call/3`、`handle_cast/2`、`handle_info/2`，
  运行在**服务进程**，唯一能碰状态的地方。

```elixir
def start_link(opts \\ []) do
  name = Keyword.get(opts, :name)
  args = %{idle_ms: Keyword.get(opts, :idle_ms, :infinity),
           initial: Keyword.get(opts, :initial, %{})}
  if name,
    do: GenServer.start_link(__MODULE__, args, name: name),
    else: GenServer.start_link(__MODULE__, args)
end

@impl true
def init(%{idle_ms: idle_ms, initial: initial}) do
  {:ok, %__MODULE__{data: initial, idle_ms: idle_ms}}   # 返回值成为初始状态
end
```

`start_link` 的第二个参数原样传给 `init/1`；`init` 返回 `{:ok, 状态}`。
这就是为什么状态初始化逻辑（加载配置、打开文件）放在 init 而不是客户端函数里。

```text
-- 1. 客户端 API 只发消息；init/1 把启动参数变成初始状态 --
  initial 注入 seed=0，get => 0
```

## 15.2 call：同步请求—回复

`GenServer.call(server, msg)` 把消息送到服务进程并**阻塞等回复**，
对应 `handle_call(msg, from, state)`，必须返回
`{:reply, 答案, 新状态}`（可带第四项超时，见 15.4）：

```elixir
def handle_call({:get, key}, _from, state = %__MODULE__{}) do
  {:reply, Map.get(state.data, key), state, idle_after(state)}
end

def handle_call({:put, key, value}, _from, state = %__MODULE__{}) do
  state = %__MODULE__{state | data: Map.put(state.data, key, value), armed?: true}
  {:reply, :ok, state, state.idle_ms}
end
```

所有调用在服务进程里**串行**处理——没有锁，却天然原子。状态只活在回调参数里，
和第 12 章手写计数器是同一个递归 loop，只是消息分发由 OTP 代劳。

```text
-- 2. call：handle_call 必须 {:reply, 答案, 新状态} --
  put(:a, 1) => :ok
  get(:a)    => 1
  snapshot   => [a: 1, seed: 0]（map 一律排序）
```

## 15.3 cast 与 info：异步通知与普通消息

除了 call，服务进程还接两类消息：

| 入口 | 发送方式 | 回调 | 回调返回 |
|---|---|---|---|
| call | `GenServer.call/2,3` | `handle_call/3` | `{:reply, ...}` |
| cast | `GenServer.cast/2` | `handle_cast/2` | `{:noreply, ...}` |
| 普通消息 | `send/2`、监控 DOWN、定时器 | `handle_info/2` | `{:noreply, ...}` |

cast 火并忘：没有调用方在等，所以回调不能 reply。本章的 `bump/1` 故意展示
info 通道——它用最朴素的 `send(server, :bump)`，由 `handle_info(:bump, state)`
接住。**`handle_info/2` 必须有兜底子句**：不认识的普通消息（监控通知、
旁人发错的消息）如果没有子句匹配，会让整个服务进程崩掉：

```elixir
def handle_info(_unknown, state = %__MODULE__{}) do
  {:noreply, state, idle_after(state)}   # 未知消息忽略，不能崩
end
```

```text
-- 3. cast 火并忘；普通 send/2 走 handle_info --
  cast 写 :b=2 后 get => 2（同发送方有序）
  bump 三次 + 一条未知消息后 stats {bump, clears} => {3, 0}
```

## 15.4 init 与超时：空闲自动清空

`handle_*` 返回元组的**第四项**可以给一个毫秒数（或 `:infinity`/`:hibernate`）：
它武装一个「闲置计时器」——服务进程处理完这条消息后，**只要接下来该时长内
没有新消息**，就给自己发一条 `:timeout` 普通消息，再次活动会重置计时。
本章用它实现「闲置 40ms 清空数据」：

```elixir
def handle_info(:timeout, state = %__MODULE__{}) do
  {:noreply, %__MODULE__{state | data: %{}, clears: state.clears + 1, armed?: false},
   :infinity}                          # 清空后不再上膛，等下一次 put
end
```

注意两个设计细节：put 时才把 `armed?` 置真（空存储不计时），清空后置假并返回
`:infinity`，避免空状态反复触发让 `clears` 计数随时间漂移——**任何随墙钟
累积的计数都会破坏第 5 层逐字节比对**。实测生命周期：

```text
-- 4. 闲置 40ms 自动清空；每次活动重置计时器 --
  idle_clear_demo => {{1, {0, 0}}, {nil, {0, 1}}, {nil, {0, 2}}}
```

写入立即可读；睡过闲置时长后数据清空、`clears=1`；再次写入、再等，
计数变 2。测试里还验证了「每 20ms 活动一次就始终不清空」——活动会重置计时。
另一种常见定时手段是 `Process.send_after/3`（周期性给本进程发自定义消息），
适合固定节奏任务；第四项超时适合「闲置 N 毫秒才做」。

## 15.5 call 超时：杀调用方，不杀服务端

`GenServer.call(server, msg, timeout_ms)` 第三参是**调用方愿意等多久**
（默认 5000ms）。超时后：**调用方进程以 `{:timeout, {GenServer, :call, ...}}`
退出，但服务端照常存活**——它可能稍后才把回复算出来，只是接收者已死。
这与 Task.await 的连坐语义不同，本章实测：

```text
-- 5. GenServer.call 超时只杀调用方进程，服务端照常存活 --
  call_timeout_demo => {{:timeout, :call}, true, {:slept, 1}}
```

runner 对一个要睡 200ms 的慢调用只等 30ms，于是自己退出（`{:timeout, :call}`）；
主进程随后直接向同一服务发了个 1ms 的快调用，`{:slept, 1}` 证明它毫发无损。
推论：**回调慢 = 所有客户端排队**；超时不会取消服务端正在做的事，
只解除调用方的等待。

## 15.6 命名注册

和第 12 章的裸进程一样，`start_link` 传 `name: :atom` 即可注册：
此后调用不必再传递 pid，监督树下的服务几乎都用名字访问。

```text
-- 6. name: 注册：调用方拿名字即可，不必传递 pid --
  whereis 命中？ => true
  按名字 get(:who) => "named"
  stop 后 whereis => nil
```

## 15.7 模式与边界

```text
  客户端 API 做参数校验和发消息；状态逻辑只写在 handle_* 回调里
  call  需要回复/序列化写操作；cast 只管通知（丢了也无所谓的那种）
  普通 send/2 的消息一律在 handle_info 接，未知消息子句兜底防崩
  回调返回值第四项 -> 空闲超时；周期任务用 Process.send_after/3
  别在回调里做长 IO/重 CPU：服务进程一个，堵住所有客户端
  只需要 get/set 状态 -> 第 14 章 Agent；要自定义消息词汇表才用 GenServer
```

一个类型检查器细节（本章编译时实际遇到）：回调里对状态做 struct 更新
（`%__MODULE__{state | ...}`）时，1.20 检查器要求子句头显式标注
`state = %__MODULE__{}`，否则认为 state 类型未知；另外模块顶部不能漏
`use GenServer`——没有它，`@impl true` 会报「no behaviour was declared」。

## 15.8 坑位清单

1. **客户端 API 和服务端回调跑在两个进程**。在客户端函数里改不了状态，
   在回调里 `IO.puts` 调试时也要意识到那是服务进程的输出。
2. **handle_call 必须 reply、handle_cast/info 必须 noreply**，返回元组写错
   （比如 cast 里回 `{:reply, ...}`）会导致进程异常退出。
3. **`handle_info/2` 必须有 `_unknown` 兜底**。监控通知、定时消息、外人误发
   都会进这里；没有兜底子句，一条意外消息就能杀死服务。
4. **回调返回值第四项是「闲置」超时，不是处理时限**：每次新消息都重置计时；
   要周期性执行用 `Process.send_after/3`，别用它当 cron。
5. **call 超时只杀调用方，取消不了服务端的活儿**；慢回复之后还会到达，
   接收者可能已不存在。回调必须快，慢活拆到 Task（第 13 章）。
6. **别在回调里无限等待另一个 call**（A 的回调 call B，B 的回调又 call A），
   会形成死锁式排队；需要跨服务握手时重新设计消息流。
7. **状态只活在回调参数里**：init 给初值，每个回调返回新状态；忘了在返回值
   里带更新后的状态，修改就「丢了」。
8. **cast 不保证执行、不返回结果**：重要写操作需要确认时用 call；
   cast 之后立刻 call（同一发送方）是可见的，但跨进程没有这个保证。
9. **struct 状态的回调头写 `state = %__MODULE__{}`**，否则 1.20 类型检查器
   无法确认 `%__MODULE__{state | ...}` 合法；模块里别忘了 `use GenServer`。
10. **map 状态对外输出要排序**（老规矩）；任何依赖墙钟/调度时序的输出
    （时间戳、超时触发次数）都要改造成确定性的形态才能过第 5 层。

---

下一章让服务「崩了能自己活过来」：[16 · Supervisor 与 Application](16-supervisor.md)
——监督策略、child_spec、重启阈值、应用回调与启动顺序，把前面三章的进程
组装成一棵会自愈的监督树。
