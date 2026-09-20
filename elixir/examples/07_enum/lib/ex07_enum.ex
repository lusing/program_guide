defmodule Ex07Enum do
  @moduledoc """
  第 07 章示例：Enum 与管道。

  两条主线：

  1. **`Enum.reduce/3` 是万物之源**——`my_map/2`、`my_filter/2`、`my_take/2`
     用 reduce 手写实现对应的 Enum 函数，测试里对一批输入断言与标准版逐一等价；
  2. **管道 `|>` 是纯语法糖**——`pipe_proof/0` 用 `quote` + `Macro.expand` 把管道
     表达式展开成嵌套调用，实证「`a |> f(b)` 与 `f(a, b)` 在运行时是同一棵树」。

  此外还实证了两件容易想当然的事：Stream 的惰性到底省了什么
  （`lazy_vs_eager/1`，用求值次数说话，不用墙钟时间），以及排序稳定性与
  比较函数「严格与否」的关系（`sort_stability/0`）。

  """

  # ============================================================
  # 1. Enumerable：谁实现了这个协议
  # ============================================================

  @doc """
  探测一个 term 是否为 Enumerable：是实现模块名，还是 `nil`。

  注意 tuple 与二进制**不是** Enumerable——这不是疏忽，是设计决定：
  元组是定长索引结构，二进制的最小遍历单位（字节还是码点？）有歧义。

      iex> Ex07Enum.enumerable_impl([1, 2])
      "Enumerable.List"

      iex> Ex07Enum.enumerable_impl(%{a: 1})
      "Enumerable.Map"

      iex> Ex07Enum.enumerable_impl({1, 2})
      nil

      iex> Ex07Enum.enumerable_impl("abc")
      nil

  """
  @spec enumerable_impl(term()) :: String.t() | nil
  def enumerable_impl(term) do
    case Enumerable.impl_for(term) do
      nil -> nil
      impl -> inspect(impl)
    end
  end

  # ============================================================
  # 2. reduce 是万物之源：手写 map / filter / take
  # ============================================================

  @doc """
  用 `Enum.reduce/3` 手写 `Enum.map/2`。

  惯例是「前插 + 最后 reverse」：对 cons 列表，前插是 O(1)，后插是 O(n)，
  所以累加时永远前插，收尾一次性反转（reverse 也是 O(n)，但常数极小）。

      iex> Ex07Enum.my_map([1, 2, 3], &(&1 * 2))
      [2, 4, 6]

      iex> Ex07Enum.my_map([], &(&1 * 2))
      []

  """
  @spec my_map(Enumerable.t(), (term() -> term())) :: list()
  def my_map(enum, fun) do
    enum
    |> Enum.reduce([], fn x, acc -> [fun.(x) | acc] end)
    |> Enum.reverse()
  end

  @doc """
  用 `Enum.reduce/3` 手写 `Enum.filter/2`。

      iex> Ex07Enum.my_filter([1, 2, 3, 4], &(rem(&1, 2) == 0))
      [2, 4]

      iex> Ex07Enum.my_filter([1, 3], &(rem(&1, 2) == 0))
      []

  """
  @spec my_filter(Enumerable.t(), (term() -> as_boolean(term()))) :: list()
  def my_filter(enum, fun) do
    enum
    |> Enum.reduce([], fn x, acc -> if fun.(x), do: [x | acc], else: acc end)
    |> Enum.reverse()
  end

  @doc """
  用 `Enum.reduce_while/3` 手写 `Enum.take/2`（n >= 0 的情形）。

  `reduce_while` 比 `reduce` 多一个能力：回调返回 `{:halt, acc}` 可以**提前
  收工**，不必遍历完整个 Enumerable。`take` 这种「拿够就走」的函数必须靠它，
  否则对无限流（`Stream.repeatedly/1`）就永远停不下来。

      iex> Ex07Enum.my_take([1, 2, 3, 4, 5], 2)
      [1, 2]

      iex> Ex07Enum.my_take([1, 2], 5)
      [1, 2]

      iex> Ex07Enum.my_take([1, 2, 3], 0)
      []

  """
  @spec my_take(Enumerable.t(), non_neg_integer()) :: list()
  def my_take(enum, n) when n >= 0 do
    {taken, _remaining} =
      Enum.reduce_while(enum, {[], n}, fn
        _x, {acc, 0} -> {:halt, {acc, 0}}
        x, {acc, k} -> {:cont, {[x | acc], k - 1}}
      end)

    Enum.reverse(taken)
  end

  @doc """
  对一批确定性输入（列表、Range、map），断言手写版与标准版等价。

  返回值是 `{对比过的函数个数, 全部等价?}`。map 输入也安全：同一个 map 值
  在同一次运行里被两个函数各遍历一次，迭代顺序一致（尽管**跨运行不保证**，
  所以这里只断言等价性、绝不打印 map 的遍历结果——见 `frequencies_sorted/1`）。

      iex> Ex07Enum.equivalence_check()
      {3, true}

  """
  @spec equivalence_check() :: {non_neg_integer(), boolean()}
  def equivalence_check do
    inputs = [
      [],
      [1],
      [1, 2, 3, 4, 5],
      1..10,
      %{a: 1, b: 2}
    ]

    map_ok =
      Enum.all?(inputs, fn input ->
        my_map(input, &inspect/1) == Enum.map(input, &inspect/1)
      end)

    filter_ok =
      Enum.all?(inputs, fn input ->
        pred = fn x -> rem(:erlang.phash2(x), 2) == 0 end
        my_filter(input, pred) |> Enum.sort() == Enum.filter(input, pred) |> Enum.sort()
      end)

    take_ok =
      Enum.all?(inputs, fn input ->
        Enum.all?(0..7, fn n ->
          my_take(input, n) |> Enum.sort() == Enum.take(input, n) |> Enum.sort()
        end)
      end)

    {3, map_ok and filter_ok and take_ok}
  end

  # ============================================================
  # 3. Enum 立即求值 vs Stream 惰性：用求值次数实证
  # ============================================================

  @doc """
  对 `1..n` 做「map 之后 take 3」，分别统计 Stream 形态与 Enum 形态下
  映射函数**真正被求值的次数**。

  Stream 只被拉取了 3 个元素，函数就只求值 3 次；Enum.map 则老老实实把
  n 个元素全算完再取前 3 个。这就是「惰性」的全部含义——**不是快慢问题，
  是求值次数与中间列表的问题**。

      iex> Ex07Enum.lazy_vs_eager(100)
      {[2, 4, 6], 3, [2, 4, 6], 100}

  """
  @spec lazy_vs_eager(pos_integer()) ::
          {[integer()], non_neg_integer(), [integer()], non_neg_integer()}
  def lazy_vs_eager(n) do
    {:ok, counter} = Agent.start(fn -> 0 end)

    counted_double = fn x ->
      Agent.update(counter, &(&1 + 1))
      x * 2
    end

    stream_result = 1..n |> Stream.map(counted_double) |> Enum.take(3)
    stream_calls = Agent.get(counter, & &1)
    :ok = Agent.update(counter, fn _ -> 0 end)
    enum_result = 1..n |> Enum.map(counted_double) |> Enum.take(3)
    enum_calls = Agent.get(counter, & &1)
    Agent.stop(counter)

    {stream_result, stream_calls, enum_result, enum_calls}
  end

  # ============================================================
  # 4. 管道的本质：宏展开实证
  # ============================================================

  @doc """
  把管道 AST 完整展开成嵌套调用：`Macro.prewalk/2` + `Macro.expand/2`。

  返回 `{展开前, 展开后}` 的源码字符串。两棵 AST 编译出的字节码行为一致——
  管道不产生任何运行时开销，它甚至不存在于运行时：编译期就被改写掉了。

      iex> Ex07Enum.pipe_proof()
      {"a |> b() |> c(1)", "c(b(a), 1)"}

  """
  @spec pipe_proof() :: {String.t(), String.t()}
  def pipe_proof do
    ast = quote do: a |> b() |> c(1)
    expanded = Macro.prewalk(ast, &Macro.expand(&1, __ENV__))
    {Macro.to_string(ast), Macro.to_string(expanded)}
  end

  @doc """
  嵌套调用与管道写法**完全等价**（同一段计算，两种写法，同一结果）。

      iex> Ex07Enum.nested_style("  Hello  ")
      "<hello>"

      iex> Ex07Enum.pipe_style("  Hello  ")
      "<hello>"

      iex> Ex07Enum.nested_style("  Hello  ") == Ex07Enum.pipe_style("  Hello  ")
      true

  """
  @spec nested_style(String.t()) :: String.t()
  def nested_style(s), do: "<" <> String.downcase(String.trim(s)) <> ">"

  @spec pipe_style(String.t()) :: String.t()
  def pipe_style(s) do
    s
    |> String.trim()
    |> String.downcase()
    |> then(&("<" <> &1 <> ">"))
  end

  # ============================================================
  # 5. 排序：稳定性与比较器
  # ============================================================

  @doc """
  排序稳定性实测：对 `[{1, :a}, {0, :b}, {1, :c}, {0, :d}]` 按第一个元素排序，
  用四种比较函数写法。

  反直觉的结论：**`<=` / `>=`（非严格）才稳定；`<` / `>`（严格）反而会把相等
  元素的相对顺序调换**。原因在归并排序的合并步：左右两半各取一个元素比较时，
  `fun.(left, right)` 为 true 才取左边（保序）。严格比较在「相等」时返回
  false，于是取了右边——顺序就翻了。

      iex> Ex07Enum.sort_stability()
      [
        asc_non_strict: [{0, :b}, {0, :d}, {1, :a}, {1, :c}],
        asc_strict: [{0, :d}, {0, :b}, {1, :c}, {1, :a}],
        desc_non_strict: [{1, :a}, {1, :c}, {0, :b}, {0, :d}],
        desc_strict: [{1, :c}, {1, :a}, {0, :d}, {0, :b}]
      ]

  """
  @spec sort_stability() :: keyword()
  def sort_stability do
    pairs = [{1, :a}, {0, :b}, {1, :c}, {0, :d}]
    key = &elem(&1, 0)

    [
      asc_non_strict: Enum.sort(pairs, fn a, b -> key.(a) <= key.(b) end),
      asc_strict: Enum.sort(pairs, fn a, b -> key.(a) < key.(b) end),
      desc_non_strict: Enum.sort(pairs, fn a, b -> key.(a) >= key.(b) end),
      desc_strict: Enum.sort(pairs, fn a, b -> key.(a) > key.(b) end)
    ]
  end

  @doc """
  返回 `:lt / :eq / :gt` 的比较器（如 `Date.compare/2`）可以直接交给
  `Enum.sort/2`，也可以配 `{:asc, Mod}` / `{:desc, Mod}` 指定方向。

      iex> Ex07Enum.sort_dates()
      [~D[2024-01-01], ~D[2024-03-15], ~D[2024-12-31]]

      iex> Ex07Enum.sort_dates_desc()
      [~D[2024-12-31], ~D[2024-03-15], ~D[2024-01-01]]

  """
  @spec sort_dates() :: [Date.t()]
  def sort_dates do
    Enum.sort([~D[2024-12-31], ~D[2024-01-01], ~D[2024-03-15]], Date)
  end

  @spec sort_dates_desc() :: [Date.t()]
  def sort_dates_desc do
    Enum.sort([~D[2024-12-31], ~D[2024-01-01], ~D[2024-03-15]], {:desc, Date})
  end

  # ============================================================
  # 6. 不确定性函数的正确用法：只断言性质
  # ============================================================

  @doc """
  `Enum.shuffle/1` 与 `Enum.random/1` 的结果每次运行都可能不同，所以
  示例里**只断言性质**：洗牌是原列表的一个排列（排序后相等）；随机的
  结果一定是成员。

      iex> Ex07Enum.shuffle_is_permutation?(1..5)
      true

      iex> Ex07Enum.random_is_member?(1..5)
      true

  """
  @spec shuffle_is_permutation?(Enumerable.t()) :: boolean()
  def shuffle_is_permutation?(enum) do
    original = Enum.sort(enum)
    Enum.sort(Enum.shuffle(original)) == original
  end

  @spec random_is_member?(Enumerable.t()) :: boolean()
  def random_is_member?(enum) do
    Enum.member?(enum, Enum.random(enum))
  end

  # ============================================================
  # 7. for 推导式
  # ============================================================

  @doc """
  多 generator 的笛卡尔积，按**声明顺序**嵌套（左边的变化最慢）。

      iex> Ex07Enum.cartesian()
      [{:spade, 1}, {:spade, 2}, {:heart, 1}, {:heart, 2}]

  """
  @spec cartesian() :: [{atom(), pos_integer()}]
  def cartesian do
    for suit <- [:spade, :heart], rank <- [1, 2], do: {suit, rank}
  end

  @doc """
  `uniq: true` 去重、`into:` 换收集容器、`:reduce` 直接归约。

      iex> Ex07Enum.comprehension_uniq()
      [1, 2, 3]

      iex> Ex07Enum.comprehension_into_map()
      %{"a" => 1, "bb" => 2}

      iex> Ex07Enum.comprehension_reduce()
      10

  """
  @spec comprehension_uniq() :: [pos_integer()]
  def comprehension_uniq do
    for x <- [1, 1, 2, 2, 3], uniq: true, do: x
  end

  @spec comprehension_into_map() :: %{String.t() => pos_integer()}
  def comprehension_into_map do
    for {k, v} <- [{"a", 1}, {"bb", 2}], into: %{}, do: {k, v}
  end

  @spec comprehension_reduce() :: pos_integer()
  def comprehension_reduce do
    for x <- [1, 2, 3, 4], reduce: 0, do: (acc -> acc + x)
  end

  @doc """
  二进制推导式：生成器写成 `<<pattern <- binary>>`，可以指定单位
  （这里按 4-bit 半字节切）。

  注意分隔符细节：内层二进制自己的 `>>` 和外层生成器的 `>>` 连着写成
  `>>>>` 会让 tokenizer 断错词（MismatchedDelimiterError）。手写时留一个
  空格，`mix format` 会自动改写成带括号的 `<<(pattern <- <<...>>)>>`
  （坑位清单第 7 条）。

      iex> Ex07Enum.binary_comprehension()
      [13, 14, 10, 13, 11, 14, 14, 15]

  """
  @spec binary_comprehension() :: [0..15]
  def binary_comprehension do
    for <<(nibble::4 <- <<0xDE, 0xAD, 0xBE, 0xEF>>)>>, do: nibble
  end

  # ============================================================
  # 8. 性能：多次遍历 vs 单次 reduce
  # ============================================================

  @doc """
  三段管道（map → filter → sum，三次遍历 + 两个中间列表）。

      iex> Ex07Enum.multi_pass(1..12)
      60

  """
  @spec multi_pass(Enumerable.t()) :: number()
  def multi_pass(enum) do
    enum
    |> Enum.map(&(&1 * 2))
    |> Enum.filter(&(rem(&1, 3) == 0))
    |> Enum.sum()
  end

  @doc """
  单次 reduce（一次遍历、零中间列表），结果必须与 `multi_pass/1` 相同
  （测试里对 1..30 断言过）。

      iex> Ex07Enum.single_pass(1..12)
      60

  """
  @spec single_pass(Enumerable.t()) :: number()
  def single_pass(enum) do
    Enum.reduce(enum, 0, fn x, acc ->
      y = x * 2
      if rem(y, 3) == 0, do: acc + y, else: acc
    end)
  end

  # ============================================================
  # 9. map 遍历顺序不保证：打印前先排序
  # ============================================================

  @doc """
  `Enum.frequencies/1` 返回 map，而 **map 的遍历顺序不属于语言承诺**。
  所以任何要打印/比较的 map 结果，一律先 `Enum.sort/1` 变成有序键值对。
  这也是 run-all.sh 第 5 层（单调度器重跑、逐字节比对）能通过的纪律来源。

      iex> Ex07Enum.frequencies_sorted(~w(apple fig apple banana apple fig))
      [{"apple", 3}, {"banana", 1}, {"fig", 2}]

  """
  @spec frequencies_sorted(Enumerable.t()) :: [{term(), pos_integer()}]
  def frequencies_sorted(enum) do
    enum
    |> Enum.frequencies()
    |> Enum.sort()
  end

  @doc """
  `Enum.group_by/3` 同理：分组后对键排序再输出。

      iex> Ex07Enum.group_by_rem_sorted(1..10, 3)
      [{0, [3, 6, 9]}, {1, [1, 4, 7, 10]}, {2, [2, 5, 8]}]

  """
  @spec group_by_rem_sorted(Enumerable.t(), pos_integer()) :: [{integer(), [integer()]}]
  def group_by_rem_sorted(enum, divisor) do
    enum
    |> Enum.group_by(&rem(&1, divisor))
    |> Enum.sort()
  end
end
