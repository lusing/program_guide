# 05 · 函数与递归

> 对应示例：`examples/05_functions/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Elixir 没有 `for`/`while` 式的命令式循环，也没有可变状态。本章讲清它拿什么替代：

1. **多子句函数 + 守卫**——按参数的形状和条件做分派，替代大部分 `if/switch`；
2. **递归 + 累加器**——遍历一切数据结构的基本手段；
3. **尾调用优化（TCO）**——让递归在 BEAM 上深度百万也不增长栈。

另外讲透函数的几个语法点：默认参数与「函数头」、匿名函数的 `.()` 调用、`&` 捕获操作符。

## 5.1 多子句分派与守卫

同一个函数名可以定义多个子句，调用时**从上到下**尝试，第一个模式对得上、且守卫为真的
子句生效：

```elixir
def sign(n) when is_number(n) and n > 0, do: :positive
def sign(0), do: :zero
def sign(n) when is_number(n), do: :negative
def sign(_other), do: :not_a_number
```

```text
sign(5)      => :positive
sign(0)      => :zero
sign(-3.14)  => :negative
sign("x")    => :not_a_number
```

两条书写纪律：**更具体的子句写在前面**（`sign(0)` 在「任意数字」子句之前），万能兜底
（`_other`）放最后。

### 守卫（guard）

`when` 后面能放的不是任意表达式，而是一份**白名单**：类型判定（`is_integer/1` 等）、
比较运算、算术、`and/or/not`、`in`、少量安全函数（`hd/1`、`length/1`、`elem/2`、
`rem/2`、`abs/1`、`map_size/1`……）。自定义函数不能进守卫。

```elixir
def http_label(code) when code in 200..299, do: :success
def http_label(code) when code in 300..399, do: :redirect
# ... 4xx / 5xx ...
def http_label(_other), do: :unknown
```

### 守卫是「安全」的：出错只让子句落选

这是与普通代码最大的区别。普通代码里 `hd([])` 会抛 `ArgumentError`；**在守卫里它不抛**，
该子句直接判定为不匹配，继续尝试下一个子句：

```elixir
def first_is_ok?(list) when hd(list) == :ok, do: true
def first_is_ok?(_other), do: false
```

```text
first_is_ok?([:ok, 1]) => true
first_is_ok?([:no])    => false
first_is_ok?([])       => false   # hd([]) 在守卫里失败 → 落到兜底，没有异常
```

所以守卫既能「加条件」，也能充当「试一下，不行就算了」的探测，不需要 try。

## 5.2 默认参数与函数头

参数默认值用 `\\` 给。当函数有多个子句、又带默认值时，Elixir 要求把默认值集中写在一个
**没有函数体的函数头**里：

```elixir
def join(a, b, sep \\ ", ")                                    # 函数头：只声明默认值
def join(a, b, sep) when is_binary(a) and is_binary(b), do: a <> sep <> b
def join(a, b, _sep), do: {:non_binary, a, b}
```

```text
join("a", "b")      => "a, b"
join("a", "b", "-") => "a-b"
join(1, 2, "-")     => {:non_binary, 1, 2}
```

默认参数在**调用处**求值（不是定义处），且会让一个函数同时具有两个 arity：`join/2` 与
`join/3` 都真实存在（测试用 `function_exported?/3` 钉死了这一点）。这解释了为什么 Elixir
世界用「名字/参数个数」标识函数——它们本来就可以是不同的函数。

## 5.3 递归：遍历靠自己调自己

列表的递归遵循同一个二分法：**空列表是基线**，非空列表是 `[头 | 尾]`。

```elixir
def fact(0), do: 1
def fact(n) when is_integer(n) and n > 0, do: n * fact(n - 1)

def sum([]), do: 0
def sum([head | tail]), do: head + sum(tail)
```

```text
fact(10) = 3628800
sum(1..100) = 5050
```

这叫**体递归（body recursion）**：递归调用返回后还有乘法/加法等着做，运行时必须把每一
层栈帧留住。写起来最直白，但遍历长列表时栈会随长度增长。

### 累加器：把「等返回后再算」改成「往下传时就算」

尾递归版引入一个累加器参数，把中间结果带着走；用户接口仍只暴露一个参数，两参数版用
`defp` 设为私有：

```elixir
def sum_tail(list), do: sum_tail(list, 0)
defp sum_tail([], acc), do: acc
defp sum_tail([head | tail], acc), do: sum_tail(tail, head + acc)
```

反转列表是累加器的经典教学例子——每步把头元素 cons 到累加器前面，走完正好是倒序：

```elixir
def my_reverse(list), do: my_reverse(list, [])
defp my_reverse([], acc), do: acc
defp my_reverse([head | tail], acc), do: my_reverse(tail, [head | acc])
```

```text
my_reverse([1, 2, 3]) => [3, 2, 1]
```

> 标准库的 `Enum`/`List` 模块大量使用尾递归，但**不必把所有递归都改写成尾递归**：体递归
> 更短、更清晰，深度不大时（树遍历通常只有几十层）没有区别。BEAM 也不像 C 那样有固定的
> 小栈——栈帧在堆上，体递归百万次最多是多占内存，不会段错误。

## 5.4 函数是值：匿名函数、闭包、`&` 捕获

函数和整数、原子一样是 term。匿名函数用 `fn -> end` 创建，调用时**名字后面必须有个点**
`.(...)`——这个点用来和命名函数做语法区分：

```elixir
square = fn x -> x * x end
square.(8)          # => 64
```

函数可以当参数传（高阶函数），也可以当返回值。返回的函数会**闭包**捕获外层变量：

```elixir
def adder(n), do: fn x -> x + n end

add10 = adder(10)
add10.(5)           # => 15
```

示例用递归手写了 Enum 的三件套（07 章会讲标准库版本）：

```elixir
def my_map([], _fun), do: []
def my_map([head | tail], fun), do: [fun.(head) | my_map(tail, fun)]

def my_reduce([], acc, _fun), do: acc
def my_reduce([head | tail], acc, fun), do: my_reduce(tail, fun.(head, acc), fun)
```

```text
my_map([1,2,3,4,5,6], fn x -> x * x end)   => [1, 4, 9, 16, 25, 36]
my_reduce([1,2,3,4,5,6], 0, fn x, a -> x + a end) => 21
```

### `&` 捕获操作符

每次都写 `fn x -> ... end` 啰嗦，`&` 提供两种简写：

- `&(&1 * &1)`——就地构造匿名函数，`&1`/`&2` 是第 1/2 个参数；
- `&Module.fun/arity`——把一个已有的命名函数整体捕获成函数值。

```text
my_filter(1..6, &(rem(&1, 2) == 0)) => [2, 4, 6]
my_reduce(1..6, 0, &+/2)            => 21     # &+/2 捕获内核加法函数
(&Ex05Functions.fact/1).(6)         => 720
```

## 5.5 嵌套递归：树状结构不需要手工维护栈

递归函数天然处理任意深度的嵌套——元素本身是列表，就递归进去；元素是数字，就累加；
其余跳过：

```elixir
def deep_sum([]), do: 0
def deep_sum([head | tail]) when is_list(head), do: deep_sum(head) + deep_sum(tail)
def deep_sum([head | tail]) when is_number(head), do: head + deep_sum(tail)
def deep_sum([_other | tail]), do: deep_sum(tail)
```

```text
deep_sum([1, [2, [3]], 4, [5, [6]]]) => 21
deep_sum([1, :skip, [2, nil]])       => 3
```

这是命令式语言里要显式压栈的活；在递归语言里，「结构有多深，调用栈就有多深」是免费的。
JSON/XML 解析、AST 变换都是这个形状（23 章宏处理的就是 AST）。

## 5.6 尾调用优化（TCO）

当一个函数体的**最后一个动作**就是调用另一个函数（或自己）、且其返回值被直接返回时，
BEAM 不保留当前栈帧，而是**复用**它跳转过去——这就是尾调用优化。关键后果：

- 尾递归的内存占用是**恒定**的，与递归次数无关；
- 尾调用不限于自调用，**调用别的函数也算**（相互递归同样优化）。

```elixir
def count_down(0), do: :done
def count_down(n) when n > 0, do: count_down(n - 1)   # 最后一个动作：调用自己

def even?(0), do: true
def even?(n) when n > 0, do: odd?(n - 1)             # 最后一个动作：调用 odd?
def odd?(0), do: false
def odd?(n) when n > 0, do: even?(n - 1)
```

实测（1.20 / OTP 29）：

```text
count_down(2_000_000)       => :done
百万列表 sum     = 500000500000
百万列表 sum_tail= 500000500000
even?(1_000_000) => true
```

注意体递归与尾递归的判别：`n * fact(n - 1)` **不是**尾调用（递归回来还要乘）；
`fact_tail(n - 1, acc * n)` **是**（递归调用的结果直接返回，乘法已经先算完了）。

TCO 也是 12 章进程无限循环（`receive -> loop(state)`）的基石——BEAM 进程靠尾递归「驻留」，
不泄漏栈。

## 5.7 坑位清单

1. **匿名函数调用有个点**：`square.(8)`，写成 `square(8)` 会被当成调用名为 square 的命名
   函数而报错。命名函数引用成值要用 `&Mod.fun/arity` 捕获。

2. **多子句 + 默认值必须写函数头**：`def join(a, b, sep \\ ", ")` 单独一行，具体子句里不
   再写默认值，否则编译告警。默认值在**调用处**求值，且产生 `join/2`、`join/3` 两个函数。

3. **守卫是白名单，且出错不抛**：自定义函数不能进守卫；`hd([])` 这类错误在守卫里只让子句
   落选。想要「异常即失败」的探测，放守卫里最省事。

4. **子句顺序就是优先级**：具体的（`0`、`[]`、`[h|t]`）写前面，`_` 兜底写最后；写反了具体
   子句永不执行（新版编译器还会告警为不可达子句）。

5. **`n * fact(n-1)` 不是尾调用**：递归返回后还有运算要做，栈帧必须保留。想 TCO 就把待算
   的东西挪进累加器，让递归调用成为函数体最后一个动作。

6. **`defp` 是私有函数**：累加器版本、内部辅助一律 `defp`，对外只暴露干净的单参数入口
   （`sum_tail(list)` 包 `sum_tail(list, 0)`）。

7. **类型变量在 `@spec` 里要显式声明**：`@spec my_map([a], (a -> b)) :: [b] when a: var,
   b: var`，裸写 `a`/`b` 会报 `TypespecError: type a/0 undefined`。

8. **Range 不是 cons 列表**：`[h | t] = 1..100` 会 MatchError；要把区间当列表递归，先
   `Enum.to_list/1`（或对 Range 直接用 Enum/Stream——07、18 章）。

---

下一章：[06 · 控制流](06-control-flow.md)
