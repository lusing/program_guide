# 25 · 函数式思维：不可变、纯函数、声明式

> 对应示例：`examples/25_thinking/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）
>
> 本章取材自《函数式编程入门：使用 Elixir》（Ulisses Almeida）第 1 章「函数思想」——在进入语法细节之前，先回答三个问题：**数据为什么不可变？函数为什么是主角？代码为什么是声明式的？** 前面 24 章里它们散落在各处，这里正面把它们讲透。

## 25.1 命令式的困境：共享可变值

命令式与面向对象语言靠**共享可变值**协作：程序的不同部分引用同一块
数据，谁都能改。单线程时代这很高效；多核时代它是灾难的源头——
想象两段并行代码同时操作一个数组，一个 `pop` 一个 `push`，结果取决于
谁先谁后。命令式语言的答案是锁与同步原语，而锁是并发的头号杀手：
死锁、竞态、优先级反转，全是它带来的。

书里用 Ruby 举了个例子（关注概念，别纠结语法）：

```ruby
list = [1, 2, 3, 4]
list.pop     # => 4，list 变成 [1, 2, 3]
list.push(1) # => list 变成 [1, 2, 3, 1]
```

`list` 是**被修改**的，不是被替换的。CPU 主频早已停滞，性能靠多核；
靠共享可变状态写不出安全的多核程序——这就是范式转向的原动力。

顺带戳破一个安慰剂：Ruby 的 `freeze` 只冻结容器，冻不住里面的内容——
`users.freeze` 之后 `users.first.name = "Karina"` 照样生效。在默认可变的
语言里「借用函数式概念」，得到的不是函数式的保障。

## 25.2 不可变数据：操作产生新值

Elixir 里对值的一切操作都**返回新值**，原值纹丝不动：

```elixir
iex> list = [1, 2, 3, 4]
iex> List.delete_at(list, -1)
[1, 2, 3]
iex> list ++ [5]
[1, 2, 3, 4, 5]
iex> list
[1, 2, 3, 4]          # 原值从未变过
```

不可变带来的第一份礼物是**免锁的并发**：三行操作互不干扰，编译器和
运行时可以放心并行执行它们，不需要任何同步。

第二份礼物要靠实证——「每次都产生新值」听起来像「每次都全量复制」，
很贵。其实不然。列表是单向链表，**cons（`[head | tail]`）出的新列表，
尾部就是旧列表本身**：

```elixir
iex> base = Ex25Thinking.runtime_list()   # 运行时构建 [1, 2, 3]
iex> newer = Ex25Thinking.cons_ahead(base)
iex> :erts_debug.same(tl(newer), base)    # 同一个内存对象？
true
```

`:erts_debug.same/2` 判断两个项是不是**同一块内存**。`true` 说明新列表
的尾巴没有复制——新旧列表共用同一条链。这就是持久化数据结构
（persistent data structure）的**结构共享**：每次「修改」只新建 O(1)
的节点，其余全部共享。

反面对照是 `++`：它复制左操作数的所有单元格，结果的尾部与旧列表
内容相等、指针不同：

```elixir
iex> copy = Ex25Thinking.append_copy(base)   # base ++ [4]
iex> Enum.take(copy, 3) == base
true
iex> :erts_debug.same(tl(copy), tl(base))
false
```

所以递归构建列表永远用 cons（第 05、27 章），`++` 留给一次性拼接。

```text
-- 2. 结构共享：cons 出的新列表，尾部就是旧列表本身 --
  cons 出的新列表，尾部与旧列表同一对象 => true
  ++ 复制左表：前 3 个内容相等 => true，尾部同一对象 => false
  （cons O(1) 共享；++ O(n) 复制——不可变的代价远小于全量拷贝）
```

## 25.3 纯函数：可预测的积木

函数式编程用函数构建程序。当一个函数满足三条判据，它就是**纯函数**：

1. 值是不可变的（不在函数里改数据）；
2. 结果只受参数影响（不读外部状态）；
3. 除了返回值不产生其他影响（不写外部状态）。

```elixir
iex> Ex25Thinking.tax(100, 8)
8.0
iex> Ex25Thinking.tax(100, 8)   # 调一百次也一样
8.0
```

纯函数的核心性质是**引用透明**：调用可以被结果原样替换——
`Ex25Thinking.tax(100, 8)` 换成 `8.0`，程序行为不变。重构安全、
结果可缓存、执行可并行，全靠这一条。

纯函数也可能出错，但**错误同样可预测**：给 `tax/2` 传 `nil` 永远得到
ArithmeticError，绝不会今天抛、明天静默返回 0。与之对照，
`IO.gets/1`（用户想输什么输什么）、`DateTime.utc_now/0`（每次都不同）
这类**非纯函数**才是真正的不可预测之源——如何驯服它们是第 28 章的主题。

## 25.4 状态显式流动：函数式的 Set

面向对象把状态藏进对象、方法依赖调用时刻的内部状态，状态与方法互相
纠缠，随软件长大越来越难调试。函数式的答案：**状态不藏，在函数之间
显式流动**。书的 MySet 例子（`Ex25Thinking.MySet`）：

```elixir
defmodule Ex25Thinking.MySet do
  defstruct items: []

  def push(set = %{items: items}, item) do
    if Enum.member?(items, item) do
      set                              # 已存在：原样返回（幂等）
    else
      %{set | items: items ++ [item]}  # 不存在：返回新结构体
    end
  end
end
```

用法上，每一步的输入输出摆在明面上：

```elixir
iex> set0 = %Ex25Thinking.MySet{}
iex> set1 = Ex25Thinking.MySet.push(set0, "apple")
iex> set2 = Ex25Thinking.MySet.push(set1, "pie")
iex> set1
%Ex25Thinking.MySet{items: ["apple"]}   # set1 没被 set2 影响
iex> Ex25Thinking.MySet.push(set2, "apple") == set2   # 幂等
true
```

没有「对象积累内部状态」这回事——`push` 吃集合、吐集合，链到多长
都能一眼看穿。第 09 章的 struct、第 12 章的「状态 loop」，本质都是
这个模式的延伸。

## 25.5 声明式：同一个问题的三种写法

命令式编程描述**如何做**（控制流 + 可变状态）；声明式编程描述
**要什么**（数据必须长什么样）。把字符串列表全部大写：

**写法一：命令式**（JavaScript / Python 里天天写）——for 循环、下标
自增、往可变累加器里塞：

```javascript
var list = ["dogs", "hot dogs", "bananas"];
function upcase(list) {
  var newList = [];
  for (var i = 0; i < list.length; i++) {
    newList.push(list[i].toUpperCase());
  }
  return newList;
}
```

**写法二：声明式递归**——两个子句描述了结果的结构：

```elixir
def upcase_rec([]), do: []
def upcase_rec([first | rest]), do: [String.upcase(first) | upcase_rec(rest)]
```

空列表的大写还是空列表；非空列表的大写是「头元素大写拼上其余元素
大写的结果」。没有下标、没有累加器、没有循环变量——递归天然处理
「剩余部分」（第 05 章）。

**写法三：把变换当参数**——「大写」这个动作本身是值（`&String.upcase/1`），
直接交给 `Enum.map/2`：

```elixir
iex> Ex25Thinking.upcase_map(["dogs", "hot dogs", "bananas"])
["DOGS", "HOT DOGS", "BANANAS"]
```

三写的演进方向：**控制流越来越少，意图越来越显**。如今 Java、Python、
Ruby 都在往声明式靠（stream、推导式、`map`），Elixir 从第一天就是。

## 25.6 管道：让值的流动可见

同一个转换链条，嵌套调用从里往外读，管道从上往下读：

```elixir
# 嵌套：由内向外
join_with_whitespace(capitalize_all(String.split(title)))

# 管道：数据从上向下流
title
|> String.split()
|> capitalize_all()
|> join_with_whitespace()
```

`a |> g() |> f()` 就是 `f(g(a))`——纯粹的语法糖，但可读性天差地别。
`"the dark tower"` 变 `"The Dark Tower"` 的每一步都摆在眼前。第 07 章
已把 `|>` 用成肌肉记忆，这里补上它的「世界观」：**程序是值的转换
管道，不是指令的执行序列**。

## 25.7 要点小结

```text
  命令式靠共享可变状态 + 锁，函数式靠不可变 + 纯函数，后者天然适合多核
  不可变 ≠ 全量复制：cons O(1) 且与旧列表共享尾部（结构共享实证）
  纯函数三判据：不改数据、只依赖参数、只产出返回值
  引用透明：调用可被结果替换 → 重构/缓存/并行都安全；错误也可预测
  状态显式流动：函数吃数据吐数据，没有藏在对象里的调用时刻依赖
  声明式：描述「要什么」（递归子句、map、管道），不描述「怎么改」
```

## 25.8 坑位清单

1. **结构共享实验必须用运行时构建的列表**。字面量 `[1, 2, 3]` 住在
   BEAM 只读字面量区，从它身上取子项时 `tl/1` 与模式匹配取出的指针
   在不同求值上下文（eval / 编译模块）里时同时不同——断言会随机翻车；
   `Enum.to_list/1` 现场构建才稳定。
2. **`[0] ++ base` 不复制**。字面量作前缀的 `++` 会被编译器重写成
   `[0 | base]`，照样共享尾部——想演示「++ 复制左表」必须用变量
   作左操作数（`base ++ [4]`）。
3. **1.20 类型检查器对字面量坏参数告警**：doctest / 测试里写
   `tax(nil, 8)` 会触发「类型不兼容」编译告警（第 2 层门禁挂）；
   验证错误路径用 `apply(Mod, :fun, [nil, ...])` 绕开静态检查。
4. **嵌套模块写在同文件时，被依赖的模块要放前面**：`%Struct{}`
   展开要求 struct 模块已编译；后置会报「cannot expand struct /
   cyclic module usage」。
5. **doctest 里空行会切断变量作用域**：两组 `iex>` 例子之间空一行，
   就是两个独立会话，前一组绑定的变量后一组不可见（「undefined
   variable」编译错）。

---

下一章把「函数是值」再往深推一层：闭包如何在不传参数的情况下共享值。
