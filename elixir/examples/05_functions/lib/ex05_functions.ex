defmodule Ex05Functions do
  @moduledoc """
  第 05 章示例：函数与递归。

  上一章的模式匹配是「子弹」，本章把它装进函数这把「枪」：

  * **多子句函数**——同一个函数名按参数的形状/类型分派到不同子句；
  * **守卫（guard）**——在模式之外追加「条件」，且守卫里出错不会抛异常，只是该子句落选；
  * **默认参数**——多子句函数带默认值时，必须先声明一个没有函数体的「函数头」；
  * **递归**——Elixir 没有循环，遍历靠函数调用自己；配合累加器写成**尾递归**，
    BEAM 保证尾调用复用栈帧（TCO），深度只受内存限制、栈不增长。

      iex> Ex05Functions.sign(-3.14)
      :negative

      iex> Ex05Functions.sign(0)
      :zero

  """

  # ============================================================
  # 1. 多子句分派 + 守卫
  # ============================================================

  @doc """
  按数值符号分派。多个子句从上到下匹配，第一个对得上的生效。

  守卫用 `when` 附加，`and`/`or`/`not` 可以直接组合；更具体的子句（`0`）
  必须写在宽泛子句前面。

      iex> Ex05Functions.sign(5)
      :positive

      iex> Ex05Functions.sign(0)
      :zero

      iex> Ex05Functions.sign(-3)
      :negative

      iex> Ex05Functions.sign("x")
      :not_a_number

  """
  @spec sign(term()) :: :positive | :zero | :negative | :not_a_number
  def sign(n) when is_number(n) and n > 0, do: :positive
  def sign(0), do: :zero
  def sign(n) when is_number(n), do: :negative
  def sign(_other), do: :not_a_number

  @doc """
  守卫里的 `in`：判断值是否落在区间/列表中。把 HTTP 状态码分段成标签。

      iex> Ex05Functions.http_label(204)
      :success

      iex> Ex05Functions.http_label(404)
      :client_error

      iex> Ex05Functions.http_label(503)
      :server_error

      iex> Ex05Functions.http_label(600)
      :unknown

  """
  @spec http_label(term()) :: :success | :redirect | :client_error | :server_error | :unknown
  def http_label(code) when code in 200..299, do: :success
  def http_label(code) when code in 300..399, do: :redirect
  def http_label(code) when code in 400..499, do: :client_error
  def http_label(code) when code in 500..599, do: :server_error
  def http_label(_other), do: :unknown

  @doc """
  **守卫是安全的**：守卫表达式出错（比如对空列表取 `hd/1`）不会把异常抛出来，
  而是直接判定该子句不匹配，继续尝试下一个子句。

      iex> Ex05Functions.first_is_ok?([:ok, 1])
      true

      iex> Ex05Functions.first_is_ok?([:no])
      false

      iex> Ex05Functions.first_is_ok?([])
      false

  """
  @spec first_is_ok?(term()) :: boolean()
  def first_is_ok?(list) when hd(list) == :ok, do: true
  def first_is_ok?(_other), do: false

  # ============================================================
  # 2. 默认参数与「函数头」
  # ============================================================

  @doc """
  多子句函数中某个参数带默认值时，必须把默认值写在一个**没有函数体的函数头**
  （`def join(a, b, sep \\\\ ", ")` 这行）里，具体子句不再写默认值。

  默认参数让这个函数同时具有 `join/2` 与 `join/3` 两个 arity。

      iex> Ex05Functions.join("a", "b")
      "a, b"

      iex> Ex05Functions.join("a", "b", "-")
      "a-b"

      iex> Ex05Functions.join(1, 2, "-")
      {:non_binary, 1, 2}

  """
  @spec join(term(), term(), binary()) :: binary() | {:non_binary, term(), term()}
  def join(a, b, sep \\ ", ")
  def join(a, b, sep) when is_binary(a) and is_binary(b), do: a <> sep <> b
  def join(a, b, _sep), do: {:non_binary, a, b}

  # ============================================================
  # 3. 递归：先写最朴素的「体递归」
  # ============================================================

  @doc """
  阶乘，最直白的体递归：递归调用的结果还要参与乘法，所以调用栈必须一路保留。

      iex> Ex05Functions.fact(5)
      120

      iex> Ex05Functions.fact(0)
      1

  """
  @spec fact(non_neg_integer()) :: pos_integer()
  def fact(0), do: 1
  def fact(n) when is_integer(n) and n > 0, do: n * fact(n - 1)

  @doc """
  同一个阶乘的尾递归写法：引入累加器，把「中间结果」当参数往下传。
  每个子句的最后一件事就是递归调用本身（其返回值直接返回），BEAM 因此
  可以复用栈帧——递归一百万次也不增长栈。

  用户仍只看到 `fact_tail/1`；两参数版本是 `defp` 私有的。

      iex> Ex05Functions.fact_tail(5)
      120

  """
  @spec fact_tail(non_neg_integer()) :: pos_integer()
  def fact_tail(n), do: fact_tail(n, 1)
  defp fact_tail(0, acc), do: acc
  defp fact_tail(n, acc) when n > 0, do: fact_tail(n - 1, acc * n)

  @doc """
  列表求和（体递归版）。

      iex> Ex05Functions.sum([1, 2, 3, 4])
      10

  """
  @spec sum([number()]) :: number()
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)

  @doc """
  列表求和（尾递归版）：累加器初值 0，每步把 head 加进去。

      iex> Ex05Functions.sum_tail([1, 2, 3, 4])
      10

  """
  @spec sum_tail([number()]) :: number()
  def sum_tail(list), do: sum_tail(list, 0)
  defp sum_tail([], acc), do: acc
  defp sum_tail([head | tail], acc), do: sum_tail(tail, head + acc)

  @doc """
  手写列表长度——每个 cons 单元贡献 1。

      iex> Ex05Functions.my_length([1, 2, 3])
      3

      iex> Ex05Functions.my_length([])
      0

  """
  @spec my_length(list()) :: non_neg_integer()
  def my_length([]), do: 0
  def my_length([_ | tail]), do: 1 + my_length(tail)

  @doc """
  反转列表是累加器的经典用例：每步把头元素 cons 到累加器前面，
  走完时累加器正好是倒序。

      iex> Ex05Functions.my_reverse([1, 2, 3])
      [3, 2, 1]

  """
  @spec my_reverse([term()]) :: [term()]
  def my_reverse(list), do: my_reverse(list, [])
  defp my_reverse([], acc), do: acc
  defp my_reverse([head | tail], acc), do: my_reverse(tail, [head | acc])

  # ============================================================
  # 4. 高阶函数：函数是值，可以当参数、当返回值
  # ============================================================

  @doc """
  把函数 `fun` 对 `x` 连续作用两次。注意调用匿名函数/函数变量要用 `.()`。

      iex> Ex05Functions.twice(fn x -> x + 1 end, 40)
      42

  """
  @spec twice((term() -> term()), term()) :: term()
  def twice(fun, x), do: fun.(fun.(x))

  @doc """
  返回一个函数——闭包捕获了 `n`。这就是「工厂函数」。

      iex> Ex05Functions.adder(10).(5)
      15

  """
  @spec adder(number()) :: (number() -> number())
  def adder(n), do: fn x -> x + n end

  @doc """
  手写 `Enum.map/2`（体递归；cons 保持顺序）。

      iex> Ex05Functions.my_map([1, 2, 3], fn x -> x * 2 end)
      [2, 4, 6]

  """
  @spec my_map([a], (a -> b)) :: [b] when a: var, b: var
  def my_map([], _fun), do: []
  def my_map([head | tail], fun), do: [fun.(head) | my_map(tail, fun)]

  @doc """
  手写 `Enum.filter/2`：断言为真才 cons 进结果。

      iex> Ex05Functions.my_filter([1, 2, 3, 4], fn x -> rem(x, 2) == 0 end)
      [2, 4]

  """
  @spec my_filter([a], (a -> as_boolean(term()))) :: [a] when a: var
  def my_filter([], _pred), do: []

  def my_filter([head | tail], pred) do
    if pred.(head) do
      [head | my_filter(tail, pred)]
    else
      my_filter(tail, pred)
    end
  end

  @doc """
  手写 `Enum.reduce/3`——07 章会看到 Enum 的一切都由 reduce 派生。
  约定 `fun.(元素, 累加器)`；写成尾递归，遍历再长也是恒定栈。

      iex> Ex05Functions.my_reduce([1, 2, 3], 0, fn x, acc -> x + acc end)
      6

  """
  @spec my_reduce([a], b, (a, b -> b)) :: b when a: var, b: var
  def my_reduce([], acc, _fun), do: acc
  def my_reduce([head | tail], acc, fun), do: my_reduce(tail, fun.(head, acc), fun)

  @doc """
  手写 `Enum.take/2`（只支持非负个数）：0、空列表、越界、非法参数各有去向。

      iex> Ex05Functions.my_take([1, 2, 3, 4], 2)
      [1, 2]

      iex> Ex05Functions.my_take([1], 5)
      [1]

      iex> Ex05Functions.my_take([1, 2], -1)
      :error

  """
  @spec my_take(term(), term()) :: list() | :error
  def my_take([], _n), do: []
  def my_take(_list, 0), do: []
  def my_take([head | tail], n) when is_integer(n) and n > 0, do: [head | my_take(tail, n - 1)]
  def my_take(_list, _n), do: :error

  # ============================================================
  # 5. 嵌套递归：结构有多深，递归就有多深
  # ============================================================

  @doc """
  对任意嵌套的数字列表求和。元素本身是列表就递归进去——递归天然处理树状结构，
  不需要手工维护栈。

      iex> Ex05Functions.deep_sum([1, [2, [3]], 4, [5, [6]]])
      21

      iex> Ex05Functions.deep_sum([1, :skip, [2, nil]])
      3

  """
  @spec deep_sum(list()) :: number()
  def deep_sum([]), do: 0
  def deep_sum([head | tail]) when is_list(head), do: deep_sum(head) + deep_sum(tail)
  def deep_sum([head | tail]) when is_number(head), do: head + deep_sum(tail)
  def deep_sum([_other | tail]), do: deep_sum(tail)

  # ============================================================
  # 6. TCO：尾递归（含跨函数的相互尾递归）
  # ============================================================

  @doc """
  纯尾递归「倒计时」：函数体最后一个动作就是调用自己，没有任何等待计算的运算。
  从两百万倒数到 0 也只用一个栈帧。

      iex> Ex05Functions.count_down(3)
      :done

  """
  @spec count_down(non_neg_integer()) :: :done
  def count_down(0), do: :done
  def count_down(n) when n > 0, do: count_down(n - 1)

  @doc """
  `even?/1` 与 `odd?/1` **相互递归**：最后一个动作调用的是另一个函数，
  这同样是尾调用，BEAM 一样做 TCO（不是只有自调用才算）。

      iex> Ex05Functions.even?(10)
      true

      iex> Ex05Functions.odd?(7)
      true

      iex> Ex05Functions.even?(7)
      false

  """
  @spec even?(non_neg_integer()) :: boolean()
  def even?(0), do: true
  def even?(n) when n > 0, do: odd?(n - 1)

  @spec odd?(non_neg_integer()) :: boolean()
  def odd?(0), do: false
  def odd?(n) when n > 0, do: even?(n - 1)
end
