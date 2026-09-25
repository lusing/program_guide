defmodule Ex25Thinking.MySet do
  @moduledoc """
  不允许重复元素的集合——第 25 章的「状态显式流动」示例。

  面向对象版本把状态藏在对象里，方法结果取决于调用时刻的内部状态；
  这个版本没有隐藏状态：`push` 接收集合、返回新集合，所有状态变化
  都发生在返回值里。
  """

  defstruct items: []

  @type t :: %__MODULE__{items: [term()]}

  @doc """
  添加元素，返回**新的**集合；重复元素不加（幂等）：

      iex> set = %Ex25Thinking.MySet{}
      iex> set = Ex25Thinking.MySet.push(set, "apple")
      iex> set = Ex25Thinking.MySet.push(set, "pie")
      iex> Ex25Thinking.MySet.push(set, "apple")
      %Ex25Thinking.MySet{items: ["apple", "pie"]}

  """
  @spec push(t(), term()) :: t()
  def push(set = %{items: items}, item) do
    if Enum.member?(items, item) do
      set
    else
      %{set | items: items ++ [item]}
    end
  end

  @doc """
  成员查询——同样是无状态的函数：

      iex> set = %Ex25Thinking.MySet{} |> Ex25Thinking.MySet.push("apple")
      iex> Ex25Thinking.MySet.member?(set, "apple")
      true
      iex> Ex25Thinking.MySet.member?(set, "pie")
      false

  """
  @spec member?(t(), term()) :: boolean()
  def member?(%{items: items}, item), do: Enum.member?(items, item)
end

defmodule Ex25Thinking do
  @moduledoc """
  第 25 章示例：函数式思维。

  对应《函数式编程入门：使用 Elixir》第 1 章「函数思想」。命令式语言
  靠共享可变状态 + 锁来并发，函数式换了一条路：

  * **不可变数据**——对值的任何操作都返回新值，原值纹丝不动；列表的
    尾部在新旧列表之间共享内存（结构共享），不可变不等于全量复制；
  * **纯函数**——同样的输入永远得到同样的输出，除了返回值不产生
    任何影响；调用可以被它的结果原样替换（引用透明）；
  * **声明式**——描述「数据必须长什么样」，而不是「如何一步步改它」。

      iex> Ex25Thinking.add2(40)
      42

  """

  # ============================================================
  # 1. 不可变数据：操作产生新值，原值不动
  # ============================================================

  @doc """
  「删掉最后一个元素」不修改原列表，而是返回一个新列表：

      iex> list = [1, 2, 3, 4]
      iex> Ex25Thinking.without_last(list)
      [1, 2, 3]
      iex> list
      [1, 2, 3, 4]

  原值纹丝不动——命令式语言里 `list.pop()` 那种就地修改在这里不存在，
  并发读取同一个值因此永远是安全的，不需要锁。
  """
  @spec without_last(list()) :: list()
  def without_last(list), do: List.delete_at(list, -1)

  @doc """
  追加同样产生新值（`++` 每次都构建新列表）：

      iex> list = [1, 2, 3, 4]
      iex> Ex25Thinking.append(list, 5)
      [1, 2, 3, 4, 5]
      iex> list
      [1, 2, 3, 4]

  """
  @spec append(list(), term()) :: list()
  def append(list, item), do: list ++ [item]

  @doc """
  不可变 ≠ 每次全量复制。列表是单向链表，cons（`[head | tail]`）出一个
  新列表时，新列表的**尾部就是旧列表本身**——同一个内存对象，O(1)、
  零复制。`:erts_debug.same/2` 判断两个项是否为同一个内存对象：

      iex> base = Ex25Thinking.runtime_list()
      iex> newer = Ex25Thinking.cons_ahead(base)
      iex> :erts_debug.same(tl(newer), base)
      true

  这就是持久化数据结构（persistent data structure）的**结构共享**：
  新旧列表共用同一条尾巴，不可变的代价远比「每次复制一份」小。

  注意 `base` 必须是运行时构建的列表：字面量住在 BEAM 的只读字面量区，
  `tl/1` 从字面量里取子项会得到与模式匹配不同的指针（实测坑，见
  CHEATSheet）。`runtime_list/0` 用 `Enum.to_list/1` 现场构建。
  """
  @spec cons_ahead(nonempty_list(any())) :: nonempty_list(any())
  def cons_ahead(base), do: [0 | base]

  @doc """
  反面对照：`++` 复制左操作数——拼接结果的单元格全是新造的，与旧列表
  **不共享**（`tl/1` 取出的尾部结构相等、指针不同）：

      iex> base = Ex25Thinking.runtime_list()
      iex> copy = Ex25Thinking.append_copy(base)
      iex> Enum.take(copy, 3) == base
      true
      iex> :erts_debug.same(tl(copy), tl(base))
      false

  cons 是 O(1) 且共享；`base ++ [x]` 是 O(n) 且复制。往列表头部加元素
  永远用 cons（第 27 章递归构建列表全靠它）。另有一个实测坑：**字面量
  作前缀**的 `[0] ++ base` 会被编译器重写成 `[0 | base]`——那一份就
  共享了，别拿它证明「++ 复制」。
  """
  @spec append_copy(nonempty_list(any())) :: nonempty_list(any())
  def append_copy(base), do: base ++ [4]

  @doc """
  运行时构建的列表。字面量（如 `[1, 2, 3]`）住在 BEAM 的只读字面量区，
  从中取子项的指针行为与运行时数据不同；做结构共享实验要用它：

      iex> Ex25Thinking.runtime_list()
      [1, 2, 3]

  """
  @spec runtime_list() :: [integer()]
  def runtime_list, do: Enum.to_list(1..3)

  # ============================================================
  # 2. 纯函数：同参同果、无副作用、引用透明
  # ============================================================

  @doc """
  最简单的纯函数：结果只由参数决定。调用多少次都一样：

      iex> Ex25Thinking.add2(2)
      4
      iex> Ex25Thinking.add2(2)
      4

  「引用透明」：把 `Ex25Thinking.add2(2)` 原样换成 `4`，程序行为
  不变——这是纯函数最实用的性质（重构、缓存、并行都靠它）。
  """
  @spec add2(number()) :: number()
  def add2(n), do: n + 2

  @doc """
  纯函数也可能出错——但错误同样**可预测**：坏输入永远得到同一个异常
  （给 `nil` 永远是 ArithmeticError，测试里用 `apply/3` 验证——1.20 的
  类型检查器会对手写 `tax(nil, 8)` 字面量报「类型不兼容」告警）。
  对比 `IO.gets/1`、`DateTime.utc_now/0` 这类非纯函数：参数固定，
  结果却每次不同（见第 28 章）。

      iex> Ex25Thinking.tax(100, 8)
      8.0

  """
  @spec tax(number(), number()) :: float()
  def tax(price, rate), do: price * rate / 100

  # ============================================================
  # 3. 状态显式流动：函数式的 Set
  # ============================================================

  @doc """
  `MySet`（见下方嵌套模块）的驱动流水线：状态不在对象里、不在全局里，
  而是作为参数与返回值在函数之间**显式流动**，每一步的输入输出摆在
  明面上——没有「方法结果取决于调用时刻内部状态」这回事：

      iex> Ex25Thinking.myset_demo()
      ["apple", "pie"]

  而中途的每一步旧值都完好无损（见 `Ex25Thinking.MySet.push/2`）。
  """
  @spec myset_demo() :: [String.t()]
  def myset_demo do
    set0 = %Ex25Thinking.MySet{}

    set0
    |> Ex25Thinking.MySet.push("apple")
    |> Ex25Thinking.MySet.push("pie")
    |> then(fn set -> set.items end)
  end

  # ============================================================
  # 4. 声明式：同一个问题的三种写法
  # ============================================================

  @doc """
  把字符串列表全部大写。命令式语言要写 for 循环 + 可变累加器 +
  下标递增；函数式的递归版本只用两个子句就**描述了结果的样子**：
  空列表的大写还是空列表；非空列表的大写是「头元素大写拼上其余
  元素大写的结果」。

      iex> Ex25Thinking.upcase_rec(["dogs", "hot dogs", "bananas"])
      ["DOGS", "HOT DOGS", "BANANAS"]

      iex> Ex25Thinking.upcase_rec([])
      []

  说「要什么」，不说「怎么改」——这就是声明式。
  """
  @spec upcase_rec([String.t()]) :: [String.t()]
  def upcase_rec([]), do: []
  def upcase_rec([first | rest]), do: [String.upcase(first) | upcase_rec(rest)]

  @doc """
  同一件事的第二种声明式写法：把「大写」这个变换本身
  （`&String.upcase/1`）作为值传给 `Enum.map/2`。函数是积木，
  可以在函数之间传递：

      iex> Ex25Thinking.upcase_map(["dogs", "hot dogs", "bananas"])
      ["DOGS", "HOT DOGS", "BANANAS"]

  """
  @spec upcase_map([String.t()]) :: [String.t()]
  def upcase_map(list), do: Enum.map(list, &String.upcase/1)

  @doc """
  值的转换链条。嵌套调用要从最里面往外读；管道 `|>` 让数据从上往下
  流，一眼看清「标题 → 单词列表 → 首字母大写列表 → 标题字符串」：

      iex> Ex25Thinking.capitalize_words("the dark tower")
      "The Dark Tower"

      iex> Ex25Thinking.capitalize_words_nested("the dark tower")
      "The Dark Tower"

  两者完全等价——`a |> g |> f` 就是 `f(g(a))`。
  """
  @spec capitalize_words(String.t()) :: String.t()
  def capitalize_words(title) do
    title
    |> String.split()
    |> capitalize_all()
    |> join_with_whitespace()
  end

  @spec capitalize_words_nested(String.t()) :: String.t()
  def capitalize_words_nested(title),
    do: join_with_whitespace(capitalize_all(String.split(title)))

  defp capitalize_all(words), do: Enum.map(words, &String.capitalize/1)
  defp join_with_whitespace(words), do: Enum.join(words, " ")
end
