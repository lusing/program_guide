defmodule Ex24Capstone do
  @moduledoc """
  第 24 章收官项目：容错键值缓存 + 并发文件词频统计。

  本模块放纯函数核心（无进程、无 IO）：Unicode 分词、计数合并、Top-N 排序。
  有了纯函数核心，并发与监督都是外层的组装。
  """

  @doc """
  分词：以「非字母非数字」序列为界；Unicode downcase（\p{L} 覆盖中文）。

      iex> Ex24Capstone.tokenize("Hello, 世界 HELLO")
      ["hello", "世界", "hello"]

      iex> Ex24Capstone.tokenize("a-b,c! 123")
      ["a", "b", "c", "123"]

  """
  @spec tokenize(String.t()) :: [String.t()]
  def tokenize(line) when is_binary(line) do
    line
    |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true)
    |> Enum.map(&String.downcase/1)
  end

  @doc """
  合并两张词频表：同键相加。

      iex> Ex24Capstone.merge_counts(%{"a" => 1}, %{"a" => 2, "b" => 1})
      %{"a" => 3, "b" => 1}

      iex> Ex24Capstone.merge_counts(%{}, %{"x" => 9})
      %{"x" => 9}

  """
  @spec merge_counts(%{String.t() => integer()}, %{String.t() => integer()}) :: %{
          String.t() => integer()
        }
  def merge_counts(a, b) do
    Map.merge(a, b, fn _word, x, y -> x + y end)
  end

  @doc """
  频次最高的 n 个：频次降序、同频按词升序——双重键保证跨环境一致。

      iex> Ex24Capstone.top_n(%{"a" => 1, "b" => 3, "c" => 3, "d" => 2}, 2)
      [{"b", 3}, {"c", 3}]

      iex> Ex24Capstone.top_n(%{"z" => 1, "a" => 1}, 3)
      [{"a", 1}, {"z", 1}]

  """
  @spec top_n(%{String.t() => non_neg_integer()}, pos_integer()) :: [
          {String.t(), non_neg_integer()}
        ]
  def top_n(counts, n) do
    counts
    |> Enum.sort_by(fn {word, count} -> {-count, word} end)
    |> Enum.take(n)
  end
end
