defmodule Ex27RecursionDeep do
  @moduledoc """
  第 27 章示例：递归进阶——减治、分治与无界递归。

  对应《函数式编程入门：使用 Elixir》第 4 章「运用递归」的深挖。第 05
  章写过朴素递归与尾递归；本章把递归的**治理术**配齐：

  * **有界递归**——终止子句必须写在重复子句**前面**；
  * **减治法**——把问题逐步化简到基本情形（阶乘）；
  * **分治法**——切成可独立求解的子问题再合并（归并排序）；
  * **无界递归**——加深度界限、跳过符号链接防环；
  * **匿名函数的自递归**——`fn` 里调自己编译不过，自应用技巧可破。

      iex> Ex27RecursionDeep.ascending([9, 5, 1, 5, 4])
      [1, 4, 5, 5, 9]

  """

  # ============================================================
  # 1. 有界递归：终止子句在前
  # ============================================================

  @doc """
  0 加到 n。递归每走一步，剩余迭代少一步——迭代次数由参数决定，这叫
  **有界递归**。两个子句：`0` 是终止（边界）子句，另一个递归。

      iex> Ex27RecursionDeep.up_to(5)
      15
      iex> Ex27RecursionDeep.up_to(10)
      55
      iex> Ex27RecursionDeep.up_to(0)
      0

  展开是 `5 + (4 + (3 + (2 + (1 + 0))))`。边界子句必须写在前面：
  交换位置或删掉它，递归就失去终止条件。
  """
  @spec up_to(non_neg_integer()) :: non_neg_integer()
  def up_to(0), do: 0
  def up_to(n) when is_integer(n) and n > 0, do: n + up_to(n - 1)

  @doc """
  `up_to/1` 的尾递归版（书附录练习答案）：中间结果装进累加器往下传，
  每个子句的最后一个动作是递归调用本身——栈帧复用（第 05 章 TCO）：

      iex> Ex27RecursionDeep.up_to_tail(10)
      55
      iex> Ex27RecursionDeep.up_to_tail(1_000_000)
      500000500000

  百万级也不增长栈——体递归版本到同样深度要吃下整条调用链的内存。
  """
  @spec up_to_tail(non_neg_integer()) :: non_neg_integer()
  def up_to_tail(n), do: sum_up_to(n, 0)
  defp sum_up_to(0, sum), do: sum
  defp sum_up_to(n, sum) when n > 0, do: sum_up_to(n - 1, n + sum)

  # ============================================================
  # 2. 用 cons 构建新列表：魔法商店
  # ============================================================

  @doc """
  书的魔法商店测试数据：`magic: true` 的物品已经施过法：

      iex> Ex27RecursionDeep.test_data() |> Enum.map(& &1.title)
      ["Longsword", "Healing Potion", "Rope", "Dragon's Spear"]

  """
  @spec test_data() :: [map()]
  def test_data do
    [
      %{title: "Longsword", price: 50, magic: false},
      %{title: "Healing Potion", price: 60, magic: true},
      %{title: "Rope", price: 10, magic: false},
      %{title: "Dragon's Spear", price: 100, magic: true}
    ]
  end

  @enchanter_name "Edwin"

  @doc """
  递归转换列表：三个子句——空列表（边界）、已施法（跳过，原文保留）、
  待施法（改名 `Edwin's X`、价格 ×3、标记 `magic: true`）。新列表用
  cons（`[new_item | ...]`）逐头构建，O(1) 且与尾递归调用天然契合：

      iex> items = Ex27RecursionDeep.enchant_for_sale(Ex27RecursionDeep.test_data())
      iex> Enum.map(items, & &1.title)
      ["Edwin's Longsword", "Healing Potion", "Edwin's Rope", "Dragon's Spear"]
      iex> Enum.map(items, & &1.price)
      [150, 60, 30, 100]

  中间的子句用 `%{magic: true}` 做**子图匹配**：map 模式只要求这个键值
  对存在，其余键不管——已施法的物品原样保留（价格 60、100 未变）。
  """
  @spec enchant_for_sale([map()]) :: [map()]
  def enchant_for_sale([]), do: []

  def enchant_for_sale([item = %{magic: true} | rest]) do
    [item | enchant_for_sale(rest)]
  end

  def enchant_for_sale([item | rest]) do
    new_item = %{
      title: "#{@enchanter_name}'s #{item.title}",
      price: item.price * 3,
      magic: true
    }

    [new_item | enchant_for_sale(rest)]
  end

  @doc """
  同一件事交给 `Enum.map/2` + 私有转换函数（书第 5 章练习答案的形态）：
  递归结构被高阶函数收编。**能写成 map/filter/reduce 的遍历就不要手写
  递归**；手写递归留给 map 装不下的形状：

      iex> a = Ex27RecursionDeep.enchant_for_sale(Ex27RecursionDeep.test_data())
      iex> b = Ex27RecursionDeep.enchant_enum(Ex27RecursionDeep.test_data())
      iex> a == b
      true

  """
  @spec enchant_enum([map()]) :: [map()]
  def enchant_enum(items), do: Enum.map(items, &transform/1)

  defp transform(item = %{magic: true}), do: item

  defp transform(item) do
    %{title: "#{@enchanter_name}'s #{item.title}", price: item.price * 3, magic: true}
  end

  # ============================================================
  # 3. 减治法：从手写答案里发现递归模式
  # ============================================================

  @doc """
  减治法第一步：把最小情形**手写**出来。0..4 的阶乘各写一个子句——
  能算 0 到 4，但 5 就崩了：

      iex> Ex27RecursionDeep.naive_factorial(4)
      24
      iex> Ex27RecursionDeep.naive_factorial(5)
      ** (FunctionClauseError) no function clause matching in Ex27RecursionDeep.naive_factorial/1

  """
  @spec naive_factorial(0 | 1 | 2 | 3 | 4) :: pos_integer()
  def naive_factorial(0), do: 1
  def naive_factorial(1), do: 1 * 1
  def naive_factorial(2), do: 2 * 1
  def naive_factorial(3), do: 3 * 2 * 1
  def naive_factorial(4), do: 4 * 3 * 2 * 1

  @doc """
  第二步：在手写答案里找模式——`3! = 3 * 2!`、`2! = 2 * 1!`，每个
  答案都引用**前一个**的阶乘。把展开式换成函数调用，两条子句收工。
  这就是减治法：**化简到基本情形，再让函数调用自己**：

      iex> Ex27RecursionDeep.factorial(5)
      120
      iex> Ex27RecursionDeep.factorial(0)
      1
      iex> Ex27RecursionDeep.factorial(-1)
      ** (FunctionClauseError) no function clause matching in Ex27RecursionDeep.factorial/1

  守卫 `n > 0` 挡住负数——递归没有「负方向」的终止条件。
  """
  @spec factorial(non_neg_integer()) :: pos_integer()
  def factorial(0), do: 1
  def factorial(n) when is_integer(n) and n > 0, do: n * factorial(n - 1)

  @doc """
  尾递归版（累加器），与 `factorial/1` 殊途同归：

      iex> Ex27RecursionDeep.factorial_tail(5)
      120
      iex> Ex27RecursionDeep.factorial_tail(20)
      2432902008176640000

  """
  @spec factorial_tail(non_neg_integer()) :: pos_integer()
  def factorial_tail(n), do: factorial_of(n, 1)
  defp factorial_of(0, acc), do: acc
  defp factorial_of(n, acc) when n > 0, do: factorial_of(n - 1, n * acc)

  # ============================================================
  # 4. 分治法：归并排序
  # ============================================================

  @doc """
  分治法：把列表**对半切**成两个独立的小问题，分别排好，再按序合并。
  单元素列表天然有序——那就是基本情形：

      iex> Ex27RecursionDeep.ascending([9, 5, 1, 5, 4])
      [1, 4, 5, 5, 9]
      iex> Ex27RecursionDeep.ascending([2, 2, 3, 1])
      [1, 2, 2, 3]
      iex> Ex27RecursionDeep.ascending(["c", "d", "a", "c"])
      ["a", "c", "c", "d"]
      iex> Ex27RecursionDeep.ascending([])
      []

  """
  @spec ascending(list()) :: list()
  def ascending(list), do: merge_sort(list, &<=/2)

  @doc """
  降序只要换一个比较器——**减治重在化简，分治重在可独立求解的切分**；
  切出来的两半可以各自并行排（书 4.2.2）：

      iex> Ex27RecursionDeep.descending([9, 5, 1, 5, 4])
      [9, 5, 5, 4, 1]

  """
  @spec descending(list()) :: list()
  def descending(list), do: merge_sort(list, &>=/2)

  @spec merge_sort(list(), (term(), term() -> boolean())) :: list()
  defp merge_sort([], _cmp), do: []
  defp merge_sort([a], _cmp), do: [a]

  defp merge_sort(list, cmp) do
    half_size = div(Enum.count(list), 2)
    {list_a, list_b} = Enum.split(list, half_size)
    merge(merge_sort(list_a, cmp), merge_sort(list_b, cmp), cmp)
  end

  defp merge([], list_b, _cmp), do: list_b
  defp merge(list_a, [], _cmp), do: list_a

  defp merge([head_a | tail_a], list_b = [head_b | _], cmp) do
    # 比较器是闭包，进不了守卫（when 里只能用纯函数），用 if 分流
    if cmp.(head_a, head_b) do
      [head_a | merge(tail_a, list_b, cmp)]
    else
      [head_b | merge([head_a | tail_a], tl(list_b), cmp)]
    end
  end

  # ============================================================
  # 5. 无界递归：加界限、防循环（虚拟文件系统）
  # ============================================================

  @doc """
  目录树的深度**不可预测**——每个目录都可能藏着更深的一层，这就是
  无界递归。书里遍历真实文件系统；这里换成内存里的虚拟 FS，输出确定：

      iex> Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 2)
      %{files: 3, symlink_skipped: ["loop -> lib"], visited: ["/lib", "/lib/deep", "/lib/deep/deeper"]}

  `max_depth: 2` 表示最多**下钻两层**：`/lib/deep/deeper` 被记录但不再
  进入（里面的 `x.ex` 没数上），`{:symlink, "loop", "lib"}` 指回祖先
  目录——跟进去就是无限循环，一律跳过并登记（对应书里用 `File.lstat/1`
  区分真目录与符号链接的做法）。
  """
  @spec walk(list(), non_neg_integer()) :: %{
          visited: [String.t()],
          files: non_neg_integer(),
          symlink_skipped: [String.t()]
        }
  def walk(entries, max_depth) do
    {dirs, files, links} = walk_entries(entries, 0, max_depth, "")
    %{visited: Enum.reverse(dirs), files: files, symlink_skipped: Enum.reverse(links)}
  end

  @doc """
  虚拟文件系统：`lib/deep/deeper` 三层嵌套 + 一个指回 `lib` 的符号
  链接（环）：

      iex> Ex27RecursionDeep.test_fs() |> List.first() |> elem(1)
      "lib"

  """
  @spec test_fs() :: list()
  def test_fs do
    [
      {:dir, "lib",
       [
         {:file, "app.ex"},
         {:dir, "deep", [{:dir, "deeper", [{:file, "x.ex"}]}]},
         {:file, "util.ex"}
       ]},
      {:file, "README.md"},
      {:symlink, "loop", "lib"}
    ]
  end

  defp walk_entries(entries, depth, max_depth, prefix) do
    Enum.reduce(entries, {[], 0, []}, fn entry, acc ->
      walk_entry(entry, depth, max_depth, prefix, acc)
    end)
  end

  defp walk_entry({:file, _name}, _depth, _max_depth, _prefix, {dirs, files, links}) do
    {dirs, files + 1, links}
  end

  defp walk_entry({:dir, name, children}, depth, max_depth, prefix, {dirs, files, links}) do
    path = prefix <> "/" <> name
    dirs = [path | dirs]

    if depth >= max_depth do
      {dirs, files, links}
    else
      walk_entries(children, depth + 1, max_depth, path)
      |> accumulate(dirs, files, links)
    end
  end

  defp walk_entry({:symlink, name, target}, _depth, _max_depth, _prefix, {dirs, files, links}) do
    {dirs, files, ["#{name} -> #{target}" | links]}
  end

  defp accumulate({dirs2, files2, links2}, dirs, files, links) do
    {dirs2 ++ dirs, files + files2, links2 ++ links}
  end

  # ============================================================
  # 6. 匿名函数的自递归：自应用技巧
  # ============================================================

  @doc """
  `fn` 里引用自己？不行——定义时变量还没绑定完：

      factorial = fn
        0 -> 1
        x when x > 0 -> x * factorial.(x - 1)   # 编译错：undefined function factorial/0
      end

  出路是把「函数生成器」作为参数传给自己（`me.(me)` 造出真正的函数）——
  lambda 演算的不动点组合子思路：

      iex> f = Ex27RecursionDeep.make_factorial()
      iex> f.(5)
      120
      iex> f.(10)
      3628800

  实战里别这么写——递归请用具名函数，需要函数值时用 `&` 拿引用
  （见 `named_factorial/0`）。自应用只为理解「函数靠自己站起来的
  最小机制」。
  """
  @spec make_factorial() :: (non_neg_integer() -> pos_integer())
  def make_factorial do
    fact_gen = fn me ->
      fn
        0 -> 1
        x when x > 0 -> x * me.(me).(x - 1)
      end
    end

    fact_gen.(fact_gen)
  end

  @doc """
  具名递归 + `&` 引用——同样能当值传，还读得懂：

      iex> f = Ex27RecursionDeep.named_factorial()
      iex> f.(5)
      120

  """
  @spec named_factorial() :: (non_neg_integer() -> pos_integer())
  def named_factorial, do: &factorial/1
end
