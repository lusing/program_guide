defmodule Ex06ControlFlow do
  @moduledoc """
  第 06 章示例：控制流。

  模式匹配解决了「按形状分派」，但还需要几样东西覆盖其余的决策场景：

  * `case`——对一个值试一组「模式 + 守卫」，本质是函数子句的内联版；
  * `cond`——一组彼此无关的布尔条件，分支不共享同一个值；
  * `if` / `unless`——单条件的便捷宏，真值规则仍是「只有 false/nil 为假」；
  * `with`——把多步 `{:ok, _}` 链式串起来，失败短路、错误集中处理；
  * 作用域——`if`/`case`/`cond`/`with` 的块内赋值**不会泄漏**到块外。

      iex> Ex06ControlFlow.tier(95)
      :A

      iex> Ex06ControlFlow.tier(30)
      :C

  """

  # ============================================================
  # 1. case：模式 + 守卫的内联分派
  # ============================================================

  @doc """
  `case` 对一个值从上到下试分支：先比模式，模式一样再看守卫。
  最后一个分支用 `other` 兜底（等价于 `_`，但能拿到值）；
  一个都不匹配会抛 `CaseError`。

      iex> Ex06ControlFlow.describe({:ok, 1})
      :ok_tuple

      iex> Ex06ControlFlow.describe({:error, :x})
      :error_tuple

      iex> Ex06ControlFlow.describe(42)
      {:integer, 42}

      iex> Ex06ControlFlow.describe([1])
      :non_empty_list

      iex> Ex06ControlFlow.describe("s")
      {:other, "s"}

  """
  @spec describe(term()) ::
          :ok_tuple
          | :error_tuple
          | :non_empty_list
          | :empty_list
          | {:integer, integer()}
          | {:other, term()}
  def describe(value) do
    case value do
      {:ok, _} -> :ok_tuple
      {:error, _} -> :error_tuple
      n when is_integer(n) -> {:integer, n}
      [_ | _] -> :non_empty_list
      [] -> :empty_list
      other -> {:other, other}
    end
  end

  @doc """
  分支守卫的顺序就是判定顺序：90 分以上 A，否则 60 以上 B，依此类推。

      iex> Ex06ControlFlow.tier(95)
      :A

      iex> Ex06ControlFlow.tier(70)
      :B

      iex> Ex06ControlFlow.tier(30)
      :C

      iex> Ex06ControlFlow.tier(-5)
      :invalid

      iex> Ex06ControlFlow.tier(:x)
      :invalid

  """
  @spec tier(term()) :: :A | :B | :C | :invalid
  def tier(score) do
    case score do
      n when is_number(n) and n >= 90 -> :A
      n when is_number(n) and n >= 60 -> :B
      n when is_number(n) and n >= 0 -> :C
      _ -> :invalid
    end
  end

  # ============================================================
  # 2. cond：一组互不相干的布尔条件
  # ============================================================

  @doc """
  `cond` 列出若干条件，第一个为真的分支胜出，**每个分支不共享同一个值**——
  这是它与 `case` 的分工：条件彼此无关、或要做复合布尔判断时用 cond。
  最后写 `true ->` 兜底，否则一个都不中会抛 `CondClauseError`。

      iex> Ex06ControlFlow.fizzbuzz(15)
      "fizzbuzz"

      iex> Ex06ControlFlow.fizzbuzz(9)
      "fizz"

      iex> Ex06ControlFlow.fizzbuzz(10)
      "buzz"

      iex> Ex06ControlFlow.fizzbuzz(7)
      7

  """
  @spec fizzbuzz(integer()) :: binary() | integer()
  def fizzbuzz(n) do
    cond do
      rem(n, 15) == 0 -> "fizzbuzz"
      rem(n, 3) == 0 -> "fizz"
      rem(n, 5) == 0 -> "buzz"
      true -> n
    end
  end

  @doc """
  同样的 cond，按温度分段——注意条件必须按最窄到最宽排序。

      iex> Ex06ControlFlow.classify_temp(-5)
      :freezing

      iex> Ex06ControlFlow.classify_temp(10)
      :cold

      iex> Ex06ControlFlow.classify_temp(20)
      :mild

      iex> Ex06ControlFlow.classify_temp(35)
      :hot

  """
  @spec classify_temp(number()) :: :freezing | :cold | :mild | :hot
  def classify_temp(t) do
    cond do
      t < 0 -> :freezing
      t < 15 -> :cold
      t < 28 -> :mild
      true -> :hot
    end
  end

  # ============================================================
  # 3. if / unless：宏，且都是「表达式」
  # ============================================================

  @doc """
  `if` 是宏而不是语言关键字，和一切表达式一样**有返回值**——不需要的话也可以
  直接整个 `if` 赋值给变量。真值规则沿用 03 章：只有 `false` 和 `nil` 为假。

      iex> Ex06ControlFlow.greeting("Ada")
      "hello Ada"

      iex> Ex06ControlFlow.greeting("")
      "hello stranger"

  """
  @spec greeting(term()) :: binary()
  def greeting(name) do
    if is_binary(name) and name != "" do
      "hello #{name}"
    else
      "hello stranger"
    end
  end

  @doc """
  单行形式用 `do:`/`else:` 关键字列表；合法正整数原样返回，其余给 nil。

      iex> Ex06ControlFlow.positive_only(5)
      5

      iex> Ex06ControlFlow.positive_only(-1)
      nil

      iex> Ex06ControlFlow.positive_only(:x)
      nil

  """
  @spec positive_only(term()) :: integer() | nil
  def positive_only(n), do: if(is_integer(n) and n > 0, do: n, else: nil)

  @doc """
  `unless` 是 `if` 的反面，同样遵循「只有 false/nil 为假」——
  所以 `0`、`""`、`[]` 都走进 truthy 分支。

      iex> Ex06ControlFlow.truthy_label(0)
      :truthy

      iex> Ex06ControlFlow.truthy_label(nil)
      :falsy

      iex> Ex06ControlFlow.truthy_label(false)
      :falsy

  """
  @spec truthy_label(term()) :: :truthy | :falsy
  def truthy_label(x), do: unless(x in [nil, false], do: :truthy, else: :falsy)

  # ============================================================
  # 4. with：{:ok,_} 流水线
  # ============================================================

  @doc """
  注册用户的三步流水线。`with` 用 `<-` 串起若干「成功形状」的匹配：
  全成功就执行 `do` 块；任何一步对不上就**短路**，失败值交给 `else`
  里的模式集中处理（没有 else 时，失败值直接成为整个 with 的返回值）。

      iex> Ex06ControlFlow.register(%{name: "  Ada  "})
      {:ok, %{id: :deterministic_id, name: "Ada"}}

      iex> Ex06ControlFlow.register(%{name: ""})
      {:error, :invalid_name}

      iex> Ex06ControlFlow.register(%{name: "   "})
      {:error, {:unexpected, :blank_after_trim}}

      iex> Ex06ControlFlow.register(%{name: "this-name-is-way-too-long"})
      {:error, :name_too_long}

      iex> Ex06ControlFlow.register(:not_a_map)
      {:error, :invalid_name}

  """
  @spec register(term()) ::
          {:ok, %{id: :deterministic_id, name: binary()}}
          | {:error, atom() | {:unexpected, term()}}
  def register(params) do
    with {:ok, params} <- validate(params),
         {:ok, user} <- normalize(params),
         {:ok, saved} <- save(user) do
      {:ok, saved}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unexpected, other}}
    end
  end

  defp validate(params) do
    if is_map(params) and is_binary(params[:name]) and params[:name] != "" do
      {:ok, params}
    else
      {:error, :invalid_name}
    end
  end

  # 注意这一步的失败形状是裸原子 :blank_after_trim，不是 {:error, _}——
  # with 的 else 里因此既要有 {:error, reason} 分支，也要有 other 兜底。
  defp normalize(params) do
    trimmed = Map.update!(params, :name, &String.trim/1)

    if trimmed.name != "" do
      {:ok, trimmed}
    else
      :blank_after_trim
    end
  end

  defp save(%{name: name}) do
    if String.length(name) < 20 do
      {:ok, %{id: :deterministic_id, name: name}}
    else
      {:error, :name_too_long}
    end
  end

  @doc """
  不带 `else` 的 with：第一步失败时，**失败的那个值直接返回**，do 块不执行。

      iex> Ex06ControlFlow.chain({:ok, 1}, {:ok, 2})
      3

      iex> Ex06ControlFlow.chain({:error, :x}, {:ok, 2})
      {:error, :x}

      iex> Ex06ControlFlow.chain({:ok, 1}, :oops)
      :oops

  """
  @spec chain(term(), term()) :: term()
  def chain(a, b) do
    with {:ok, x} <- a,
         {:ok, y} <- b do
      x + y
    end
  end

  # ============================================================
  # 5. 作用域：块内赋值不外泄
  # ============================================================

  @doc """
  `if` 块内的重绑定只在块内有效，出了块，外层的 `x` 还是旧值。
  传 10 进来，块内变成 11，函数最终返回的仍是 10。

      iex> Ex06ControlFlow.rebind_inside(10)
      10

  """
  @spec rebind_inside(number()) :: number()
  def rebind_inside(x) do
    if true do
      x = x + 1
      x
    else
      :never
    end

    x
  end
end
