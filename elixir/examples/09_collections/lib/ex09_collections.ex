defmodule Ex09Collections.User do
  @moduledoc """
  本章的示例结构体之一：一个带必填键约束的「用户」。

  `@enforce_keys [:id]` 让构造时漏掉 `:id` 直接抛 ArgumentError；
  其余字段有默认值。结构体定义必须在使用它的模块被编译前可见。
  """

  @enforce_keys [:id]
  defstruct id: nil, name: "anonymous", tags: [], admin: false
end

defmodule Ex09Collections.Point do
  @moduledoc "本章的示例结构体之二：坐标点。"

  defstruct x: 0, y: 0
end

defmodule Ex09Collections do
  @moduledoc """
  第 09 章示例：四种键值集合的正确用法。

  Elixir 没有「哈希表」这个单一概念，而是四种各有分工的结构：

  - **Keyword**：原子键二元组列表，允许重复键、有序、线性查找，专用于**选项**；
  - **Map**：通用键值结构，键可以是任意类型，无序（相等与顺序无关）；
  - **Struct**：带 `__struct__` 标记、编译期固定字段的 map，是 Elixir 的「名义类型」；
  - **MapSet**：建立在 Map 上的集合，做去重与集合代数。

  另外有两套取值语法要分清：`data[key]`（Access 行为，nil 安全）与
  `Map.fetch/2`、`get_in/2` 家族。本章所有打印 map 的地方都先排序，
  因为 map 的展示顺序在实现上不保证稳定（见 run.exs 第 2 节实测）。

      iex> Ex09Collections.option([a: 1], :a)
      1

  """

  alias Ex09Collections.{Point, User}

  # ============================================================
  # 1. Keyword：选项列表
  # ============================================================

  @doc """
  从 Keyword 选项里取值，支持默认值（`Keyword.get/3`）。

      iex> Ex09Collections.option([], :port, 5432)
      5432

      iex> Ex09Collections.option([port: 6543], :port, 5432)
      6543

      iex> Ex09Collections.option([a: 1, a: 2], :a)
      1

  重复键时取**第一个**——要全部值得用 `Keyword.get_values/2`。
  """
  @spec option(Keyword.t(), atom(), term()) :: term()
  def option(opts, key, default \\ nil) when is_list(opts) and is_atom(key) do
    Keyword.get(opts, key, default)
  end

  @doc """
  实际库函数最常见的签名：`name + opts`。选项全是可选的，
  靠 `option/3` 逐个取默认值。

      iex> Ex09Collections.greet("Ada")
      "Hello, Ada"

      iex> Ex09Collections.greet("Ada", prefix: "Hola", shout?: true)
      "HOLA, ADA"

  """
  @spec greet(binary(), Keyword.t()) :: binary()
  def greet(name, opts \\ []) when is_binary(name) and is_list(opts) do
    prefix = option(opts, :prefix, "Hello")
    result = "#{prefix}, #{name}"

    if option(opts, :shout?, false) do
      String.upcase(result)
    else
      result
    end
  end

  @doc """
  写入一个选项（`Keyword.put/3`）：替换同名的**第一个**键，
  并移除其余同名键，最后挪到列表头部。

      iex> Ex09Collections.set_option([b: 2], :a, 1)
      [a: 1, b: 2]

  """
  @spec set_option(Keyword.t(), atom(), term()) :: Keyword.t()
  def set_option(opts, key, value) when is_list(opts) do
    Keyword.put(opts, key, value)
  end

  # ============================================================
  # 2. Map：通用键值结构
  # ============================================================

  @doc """
  Map 取值带默认值（`Map.get/3`）。注意 Keyword 和 Map 的默认值都是
  第三个参数，而 `map[:missing]` 这种 Access 语法只给 `nil`，
  区分不了「键不存在」与「值就是 nil」。

      iex> Ex09Collections.value_or(%{a: 1}, :b, :default)
      :default

      iex> Ex09Collections.value_or(%{a: nil}, :a, :default)
      nil

  """
  @spec value_or(map(), any(), any()) :: any()
  def value_or(map, key, default) when is_map(map) do
    Map.get(map, key, default)
  end

  @doc """
  `Map.merge/3` 对冲突键调用用户函数求和。默认 `Map.merge/2` 是后者覆盖。

      iex> Ex09Collections.merge_counters(%{a: 1, b: 2}, %{b: 10, c: 3})
      %{c: 3, a: 1, b: 12}

  注意 inspect 的键序（c, a, b）不保证与书写顺序一致——依赖输出时要排序。
  """
  @spec merge_counters(%{optional(atom()) => number()}, %{optional(atom()) => number()}) :: map()
  def merge_counters(a, b) do
    Map.merge(a, b, fn _key, x, y -> x + y end)
  end

  @doc """
  按 key 排序输出 map 内容。教程所有「展示一个 map」的地方都走它，
  保证输出与 map 内部表示（小 map / 大 map 两种存储）无关。

      iex> Ex09Collections.sorted_pairs(%{z: 1, a: 2})
      [a: 2, z: 1]

  """
  @spec sorted_pairs(map()) :: [{any(), any()}]
  def sorted_pairs(map) when is_map(map) do
    map |> Map.to_list() |> Enum.sort()
  end

  # ============================================================
  # 3. Struct：带类型的 map
  # ============================================================

  @doc """
  用 `struct!/2` 构造结构体：多给未知键会抛 KeyError
  （普通 `struct/2` 会悄悄忽略未知键）。

      iex> Ex09Collections.user_from_map(%{id: 7, name: "Ada"})
      %Ex09Collections.User{id: 7, name: "Ada", tags: [], admin: false}

  """
  @spec user_from_map(map()) :: User.t()
  def user_from_map(attrs) when is_map(attrs) do
    struct!(User, attrs)
  end

  @doc """
  按结构体名分派——这就是 struct 作为「名义类型」的用途：
  同样形状的普通 map 不会匹配 `%User{}`。

      iex> Ex09Collections.shape(%Ex09Collections.Point{x: 1})
      :point

      iex> Ex09Collections.shape(%Ex09Collections.User{id: 1})
      :user

      iex> Ex09Collections.shape(%{x: 1, y: 2})
      :plain_map

  """
  @spec shape(term()) :: :point | :user | :plain_map
  def shape(%Point{}), do: :point
  def shape(%User{}), do: :user
  def shape(other) when is_map(other), do: :plain_map

  @doc """
  结构体更新语法只改列出的字段，其余原样保留，且编译期检查字段名。

      iex> Ex09Collections.promote(%Ex09Collections.User{id: 1})
      %Ex09Collections.User{id: 1, name: "anonymous", tags: [], admin: true}

  """
  @spec promote(User.t()) :: User.t()
  def promote(%User{} = user), do: %{user | admin: true}

  @doc """
  给用户加一个标签，去重并保持追加顺序。函数对 `%User{}` 做精确匹配，
  传普通 map 会在函数入口产生 FunctionClauseError，而不是把数据悄悄改坏。

      iex> Ex09Collections.add_tag(%Ex09Collections.User{id: 1}, "elixir")
      %Ex09Collections.User{id: 1, name: "anonymous", tags: ["elixir"], admin: false}

      iex> u = %Ex09Collections.User{id: 1}
      %Ex09Collections.User{id: 1, name: "anonymous", tags: [], admin: false}
      iex> u |> Ex09Collections.add_tag("x") |> Ex09Collections.add_tag("x")
      %Ex09Collections.User{id: 1, name: "anonymous", tags: ["x"], admin: false}

  """
  @spec add_tag(User.t(), binary()) :: User.t()
  def add_tag(%User{tags: tags} = user, tag) when is_binary(tag) do
    %{user | tags: Enum.uniq(tags ++ [tag])}
  end

  # ============================================================
  # 4. MapSet：去重与集合代数
  # ============================================================

  @doc """
  去重后排序输出。「去重」最省事的写法就是 MapSet，别自己写 reduce。

      iex> Ex09Collections.uniq_sorted([3, 1, 3, 2, 1])
      [1, 2, 3]

  """
  @spec uniq_sorted([a]) :: [a] when a: var
  def uniq_sorted(list), do: list |> MapSet.new() |> MapSet.to_list() |> Enum.sort()

  @doc """
  一次性给出两个集合的并集 / 交集 / 差集，结果都排序以保证确定性。

      iex> Ex09Collections.venn([1, 2, 3], [2, 3, 4])
      %{union: [1, 2, 3, 4], inter: [2, 3], only_left: [1]}

  """
  @spec venn([a], [a]) :: %{union: [a], inter: [a], only_left: [a]} when a: var
  def venn(left, right) do
    a = MapSet.new(left)
    b = MapSet.new(right)

    %{
      union: a |> MapSet.union(b) |> MapSet.to_list() |> Enum.sort(),
      inter: a |> MapSet.intersection(b) |> MapSet.to_list() |> Enum.sort(),
      only_left: a |> MapSet.difference(b) |> MapSet.to_list() |> Enum.sort()
    }
  end

  @doc """
  成员判定。判断「某值是否在一个集合里」且判定次数很多时，
  MapSet 的 `member?` 是 O(log n)，`Enum.member?/2` 是 O(n)。

      iex> Ex09Collections.set_member?([1, 2], 2)
      true

      iex> Ex09Collections.set_member?([1, 2], 9)
      false

  """
  @spec set_member?([a], a) :: boolean() when a: var
  def set_member?(list, value), do: MapSet.member?(MapSet.new(list), value)

  # ============================================================
  # 5/6. Access 与 get_in / put_in 家族
  # ============================================================

  @doc """
  沿路径安全下钻（`get_in/2`）：任何一层缺失都返回 `nil`，不抛异常。
  原子键用于 map/keyword，字符串键用于解码出的 JSON，
  列表下标必须显式用 `Access.at/1`。

      iex> Ex09Collections.dig(%{db: %{port: 5432}}, [:db, :port])
      5432

      iex> Ex09Collections.dig(%{db: %{}}, [:db, :host, :domain])
      nil

      iex> Ex09Collections.dig(%{"users" => [%{"name" => "Ada"}]}, ["users", Access.at(0), "name"])
      "Ada"

  """
  @spec dig(Access.t(), list()) :: term()
  def dig(data, path) when is_list(path), do: get_in(data, path)

  @doc """
  沿路径更新（`update_in/3` 的函数形式）。路径是运行时数据时只能用函数形式；
  编译期已知的路径可以写宏形式 `update_in(data.a.b, &... )`。

      iex> Ex09Collections.bump_in(%{stats: %{count: 1}}, [:stats, :count], &(&1 + 1))
      %{stats: %{count: 2}}

  """
  @spec bump_in(Access.t(), list(), (term() -> term())) :: Access.t()
  def bump_in(data, path, fun), do: update_in(data, path, fun)

  @doc """
  沿路径写入（`put_in/3` 的函数形式），中间层缺失时不自动建层，
  而是返回 nil 路径处的错误语义——所以写之前数据结构应已存在。

      iex> Ex09Collections.put_deep(%{db: %{port: 5432}}, [:db, :port], 6543)
      %{db: %{port: 6543}}

  """
  @spec put_deep(Access.t(), list(), term()) :: Access.t()
  def put_deep(data, path, value), do: put_in(data, path, value)

  @doc """
  对列表里每个 map 的同一字段取值——`Access.all/0` 是一条
  「遍历当前位置所有元素」的路径片段。

      iex> Ex09Collections.pluck([%{v: 1}, %{v: 2}], :v)
      [1, 2]

      iex> Ex09Collections.pluck([], :v)
      []

  """
  @spec pluck([map()], any()) :: list()
  def pluck(list, key), do: get_in(list, [Access.all(), key])

  @doc """
  元组不能用 `[index]` 取值（元组没有实现 Access），要在路径里用
  `Access.elem/1`。

      iex> Ex09Collections.tuple_nth({:a, :b, :c}, 1)
      :b

  """
  @spec tuple_nth(tuple(), non_neg_integer()) :: term()
  def tuple_nth(tuple, index), do: get_in(tuple, [Access.elem(index)])
end
