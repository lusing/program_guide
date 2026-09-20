defmodule Ex18Streams do
  @moduledoc """
  第 18 章示例：Stream 惰性流。

  Enum 是「给我整个集合」——每个中间步骤都生成一个新列表；Stream 是
  「一份拉取配方」——map/filter/take 只组合描述、不执行，直到 Enum.to_list、
  Enum.take 等终点操作才按需从源头一个一个地拉。本章演示惰性组合、四个无限源
  （iterate/cycle/unfold/resource）、chunk 家族与恒定内存。
  """

  # ------------------------------------------------------------
  # 1. 惰性：组合不执行，终点操作才拉取
  # ------------------------------------------------------------

  @doc """
  构造一个「一旦求值就会炸」的流并丢弃它：构造阶段返回正常，证明 Stream 操作
  不会提前调用源函数。

      iex> Ex18Streams.build_untouched()
      :stream_built

  """
  @spec build_untouched() :: :stream_built
  def build_untouched do
    Stream.map(Stream.repeatedly(fn -> raise "不应被执行" end), &Function.identity/1)
    :stream_built
  end

  @doc """
  从 1 开始递增，找平方大于 n 的第一个值。源是无限的，但 Enum.find 找到即停，
  map 实际只执行到 11²=121。

      iex> Ex18Streams.first_square_over(100)
      121

  """
  @spec first_square_over(pos_integer()) :: pos_integer() | nil
  def first_square_over(n) when is_integer(n) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&(&1 * &1))
    |> Enum.find(&(&1 > n))
  end

  # ------------------------------------------------------------
  # 2. map/filter/take 融合：没有中间列表
  # ------------------------------------------------------------

  @doc """
  1..100 翻倍后取能被 3 整除的前 3 个：只要前 9 个数就够产出 3 个结果。

      iex> Ex18Streams.take_doubles()
      [6, 12, 18]

  """
  @spec take_doubles() :: [pos_integer()]
  def take_doubles do
    1..100
    |> Stream.map(&(&1 * 2))
    |> Stream.filter(&(rem(&1, 3) == 0))
    |> Enum.take(3)
  end

  # ------------------------------------------------------------
  # 3. Stream.iterate/2：初值 + 下一步，无限
  # ------------------------------------------------------------

  @doc """
  从 1 开始反复乘 2，取前 n 个（2 的幂）。

      iex> Ex18Streams.powers_of_two(6)
      [1, 2, 4, 8, 16, 32]

  """
  @spec powers_of_two(pos_integer()) :: [pos_integer()]
  def powers_of_two(n) do
    Stream.iterate(1, &(&1 * 2)) |> Enum.take(n)
  end

  # ------------------------------------------------------------
  # 4. Stream.cycle/1：有限列表无限轮转
  # ------------------------------------------------------------

  @doc """
  把一个有限列表无限重复，取前 n 个（跨轮次边界继续）。

      iex> Ex18Streams.cycle_take([1, 2, 3], 7)
      [1, 2, 3, 1, 2, 3, 1]

  """
  @spec cycle_take([elem], pos_integer()) :: [elem] when elem: term()
  def cycle_take(list, n) when is_list(list) do
    Stream.cycle(list) |> Enum.take(n)
  end

  # ------------------------------------------------------------
  # 5. Stream.unfold/2：携带状态的生成器
  # ------------------------------------------------------------

  @doc """
  unfold 每次返回 `{吐出的值, 下一状态}`，返回 nil 才结束。
  用相邻两项做状态生成前 n 个斐波那契数。

      iex> Ex18Streams.fib(10)
      [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

  """
  @spec fib(pos_integer()) :: [non_neg_integer()]
  def fib(n) do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
    |> Enum.take(n)
  end

  # ------------------------------------------------------------
  # 6. Stream.resource/3：开 / 用 / 关 三段式资源
  # ------------------------------------------------------------

  @doc """
  resource 三回调：start 打开资源（发 :opened），next 吐一批值并推进状态、
  `{:halt, _}` 结束，after 做清理（发 :closed）。返回 `{值列表, 生命周期标签}`。
  实测注意：after 回调**会被调用但返回值被丢弃**，它只负责释放。

      iex> Ex18Streams.resource_demo()
      {[10, 20, 30], [:opened, :closed]}

  """
  @spec resource_demo() :: {[pos_integer()], [:opened | :closed]}
  def resource_demo do
    parent = self()

    values =
      Stream.resource(
        fn ->
          send(parent, :opened)
          [[1, 2], [3]]
        end,
        fn
          [] -> {:halt, []}
          [batch | rest] -> {Enum.map(batch, &(&1 * 10)), rest}
        end,
        fn _ ->
          send(parent, :closed)
          []
        end
      )
      |> Enum.to_list()

    {values, drain([])}
  end

  @doc """
  Stream.each/2 只做副作用、原值照穿；不关心结果时用 Stream.run/0 跑完。
  副作用按顺序发生（同一进程内消息有序）。

      iex> Ex18Streams.run_each()
      [{:tick, 1}, {:tick, 2}, {:tick, 3}]

  """
  @spec run_each() :: [{:tick, pos_integer()}]
  def run_each do
    1..3
    |> Stream.each(&send(self(), {:tick, &1}))
    |> Stream.run()

    drain([])
  end

  # ------------------------------------------------------------
  # 7. chunk 家族与无限流恒定内存
  # ------------------------------------------------------------

  @doc """
  按固定大小切组；最后一组不足长也保留（短组）。

      iex> Ex18Streams.pairs(5)
      [[1, 2], [3, 4], [5]]

  """
  @spec pairs(pos_integer()) :: [[pos_integer()]]
  def pairs(n) do
    Stream.chunk_every(1..n, 2) |> Enum.to_list()
  end

  @doc """
  chunk_by 在 key 函数结果**变化**的边界切组：把连续同奇偶的数归为一组。

      iex> Ex18Streams.parity_runs([1, 3, 2, 4, 5])
      [[1, 3], [2, 4], [5]]

  """
  @spec parity_runs(Enumerable.t()) :: [[integer()]]
  def parity_runs(enumerable) do
    Stream.chunk_by(enumerable, &rem(&1, 2)) |> Enum.to_list()
  end

  @doc """
  chunk_while 携带累加器：累计元素和达到阈值就吐出一组，
  流结束时把残余值作为最后一组吐出。

      iex> Ex18Streams.running_groups(1..6, 5)
      [[1, 2, 3], [4, 5], [6]]

  """
  @spec running_groups(Enumerable.t(), pos_integer()) :: [[pos_integer()]]
  def running_groups(enumerable, threshold) do
    enumerable
    |> Stream.chunk_while(
      {0, []},
      fn x, {sum, acc} ->
        new_sum = sum + x
        new_acc = [x | acc]

        if new_sum >= threshold do
          {:cont, Enum.reverse(new_acc), {0, []}}
        else
          {:cont, {new_sum, new_acc}}
        end
      end,
      fn
        {0, []} -> {:cont, []}
        {_sum, acc} -> {:cont, Enum.reverse(acc), {0, []}}
      end
    )
    |> Enum.to_list()
  end

  @doc """
  从无限奇数流里取前 n 个：任意时刻只有「当前元素」在内存里。

      iex> Ex18Streams.odds(5)
      [1, 3, 5, 7, 9]

  """
  @spec odds(pos_integer()) :: [pos_integer()]
  def odds(n) do
    Stream.iterate(1, &(&1 + 2)) |> Enum.take(n)
  end

  # 排空当前进程邮箱（resource/each 演示的副作用收集），按到达顺序返回。
  defp drain(acc) do
    receive do
      msg -> drain([msg | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
