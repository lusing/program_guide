# 14 · Agent 状态

> 对应示例：`examples/14_agents/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

第 12 章我们手写了一个计数器：一个进程用递归参数持有状态，外部只能发消息，
读值要「发问询消息 → receive 等回复」。如果整个系统里每处共享状态都要手写
这套 loop，代码会被消息格式淹没。**Agent 就是这套模式的封装**：
一个状态、一个进程、四个操作。

| 操作 | 语义 | 是否等 Agent 确认 |
|---|---|---|
| `Agent.start_link(fun)` | `fun.()` 的返回值作为初始状态 | 返回 `{:ok, pid}` |
| `Agent.get(agent, fun)` | `fun.(状态)` 的返回值回传给调用方 | 同步 |
| `Agent.update(agent, fun)` | `fun.(状态)` 的返回值成为**新状态** | 同步（回 `:ok`） |
| `Agent.cast(agent, fun)` | 同 update，但发完即走 | **异步** |
| `Agent.get_and_update(agent, fun)` | 回调返回 `{给调用方的值, 新状态}` | 同步，一次往返 |

本质上 Agent 就是一个只懂「取/换状态」的 GenServer（下一章的主角），
所有回调都在 **Agent 自己的进程**里串行执行。

## 14.1 start_link / get / update / cast

计数器的完整 API 只有薄薄一层：

```elixir
def start_link(initial \\ 0), do: Agent.start_link(fn -> initial end)

def increment(agent, by \\ 1) do
  Agent.update(agent, fn n -> n + by end)
end

def current(agent), do: Agent.get(agent, fn n -> n end)
```

注意回调的两种角色：**get 回调的返回值是「答案」，update 回调的返回值是
「新状态」**——别写反（update 里返回旧状态等于什么都没改）。

`cast` 是异步的：调用立即返回 `:ok`，不保证回调已经执行。但它不是「消息会丢」：
BEAM 保证**同一发送方到同一进程的消息有序**，所以 cast 之后紧接一个同步 get，
get 一定排在那条 cast 后面处理，必然看得到修改：

```text
-- 1. update 同步写、get 同步读；cast 异步写但同发送方消息有序 --
  初始值        => 5
  +1、+10 后    => 16
  cast +100 后  => 116（get 一定看得到前一条 cast）
  stop 后进程消失（监督树下不要手动 stop）
```

## 14.2 get_and_update：一次往返的原子读改写

「读出当前值、加上 n、返回新值」如果用 get + update 两条消息实现，两个并发
客户端可能各自 get 到同一个旧值（读改写之间有窗口）。`get_and_update` 把三步
压缩成 Agent 进程里的**一次**回调，中间不可能插入别的请求：

```elixir
Agent.get_and_update(agent, fn n ->
  {n + by, n + by}   # {回传给调用方的答案, 新状态}
end)
```

```text
-- 2. get_and_update：读-改-写在 Agent 进程一次执行，天然原子 --
  add_and_get(8) => 18（返回值与新状态一致）
  当前值        => 18
```

## 14.3 结构化状态与「是否真需要 Agent」

状态可以是任意 Elixir 数据。本章的注册表 Agent 持有一个 map，put/get 都是
一条 update/get；输出沿用第 9 章的纪律——**map 迭代顺序跨调度器不稳定，
对外一律 `Map.to_list() |> Enum.sort()`**：

```text
-- 3. map 状态跨请求累积；map 输出一律排序 --
  乱序写入 z/a/m，排序读出 => [a: 2, m: 3, z: 1]
  reg_get(:x, :缺省)       => :缺省
  纯函数词频 word_count   => [{"a", 3}, {"b", 2}, {"c", 1}]
```

第三节里故意放了一个**对照组**：词频统计用纯函数 + `Enum.reduce/3` 就能写，
状态只随数据在管道里流动，根本不需要 Agent：

```elixir
def word_count(acc, words) do
  Enum.reduce(words, acc, fn w, a -> Map.update(a, w, 1, &(&1 + 1)) end)
end
```

这是使用 Agent 前最重要的一问：**状态需要被多个进程共享、或寿命跨越一次请求吗？**
单一进程内部的累积用变量和递归参数即可——Agent 是进程，带来消息往返与
序列化开销，不是「可变变量的替代品」。

## 14.4 崩溃语义：回调崩 = Agent 崩；重启 = 状态归零

回调运行在 Agent 进程里，所以回调里 raise 不是「调用失败」，而是**Agent 进程
死亡**。由此有三条实测结论：

1. **Agent 与启动者 link**：在测试进程里直接起的 Agent 崩溃，会连坐杀死测试
   进程（本章对应测试需要先 `Process.flag(:trap_exit, true)`，与第 12 章同理）；
2. **Agent 已死后再 get**：调用方收到 `{:noproc, ...}` 退出信号——本章的
   `dead_agent_reason/0` 在独立 runner 进程里发起调用、主进程 monitor，
   规范化死因为 `{:exit, :noproc}`；
3. **监督重启不恢复状态**：在 `restart: :permanent` 的监督者下，Agent 崩后
   会以**同一个注册名**被重拉，但状态是初始函数**重新执行一遍**的结果。

```text
-- 4. 回调在 Agent 进程执行，回调崩 = Agent 崩 --
  监督重启 {崩前值, 重启后值} => {1, 0}
  Agent 已死后 get 的死因    => {:exit, :noproc}
```

`{1, 0}` 就是证据：崩溃前自增到 1，监督者拉起的新 Agent 从初始函数 `fn -> 0 end`
重新开始，旧状态丢失。要让重启不丢状态，必须在初始化回调里自己从外部存储
加载（或把状态放在能恢复的地方）——Agent 不替你做持久化。实现时还有一个
时序细节：cast 触发崩溃到监督者完成重启之间有空窗，这期间按名字 get 会让
调用方 exit，所以等待重启的轮询用 `catch :exit, _ -> nil` 兜住。

## 14.5 选型边界

```text
  单一进程内的状态传递      -> 变量/递归参数/Map.update，不要上 Agent
  多进程共享、需要串行化    -> Agent（消息队列把并发读写排成串行）
  需要原子读改写           -> get_and_update，别用 get 后再 update（中间有窗口）
  回调里做重活/睡眠/IO     -> 不要：所有其他客户端都被这一个回调堵住
  需要崩溃不丢状态         -> 监督重启会归零，init 回调里自己加载/持久化
  消息不止 :get/:set       -> Agent 到头了，用第 15 章的 GenServer
```

Agent 的天花板要认清：它的消息词汇表是固定的（get/update/cast/get_and_update）。
当你需要自定义消息（`:add`、`:checkout`、`:expire`）、需要定时器、需要在不同
消息之间安排流程时，就该直接写 GenServer——Agent 不过是它的一个特化特例。

## 14.6 坑位清单

1. **get 回调的返回值是答案，update/cast 回调的返回值是新状态**。写反会出现
   「update 之后状态纹丝不动」或「get 回传了整个状态而不是要的字段」。
2. **不要在回调里做重活、睡眠或阻塞 IO**。所有客户端共享 Agent 的一个进程，
   一个慢回调会堵住所有人；重活在调用方进程（或 Task）做完，把结果送进来。
3. **get 之后再 update 不是原子操作**。需要读改写用 `get_and_update`，
   并发下两条消息之间一定有窗口。
4. **`cast` 立即返回不代表已执行**，只代表消息已入队；依赖「cast 已生效」
   做后续判断时，用一条同步调用建立先后（同发送方消息有序保证可见性）。
5. **不要把 Agent 当可变变量用**。单进程内的累积用纯函数 reduce；
   Agent 是跨进程共享/长寿状态的工具，每次调用都是消息往返。
6. **回调崩 = Agent 进程崩**，而且 Agent 与启动者 link：在测试/脚本里直接
   `start_link` 又故意制造崩溃时，记得 trap_exit 或放进监督树。
7. **监督重启状态归零**：重启执行的是初始函数，不恢复内存状态；
   需要可恢复状态要在初始化时自行加载。
8. **Agent 死后调用得到 `:noproc` 退出信号**（不是 `{:error, _}` 返回值）；
   轮询重启空窗要用 `catch :exit` 或独立进程 + monitor。
9. **map 状态对外输出要排序**（第 9 章的老规矩）：Agent 不改变 map 迭代顺序
   跨调度器不稳定的事实。
10. **词汇表超出 get/set 就别用 Agent**：自定义消息、定时器、多阶段流程
    直接上 GenServer（第 15 章），不要在 Agent 回调里塞编码过的特殊消息。

---

下一章：[15 · GenServer](15-genserver.md)——Agent 的通用版：客户端 API +
服务端回调两段式结构，call/cast/info 三类消息，init 与超时，看看 OTP
最经典的「通用服务器」模式。
