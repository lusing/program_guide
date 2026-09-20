defmodule Ex18StreamsTest do
  use ExUnit.Case, async: true

  doctest Ex18Streams

  alias Ex18Streams

  describe "惰性" do
    test "构造流不触发源函数" do
      assert Ex18Streams.build_untouched() == :stream_built
    end

    test "求值时才触发：枚举即 raise" do
      assert_raise RuntimeError, "不应被执行", fn ->
        Stream.map(Stream.repeatedly(fn -> raise "不应被执行" end), &Function.identity/1)
        |> Enum.take(1)
      end
    end

    test "Enum.find 在无限平方流上短路" do
      assert Ex18Streams.first_square_over(1000) == 1024
    end

    test "take_doubles 融合管道只取所需" do
      assert Ex18Streams.take_doubles() == [6, 12, 18]
    end
  end

  describe "无限源" do
    test "iterate 自定义步长也能 take" do
      result = Stream.iterate(100, &div(&1, 2)) |> Enum.take(4)
      assert result == [100, 50, 25, 12]
    end

    test "cycle 不能轮转空枚举" do
      assert_raise ArgumentError, "cannot cycle over an empty enumerable", fn ->
        force_cycle([])
      end
    end

    test "unfold 返回 nil 时自然终止（有限流）" do
      result =
        Stream.unfold(0, fn
          n when n >= 3 -> nil
          n -> {n, n + 1}
        end)
        |> Enum.to_list()

      assert result == [0, 1, 2]
    end

    test "fib 前几项" do
      assert Ex18Streams.fib(8) == [0, 1, 1, 2, 3, 5, 8, 13]
    end
  end

  describe "resource" do
    test "打开与清理标签成对出现，值是各批拍平结果" do
      assert {[10, 20, 30], [:opened, :closed]} = Ex18Streams.resource_demo()
    end

    test "消费者提前 halt（take 1）也会调用 after 清理" do
      parent = self()

      stream =
        Stream.resource(
          fn ->
            send(parent, :opened)
            [1, 2, 3]
          end,
          fn
            [] -> {:halt, []}
            [h | t] -> {[h], t}
          end,
          fn _ ->
            send(parent, :closed)
            []
          end
        )

      assert Enum.take(stream, 1) == [1]
      assert_receive :opened
      assert_receive :closed
    end

    test "after 回调的返回值被丢弃，不能用来吐尾元素" do
      parent = self()

      result =
        Stream.resource(
          fn -> nil end,
          fn acc -> {[:a], acc} end,
          fn _ ->
            send(parent, :after_called)
            [:should_not_appear]
          end
        )
        |> Enum.take(1)

      assert result == [:a]
      assert_receive :after_called
    end

    test "each + run 副作用按源顺序发生" do
      assert Ex18Streams.run_each() == [{:tick, 1}, {:tick, 2}, {:tick, 3}]
    end
  end

  describe "chunk 家族" do
    test "chunk_every 整除时无短组" do
      assert Ex18Streams.pairs(6) == [[1, 2], [3, 4], [5, 6]]
    end

    test "chunk_every 最后不足一组保留为短组" do
      assert Ex18Streams.pairs(5) == [[1, 2], [3, 4], [5]]
    end

    test "chunk_by 连续同 key 归组，相同 key 断开也不合并" do
      assert Ex18Streams.parity_runs([1, 3, 2, 4, 5]) == [[1, 3], [2, 4], [5]]
      assert Ex18Streams.parity_runs([1, 2, 1]) == [[1], [2], [1]]
    end

    test "chunk_while 阈值成组，残余最后吐出" do
      assert Ex18Streams.running_groups(1..6, 5) == [[1, 2, 3], [4, 5], [6]]
      assert Ex18Streams.running_groups([1, 1, 1], 10) == [[1, 1, 1]]
    end

    test "无限奇数流取前 N 个，输出有界" do
      assert Ex18Streams.odds(5) == [1, 3, 5, 7, 9]
    end
  end

  # term() 包装：空列表字面量会被类型检查器判定「恒失败」，
  # 走 term() 参数把运行时才成立的错误与静态检查隔离开。
  @spec force_cycle(term()) :: term()
  defp force_cycle(enumerable), do: Enum.to_list(Stream.cycle(enumerable))
end
