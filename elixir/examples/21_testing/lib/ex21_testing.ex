defmodule Ex21Testing do
  @moduledoc """
  第 21 章示例：ExUnit 测试。

  本章刻意造一批「值得测」的小零件，好让测试文件演示 ExUnit 的各种手段：
  纯函数（`Math`）、函数式购物车（`Cart`，金额用整数分）、自定义异常与
  tagged tuple 两种错误风格（`Order`）、一个行为与它的控制台实现
  （`Notifier`），以及一个发消息的进程（`Ticker`）。
  """
end

defmodule Ex21Testing.Math do
  @moduledoc "纯函数：供 doctest、assert_in_delta、守卫断言演示。"

  @doc """
  除以 2。

      iex> Ex21Testing.Math.halve(10)
      5.0

  """
  @spec halve(number()) :: float()
  def halve(x) when is_number(x), do: x / 2

  @doc """
  平方。

      iex> Ex21Testing.Math.square(9)
      81

  """
  @spec square(number()) :: number()
  def square(x), do: x * x

  @doc """
  平方根（浮点），测试用 assert_in_delta 容忍浮点误差。

      iex> Ex21Testing.Math.sqrt(2)
      1.4142135623730951

  """
  @spec sqrt(number()) :: float()
  def sqrt(x) when x >= 0, do: :math.sqrt(x)

  @doc """
  把值夹在 [min, max] 之间。

      iex> Ex21Testing.Math.clamp(15, 0, 10)
      10

      iex> Ex21Testing.Math.clamp(-3, 0, 10)
      0

  """
  @spec clamp(number(), number(), number()) :: number()
  def clamp(x, min, max) when min <= max do
    cond do
      x < min -> min
      x > max -> max
      true -> x
    end
  end
end

defmodule Ex21Testing.Cart do
  @moduledoc """
  函数式购物车：items 为 `{名称, 数量, 单价（整数分）}` 列表。
  金额一律用整数分，绝不用 float 算钱。
  """

  defstruct items: []

  @type t() :: %__MODULE__{items: [{String.t(), pos_integer(), non_neg_integer()}]}

  @doc "空购物车。"
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  加商品；同名商品合并数量。

      iex> cart = Ex21Testing.Cart.new()
      iex> cart = Ex21Testing.Cart.add_item(cart, "苹果", 2, 300)
      iex> Ex21Testing.Cart.add_item(cart, "苹果", 1, 300).items
      [{"苹果", 3, 300}]

  """
  @spec add_item(t(), String.t(), pos_integer(), non_neg_integer()) :: t()
  def add_item(%__MODULE__{items: items} = cart, name, qty, price_cents) do
    items =
      case List.keyfind(items, name, 0) do
        nil ->
          [{name, qty, price_cents} | items]

        {^name, old_qty, _price} ->
          List.keyreplace(items, name, 0, {name, old_qty + qty, price_cents})
      end

    %{cart | items: items}
  end

  @doc """
  总价（整数分）。

      iex> cart =
      iex>   Ex21Testing.Cart.new()
      iex>   |> Ex21Testing.Cart.add_item("苹果", 2, 300)
      iex>   |> Ex21Testing.Cart.add_item("香蕉", 1, 200)
      iex> Ex21Testing.Cart.total(cart)
      800

  """
  @spec total(t()) :: non_neg_integer()
  def total(%__MODULE__{items: items}) do
    Enum.reduce(items, 0, fn {_name, qty, price}, acc -> acc + qty * price end)
  end
end

defmodule Ex21Testing.EmptyCartError do
  @moduledoc "购物车为空却要求下单。"
  defexception [:message]

  @impl true
  def message(%{message: nil}), do: "购物车为空，无法下单"
  def message(%{message: msg}), do: msg
end

defmodule Ex21Testing.Notifier do
  @moduledoc "通知行为：下单后如何通知外部世界。"

  @callback deliver(summary :: map()) :: :ok
end

defmodule Ex21Testing.ConsoleNotifier do
  @moduledoc "默认实现：记一条日志（测试用 capture_log 捕获）。"

  @behaviour Ex21Testing.Notifier

  require Logger

  @impl true
  def deliver(%{} = summary) do
    Logger.info("订单已通知 total=#{Map.fetch!(summary, :total_cents)}")
    :ok
  end
end

defmodule Ex21Testing.Order do
  @moduledoc "下单：tagged tuple 与异常两种错误风格 + 收据打印。"

  @doc """
  下单。空车 => `{:error, :empty}`；否则通知并返回 `{:ok, summary}`。
  notifier 作为参数注入——这正是「不 mock」测试法的抓手。
  """
  @spec place(Ex21Testing.Cart.t(), module()) ::
          {:ok, map()} | {:error, :empty}
  def place(%Ex21Testing.Cart{items: []}, _notifier), do: {:error, :empty}

  def place(%Ex21Testing.Cart{} = cart, notifier) do
    summary = %{total_cents: Ex21Testing.Cart.total(cart), lines: length(cart.items)}
    :ok = notifier.deliver(summary)
    {:ok, summary}
  end

  @doc "下单的 ! 版本：空车抛 `EmptyCartError`，供 assert_raise 测试。"
  @spec place!(Ex21Testing.Cart.t(), module()) :: map()
  def place!(%Ex21Testing.Cart{items: []}, _notifier),
    do: raise(Ex21Testing.EmptyCartError)

  def place!(%Ex21Testing.Cart{} = cart, notifier) do
    {:ok, summary} = place(cart, notifier)
    summary
  end

  @doc """
  打印收据到标准输出（每行一项 + 合计），供 capture_io 测试。
  只打印、返回 :ok。
  """
  @spec print_receipt(Ex21Testing.Cart.t()) :: :ok
  def print_receipt(%Ex21Testing.Cart{items: items}) do
    Enum.each(items, fn {name, qty, price} ->
      IO.puts("#{name} x#{qty} = #{qty * price}")
    end)

    IO.puts("合计 #{Enum.reduce(items, 0, fn {_, q, p}, a -> a + q * p end)}")
  end
end

defmodule Ex21Testing.Ticker do
  @moduledoc "启动后立刻向调用进程发送若干 {:tick, n} 消息，供 assert_receive 测试。"

  @doc """
  非阻塞：派生进程一次性发完编号消息（不 sleep——定时等待是测试脆弱性之源）。
  """
  @spec start(pos_integer()) :: pid()
  def start(count) do
    parent = self()

    spawn(fn ->
      Enum.each(1..count, fn i -> send(parent, {:tick, i}) end)
    end)
  end
end
