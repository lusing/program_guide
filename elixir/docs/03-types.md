# 03 · 基础类型与不可变性

> 对应示例：`examples/03_types/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Elixir 的值类型一共就十来种，本章把它们一次讲透，并把三条贯穿全书的底层事实钉死：

1. **一切值不可变**——「修改」永远是「算出一个新值」，旧值原封不动；
2. **整数任意精度、`/` 永远返回浮点**，而 `**` 的整数/浮点规则比传言的更微妙；
3. **所有 term 有全序**——任意两个值都能比较大小，混合类型排序不会崩。

每一条结论都在示例里做成了可断言的函数，`mix test` 会替你验证而不是靠记忆。

## 3.1 数字：三种除法、任意精度、进制字面量

Elixir 有三种「除法」，初学者几乎必踩：

| 运算 | 结果类型 | 语义 |
|---|---|---|
| `a / b` | **永远浮点** | 数学除法，`4 / 2` 得到 `2.0` 而非 `2` |
| `div(a, b)` | 整数 | 向零截断（同 C/Rust/Go），`div(-7, 2)` 是 `-3` |
| `rem(a, b)` | 整数 | 取余，符号跟随**被除数**，与 `div` 配套 |

```text
7 / 2            => 3.5     （/ 永远返回浮点）
4 / 2            => 2.0     （整除也是浮点）
div(7, 2)        => 3
div(-7, 2)       => -3      （向零截断，同 C；Python 的 // 是 -4）
rem(-7, 2)       => -1      （符号跟随被除数）
rem(7, -2)       => 1
```

`div` 与 `rem` 满足恒等式 `div(a, b) * b + rem(a, b) == a`，测试里对负数也断言了这一点。

**整数没有位宽上限**。超出机器字长会自动升级成 Erlang 的 bignum，代价只是分配和运算变慢，
**永远不会回绕**（不像 C/Rust/Java 的固定宽整数）：

```elixir
Integer.pow(2, 64)   # => 18446744073709551616，超过 u64 上限照样精确
```

### 幂运算 `**` 的真实规则（常见误解）

一个广为流传的说法是「`**` 永远返回浮点，整数幂要用 `Integer.pow/2`」。**这在现代 Elixir 上是错的**。
实测（1.20 / OTP 29）：

```text
2 ** 64           => 18446744073709551616   （整数底 + 非负整数指数 => 精确整数！）
2 ** -1           => 0.5                    （负指数 => 静默转浮点）
3.0 ** 40 (float) => 12157665459056928768   （混入浮点 => 低位被吞）
Integer.pow(3,40) => 12157665459056928801   （精确，二者相差 33）
```

规则是：**底数与指数都是整数、且指数非负时，`**` 走精确整数**（与 `Integer.pow/2` 等价）；
只要有一个浮点、或指数为负，就掉进 IEEE 754。浮点丢精度要用**非 2 的幂**才看得出来——
`2.0 ** 100` 恰好能被 double 精确表示（2 的幂、尾数全 0），`3.0 ** 40` 就比精确整数少了 33。

那 `Integer.pow/2` 的价值是什么？是**强制整数语义**：`Integer.pow(2, -1)` 直接抛
`ArithmeticError`，而 `2 ** -1` 会不声不响给你一个浮点 `0.5`。

进制字面量与可读性分隔符：

```elixir
0xFF        # => 255   十六进制
0o777       # => 511   八进制
0b1010      # => 10    二进制
1_000_000   # => 1000000，下划线只是分隔符，编译期丢弃
```

## 3.2 浮点相等陷阱

`0.1` 和 `0.2` 在 IEEE 754 双精度下都不是精确值，加起来是 `0.30000000000000004`：

```text
0.1 + 0.2 == 0.3        => false
nearly_equal(0.1+0.2, 0.3) => true
```

正确姿势是**容差比较**，不要用 `==` 比浮点：

```elixir
def nearly_equal(a, b, epsilon \\ 1.0e-9), do: abs(a - b) <= epsilon
```

## 3.3 原子：`nil`/`true`/`false` 也是原子，且原子表只增不减

原子（atom）是**以自身名字为值**的常量，写作用 `:` 开头：`:ok`、`:error`、`:not_found`。
布尔和 nil 没有特殊地位，它们就是三个普通原子：

```text
is_atom(:ok) / is_atom(true) / is_atom(nil) => true / true / true
```

含空格或特殊字符的名字要用引号原子：`:"hello world"`。模块名 `Ex03Types` 的真身是原子
`:"Elixir.Ex03Types"`——这解释了为什么 12 章里模块名能当进程注册名、能当消息发。

**原子表是一块只增不减的全局表，上限约一百万个**（`:erlang.system_info(:atom_limit)` 实测
`1048576`）。每个新原子永久占一个槽位，GC 不回收。所以：

- 内部标签、有限枚举：放心用原子；
- **外部输入（用户输入、JSON 键、HTTP 头）绝不能直接 `String.to_atom/1`**——那等于让外部
  数据无限制造原子，是教科书级的内存泄漏 + DoS 漏洞。

正确做法是 `String.to_existing_atom/1`，它只接受**原子表里已经存在**的原子，否则抛
`ArgumentError`，绝不新建：

```elixir
def atom_from(binary) when is_binary(binary) do
  try do
    {:ok, String.to_existing_atom(binary)}
  rescue
    ArgumentError -> {:error, :no_such_atom}
  end
end
```

```text
atom_from("nil")                    => {:ok, nil}
atom_from("true")                   => {:ok, true}
atom_from("Ex03Types")              => {:ok, :Ex03Types}   # 注意：裸名字，不带 Elixir. 前缀
atom_from("no_such_atom_for_sure_9x7") => {:error, :no_such_atom}
```

测试还在原子计数层面钉死了差别：调一次失败的 `atom_from` 前后 `:atom_count` 不变；而
`String.to_atom/1` 调一次，计数真的 `+1`，且永远收不回来。

## 3.4 真假值：只有 `false` 和 `nil` 是假

这是 Elixir 与 C/C++/Python/JavaScript 最大的分歧之一：**除了 `false` 和 `nil`，一切皆真**——
`0`、`0.0`、`""`、`[]` 全是真值。

```text
truthy?(0)     => true
truthy?("")    => true
truthy?([])    => true
truthy?(false) => false
truthy?(nil)   => false
```

`&&` / `||` / `!` 基于这套规则，且 **`&&`/`||` 返回的是操作数本身，不是布尔**：

```elixir
nil || "默认值"   # => "默认值"
0 || "默认值"     # => 0          （0 是真值，右边根本不求值！）
"a" && "b"        # => "b"
nil && "b"        # => nil
```

`0 || "默认值"` 返回 `0` 这条值得贴在显示器上——从 Python/JS 过来的人会本能地以为得到默认值。

## 3.5 字符串三层：字节 / 码点 / 字素簇，外加 charlist

Elixir 字符串是 **UTF-8 编码的二进制**，而 charlist（`~c"..."`）是**码点整数列表**，两者是
完全不同的类型：

```elixir
is_binary("abc")   # => true
~c"abc" == [97, 98, 99]   # => true，charlist 的真身就是码点列表
is_list(~c"abc")   # => true
is_binary(~c"abc") # => false
```

处理文本时有三个**不同的单位**，务必分清：

| 单位 | 取法 | 含义 |
|---|---|---|
| 字节 | `byte_size/1` | UTF-8 编码后的原始字节数 |
| 码点 | `length(String.codepoints/1)` | Unicode 码位个数 |
| 字素簇 | `String.length/1` / `String.graphemes/1` | 人眼看到的「一个字符」 |

**关键反直觉点：`String.length/1` 数的是字素簇，不是码点。** 数码点要用 `String.codepoints/1`。

```text
单码点 "é"（U+00E9）：byte_size=2，码点=1，字素簇=1
组合序列 e + U+0301  ：byte_size=3，码点=2，字素簇=1
  graphemes => ["é"]
```

`é` 可以写成一个码点 U+00E9（NFC），也可以写成「字母 e + 组合重音 U+0301」（NFD）——
字节数、码点数都不同，却都是人眼看到的同一个 `é`（一个字素簇）。第 08 章会深入 Unicode
这片深水区（大小写转换、emoji、规范化），现在先记住三个单位的差别。

## 3.6 元组：定长、按位 O(1)、不可变

元组（tuple）是**定长、连续存放**的结构，按位置取元素是 O(1)：

```elixir
t = {:ok, 42, "extra"}
tuple_size(t)      # => 3
elem(t, 1)         # => 42
t2 = put_elem(t, 1, 99)
# t  仍是 {:ok, 42, "extra"}（没变）
# t2 是   {:ok, 99, "extra"}（新值）
```

元组的本职工作是**装固定个数、不同含义的字段**——尤其是 `{:ok, value}` / `{:error, reason}`
这对返回约定（02 章已见）。变长集合不要用元组（追加是 O(n)），那是列表的活。

## 3.7 列表：cons 单元链与 keyword

Elixir 的列表是**链表**，每个节点是一个 `[head | tail]` cons 单元。头/尾分解是 O(1)：

```elixir
[h | rest] = [1, 2, 3]   # h=1, rest=[2, 3]
[1, 2] ++ [3]            # => [1, 2, 3]
[1, 2, 1, 3] -- [1]      # => [2, 1, 3]，-- 只删每个元素的第一次出现
```

对空列表取头会抛 `ArgumentError`，示例用模式匹配把两种形状分开：

```elixir
def list_parts([]), do: {:error, :empty}
def list_parts([head | tail]), do: {:ok, head, tail}
```

**keyword 列表不是新类型**，它就是「键为原子的二元组列表」的语法糖，而且**键可重复、
有序、按键查找是线性的**：

```elixir
[name: "Elixir", year: 2012] == [{:name, "Elixir"}, {:year, 2012}]   # => true
Keyword.get([name: "x", name: "y"], :name)   # => "x"（取第一个）
```

正因为线性、可重复，keyword 专用于**函数的可选项**（`String.split(s, " ", trim: true)`），
不当通用 map 用——那是 09 章的主题。

## 3.8 不可变性：「更新」就是「返回新值」

Elixir 的每一个值都是不可变的。`Map.update!/3` 不会改掉旧 map，而是返回一个新 map：

```elixir
def bump(map, key) do
  updated = Map.update!(map, key, &(&1 + 1))
  {map, updated}      # 旧值、新值同时返回，亲眼看到两者并存
end
```

```text
bump(%{count: 1}, :count) => 原值 %{count: 1} 与新值 %{count: 2} 并存
```

顶层的 `x = x + 1` 看起来像「改变变量」，其实是**重新绑定**：右边用旧绑定 `x=1` 算出 `2`，
再让名字 `x` 指向新值，旧的 `1` 从未被修改。字符串拼接同理：`s <> "d"` 产生新二进制，
`s` 还是旧的。

不可变性是后面一切并发故事的地基：正因为谁都改不了共享数据，BEAM 才能让成千上万进程
零锁地并发（12 章起展开）。

## 3.9 类型判定全家桶

所有类型都有对应的 `is_*` 判定函数：`is_atom/1`、`is_integer/1`、`is_float/1`、
`is_binary/1`、`is_list/1`、`is_map/1`、`is_tuple/1`、`is_function/1`、`is_pid/1`、
`is_port/1`、`is_reference/1`、`is_number/1`、`is_bitstring/1`、`is_struct/1`、
`is_exception/1`、`is_nil/1`、`is_boolean/1`。

示例里的 `type_of/1` 把任意 term 映射成类型标签，**判定顺序本身就是知识点**——
更具体的类型必须排在更宽泛的前面：

```elixir
def type_of(term) do
  cond do
    is_nil(term) -> nil
    is_boolean(term) -> :boolean
    is_atom(term) -> :atom        # true/false 也是原子，所以 boolean 必须在前
    is_integer(term) -> :integer
    is_float(term) -> :float
    is_struct(term) -> :struct
    is_binary(term) -> :binary
    is_bitstring(term) -> :bitstring   # binary 是 8 位对齐的 bitstring
    is_list(term) -> :list
    is_tuple(term) -> :tuple
    is_map(term) -> :map              # struct 是带 :__struct__ 键的 map，必须排在 struct 之后
    # ...
  end
end
```

两条父子关系：`is_number` 同时认整数和浮点；`binary` 是 `bit_size` 为 8 的倍数的 `bitstring`。
还有 `is_struct/1` 认 struct（`is_map` 对 struct 也为真）、`is_exception/1` 认异常 struct，
而 `{:error, :oops}` 这种 error 元组**不是**异常。

> **1.20 类型检查器坑**：直接对字面量写 `is_number(42)` 会被告警「always succeed」，
> 写 `1 < :a` 会被告警「comparison between distinct types」，`--warnings-as-errors` 下直接
> 编译失败。示例刻意把这些包进参数为 `term()` 的探针函数（`number?/1`、`lt/2`）让检查器
> 无法静态判定；测试代码也必须照办（本章测试就是因此修复的）。

## 3.10 term 全序：混合类型排序不崩

与许多语言不同，BEAM 为**任意两个 term** 定义了全序，所以混合类型的列表也能 `Enum.sort/1`，
不会抛类型错误。大类顺序是：

```text
number < atom < reference < function < port < pid < tuple < map < list < binary
```

实测对 `[整数, 浮点, 原子, ref, 函数, pid, 元组, map, 列表, 二进制]` 排序后的类型标签：

```text
[:float, :integer, :atom, :reference, :function, :pid, :tuple, :map, :list, :binary]
```

两个细节：

1. **number 内部不再区分 int/float，按数值排**——`3.14 < 42`，所以这里 `:float` 排在
   `:integer` 前。换成 `[1, 3.14]` 就变成 `:integer` 在前。
2. 同类型内部按各自规则递归比较（列表逐元素、元组逐位、map 先比大小再比键值）；
   原子自 OTP 26 起按**文本字节序**比较：`Enum.sort([:zebra, :apple]) => [:apple, :zebra]`。

相等有两个运算符：`==` 跨数值类型比值（`1 == 1.0` 为真），`===` 还要求类型一致
（`1 === 1.0` 为假）。需要严格相等时用 `===`。

## 3.11 坑位清单

1. **`/` 永远返回浮点**：要整数结果用 `div/2`；`div` 向零截断（`-7/2 => -3`，不是 Python 的 `-4`）。

2. **「`**` 永远返回浮点」是过时说法**：整数底 + 非负整数指数走精确整数；混入浮点或负指数
   才走浮点。要强制整数语义、负指数报错，用 `Integer.pow/2`。演示浮点丢精度别用 2 的幂
   （double 能精确表示），用 `3.0 ** 40` 这类。

3. **`String.length/1` 数的是字素簇不是码点**：数码点用 `String.codepoints/1`，数字节用
   `byte_size/1`。组合字符（`e + U+0301`）码点数 2 但 `String.length` 是 1。

4. **别拿 `String.to_atom/1` 处理外部输入**：原子表只增不减、上限约一百万，等于 DoS。
   用 `String.to_existing_atom/1`。

5. **只有 `false` 和 `nil` 是假值**：`0`、`""`、`[]` 都为真；`0 || x` 返回 `0` 而非 `x`。

6. **`is_*` 判定要先具体后宽泛**：`is_boolean` 在 `is_atom` 前、`is_struct` 在 `is_map` 前、
   `is_binary` 在 `is_bitstring` 前，否则结论被宽类型吞掉。

7. **1.20 类型检查器对字面量较真**：`is_number(42)`、`1 < :a`、`1 === 1.0`、不同形状 map
   比较都会告警。包进参数为 `term()` 的函数，让检查器失去静态信息。1.20.4 更进一步：
   `assert is_struct(p)`（p 是字面量构造的 struct）会把守卫断言重写成模式匹配，失败
   分支被证明不可达而告警——测试里用 `struct(Ex03Types.Point, ...)` 动态构造抹掉类型。

8. **不可变 ≠ 不能「更新」**：所有「修改」都返回新值；这不是性能负担（结构共享），而是 BEAM
   无锁并发的前提。

---

下一章：[04 · 模式匹配](04-pattern-matching.md)
