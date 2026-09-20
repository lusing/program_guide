defmodule Ex02Hello do
  @moduledoc """
  第 02 章示例：最小模块的解剖。

  Elixir 的代码必须装在模块里，模块必须装在文件里；一个文件可以放多个模块，
  但**约定是一个文件一个模块，且文件名是模块名的 snake_case**（`Ex02Hello`
  → `ex02_hello.ex`）。这条不是语法要求，是 `mix new` 的目录约定与
  `Code.fetch_docs/1` 找文档时的路径推导依赖它。

      iex> Ex02Hello.hello()
      "Hello, Elixir!"

  """

  @doc """
  最简单的公开函数：无参数、返回字符串。

  `def` 定义公开函数，`defp` 定义私有函数（外部调不到，编译器会告警未被
  使用的私有函数——`--warnings-as-errors` 下直接拦下）。
  """
  @spec hello() :: String.t()
  def hello, do: "Hello, Elixir!"

  @doc """
  arity（参数个数）是函数名的一部分：`greet/1` 与 `greet/2` 是**两个不同的函数**，
  不是重载同一个函数。这一点在 04 章「模式匹配即分派」里会成为核心机制。
  """
  @spec greet(String.t()) :: String.t()
  def greet(name), do: "你好，#{name}！"

  @doc "同名不同 arity：与 `greet/1` 并存，互不影响。"
  @spec greet(String.t(), String.t()) :: String.t()
  def greet(greeting, name), do: "#{greeting}，#{name}！"

  @doc """
  私有函数：只能在模块内部调用。

  这里演示 `{:ok, value}` / `{:error, reason}` 这个贯穿全语言的返回约定——
  Elixir 不靠异常表达「预期内的失败」（11 章展开）。
  """
  @spec parse_age(String.t()) :: {:ok, non_neg_integer()} | {:error, :invalid_age}
  def parse_age(text) when is_binary(text) do
    case Integer.parse(String.trim(text)) do
      {age, ""} when age >= 0 -> {:ok, age}
      _ -> {:error, :invalid_age}
    end
  end

  @doc """
  `#\{...\}` 插值走 `String.Chars` 协议（只有「能当文本看」的类型才实现），
  `inspect/1` 走 `Inspect` 协议（**任何**类型都实现，输出的是源码形式）。

  元组与 map 没有实现 `String.Chars`，所以 `"#\{{1, 2}}"` 会当场抛
  `Protocol.UndefinedError`——这是新手最常见的一个坑。这里先用
  `impl_for/1` 探一下，探不到就退化成 `inspect/1`：

      iex> Ex02Hello.render({1, 2})
      {"(不可插值)", "{1, 2}"}

  """
  @spec render(term()) :: {String.t(), String.t()}
  def render(value) do
    interpolated =
      case String.Chars.impl_for(value) do
        nil -> "(不可插值)"
        _impl -> to_string(value)
      end

    {interpolated, inspect(value)}
  end

  @doc """
  三种运行形态里，脚本形态的入口通常长这样：接收命令行参数列表。

  `mix run run.exs -- a b` 里 `--` 之后的部分会作为 `argv` 传进来。
  """
  @spec main([String.t()]) :: :ok
  def main(argv) do
    IO.puts(hello())
    IO.puts("argv = #{inspect(argv)}")
    :ok
  end

  defp internal_only(x), do: x * 2

  @doc "证明私有函数确实在模块内部可用。"
  @spec doubled(integer()) :: integer()
  def doubled(x), do: internal_only(x)
end
