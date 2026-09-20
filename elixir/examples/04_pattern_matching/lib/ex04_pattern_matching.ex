defmodule Ex04PatternMatching do
  @moduledoc """
  第 04 章示例：模式匹配。

  Elixir 里的 `=` 不是赋值，而是**模式匹配操作符**：左边是模式（pattern），右边是值，
  运行时尝试让两者「对上」——对得上就把模式里的变量绑定到对应部分，对不上直接抛
  `MatchError`。本章把这套机制的每种形状做成可断言的函数：

  * 元组解构（尤其是 `{:ok, value}` / `{:error, reason}`）
  * 列表的头尾、精确长度、嵌套形状
  * map 的「部分匹配」与动态键（`^key => value`）
  * 二进制前缀匹配
  * `^`（pin）：用变量**已有**的值去匹配，而不是绑定新变量
  * `match?/2`：只想要「对不对得上」的布尔答案、不想崩

      iex> Ex04PatternMatching.ok?({:ok, 1})
      true

      iex> Ex04PatternMatching.ok?({:error, :x})
      false

  """

  # ============================================================
  # 1. 元组解构：{:ok, _} / {:error, _} 是这个语言的通用返回形状
  # ============================================================

  @doc """
  识别三种返回形状，返回一个标签——演示多子句按**模式**分派（05 章系统讲）。

      iex> Ex04PatternMatching.classify({:ok, 42})
      :ok_value

      iex> Ex04PatternMatching.classify({:error, :oops})
      :error_value

      iex> Ex04PatternMatching.classify({:other, 1})
      :something_else

  """
  @spec classify(term()) :: :ok_value | :error_value | :something_else
  def classify({:ok, _value}), do: :ok_value
  def classify({:error, _reason}), do: :error_value
  def classify(_other), do: :something_else

  @doc """
  成功时取出值，失败/其它形状返回 `nil`——用模式把「要么有要么没有」表达清楚。

      iex> Ex04PatternMatching.ok_value({:ok, "hi"})
      "hi"

      iex> Ex04PatternMatching.ok_value({:error, :x})
      nil

  """
  @spec ok_value(term()) :: term() | nil
  def ok_value({:ok, value}), do: value
  def ok_value(_), do: nil

  # ============================================================
  # 2. 列表：头尾、精确长度、嵌套
  # ============================================================

  @doc """
  头尾分解；空列表没有头尾，返回 `{:error, :empty}`（而不是让 hd/1 崩）。

      iex> Ex04PatternMatching.head_tail([1, 2, 3])
      {:ok, 1, [2, 3]}

      iex> Ex04PatternMatching.head_tail([])
      {:error, :empty}

  """
  @spec head_tail(list()) :: {:ok, term(), list()} | {:error, :empty}
  def head_tail([head | tail]), do: {:ok, head, tail}
  def head_tail([]), do: {:error, :empty}

  @doc """
  精确长度匹配：`[_, _]` 只接受**恰好两个元素**的列表，多一个少一个都落到兜底子句。

      iex> Ex04PatternMatching.pair?([:a, :b])
      true

      iex> Ex04PatternMatching.pair?([:a])
      false

      iex> Ex04PatternMatching.pair?([:a, :b, :c])
      false

  """
  @spec pair?(term()) :: boolean()
  def pair?([_, _]), do: true
  def pair?(_), do: false

  @doc """
  嵌套解构：直接从「元组套 map」里把深层字段抠出来，不用逐层 `.field`。

      iex> Ex04PatternMatching.city({:user, "Ada", %{city: "London"}})
      "London"

      iex> Ex04PatternMatching.city({:user, "Ada", %{}})
      :unknown

  """
  @spec city(term()) :: String.t() | :unknown
  def city({:user, _name, %{city: c}}), do: c
  def city(_), do: :unknown

  # ============================================================
  # 3. pin（^）：匹配变量已有的值，而非重新绑定
  # ============================================================

  @doc """
  `^expected` 表示「用 expected 此刻的值去匹配」。没有 pin 的 `expected -> ...`
  会把 actual **重新绑定**给一个叫 expected 的新变量，那不是比较。

      iex> Ex04PatternMatching.match_status(200, 200)
      {:ok, 200}

      iex> Ex04PatternMatching.match_status(404, 200)
      {:mismatch, 404}

  """
  @spec match_status(term(), term()) :: {:ok, term()} | {:mismatch, term()}
  def match_status(actual, expected) do
    case actual do
      ^expected -> {:ok, actual}
      other -> {:mismatch, other}
    end
  end

  @doc """
  同一模式里同名变量出现第二次，语义是「要求与第一次绑定的值相等」。
  所以 `{x, x}` 只匹配两个元素相等的二元组。

      iex> Ex04PatternMatching.same_pair({1, 1})
      true

      iex> Ex04PatternMatching.same_pair({1, 2})
      false

  """
  @spec same_pair(term()) :: boolean()
  def same_pair({x, x}), do: true
  def same_pair({_a, _b}), do: false

  # ============================================================
  # 4. map：部分匹配 + 动态键
  # ============================================================

  @doc """
  `%{name: _}` 是**部分匹配**：只要求 map 里**存在** `:name` 键，多余的键无所谓；
  没有这个键就对不上。注意它对 struct 也成立（struct 是 map 的特例）。

      iex> Ex04PatternMatching.has_name?(%{name: "x", age: 1})
      true

      iex> Ex04PatternMatching.has_name?(%{age: 1})
      false

  """
  @spec has_name?(term()) :: boolean()
  def has_name?(map) do
    match?(%{name: _}, map)
  end

  @doc """
  取**键名在运行时才知道**的值：原子键的 `%{key: v}` 语法只能写死键名，
  动态键必须用 `%{^key => value}`（键的位置 pin 一个变量）。

      iex> Ex04PatternMatching.get_key(%{a: 1, b: 2}, :b)
      {:ok, 2}

      iex> Ex04PatternMatching.get_key(%{a: 1}, :b)
      :error

      iex> Ex04PatternMatching.get_key(%{"name" => "Ada"}, "name")
      {:ok, "Ada"}

  """
  @spec get_key(term(), term()) :: {:ok, term()} | :error
  def get_key(map, key) do
    case map do
      %{^key => value} -> {:ok, value}
      _ -> :error
    end
  end

  @doc """
  要求 map 里存在 `key`，存在返回 `:ok`，不存在抛 `MatchError`。

  参数刻意标成 `term()`：这样 1.20 的类型检查器无法在编译期断定键是否存在。
  直接对字面量写 `%{missing: v} = %{present: 1}` 会被静态判定「必然匹配失败」
  而产生编译告警；包进这个函数，运行期才知道结果。

      iex> Ex04PatternMatching.force_key!(%{a: 1}, :a)
      :ok

  """
  @spec force_key!(term(), term()) :: :ok
  def force_key!(map, key) do
    %{^key => _value} = map
    :ok
  end

  # ============================================================
  # 5. 二进制前缀匹配
  # ============================================================

  @doc """
  剥掉固定前缀。`<>` 操作符的模式形式只接受**字面量**前缀（`"Hello, " <> rest`），
  前缀是变量时要用二进制模式 `<<^prefix::binary, rest::binary>>`。

      iex> Ex04PatternMatching.strip_prefix("Hello, world", "Hello, ")
      {:ok, "world"}

      iex> Ex04PatternMatching.strip_prefix("goodbye", "Hello, ")
      :error

      iex> Ex04PatternMatching.strip_prefix("data:42", "data:")
      {:ok, "42"}

  """
  @spec strip_prefix(binary(), binary()) :: {:ok, binary()} | :error
  def strip_prefix(bin, prefix) when is_binary(bin) and is_binary(prefix) do
    case bin do
      <<^prefix::binary, rest::binary>> -> {:ok, rest}
      _ -> :error
    end
  end

  @doc """
  按固定字节宽度拆包二进制（网络协议解析的最基本动作，17 章深入）。

      iex> Ex04PatternMatching.split_32(<<1, 0, 0, 0, 9, 8>>)
      {:ok, 16777216, <<9, 8>>}

      iex> Ex04PatternMatching.split_32(<<1, 2>>)
      :error

  """
  @spec split_32(binary()) :: {:ok, non_neg_integer(), binary()} | :error
  def split_32(<<a, b, c, d, rest::binary>>) do
    {:ok, Integer.undigits([a, b, c, d], 256), rest}
  end

  def split_32(_short), do: :error

  # ============================================================
  # 6. match?/2：只要布尔答案
  # ============================================================

  @doc """
  `match?/2` 是个宏：模式对得上返回 `true`，对不上返回 `false`，**永不抛 MatchError**。
  适合用在 `Enum.filter/2`、条件判断里。

      iex> Ex04PatternMatching.ok?({:ok, 1})
      true

      iex> Ex04PatternMatching.ok?(:nope)
      false

  """
  @spec ok?(term()) :: boolean()
  def ok?(term), do: match?({:ok, _}, term)

  @doc """
  `match?/2` 配合 Enum 过滤：只留下成功元组里的值。

      iex> Ex04PatternMatching.select_ok([{:ok, 1}, {:error, :x}, {:ok, 3}])
      [1, 3]

  """
  @spec select_ok([term()]) :: [term()]
  def select_ok(list) do
    for {:ok, value} <- list, do: value
  end
end
