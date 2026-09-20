defprotocol Ex10Protocols.Describable do
  @moduledoc """
  本章示例协议：任何类型都能给出「一行描述」与「类别标签」。

  协议只声明函数头（无函数体），具体行为由各类型的 `defimpl` 提供；
  分派依据是**运行时第一个参数的数据类型**。
  """

  @fallback_to_any true

  @doc "一行人类可读描述"
  def describe(value)

  @doc "类别标签"
  def category(value)
end

defimpl Ex10Protocols.Describable, for: [Integer, Float] do
  def describe(n), do: "number #{n}"
  def category(_), do: :number
end

defimpl Ex10Protocols.Describable, for: BitString do
  def describe(s), do: "string of #{String.length(s)} grapheme(s)"
  def category(_), do: :text
end

defimpl Ex10Protocols.Describable, for: List do
  def describe(list), do: "list of #{length(list)} element(s)"
  def category(_), do: :sequence
end

defmodule Ex10Protocols.Box do
  @moduledoc "显式实现协议的结构体。"
  defstruct [:item]
end

defimpl Ex10Protocols.Describable, for: Ex10Protocols.Box do
  def describe(%Ex10Protocols.Box{item: item}), do: "box holding #{inspect(item)}"
  def category(_), do: :container
end

defimpl Ex10Protocols.Describable, for: Any do
  def describe(other), do: "unknown #{inspect(other)}"
  def category(_), do: :unknown
end

defmodule Ex10Protocols.Bag do
  @moduledoc """
  不手写实现，用 `@derive` 派生——派生实现直接复用 `Any` 实现的函数体。
  """

  @derive Ex10Protocols.Describable
  defstruct [:items]
end

defmodule Ex10Protocols.Secret do
  @moduledoc "演示内置协议 Inspect / String.Chars 的自定义实现。"
  defstruct [:value]
end

defimpl Inspect, for: Ex10Protocols.Secret do
  def inspect(%Ex10Protocols.Secret{value: value}, opts) do
    Inspect.Algebra.concat(["#Secret<masked:", Inspect.Integer.inspect(value, opts), ">"])
  end
end

defimpl String.Chars, for: Ex10Protocols.Secret do
  def to_string(%Ex10Protocols.Secret{value: value}), do: "secret(#{value})"
end

defmodule Ex10Protocols.Storage do
  @moduledoc """
  本章示例**行为**（behaviour）：一个键值存储必须实现哪些回调。

  与协议的区别是：行为按**模块**分派（调用方显式传入实现模块），
  且契约在编译期检查——模块声明了 `@behaviour` 却漏写回调，编译直接告警。
  """

  @callback get(store :: term(), key :: term()) :: {:ok, term()} | :error
  @callback put(store :: term(), key :: term(), value :: term()) :: term()
  @callback keys(store :: term()) :: [term()]

  @optional_callbacks keys: 1

  @doc "行为模块里可以放所有实现共享的公共 API。"
  def fetch!(impl, store, key) do
    case impl.get(store, key) do
      {:ok, value} -> value
      :error -> raise KeyError, key: key, term: store
    end
  end
end

defmodule Ex10Protocols.MemoryStorage do
  @moduledoc "Storage 行为的一个内存实现（状态就是 map，纯函数）。"
  @behaviour Ex10Protocols.Storage

  def new, do: %{}

  @impl true
  def get(store, key) do
    case Map.fetch(store, key) do
      {:ok, value} -> {:ok, value}
      :error -> :error
    end
  end

  @impl true
  def put(store, key, value), do: Map.put(store, key, value)

  @impl true
  def keys(store), do: Map.keys(store) |> Enum.sort()
end

defmodule Ex10Protocols do
  @moduledoc """
  第 10 章示例：协议（protocol）与行为（behaviour）。

  - **协议**：按数据类型动态分派，可给内置类型和后来定义的 struct 补实现；
  - **行为**：模块间的编译期接口契约，调用时显式传实现模块。

  本章的 `Describable` 协议开了 `@fallback_to_any true`，所以任何
  没有专门实现的类型都会落到 `Any` 实现上。

      iex> Ex10Protocols.report(42)
      {:number, "number 42"}

  """

  alias Ex10Protocols.Describable

  @doc "同时返回类别与描述。"
  @spec report(term()) :: {atom(), binary()}
  def report(value) do
    {Describable.category(value), Describable.describe(value)}
  end

  @doc "对列表逐项生成报告。"
  @spec describe_all([term()]) :: [{atom(), binary()}]
  def describe_all(list), do: Enum.map(list, &report/1)

  @doc "返回当前数据类型对应的实现模块（协议的分派表查询）。"
  @spec impl_module(term()) :: module() | nil
  def impl_module(value), do: Describable.impl_for(value)

  @doc """
  协议的合并状态与实现清单（清单排序后给出，顺序不保证）。
  mix 环境下协议默认被**合并（consolidation）**，分派更快。

      iex> info = Ex10Protocols.impl_summary()
      iex> info.consolidated?
      true

  """
  @spec impl_summary() :: %{consolidated?: boolean(), impls: [module()]}
  def impl_summary do
    %{
      consolidated?: Protocol.consolidated?(Describable),
      impls:
        case Describable.__protocol__(:impls) do
          {:consolidated, list} -> Enum.sort(list)
          :not_consolidated -> []
        end
    }
  end

  @doc """
  对任意值调用 `Enum.count/1`，未实现 Enumerable 协议时把异常转成标签。
  参数类型是 `term()`：struct 默认没有 Enumerable 实现，直接写
  `Enum.count(%Box{})` 会被 1.20 类型检查器在编译期拦下。

      iex> Ex10Protocols.safe_count([1, 2, 3])
      3

      iex> Ex10Protocols.safe_count(%Ex10Protocols.Box{item: 1})
      {:raised, Protocol.UndefinedError}

  """
  @spec safe_count(term()) :: non_neg_integer() | {:raised, module()}
  def safe_count(term) do
    try do
      Enum.count(term)
    rescue
      Protocol.UndefinedError -> {:raised, Protocol.UndefinedError}
    end
  end

  @doc """
  对任意值调用 `to_string/1`，未实现 String.Chars 协议时返回标签。

      iex> Ex10Protocols.safe_to_string(%Ex10Protocols.Secret{value: 7})
      "secret(7)"

      iex> Ex10Protocols.safe_to_string(%Ex10Protocols.Box{item: 1})
      {:raised, Protocol.UndefinedError}

  """
  @spec safe_to_string(term()) :: binary() | {:raised, module()}
  def safe_to_string(term) do
    try do
      to_string(term)
    rescue
      Protocol.UndefinedError -> {:raised, Protocol.UndefinedError}
    end
  end

  @doc """
  动态编译一个声明了 `@behaviour` 却漏写回调的模块，取出编译器诊断。
  用 `Code.with_diagnostics/1` 兜住诊断，避免污染 stderr。
  返回文本里包含 "required by behaviour"。
  """
  @spec missing_callback_diagnostic() :: binary()
  def missing_callback_diagnostic do
    {_result, diagnostics} =
      Code.with_diagnostics(fn ->
        Code.compile_string("""
        defmodule Ex10Protocols.BadStorageSample do
          @behaviour Ex10Protocols.Storage
        end
        """)
      end)

    diagnostics
    |> Enum.map(& &1.message)
    |> Enum.find("", &String.contains?(&1, "required by behaviour"))
  end
end
