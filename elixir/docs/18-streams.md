# 18 · Stream 惰性流

> 对应示例：`examples/18_streams/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

`Enum.map/2` 的问题是：每一步都立刻遍历、立刻产出一个完整的新列表。
三步管道要建三趟中间列表，而且第一步就会把**整个**源头拉完——哪怕你只想要前三个结果。
**Stream** 把这件事倒过来：`map`、`filter` 这些操作只登记「将来怎么变换」，
什么都不算；直到 `Enum.to_list/1`、`Enum.take/2`、`Enum.find/2`、`Stream.run/1`
这样的**终点操作**开口要值，数据才从源头一个一个地拉，经过整条管道，
能停就停。这一章的核心就是四件事：惰性组合、无限源、资源生命周期、分块。

## 18.1 组合不执行，终点才拉取

```elixir
def build_untouched do
  Stream.map(Stream.repeatedly(fn -> raise "不应被执行" end), &Function.identity/1)
  :stream_built            # 流构造完就被丢弃，源函数一次都没被调用
end
```

流里挂着「一被拉取就 raise」的源，但构造它不报错——证明 `Stream.map` 只是把函数
登记到配方里。真正的计算发生在终点。再看一个有用的例子：在**无限**平方流上 find，
找到就停，map 实际只执行到 11²=121，后面无穷多个数根本不会被算出来：

```elixir
Stream.iterate(1, &(&1 + 1))
|> Stream.map(&(&1 * &1))
|> Enum.find(&(&1 > 100))
# => 121
```

```text
-- 1. Stream 操作只是配方；Enum.find 在无限流上找到即停 --
  构造不求值 => :stream_built
  第一个平方>100 => 121（源只拉到 11）
```

## 18.2 map/filter/take 融合：没有中间列表

`Stream.map/filter/take` 两两组合时不会产生任何中间列表——每个元素被拉出来后
**一口气穿过全部步骤**，源头只在需要下一个结果时才被多拉一次。从 1..100 翻倍、
筛 3 的倍数、取前 3 个，源头只需供到 18：

```text
-- 2. 惰性管道：翻倍→筛 3 的倍数→取 3 个，不产生中间列表 --
  结果 => [6, 12, 18]
```

「恒定内存」的含义就在这：管道占的内存与**当前产出多少**无关（只与你显式缓冲的
东西，比如 chunk 大小有关），源有百万条还是无限条都一样。

## 18.3 Stream.iterate/2：初值 + 下一步

四个无限源的第一个。`iterate(start, next_fun)` 从初值开始，每个值由上一个值
推出，没有尽头——所以**必须**用 take 之类的短路终点收口：

```elixir
Stream.iterate(1, &(&1 * 2)) |> Enum.take(6)
# => [1, 2, 4, 8, 16, 32]
```

```text
-- 3. iterate(初值, 下一步)：无限等比，take 截断 --
  2 的幂前 6 个 => [1, 2, 4, 8, 16, 32]
```

## 18.4 Stream.cycle/1：把有限列表轮转成无限

`cycle/1` 反复输出一个有限枚举，跨轮次边界无缝继续：

```text
-- 4. cycle：有限列表无限轮转，跨边界继续 --
  [1,2,3] 取 7 => [1, 2, 3, 1, 2, 3, 1]
```

空枚举无法定义「下一轮」，`Stream.cycle([])` 在被求值时抛 `ArgumentError`。

## 18.5 Stream.unfold/2：携带状态的生成器

`unfold(initial, fn state -> {emit, next_state} end)` 最通用：状态由你自己定义，
每轮吐出一个值并给出下一份状态；想结束时返回 `nil`（那样它就是有限流）。
用相邻两项做状态写斐波那契：

```elixir
Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
|> Enum.take(10)
# => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

```text
-- 5. unfold：{吐出值, 下一状态}，相邻两项生成斐波那契 --
  fib(10) => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

## 18.6 Stream.resource/3：开 / 用 / 关 三段式

无限源里最重要的一个：源背后有需要**打开和释放**的东西（文件、套接字、连接，
第 19 章的 `File.stream!/1` 底层就是它）。三个回调各司其职：

```elixir
Stream.resource(
  fn -> send(parent, :opened); [[1, 2], [3]] end,   # start：打开，给初始状态
  fn
    [] -> {:halt, []}                               # next：吐一批 {值列表, 新状态}
    [batch | rest] -> {Enum.map(batch, &(&1 * 10)), rest}
  end,
  fn _ -> send(parent, :closed); [] end             # after：清理
)
|> Enum.to_list()
```

`next` 每次可以吐**一批**值（拉平进流），用 `{:halt, state}` 表示用完。
实测有两个生命周期细节：

1. **after 回调一定会被调用**——哪怕消费者提前 `take(1)` 不再拉了（测试里验证）；
2. **after 的返回值被丢弃**——它只负责释放资源，不能靠它往流末尾补元素。

副作用的顺序在同一进程内是确定的，本章用消息收集标签：

```text
-- 6. resource 三段式（打开/批量产出/清理）；run 只为跑完副作用 --
  {值, 生命周期} => {[10, 20, 30], [:opened, :closed]}
  each+run 的副作用顺序 => [tick: 1, tick: 2, tick: 3]
```

`Stream.each/2` 原值照穿、只挂副作用；不关心产出时用 `Stream.run/1` 把整段跑完
（返回 `:ok`）。注意 start 回调是在**第一次拉取**时才执行，不是构造时。

## 18.7 chunk 家族：把流切成一组组

| 函数 | 切组依据 |
|---|---|
| `Stream.chunk_every(enum, n)` | 固定 n 个一组（末尾不足保留为短组） |
| `Stream.chunk_by(enum, key_fun)` | key 函数结果**变化**的边界 |
| `Stream.chunk_while(enum, acc, reducer, after)` | 带累加器，自己决定何时成组 |

`chunk_by` 只看相邻：`[1,3,2,4,5]` 按奇偶切成 `[[1,3],[2,4],[5]]`；
同 key 不相邻不会合并（`[1,2,1]` 是三组）。`chunk_while` 最强，能实现「累计和
达到阈值才吐出」：`1..6` 按 5 成组得到 `[[1,2,3],[4,5],[6]]`，最后残余由
收尾回调吐出。它正是第 17 章「残帧攒够再解析」的天然工具——字节流进来，
凑成完整帧才吐出一组。

```text
-- 7. chunk_every 定长 / chunk_by 边界 / chunk_while 累加；无限流取前几个 --
  pairs(5) => [[1, 2], [3, 4], [5]]
  奇偶游程 => [[1, 3], [2, 4], [5]]
  和达到 5 成组 => [[1, 2, 3], [4, 5], [6]]
  无限奇数前 5 个 => [1, 3, 5, 7, 9]
```

## 18.8 要点小结

```text
  Stream 是「拉取配方」：组合不执行，Enum.to_list/take/find/run 才求值
  无限源（iterate/cycle/unfold/resource）必须配 take/find/take_while 等短路终点
  map/filter 融合：源头按需拉取，不构建中间列表，内存与产出无关
  unfold 吐 {值, 下一状态}；resource 管 {打开, 批量产出, 清理}
  resource/transform 的 after 回调只做释放：会被调用但返回值被丢弃
  chunk_while 是跨元素的有状态缓冲：解析流式记录、按条件成组用它
```

选型一句话：**源很大、很慢、在 IO 上，或你只需要前缀 → Stream；数据小、
要反复多次使用同一结果 → Enum**（Stream 每遇到一个终点就从头重算一遍）。

## 18.9 坑位清单

1. **Stream 不是集合**。`inspect` 一个流看到的是含函数的 `%Stream{}` 结构；
   不接终点操作，里面的函数永远不执行——别拿流当列表传进只接受列表的函数。
2. **无限流必须有短路终点**。`Enum.to_list(Stream.iterate(1, &(&1 + 1)))` 永不返回；
   安全终点是 `take/2`、`take_while/2`、`find/2`、`reduce_while/3`。
3. **惰性链里混入 Enum 操作会提前枚举**。在 Stream 管道中间写 `Enum.map/2`，
   那一步立刻把上游全部拉完、惰性从断点失效；全链保持 `Stream.*` 直到最后一个终点。
4. **`Stream.cycle([])` 是运行时错误**（`ArgumentError`）。另外类型检查器看到
   字面空列表会静态告警「恒失败」，测试这类分支要经 `term()` 参数包装隔离。
5. **resource 的返回形状不能写错**：next 必须是 `{值列表, 状态}` 或
   `{:halt, 状态}`——吐单个元素而不是列表会在运行时炸；after 必须返回空列表
   （它的产出会被丢弃）。
6. **after 回调只做清理**。它在正常吃完和消费者提前停止时都会被调用，
   但**返回值被丢弃**；想在流末尾补一个收尾元素，用 `chunk_while` 的收尾回调或
   `Stream.concat/2` 显式拼。
7. **资源打开是惰性的**：start_fun 在第一次拉取时才跑。构造完流不代表文件/连接
   已打开；同一个流被两个终点枚举，start 会执行两遍。
8. **`chunk_every` 末尾默认保留短组**（`1..5` 每 2 个 → 末组 `[5]`）；
   要严格等长用 `chunk_every(enum, n, n, :discard)`。
9. **`chunk_by` 不是 group_by**：只在相邻 key 变化处切，同 key 断开后再出现
   会分成两组；要全局分组先排序或用 `Enum.group_by/2`（那是急切的）。
10. **小数据别用 Stream**：没有大中间列表可省，却为每个元素付出函数调用开销，
    且每个终点都从头重算；一次算出、反复使用的场景 Enum 更快更直观。

---

下一章让惰性流接上真实世界的数据源：[19 · 文件与 IO](19-files.md)
——`File.stream!` 按行/定长流式读写、`Path`、iodata 免拼接、`:file` 与临时文件，
用恒定内存处理装不进内存的大文件。
