# 27 · 递归进阶：减治、分治与无界递归

> 对应示例：`examples/27_recursion_deep/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）
>
> 取材自《函数式编程入门：使用 Elixir》第 4 章「运用递归」。第 05 章写过朴素递归与尾递归；本章把递归的**治理术**配齐——怎么从手写答案里发现递归模式、怎么把问题切开独立求解、以及递归失去边界时怎么加护栏。

## 27.1 有界递归：终止子句在前

递归函数反复调用自己完成重复任务。最常见的形态是**有界递归**：
迭代次数由参数直接决定——每走一步，剩下的迭代就少一步：

```elixir
def up_to(0), do: 0                                   # 边界子句
def up_to(n) when is_integer(n) and n > 0, do: n + up_to(n - 1)
```

`up_to(5)` 的展开是 `5 + (4 + (3 + (2 + (1 + 0)))) = 15`。两条纪律：

1. **边界子句永远写在重复子句前面**——子句自上而下匹配，边界在后就
   永远轮不到它；
2. 守卫挡住「没有终止方向」的输入（负数会让 `n - 1` 越走越远），
   挡下时抛 FunctionClauseError——错误暴露在第一现场。

书附录的尾递归版（累加器）在 `up_to_tail/1`：百万级求和也只占一个
栈帧（第 05 章 TCO 的复习）。

## 27.2 用 cons 构建新列表：魔法商店

`[head | tail]` 不只能解构参数，还能**构建**新列表。书的魔法商店：
埃德温给普通物品施法——改名 `Edwin's X`、价格 ×3，已施法的跳过：

```elixir
def enchant_for_sale([]), do: []

def enchant_for_sale([item = %{magic: true} | rest]) do
  [item | enchant_for_sale(rest)]          # 子图匹配：已施法，原样保留
end

def enchant_for_sale([item | rest]) do
  new_item = %{title: "Edwin's #{item.title}", price: item.price * 3, magic: true}
  [new_item | enchant_for_sale(rest)]
end
```

```text
-- 2. 魔法商店：cons 逐头构建 + 子图匹配跳过已施法物品 --
  施法后标题 => ["Edwin's Longsword", "Healing Potion", "Edwin's Rope", "Dragon's Spear"]
  施法后价格 => [150, 60, 30, 100]（已施法的 60/100 原样保留）
  与 Enum.map 版一致 => true
```

三个看点：

- **子图匹配**：`%{magic: true}` 只要求这个键值对存在，其余键随便——
  map 版的「implements 接口检查」；
- **cons 逐头构建**是 O(1)，比每步 `++`（O(n)，见第 25 章的复制实证）
  快一个量级；递归与 cons 是天作之合；
- 「跳过型中间子句」展示了多子句分派的真正威力：遍历逻辑不写 if 链，
  写成一条条子句。

书第 5 章的练习把这个函数重写成了 `Enum.map(items, &transform/1)`——
**能写成 map/filter/reduce 的遍历就不要手写递归**，手写递归留给
高阶函数装不下的形状（下一节的排序就是）。

## 27.3 减治法：从手写答案里发现模式

减治法（decrease and conquer）：先把问题化简到最小情形，**手写**出
答案，再在手写答案里找递归模式。阶乘的起步是五条死子句：

```elixir
def naive_factorial(0), do: 1
def naive_factorial(1), do: 1 * 1
def naive_factorial(2), do: 2 * 1
def naive_factorial(3), do: 3 * 2 * 1
def naive_factorial(4), do: 4 * 3 * 2 * 1
# naive_factorial(5) → FunctionClauseError：到手为止
```

盯住 `3! = 3 * 2 * 1`——右边的 `2 * 1` 正是 `2!`。每个答案都引用
**前一个**的阶乘，把展开式换成函数调用：

```elixir
def factorial(0), do: 1
def factorial(n) when is_integer(n) and n > 0, do: n * factorial(n - 1)
```

两条子句收工。这是发现递归算法的通用套路：**手算几步 → 找「答案
引用前一个答案」的模式 → 把模式写成函数调用**。体递归版每个栈帧都
要留着等乘法（`n * ...`），尾递归版 `factorial_tail/1` 用累加器把
中间结果往下带；十万级阶乘两者答案逐位一致（456,574 位——BEAM 大
整数无上限）：

```text
-- 7. 体递归 vs 尾递归：100_000! 两种写法答案逐位一致 --
  factorial(100_000) == factorial_tail(100_000) => true
  位数 => 456574（BEAM 大整数无上限）
```

选择标准（书 4.3）：迭代上百万次且尾递归不难读——用尾递归；迭代
少、或尾递归把逻辑搅浑——用体递归，别为省内存牺牲可读性。

## 27.4 分治法：归并排序

分治法（divide and conquer）：把问题**切成两个或多个可独立求解的
部分**，最后合并。减治重在「化简」，分治重在「切分」——切出来的
子问题互不干扰，理论上可以并行（第 13 章 Task 概念上的前辈）。

排序是标准案例：列表对半切，切到单元素（天然有序），再按序合并：

```elixir
defp merge_sort([], _cmp), do: []
defp merge_sort([a], _cmp), do: [a]

defp merge_sort(list, cmp) do
  half_size = div(Enum.count(list), 2)          # 奇数长度用 div 向下取整
  {list_a, list_b} = Enum.split(list, half_size)
  merge(merge_sort(list_a, cmp), merge_sort(list_b, cmp), cmp)
end
```

合并两个**已排好**的列表：各自头部取小者下锅——`merge([5,9], [1,4,5])`
的每一步：

```text
merge([5,9], [1,4,5])
[1 | merge([5,9], [4,5])]
[1, 4 | merge([5,9], [5])]
[1, 4, 5 | merge([9], [5])]
[1, 4, 5, 5 | merge([9], [])]
[1, 4, 5, 5, 9]
```

代码里有两个细节：

- **比较器是参数**（`&<=/2` 升序、`&>=/2` 降序），一套 `merge_sort`
  两用——策略注入（第 26 章）的又一次胜利；
- **闭包进不了守卫**：`when cmp.(a, b)` 直接编译错（守卫只允许纯
  函数），所以 merge 里用 `if cmp.(a, b)` 分流——这是新手高频坑。

```text
-- 4. 分治法：对半切、各自排、按序合并（merge [5,9] [1,4,5] → [1,4,5,5,9]）--
  ascending([9,5,1,5,4])  => [1, 4, 5, 5, 9]
  descending([9,5,1,5,4]) => [9, 5, 5, 4, 1]
  与 Enum.sort 一致       => true
```

## 27.5 无界递归：加界限与防环

有界递归的迭代次数看得见；**无界递归**（网络爬虫、目录遍历）连
迭代次数都无法预测——每个页面带来更多链接，每个目录藏着更深的目录。
两个护栏（书 4.4）：

1. **加界限**：深度到达上限就停——「遍历根目录下两级」；
2. **防循环**：符号链接指回祖先目录，跟进去就是无限循环——用
   `File.lstat/1` 区分真目录与链接，链接一律不进。

书里遍历真实文件系统（输出与机器绑定）；本章把目录树搬进内存，做成
**虚拟文件系统**——形状完全一样，输出完全确定：

```elixir
[
  {:dir, "lib", [
    {:file, "app.ex"},
    {:dir, "deep", [{:dir, "deeper", [{:file, "x.ex"}]}]},
    {:file, "util.ex"}
  ]},
  {:file, "README.md"},
  {:symlink, "loop", "lib"}        # 指回 lib 的环
]
```

`walk(fs, max_depth)` 深度优先走一遍，带回三种信息：

```text
-- 5. 无界递归：深度不可预测的目录树——加界限、跳过符号链接 --
  walk(test_fs(), 1) => %{files: 3, symlink_skipped: ["loop -> lib"], visited: ["/lib", "/lib/deep"]}
  walk(test_fs(), 2) => %{files: 3, symlink_skipped: ["loop -> lib"], visited: ["/lib", "/lib/deep", "/lib/deep/deeper"]}
  walk(test_fs(), 3) => %{files: 4, symlink_skipped: ["loop -> lib"], visited: ["/lib", "/lib/deep", "/lib/deep/deeper"]}
```

读法：`max_depth: 2` = 最多下钻两层——`/lib/deep/deeper` 被记录但
不再进入（`x.ex` 数不上，`files` 停在 3）；提到 3 层 `x.ex` 才被数到。
`loop -> lib` 无论深度多少都被跳过——**防环是独立于深度的第二道闸**，
只靠深度限制防不住「环 + 深度恰好没到」的情况。真实代码里对应
`File.lstat/1` 返回 `:symlink` 时不递归。

## 27.6 匿名函数的自递归：me.(me) 技巧

具名函数递归天经地义——编译器认识自己。匿名函数呢？

```elixir
factorial = fn
  0 -> 1
  x when x > 0 -> x * factorial.(x - 1)   # 编译错！
end
# ** (CompileError) undefined function factorial/0
```

定义 `factorial` 时它自己还没绑定完——先有鸡还是先有蛋。破局：把
「函数生成器」作为参数传给自己，**推迟**那次自引用：

```elixir
fact_gen = fn me ->
  fn
    0 -> 1
    x when x > 0 -> x * me.(me).(x - 1)
  end
end

factorial = fact_gen.(fact_gen)
factorial.(5)      # => 120
```

`me.(me)` 先造出真正的阶乘函数，再拿它去算 `x - 1`——这就是 lambda
演算里让递归「靠自己站起来」的最小机制（不动点组合子的雏形）。
看懂即可，**实战别写**：递归用具名函数，需要函数值时 `&factorial/1`
拿引用，两边兼得（`named_factorial/0` 就是这么做的）。

## 27.7 要点小结

```text
  有界递归：迭代次数由参数决定；边界子句永远写在重复子句前面
  守卫挡住没有终止方向的输入（负数）；挡下即 FunctionClauseError
  cons 逐头构建 O(1)，远胜每步 ++；递归转换列表 = 边界子句 + cons 子句
  子图匹配 %{magic: true} 只查一个键，其余不管——跳过型子句的好写法
  减治法：手算几步 → 找「答案引用前一个答案」→ 模式写成函数调用
  分治法：对半切到基本情形，独立求解后按序合并；比较器作参数注入
  无界递归两道闸：深度界限（下钻 N 层即停）+ 防环（符号链接不进）
  匿名函数自递归：me.(me) 自应用可破；实战用具名函数 + & 引用
```

## 27.8 坑位清单

1. **闭包进不了守卫**：`when cmp.(a, b)` 编译错——守卫只允许纯函数
   白名单；比较器分派用 `if`/`case`，或把闭包换成 `&<=/2` 这类
   可进守卫的捕获引用直接写在 `when` 里。
2. **子句顺序即优先级**：跳过型子句（`%{magic: true}`）必须排在通用
   转换子句前面，否则永远匹配不到——边界子句在前、特例在中间、
   通用垫底。
3. **`div/2` 处理奇数长度**：`Enum.count(list) / 2` 得到浮点
   （`1.5`），`Enum.split/2` 不收——切半必须 `div(Enum.count(list), 2)`。
4. **深度界限防不住环**：`max_depth` 只限制「走多远」，遇到「环 +
   深度未到顶」照样无限循环；防环要独立的 visited 集合或跳过符号
   链接。
5. **匿名函数体内引用自身编译不过**（undefined function）：定义时
   自身尚未绑定；`me.(me)` 自应用或改用具名函数。
6. **doctest 期望要跟最终版代码对齐**：书的示例常分两版演进
   （先无跳过、后有跳过），抄中间版的输出当期望值必挂——
   `Dragon's Spear` 在有跳过子句后价格是 100 不是 300。

---

下一章处理函数式世界真正的「脏活」：非纯函数——识别它、隔离它，
用错误单子和 `with` 把不确定性关进笼子。
