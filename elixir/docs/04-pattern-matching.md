# 04 · 模式匹配

> 对应示例：`examples/04_pattern_matching/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

上一章的每个函数里几乎都有 `=` 在干活。这一章把它彻底讲清：**Elixir 的 `=` 不是赋值号，
而是模式匹配操作符**。左边是模式（pattern），右边是值，运行时尝试让两者「对上」——对得上
就把模式里的变量绑定到值的对应部分；对不上直接抛 `MatchError`，没有 `null`、没有静默的
`undefined`。

模式匹配不是 Elixir 的一个特性，而是**这门语言分发控制流的基本方式**：函数多子句靠它选、
`case` 靠它选、解构靠它、过滤也靠它（05、06 章全建立在本章之上）。本章把每种形状都做成
可断言的函数，`mix test` 替你验证。

## 4.1 `=` 是匹配，不是赋值

```elixir
{x, y} = {1, 2}        # x=1, y=2：模式里的两个变量绑定到对应位置
:ok = result           # 断言 result 必须是 :ok，否则崩
```

右边对不上模式时，**当场抛 `MatchError`**，而不是得到某种「未定义」：

```text
{x, y} = {1, 2, 3} => {:raised, MatchError}（元组长度不同，形状对不上）
:ok = :error       => {:raised, MatchError}（值不同）
```

注意第一种：匹配在进入绑定之前就比较**形状**。`{1,2,3}` 有三个元素，模式只有两个位置，
直接失败，`x`/`y` 不会被部分绑定。

这给了一个零成本的断言惯用法——在函数内部写 `:ok = File.write(path, data)`：成功则继续，
失败立刻带着现场崩掉（let-it-crash，11 章细讲），比 `if` 判断醒目得多。

## 4.2 变量首次出现是绑定，再次出现是「要求相等」

模式里一个名字的**第一次**出现表示「绑定到这里」：

```elixir
{z, z} = {5, 5}   # => z=5：第一个 z 绑定 5；第二个 z 不绑定，而是要求「等于 5」
{z, z} = {5, 6}   # => MatchError：第二个位置是 6，不等于第一个位置绑到的 5
```

同一个模式里同名变量出现第二次，语义不是「再绑一次」，而是**约束两个位置必须相等**。
这让「相等性检查」直接长在模式里：

```elixir
def same_pair({x, x}), do: true    # 两元素相等的二元组
def same_pair({_a, _b}), do: false
```

```text
same_pair({1, 1}) => true
same_pair({1, 2}) => false
```

兜底从句里两个位置必须起**不同**的名字（`_a, _b`）——写成 `{x, x}` 就又变成相等约束了。
不用的变量用 `_` 或下划线前缀，编译器不会报 unused。

## 4.3 pin（`^`）：拿变量**已有的值**去匹配

模式里裸写的变量永远是「绑定」。那「我想匹配一个变量**此刻已有的值**」怎么办？用 `^`：

```elixir
expected = 200
{^expected, body} = {200, "OK"}   # 成功，body="OK"：^expected 拿 200 去比，不绑定
{^expected, _} = {404, "NF"}      # MatchError：404 != 200
```

没有 `^`，`{expected, body} = {404, "NF"}` 会**悄无声息地把 expected 重新绑定成 404**——
这是从命令式语言过来最容易犯的错：

```text
不用 ^：v = 1 之后 v = 2  => 2（第二次 = 是重新绑定，旧值被遮住）
用 ^  ：v = 2 之后 ^v = 3 => MatchError（这才是「拿 2 去和 3 比」）
```

示例的 `match_status/2` 在 `case` 里做这件事——第一个分支用 `^expected` 比较，不匹配才落到
第二分支：

```elixir
def match_status(actual, expected) do
  case actual do
    ^expected -> {:ok, actual}
    other -> {:mismatch, other}
  end
end
```

```text
match_status(200, 200) => {:ok, 200}
match_status(404, 200) => {:mismatch, 404}
```

**小结一句话**：模式中的变量名默认是「挖个坑把值装进去」，加 `^` 才是「把坑里已有的值
拿出来比」。

## 4.4 元组解构：`{:ok, _}` / `{:error, _}` 通用返回形状

03 章说过，元组装固定个数、不同含义的字段。BEAM 世界最重要的约定就是用它表达「成败」：

```elixir
def classify({:ok, _value}), do: :ok_value
def classify({:error, _reason}), do: :error_value
def classify(_other), do: :something_else
```

```text
classify({:ok, 42})       => :ok_value
classify({:error, :oops}) => :error_value
classify({:other, 1})     => :something_else
```

模式按书写顺序从上到下匹配，第一个对得上的从句生效，所以**更具体的模式要写在前面**，
`_other` 这种万能兜底永远在最后（05 章会系统讲多子句分派）。

只想在成功时取值、其余统统当没有，可以用两个从句表达「要么有要么 nil」：

```elixir
def ok_value({:ok, value}), do: value
def ok_value(_), do: nil
```

```text
ok_value({:ok, "hi"})  => "hi"
ok_value({:error, :x}) => nil
```

真实代码里更常见的是在调用处直接 `{:ok, data} = File.read!(path)` 这样解构，或在 `case`
里分两个分支处理（06 章）。

## 4.5 列表：头尾、精确长度、嵌套解构

链表的基本模式是 `[head | tail]`，O(1) 拆头尾；空列表没有头尾，单独写一个从句：

```elixir
def head_tail([head | tail]), do: {:ok, head, tail}
def head_tail([]), do: {:error, :empty}
```

```text
head_tail([1, 2, 3]) => {:ok, 1, [2, 3]}
head_tail([])        => {:error, :empty}
```

**列表模式精确匹配长度**：`[_, _]` 只接受恰好两个元素的列表，多一个少一个都不匹配
（它不是「至少两个」）：

```elixir
def pair?([_, _]), do: true
def pair?(_), do: false
```

```text
pair?([:a, :b])       => true
pair?([:a])           => false
pair?([:a, :b, :c])   => false
```

要表达「至少两个」，用 cons：`[a, b | _rest]`。

模式可以任意**嵌套**，一步从「元组套 map」里把深层字段抠出来，不必逐层访问：

```elixir
def city({:user, _name, %{city: c}}), do: c
def city(_), do: :unknown
```

```text
city({:user, "Ada", %{city: "London"}}) => "London"
city({:user, "Ada", %{}})               => :unknown
```

## 4.6 map：部分匹配与动态键

`%{name: value}` 是**部分匹配**：只要求 map 里**存在** `:name` 键，多余的键无所谓：

```elixir
def has_name?(map), do: match?(%{name: _}, map)
```

```text
has_name?(%{name: "x", age: 1}) => true
has_name?(%{age: 1})            => false
```

对**不存在**的键做强制匹配，不是返回 `nil`，而是直接 `MatchError`：

```elixir
def force_key!(map, key) do
  %{^key => _value} = map   # 键不存在就崩
  :ok
end
```

```text
force_key!(%{present: 1}, :missing) => MatchError
```

注意这里有两个语法点。第一，**动态键**（键名运行时才知道）不能用 `%{key: v}` 的原子键
语法（那是写死键名 `:key`），必须在键的位置 pin 一个变量：`%{^key => value}`。字符串键也
走箭头语法 `%{"name" => v}`：

```elixir
def get_key(map, key) do
  case map do
    %{^key => value} -> {:ok, value}
    _ -> :error
  end
end
```

```text
get_key(%{a: 1, b: 2}, :b)          => {:ok, 2}
get_key(%{a: 1}, :b)                => :error
get_key(%{"name" => "Ada"}, "name") => {:ok, "Ada"}
```

第二，**想要「没有键就给默认值」而不是崩，用 `Map.get/3`**；模式匹配表达的是「我断定这个
键必须在」。两种语义按需选择。

> **1.20 类型检查器**：对字面量直接写 `%{missing: v} = %{present: 1}` 会被静态判定为
> 「不可能匹配成功」，产生编译告警（`--warnings-as-errors` 下即失败）。示例把它包进参数为
> `term()` 的 `force_key!/2`，运行期才知道键在不在，检查器便无从判定。

## 4.7 二进制前缀匹配

字符串是二进制，模式可以直接匹配**字节前缀**。字面量前缀有 `<>` 语法糖；前缀是**变量**时
要用完整的二进制模式，且变量前缀必须 pin：

```elixir
def strip_prefix(bin, prefix) when is_binary(bin) and is_binary(prefix) do
  case bin do
    <<^prefix::binary, rest::binary>> -> {:ok, rest}
    _ -> :error
  end
end
```

```text
strip_prefix("Hello, world", "Hello, ") => {:ok, "world"}
strip_prefix("goodbye", "Hello, ")      => :error
```

`::binary` 类型标注不能省——二进制模式默认按**单个字节**匹配变量，变长前缀必须显式声明。
`rest::binary` 吃掉剩下的全部字节。

按固定字节宽度拆包是解析网络协议/文件格式的最基本动作。下例把前 4 字节当成一个大端
（base-256）32 位整数：

```elixir
def split_32(<<a, b, c, d, rest::binary>>) do
  {:ok, Integer.undigits([a, b, c, d], 256), rest}
end
def split_32(_short), do: :error
```

```text
split_32(<<1, 0, 0, 0, 9, 8>>) => {:ok, 16777216, <<9, 8>>}
split_32(<<1, 2>>)             => :error
```

17 章会讲更完整的位串语法（`size`/`unit`、大小端、位对齐）和正则。

## 4.8 `match?/2`：只问对不对得上，永不崩

很多时候你不想要绑定、也不想崩，只想问一句「这个形状对得上吗」。`match?/2` 这个宏正合此
意——对上返回 `true`，对不上返回 `false`：

```elixir
def ok?(term), do: match?({:ok, _}, term)
```

```text
ok?({:ok, 1}) => true
ok?(:nope)    => false
```

它最常见的位置是 `Enum.filter/2` 和推导式的过滤子句。下面这个 for 一边遍历一边用模式
`{:ok, value}` 过滤——对不上的元素被直接跳过，值在 do 体里直接可用：

```elixir
def select_ok(list), do: for({:ok, value} <- list, do: value)
```

```text
select_ok([{:ok, 1}, {:error, :x}, {:ok, 3}]) => [1, 3]
```

这就是「失败的数据不进管道」的声明式写法，没有一句 `if`。

## 4.9 坑位清单

1. **`=` 不是赋值**：对不上就抛 `MatchError`，没有静默的 `undefined`。`:ok = result` 是
   零成本断言惯用法。

2. **裸变量在模式里永远是绑定**：想比较变量已有的值必须 pin（`^expected`）。漏写 `^` 不会
   报错，而是悄悄重新绑定——这是本章头号 bug 来源。

3. **同名变量第二次出现是相等约束**：`{x, x}` 要求两位相等，不是绑定两次。两个不同位置要
   起不同名字。

4. **列表模式精确匹配长度**：`[_, _]` 是「恰好两个」；「至少两个」要写 `[a, b | _]`。
   更具体的子句必须排在万能兜底 `_` 前面。

5. **动态键 / 字符串键用箭头语法**：`%{^key => value}`、`%{"k" => v}`；`%{key: v}` 是写死
   原子键 `:key`。键不存在时强制匹配是 `MatchError`，想要默认值用 `Map.get/3`。

6. **变量二进制前缀必须 pin 且标注 `::binary`**：
   `<<^prefix::binary, rest::binary>>`。漏标注会按单字节匹配，行为完全不同。

7. **1.20 会静态判定「不可能的匹配」**：字面量必然失败的匹配、必然为真的 `is_*` 判定都会
   告警。可断言的库里把参数标成 `term()`；驱动脚本里要**演示崩溃**时，用 `Code.eval_string/1`
   让代码在运行时才编译（本章 `run.exs` 的 `expect_match_error` 即此法），否则既告警又有
   unused 变量。

8. **只想要布尔答案用 `match?/2`**：它永不抛错，天然适合 `Enum.filter/2` 与 for 推导的
   过滤子句；需要「崩溃以暴露不该发生的情况」时才用强制匹配。

---

下一章：[05 · 函数与递归](05-functions-recursion.md)
