# 编译顺序：宏模块必须先于使用方编译，所以本文件按
# 「宏定义 → use 目标 → 数据/类型模块 → 消费方模块」排列。

defmodule Ex23Macros do
  @moduledoc """
  本章的宏集合：`my_unless`、`debug`，以及演示卫生性的 `shadow`/`leak`。
  """

  @doc "unless 的教学复刻：条件为假时执行块。"
  defmacro my_unless(clause, do: block) do
    quote do
      if !unquote(clause), do: unquote(block)
    end
  end

  @doc "打印「源码 => 值」并原值返回；bind_quoted 自动以卫生变量注入。"
  defmacro debug(expr) do
    text = Macro.to_string(expr)

    quote bind_quoted: [value: expr, text: text] do
      IO.puts(text <> " => " <> inspect(value))
      value
    end
  end

  @doc "卫生宏：内部 x 与调用方无关。"
  defmacro shadow do
    quote do
      x = 999
      x + 1
    end
  end

  @doc "逃逸宏：var! 显式操作调用方作用域的 x。"
  defmacro leak do
    quote do
      var!(x) = 999
    end
  end
end

defmodule Ex23Macros.Greeter do
  @moduledoc "use 目标：`use Ex23Macros.Greeter, greeting: \"嗨\"` 会注入 greet/1。"

  defmacro __using__(opts) do
    greeting = Keyword.get(opts, :greeting, "你好")

    quote do
      def greet(name), do: unquote(greeting) <> "，" <> name
    end
  end
end

defmodule Ex23Macros.Money do
  @moduledoc "带自定义类型的金额模块；演示 @type/@typep/@spec 的写法。"

  @typedoc "金额，整数分"
  @type cents :: non_neg_integer()

  @type t :: %__MODULE__{amount: cents(), currency: atom()}

  # 私有类型：只在本模块的 spec 内可见，用于内部辅助函数。
  @typep pair :: {t(), t()}

  defstruct amount: 0, currency: :CNY

  @doc """
  同币种相加；跨币种返回 tag（不静默换算）。

      iex> Ex23Macros.Money.add(
      iex>   %Ex23Macros.Money{amount: 100, currency: :CNY},
      iex>   %Ex23Macros.Money{amount: 50, currency: :CNY}
      iex> )
      {:ok, %Ex23Macros.Money{amount: 150, currency: :CNY}}

      iex> Ex23Macros.Money.add(
      iex>   %Ex23Macros.Money{amount: 100, currency: :CNY},
      iex>   %Ex23Macros.Money{amount: 50, currency: :USD}
      iex> )
      {:error, :currency_mismatch}

  """
  @spec add(t(), t()) :: {:ok, t()} | {:error, :currency_mismatch}
  def add(%__MODULE__{currency: c} = a, %__MODULE__{currency: c} = b) do
    {:ok, %{a | amount: a.amount + b.amount}}
  end

  def add(%__MODULE__{}, %__MODULE__{}), do: {:error, :currency_mismatch}

  @doc false
  @spec pair_key(pair()) :: atom()
  def pair_key({a, _b}), do: a.currency
end

defmodule Ex23Macros.Greeting do
  @moduledoc "use 的消费方：编译期被注入 greet/1（用普通测试覆盖，注入函数无自身 @doc）。"
  use Ex23Macros.Greeter, greeting: "嗨"
end

defmodule Ex23MacrosTypes do
  @moduledoc """
  第 23 章主模块：观察 AST、unquote 注入、宏消费、卫生性、类型检查器。
  """

  require Ex23Macros

  @doc """
  解析源码为 AST，并去掉行号等元数据——得到可稳定打印的三元素组形态：
  `{调用名, 元数据, 参数列表}`；变量参数为 nil，列表/元组保持字面量。

      iex> Ex23MacrosTypes.ast_shape("1 + 2")
      {:+, [], [1, 2]}

      iex> Ex23MacrosTypes.ast_shape("foo(1)")
      {:foo, [], [1]}

      iex> Ex23MacrosTypes.ast_shape("[1, 2]")
      [1, 2]

  """
  @spec ast_shape(String.t()) :: Macro.t()
  def ast_shape(code) when is_binary(code) do
    Macro.prewalk(Code.string_to_quoted!(code), fn
      {name, meta, args} -> {name, Keyword.drop(meta, [:line]), args}
      other -> other
    end)
  end

  @doc """
  quote 造 AST、unquote 把运行值注入，再 eval_quoted 执行：

      iex> Ex23MacrosTypes.run_quoted(41)
      42

  """
  @spec run_quoted(term()) :: term()
  def run_quoted(n) do
    ast =
      quote do
        unquote(n) + 1
      end

    {value, _bindings} = Code.eval_quoted(ast)
    value
  end

  @doc """
  unquote_splicing 把列表展开成多个实参：

      iex> Ex23MacrosTypes.splice_sum([1, 2, 3])
      6

  """
  @spec splice_sum([number()]) :: number()
  def splice_sum(xs) when is_list(xs) do
    ast =
      quote do
        unquote(__MODULE__).sum3(unquote_splicing(xs))
      end

    {value, _bindings} = Code.eval_quoted(ast)
    value
  end

  @doc false
  @spec sum3(number(), number(), number()) :: number()
  def sum3(a, b, c), do: a + b + c

  @doc """
  my_unless：假执行、真什么都不做（nil）。

      iex> Ex23MacrosTypes.unless_demo()
      {:ran, nil}

  """
  @spec unless_demo() :: {:ran, nil}
  def unless_demo do
    a = Ex23Macros.my_unless(false, do: :ran)
    b = Ex23Macros.my_unless(true, do: :ran)
    {a, b}
  end

  @doc """
  卫生宏不触碰调用方的 x；shadow 返回 1000。

      iex> Ex23MacrosTypes.hygiene_demo()
      {1, 1000}

  """
  @spec hygiene_demo() :: {1, 1000}
  def hygiene_demo do
    x = 1
    a = Ex23Macros.shadow()
    {x, a}
  end

  @doc """
  var! 逃逸后改写调用方的 x：先读到初值 1，宏改写后读到 999。

      iex> Ex23MacrosTypes.escape_demo()
      {1, 999}

  """
  @spec escape_demo() :: {1, 999}
  def escape_demo do
    x = 1
    before = x
    Ex23Macros.leak()
    {before, x}
  end

  @doc """
  1.20 类型检查器：运行时用 Code.with_diagnostics 捕获编译告警（stderr 不污染），
  归一化成确定性三元组：`{severity, 是warning, 消息含"will always evaluate"}`。

      iex> Ex23MacrosTypes.checker_demo()
      [warning: true, always_a: true]

  """
  @spec checker_demo() :: [warning: boolean(), always_a: boolean()]
  def checker_demo do
    tag = System.unique_integer([:positive])

    src = """
    defmodule Checker#{tag} do
      def f do
        x = :a
        x && false
      end
    end
    """

    {_result, diagnostics} =
      Code.with_diagnostics(fn -> Code.compile_string(src) end)

    Enum.map(diagnostics, fn d ->
      [
        warning: d.severity == :warning,
        always_a: String.contains?(d.message, "will always evaluate")
      ]
    end)
    |> List.flatten()
  end
end
