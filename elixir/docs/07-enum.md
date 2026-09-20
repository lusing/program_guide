# 07 · Enum 与管道

> 对应示例：`examples/07_enum/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

`Enum` 是日常写 Elixir 用得最多的模块，没有之一。本章不做 API 手册（`h Enum` 比手册全），
而是建立四条能迁移到一切代码的认识：

1. **`reduce/3` 是万物之源**——map/filter/take 都是它的特例；
2. **`|>` 管道在编译期就消失了**——它就是嵌套函数调用，零运行时开销；
3. **Enum 立即求值、Stream 惰性求值**——区别用「函数被求值几次」衡量，不用墙钟时间；
4. **排序稳定性、map 遍历顺序这些「不写在类型签名里的承诺」必须实测**。

## 7.1 谁是 Enumerable

Enum 函数的第一个参数类型不是 `list()`，而是 `Enumerable.t()`——任何实现了 Enumerable
协议（第 10 章）的数据结构都能喂给 Enum：

```text
[1, 2]                        => "Enumerable.List"
%{a: 1}                       => "Enumerable.Map"
1..3                          => "Enumerable.Range"
MapSet.new([1])               => "Enumerable.MapSet"
~c"ab"（charlist 就是列表）    => "Enumerable.List"
2-arity 函数（无限流）         => "Enumerable.Function"
{1, 2}（元组）                 => nil
"abc"（二进制）                => nil
42                            => nil
```

注意**元组和二进制不是 Enumerable**。元组是定长索引结构，遍历它没有自然语义；二进制的
最小单位有歧义（字节？码点？字素？——第 08 章的主题），所以字符串要遍历得显式
`String.graphemes/1` 或 `String.codepoints/1`，要按字节走用二进制推导式（7.10）。

## 7.2 reduce 是万物之源

第 05 章用递归手写过 map/filter；它们的真正出处是同一个函数 `Enum.reduce/3`：

```elixir
def my_map(enum, fun) do
  enum
  |> Enum.reduce([], fn x, acc -> [fun.(x) | acc] end)
  |> Enum.reverse()
end
```

惯例是「**前插累加 + 收尾反转**」：cons 前插是 O(1)、尾插是 O(n)，所以永远前插，最后
一次 `Enum.reverse/1`（同样 O(n)，常数极小）。`my_filter` 只多一个条件，`my_take` 则需要
`reduce_while/3`——回调返回 `{:halt, acc}` 提前收工：

```elixir
def my_take(enum, n) when n >= 0 do
  {taken, _remaining} =
    Enum.reduce_while(enum, {[], n}, fn
      _x, {acc, 0} -> {:halt, {acc, 0}}
      x, {acc, k} -> {:cont, {[x | acc], k - 1}}
    end)

  Enum.reverse(taken)
end
```

```text
my_take([1,2,3,4,5], 2)              => [1, 2]
my_take(Stream.repeatedly(-> 7), 3)  => [7, 7, 7]   # 无限流也能拿了就走
```

`reduce_while` 是「拿够就走」类操作的唯一正解：对无限流用普通 `reduce` 永远停不下来。
示例的 `equivalence_check/0` 对空列表、单元素、Range、map 等 5 组输入，断言 3 个手写函数与
标准库逐一等价（map 输入排序后再比，原因见 7.11）。

## 7.3 立即求值 vs 惰性求值：数求值次数

「Stream 更快」是含糊的说法。准确的差别是**求值次数**。对 `1..n` 做「map 之后 take 3」，
用 Agent 计数映射函数真正被调用了多少次：

```text
1..100 |> Stream.map(翻倍) |> Enum.take(3) => [2, 4, 6]，求值 3 次
1..100 |> Enum.map(翻倍)   |> Enum.take(3) => [2, 4, 6]，求值 100 次
```

`Enum.map` 老老实实把 100 个元素全算完、生成含 100 个元素的中间列表，再丢弃 97 个；
`Stream.map` 只登记一个「菜谱」，直到 `Enum.take(3)` 来拉取时才做了 3 次翻倍。

- **惰性 ≠ 总是更优**：列表小、要多次使用结果时，Stream 的惰性反而是开销；
- 源很大/无限、且只消费前缀时，Stream 才是正确选择（第 18 章系统讲）。

衡量时也别用墙钟时间（机器负载会变），用「求值次数」这种可复现的计数——这也是本教程
所有示例的通用纪律。

## 7.4 变换、聚合、切片：常用函数速览

驱动脚本第 4–8 节把常用 API 按用途分了五组，下面列出实测输出，不必背，用时 `h Enum.xxx`。

**变换**：

```text
map(1..4, 平方)                 => [1, 4, 9, 16]
flat_map(1..3, &[&1, &1*10])    => [1, 10, 2, 20, 3, 30]
filter / reject(rem 3 == 0)     => [3, 6, 9] / [1, 2, 4, 5, 7, 8, 10]
uniq([1,1,2,1,3])               => [1, 2, 3]
dedup([1,1,2,1,3])              => [1, 2, 1, 3]   # 只压缩相邻重复！
sort_by(words, 字符串长度)       => ["go", "elixir", "cplusplus"]
```

`uniq` 全局去重，`dedup` 只压缩**相邻**重复（流处理里常见的需求：18 章）。`shuffle/random`
结果不确定，示例只断言性质：洗牌结果排序后等于原序列（必为排列）、随机结果必为成员。

**聚合**：

```text
sum / product / count           => 55 / 120 / 5（偶数个数）
min/max、min_by/max_by          => 1 / 3；"go" / "cplusplus"
frequencies（排序后）            => [{"apple", 3}, {"banana", 1}, {"fig", 2}]
reduce_while(累加超过 50 就停)   => 45（1+2+…+9，加 10 就超了）
```

**分组与切片**：

```text
chunk_every(1..5, 2)            => [[1, 2], [3, 4], [5]]
chunk_every(…, 2, 2, [nil])     => [[1, 2], [3, 4], [5, nil]]   # 末块补余
chunk_by(按长度)                 => [["a"], ["bb"], ["c"], ["dd"]]
chunk_while(切成递增段)          => [[1, 2, 3], [1, 2]]
group_by(rem 3)                 => [{0, [3,6,9]}, {1, [1,4,7,10]}, {2, [2,5,8]}]
scan([1,2,3,4], &+/2)           => [1, 3, 6, 10]   # 前缀和
slide([1,2,3,4,5], 0..1, 3)     => [3, 4, 1, 2, 5] # 把 0..1 位置移到位置 3
take_while / drop_while(&1 < 5) => [1,2,3,4] / [5,6,7,8,9,10]
```

`zip/2`、`with_index/1`、`join/2`、`intersperse/2`、`split/2`、`concat/2`、`into/3` 见驱动
输出。**判定类**短路：`any?` 遇真即停、`all?` 遇假即停、`find/2` 找不到返回 nil。

**副作用**：`Enum.each/2` 为副作用而生，返回值固定是 `:ok`；管道里想瞥一眼中间值用
`Kernel.tap/2`（放行原值），想顺手变换用 `then/2`：

```text
tap 看到中间值 3，但放行原值
3 |> tap(IO 副作用) |> then(&(&1 * 100)) => 300
```

## 7.5 管道的本质：它在编译期就不存在了

`|>` 不是什么异步/数据流机制，而是一条最简单的宏重写规则：

```text
a |> b() |> c(1)            # 写法
c(b(a), 1)                  # 编译期展开后的同一棵 AST
```

示例用 `quote` + `Macro.expand/2` + `Macro.to_string/1` 把展开前后都打印了出来（23 章讲宏
时会再次用到这套工具）。真实管道同理：

```elixir
file |> File.read!() |> String.split("\n") |> Enum.map(&String.trim/1)
# 展开 =>
Enum.map(String.split(File.read!(file), "\n"), &String.trim/1)
```

管道的价值纯粹是**可读性**：数据从左往右流，与嵌套调用「从内往外读」相反。两条纪律：

1. 管道是**单向**的，别在管道里塞分支（需要就抽函数）；
2. 管道开头别是函数调用（`f() |> g()` 会被解析成 `f(g())` 之外的歧义形状），习惯上以值或
   括号开头。

`then/2` 用于在管道里插入匿名函数，`tap/2` 用于副作用调试。

## 7.6 for 推导式

`for` 不是循环，是 `flat_map + filter` 的语法糖，但表达力很强：

```elixir
for suit <- [:spade, :heart], rank <- [1, 2], do: {suit, rank}
# 多生成器 = 笛卡尔积，左慢右快：
# => [spade: 1, spade: 2, heart: 1, heart: 2]

for x <- 1..10, rem(x, 3) == 0, do: x        # 过滤子句 => [3, 6, 9]
for x <- [1, 1, 2, 2, 3], uniq: true, do: x  # => [1, 2, 3]
for {k, v} <- pairs, into: %{}, do: {k, v}   # 收集进任意 Collectable
for x <- list, reduce: 0, do: (acc -> acc + x)  # 直接归约，不产生中间列表
```

`into:` 接受任何 Collectable（map、IO 设备、二进制……）。还有**二进制推导式**，生成器
写成 `<<pattern <- binary>>`，按 4-bit 半字节切 `0xDEADBEEF`：

```text
for <<nibble::4 <- <<0xDE,0xAD,0xBE,0xEF>>>>, do: nibble
=> [13, 14, 10, 13, 11, 14, 14, 15]
```

手写时注意一个 tokenizer 坑：内层二进制的 `>>` 与生成器的 `>>` 连着写成 `>>>>` 会断错词，
要留空格或加括号（`mix format` 会改写成 `<<(pattern <- <<...>>)>>`）。

## 7.7 排序稳定性：比较器该用 `<` 还是 `<=`

这条反直觉，值得实测。对 `[{1,:a},{0,:b},{1,:c},{0,:d}]` 按首元素排序：

```text
fn a,b -> key(a) <= key(b) end  => [{0,:b},{0,:d},{1,:a},{1,:c}]  # 稳定
fn a,b -> key(a) <  key(b) end  => [{0,:d},{0,:b},{1,:c},{1,:a}]  # 相等元素被翻面！
```

归并排序合并两半时，**比较器返回 true 才取左边**（保序）；严格 `<` 在两元素相等时返回
false，于是取了右边，相等元素的相对次序被对调。想保留「相等元素按原顺序」就写非严格
`<=`/`>=`（降序同理）。

更省心的做法是**根本不写二元比较器**：

- 按某个键排：`Enum.sort_by/2`；
- 模块自带 `compare/2`（返回 `:lt/:eq/:gt`，如 `Date`）：直接传模块名，方向用
  `{:asc, Date}` / `{:desc, Date}`：

```text
sort(dates, Date)          => [~D[2024-01-01], ~D[2024-03-15], ~D[2024-12-31]]
sort(dates, {:desc, Date})=> [~D[2024-12-31], ~D[2024-03-15], ~D[2024-01-01]]
```

不带比较器的默认排序走 03 章的 term 全序：
`Enum.sort([:b, "a", 1, [1], {1}, %{z: 1}]) => [1, :b, {1}, %{z: 1}, [1], "a"]`。

## 7.8 多次遍历 vs 单次遍历

```elixir
enum |> Enum.map(&(&1 * 2)) |> Enum.filter(&(rem(&1, 3) == 0)) |> Enum.sum()  # 3 趟 + 2 个中间列表
Enum.reduce(enum, 0, fn x, acc -> ... end)                                     # 1 趟、零中间列表
```

两者结果相同（示例对 1..1000 断言）。绝大多数业务数据量下写三段管道更清晰，不必优化；
但热路径上要知道「一串 Enum 管道 = 多趟遍历 + 每步一个中间列表」，可以合成一个 reduce，
或者用 `Stream` 把多趟融合成一趟惰性管线（18 章），或者用 for 的 `reduce:`。

## 7.9 坑位清单

1. **元组和字符串不能直接 Enum 遍历**：字符串先 `String.graphemes/1`/`codepoints/1`；
   元组用 `Tuple.to_list/1` 或直接模式匹配。

2. **`dedup` 只压相邻重复，`uniq` 才全局去重**：`[1,1,2,1] |> dedup => [1,2,1]`。

3. **自定义比较器想稳定就用 `<=`/`>=`**：严格 `</>` 会在相等元素上翻转相对顺序。能不写
   比较器就不写——`sort_by` 或传实现了 `compare/2` 的模块。

4. **map 的遍历顺序不属于语言承诺**：`frequencies/1`、`group_by/2`、`map` 自身的迭代结果
   要打印/断言，先 `Enum.sort/1`。同一 map 同次运行内多遍遍历顺序一致（所以能做等价性
   断言），但跨版本/运行不保证。

5. **不确定函数只断言性质**：`shuffle/1`、`random/1` 不打印具体结果，断言「是排列」「是
   成员」这类可复现性质（本教程第 5 层验证的纪律核心）。

6. **`Enum.each/2` 返回 `:ok`**：要结果用 `map`，要变换带副作用用 `tap`，each 只用于纯
   副作用（写文件、发消息）。

7. **二进制推导式小心 `>>>>` 断词**：写成 `<<(x::4 <- <<...>>)>>` 或交给 `mix format`。

8. **惰性不是银弹**：Stream 省的是求值次数和中间列表；数据小、结果要复用，Enum 更直接。
   无限流、大源取前缀才是 Stream 的主场（18 章）。

9. **管道零开销但别滥用**：`|>` 在编译期展开为嵌套调用；管道里不要塞分支，开头放值。

---

下一章：[08 · 字符串与 Unicode](08-strings-unicode.md)
