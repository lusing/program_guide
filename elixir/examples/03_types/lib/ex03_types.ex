defmodule Ex03Types do
  @moduledoc """
  第 03 章示例：基础类型与不可变性。

  Elixir 的值类型一共只有十来种：整数、浮点、原子、二进制/位串、列表、元组、
  map、函数、pid、port、reference（`nil`/`true`/`false` 都是原子）。本模块把
  每一条关键结论都做成了可断言的函数：

  * `/` 永远返回浮点；`div`/`rem` 只接受整数，且是「向零截断」语义（同 C，非 Python 的向下取整）
  * 整数是任意精度的，不存在溢出回绕
  * 只有 `false` 和 `nil` 是假值；`0`、`0.0`、`""`、`[]` 全是真
  * 原子表只增不减：外部输入必须走 `String.to_existing_atom/1`
  * 一切值不可变，「更新」永远是返回新值
  * 所有 term 有全序：number < atom < reference < function < port < pid < tuple < map < list < binary
    （number 内部按数值大小；atom 自 OTP 26 起按文本字节序比较）

      iex> Ex03Types.divide(7, 2)
      3.5
      iex> Ex03Types.int_div(-7, 2)
      -3
      iex> Ex03Types.remainder(-7, 2)
      -1

  """

  @doc """
  `/` 是唯一的「数学除法」：永远返回浮点数，哪怕整除。

      iex> Ex03Types.divide(4, 2)
      2.0

  """
  @spec divide(number(), number()) :: float()
  def divide(a, b), do: a / b

  @doc """
  整数除法：向零截断。`div(-7, 2)` 是 `-3`（C/Rust/Go 的语义），
  不是 Python `//` 的 `-4`（向下取整）。

      iex> Ex03Types.int_div(7, 2)
      3

  """
  @spec int_div(integer(), integer()) :: integer()
  def int_div(a, b), do: div(a, b)

  @doc """
  取余：符号跟随**被除数**，与 `div` 配套（`div(a, b) * b + rem(a, b) == a` 恒成立）。

      iex> Ex03Types.remainder(7, -2)
      1

  """
  @spec remainder(integer(), integer()) :: integer()
  def remainder(a, b), do: rem(a, b)

  @doc """
  任意精度整数：Elixir 的整数没有位宽上限，超出 64 位自动变大数（Erlang 的
  bignum），代价只是分配与运算变慢，**永远不会回绕**。

      iex> Ex03Types.pow2(64)
      18446744073709551616

  关于幂运算有个常见误解需要澄清：`**/2` **并非永远返回浮点**——当底数与指数
  都是整数、且指数非负时，它返回精确整数（`2 ** 100 == Integer.pow(2, 100)`）；
  只有混入浮点（`2.0 ** 100` 得 `1.2676506e30`、丢精度）或指数为负时才走浮点。
  这里仍用 `Integer.pow/2`，是因为它**强制整数语义**：负指数直接抛
  `ArithmeticError`，而 `2 ** -1` 会静默返回浮点 `0.5`。
  """
  @spec pow2(non_neg_integer()) :: pos_integer()
  def pow2(exponent), do: Integer.pow(2, exponent)

  @doc """
  浮点相等陷阱：0.1 与 0.2 在 IEEE 754 双精度下都不是精确值，加完不等于 0.3。
  正确姿势是容差比较。

      iex> Ex03Types.nearly_equal(0.1 + 0.2, 0.3)
      true
      iex> 0.1 + 0.2 == 0.3
      false

  """
  @spec nearly_equal(float(), float(), float()) :: boolean()
  def nearly_equal(a, b, epsilon \\ 1.0e-9), do: abs(a - b) <= epsilon

  @doc """
  真假值判定：Elixir 里**只有** `false` 和 `nil` 是假，其余一切皆真——
  `0`、`0.0`、`""`、`[]` 都是真值。这与 C/C++/Python/JS 全都相反。

      iex> Ex03Types.truthy?(0)
      true
      iex> Ex03Types.truthy?("")
      true
      iex> Ex03Types.truthy?(nil)
      false
      iex> Ex03Types.truthy?(false)
      false

  """
  @spec truthy?(term()) :: boolean()
  def truthy?(value) do
    if value, do: true, else: false
  end

  @doc """
  把外部输入安全地变成原子：`String.to_existing_atom/1` 只接受原子表里
  **已经存在**的原子，不存在就抛 `ArgumentError`——绝不新建。而
  `String.to_atom/1` 会为任意输入新建原子，原子表只增不减且上限
  1048576 个，拿它处理用户输入就是内存泄漏 + DoS 漏洞。

      iex> Ex03Types.atom_from("nil")
      {:ok, nil}
      iex> Ex03Types.atom_from("no_such_atom_for_sure_9x7")
      {:error, :no_such_atom}

  顺带一个冷知识：模块名 `Ex03Types` 的真身是原子 `:"Elixir.Ex03Types"`，
  所以查 `"Ex03Types"` 得到的是**不带** `Elixir.` 前缀的另一个原子。
  """
  @spec atom_from(String.t()) :: {:ok, atom()} | {:error, :no_such_atom}
  def atom_from(binary) when is_binary(binary) do
    try do
      {:ok, String.to_existing_atom(binary)}
    rescue
      ArgumentError -> {:error, :no_such_atom}
    end
  end

  @doc """
  类型判定全家桶的微缩版：把任意 term 映射成类型标签。

  **判定顺序本身就是知识点**：`nil`、布尔都是原子，struct 是 map，
  binary 是 bitstring——必须先判更具体的，再判更宽泛的，否则
  `true` 会被报成 `:atom`、struct 会被报成 `:map`。

      iex> Ex03Types.type_of(true)
      :boolean
      iex> Ex03Types.type_of(:ok)
      :atom
      iex> Ex03Types.type_of(nil)
      :nil
      iex> Ex03Types.type_of("bin")
      :binary
      iex> Ex03Types.type_of(<<1::1>>)
      :bitstring
      iex> Ex03Types.type_of(%{a: 1})
      :map

  """
  @spec type_of(term()) :: atom()
  def type_of(term) do
    cond do
      is_nil(term) -> nil
      is_boolean(term) -> :boolean
      is_atom(term) -> :atom
      is_integer(term) -> :integer
      is_float(term) -> :float
      is_struct(term) -> :struct
      is_binary(term) -> :binary
      is_bitstring(term) -> :bitstring
      is_list(term) -> :list
      is_tuple(term) -> :tuple
      is_map(term) -> :map
      is_function(term) -> :function
      is_pid(term) -> :pid
      is_port(term) -> :port
      is_reference(term) -> :reference
    end
  end

  @doc """
  列表 = cons 单元链。头尾分解是 O(1)；空列表没有头尾可言，
  对它调 `hd/1` 会抛 `ArgumentError`——这里用模式匹配把两种形状分开。

      iex> Ex03Types.list_parts([1, 2, 3])
      {:ok, 1, [2, 3]}
      iex> Ex03Types.list_parts([])
      {:error, :empty}

  """
  @spec list_parts(list()) :: {:ok, term(), list()} | {:error, :empty}
  def list_parts([]), do: {:error, :empty}
  def list_parts([head | tail]), do: {:ok, head, tail}

  @doc """
  keyword 列表只是「键为原子的二元组列表」的语法糖，不是新类型。

      iex> Ex03Types.keyword_is_sugar()
      true

  """
  @spec keyword_is_sugar() :: boolean()
  def keyword_is_sugar do
    [name: "Elixir", year: 2012] == [{:name, "Elixir"}, {:year, 2012}]
  end

  @doc """
  不可变性的直接演示：`Map.update!/3` 返回**新** map，原 map 原封不动。
  返回 `{原值, 新值}` 让调用方亲眼看到两者并存。

      iex> Ex03Types.bump(%{count: 1}, :count)
      {%{count: 1}, %{count: 2}}

  """
  @spec bump(map(), atom()) :: {map(), map()}
  def bump(map, key) do
    updated = Map.update!(map, key, &(&1 + 1))
    {map, updated}
  end

  @doc """
  term 全序比较探针。刻意包成接受 `term()` 的函数：Elixir 1.20 的类型检查器
  会对字面量写出的 `1 < :a` 报「comparison between distinct types」告警
  （`--warnings-as-errors` 下直接编译失败），跨类型比较必须让字面量躲进函数里。

      iex> Ex03Types.lt(1, :a)
      true
      iex> Ex03Types.lt(:a, "bin")
      true

  """
  @spec lt(term(), term()) :: boolean()
  def lt(a, b), do: a < b

  @doc """
  `is_number/1` 是「父类」判定：整数与浮点都是 number。同样包成 `term()`
  参数，躲开 1.20 对 `is_number(42)` 这类字面量的「always succeed」告警。

      iex> Ex03Types.number?(42)
      true
      iex> Ex03Types.number?("42")
      false

  """
  @spec number?(term()) :: boolean()
  def number?(term), do: is_number(term)

  @doc """
  `===/2` 严格相等探针：除了比值，还要求**类型一致**。

  `==` 会做数值类型转换（`1 == 1.0` 为 true），`===` 不会（`1 === 1.0` 为 false）。
  包成 `term()` 参数，躲开 1.20 对字面量 `1 === 1.0` 的 distinct-types 告警。

      iex> Ex03Types.strict_equal?(1, 1.0)
      false
      iex> Ex03Types.strict_equal?(1, 1)
      true

  """
  @spec strict_equal?(term(), term()) :: boolean()
  def strict_equal?(a, b), do: a === b

  @doc """
  term 全序的演示工具：把给定 terms 用 `Enum.sort/1` 排序，再映射成类型标签。

  混合类型排序**不会崩**，因为 BEAM 为所有 term 定义了全序：
  number < atom < reference < function < port < pid < tuple < map < list < binary。
  只打印类型标签而不是值本身——pid/reference/function 的 `inspect` 输出
  含运行期编号，逐字节比对（run-all.sh 第 5 层）过不了。

      iex> Ex03Types.sort_labels(["bin", 1, :a])
      [:integer, :atom, :binary]

  """
  @spec sort_labels([term()]) :: [atom()]
  def sort_labels(terms) do
    terms
    |> Enum.sort()
    |> Enum.map(&type_of/1)
  end

  defmodule Point do
    @moduledoc """
    最小的 struct：证明 struct 本质上就是带 `:__struct__` 键的 map。

        iex> is_struct(%Ex03Types.Point{})
        true
        iex> is_map(%Ex03Types.Point{})
        true

    """
    defstruct x: 0, y: 0
  end
end
