defmodule Ex07EnumTest do
  use ExUnit.Case, async: true

  doctest Ex07Enum

  describe "Enumerable 协议覆盖面" do
    test "列表、map、Range、MapSet、2-arity 函数是 Enumerable" do
      assert Ex07Enum.enumerable_impl([1, 2]) == "Enumerable.List"
      assert Ex07Enum.enumerable_impl(%{a: 1}) == "Enumerable.Map"
      assert Ex07Enum.enumerable_impl(1..3) == "Enumerable.Range"
      assert Ex07Enum.enumerable_impl(MapSet.new([1])) == "Enumerable.MapSet"

      fun = fn _, acc -> {:cont, acc} end
      assert Ex07Enum.enumerable_impl(fun) == "Enumerable.Function"
    end

    test "tuple、二进制、整数不是 Enumerable" do
      assert Ex07Enum.enumerable_impl({1, 2}) == nil
      assert Ex07Enum.enumerable_impl("abc") == nil
      assert Ex07Enum.enumerable_impl(42) == nil
      assert_raise Protocol.UndefinedError, fn -> Enum.to_list({1, 2}) end
    end
  end

  describe "reduce 手写版与标准版等价" do
    test "equivalence_check 汇总断言" do
      assert Ex07Enum.equivalence_check() == {3, true}
    end

    test "my_map 与 Enum.map 在多种输入上等价" do
      for input <- [[], [1, 2, 3], -5..5, %{x: 1, y: 2}] do
        assert Ex07Enum.my_map(input, &inspect/1) == Enum.map(input, &inspect/1)
      end
    end

    test "my_take 在无限流上也能停下（reduce_while 的 halt 能力）" do
      infinite = Stream.repeatedly(fn -> 7 end)
      assert Ex07Enum.my_take(infinite, 3) == [7, 7, 7]
      assert Enum.take(infinite, 3) == [7, 7, 7]
    end
  end

  describe "惰性 vs 立即" do
    test "Stream 只求值被拉取的部分，Enum 全量求值" do
      assert Ex07Enum.lazy_vs_eager(50) == {[2, 4, 6], 3, [2, 4, 6], 50}
    end
  end

  describe "管道" do
    test "宏展开后与嵌套调用逐字一致" do
      assert Ex07Enum.pipe_proof() == {"a |> b() |> c(1)", "c(b(a), 1)"}
    end

    test "管道写法与嵌套写法结果相同" do
      for s <- ["  Hello  ", "", " 世界 "] do
        assert Ex07Enum.pipe_style(s) == Ex07Enum.nested_style(s)
      end
    end
  end

  describe "排序" do
    test "非严格比较稳定，严格比较会调换相等元素" do
      result = Ex07Enum.sort_stability()

      # 原顺序：{1,:a}, {0,:b}, {1,:c}, {0,:d}
      # 稳定 = 相等键保持原相对顺序（:a 在 :c 前，:b 在 :d 前）
      assert result[:asc_non_strict] == [{0, :b}, {0, :d}, {1, :a}, {1, :c}]
      assert result[:desc_non_strict] == [{1, :a}, {1, :c}, {0, :b}, {0, :d}]
      # 严格比较把相等元素的顺序翻了
      assert result[:asc_strict] == [{0, :d}, {0, :b}, {1, :c}, {1, :a}]
      assert result[:desc_strict] == [{1, :c}, {1, :a}, {0, :d}, {0, :b}]
    end

    test ":lt/:eq/:gt 比较器可以直接用，方向可指定" do
      assert Ex07Enum.sort_dates() == [~D[2024-01-01], ~D[2024-03-15], ~D[2024-12-31]]
      assert Ex07Enum.sort_dates_desc() == [~D[2024-12-31], ~D[2024-03-15], ~D[2024-01-01]]
    end
  end

  describe "不确定函数只断言性质" do
    test "shuffle 是排列、random 是成员（重复 5 次都成立）" do
      for _ <- 1..5 do
        assert Ex07Enum.shuffle_is_permutation?(1..20)
        assert Ex07Enum.random_is_member?(~w(a b c))
      end
    end
  end

  describe "多次遍历 vs 单次 reduce" do
    test "结果等价" do
      assert Ex07Enum.multi_pass(1..30) == Ex07Enum.single_pass(1..30)
      assert Ex07Enum.multi_pass([]) == Ex07Enum.single_pass([])
    end
  end

  describe "map 顺序纪律" do
    test "frequencies / group_by 排序后输出确定" do
      assert Ex07Enum.frequencies_sorted(~w(b a b)) == [{"a", 1}, {"b", 2}]

      assert Ex07Enum.group_by_rem_sorted(1..6, 2) ==
               [{0, [2, 4, 6]}, {1, [1, 3, 5]}]
    end
  end
end
