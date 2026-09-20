defmodule Ex04PatternMatchingTest do
  use ExUnit.Case, async: true

  doctest Ex04PatternMatching

  describe "元组解构 / {:ok,_} {:error,_}" do
    test "classify/1 按形状分派三种返回值" do
      assert Ex04PatternMatching.classify({:ok, 1}) == :ok_value
      assert Ex04PatternMatching.classify({:error, :x}) == :error_value
      assert Ex04PatternMatching.classify({:other, 1}) == :something_else
      assert Ex04PatternMatching.classify(:plain_atom) == :something_else
    end

    test "ok_value/1 成功取值，否则 nil" do
      assert Ex04PatternMatching.ok_value({:ok, 9}) == 9
      assert Ex04PatternMatching.ok_value({:error, :x}) == nil
      assert Ex04PatternMatching.ok_value("anything") == nil
    end
  end

  describe "列表与嵌套解构" do
    test "head_tail/1 分解头尾，空列表给 :empty" do
      assert Ex04PatternMatching.head_tail([1, 2, 3]) == {:ok, 1, [2, 3]}
      assert Ex04PatternMatching.head_tail([:only]) == {:ok, :only, []}
      assert Ex04PatternMatching.head_tail([]) == {:error, :empty}
    end

    test "pair?/1 只接受恰好两个元素" do
      assert Ex04PatternMatching.pair?([:a, :b])
      refute Ex04PatternMatching.pair?([:a])
      refute Ex04PatternMatching.pair?([:a, :b, :c])
      refute Ex04PatternMatching.pair?({:a, :b})
    end

    test "city/1 从元组套 map 里深层解构" do
      assert Ex04PatternMatching.city({:user, "Ada", %{city: "London"}}) == "London"
      assert Ex04PatternMatching.city({:user, "Ada", %{}}) == :unknown
      assert Ex04PatternMatching.city("nope") == :unknown
    end
  end

  describe "pin（^）与重复变量" do
    test "match_status/2 用 ^expected 比较实际值" do
      assert Ex04PatternMatching.match_status(200, 200) == {:ok, 200}
      assert Ex04PatternMatching.match_status(404, 200) == {:mismatch, 404}
      assert Ex04PatternMatching.match_status("ok", "ok") == {:ok, "ok"}
    end

    test "same_pair/1 的 {x, x} 要求两个元素相等" do
      assert Ex04PatternMatching.same_pair({1, 1})
      refute Ex04PatternMatching.same_pair({1, 2})
    end

    test "不用 ^ 是重新绑定，用 ^ 才是拿已有值去匹配" do
      # 第二次 v = 是重新绑定；RHS 的 v 引用旧值 1（不写成 v = 2，否则首绑定 unused 告警）
      v = 1
      v = v + 1
      assert v == 2

      # ^v 此时拿 2 去匹配：= 2 成功，= 3 抛 MatchError
      _ = ^v = 2
      assert_raise MatchError, fn -> ^v = 3 end
    end

    test "^pin 解构固定值" do
      expected = 200
      assert {^expected, body} = {200, "OK"}
      assert body == "OK"
      assert_raise MatchError, fn -> {^expected, _} = {404, "NF"} end
    end
  end

  describe "map 部分匹配与动态键" do
    test "has_name?/1 只要求键存在，多余键无所谓" do
      assert Ex04PatternMatching.has_name?(%{name: "x", age: 1})
      refute Ex04PatternMatching.has_name?(%{age: 1})
    end

    test "get_key/2 用 ^key 取运行时才确定的键" do
      assert Ex04PatternMatching.get_key(%{a: 1, b: 2}, :b) == {:ok, 2}
      assert Ex04PatternMatching.get_key(%{a: 1}, :b) == :error
      assert Ex04PatternMatching.get_key(%{"name" => "Ada"}, "name") == {:ok, "Ada"}
    end

    test "%{k: v} 部分匹配对不存在的键直接 MatchError" do
      assert Ex04PatternMatching.force_key!(%{a: 1}, :a) == :ok

      assert_raise MatchError, fn ->
        Ex04PatternMatching.force_key!(%{present: 1}, :missing)
      end
    end
  end

  describe "二进制匹配" do
    test "strip_prefix/2 剥掉变量前缀" do
      assert Ex04PatternMatching.strip_prefix("Hello, world", "Hello, ") == {:ok, "world"}
      assert Ex04PatternMatching.strip_prefix("goodbye", "Hello, ") == :error
      assert Ex04PatternMatching.strip_prefix("data:42", "data:") == {:ok, "42"}
    end

    test "split_32/1 把前四字节当大端整数，余下原样返回" do
      assert Ex04PatternMatching.split_32(<<1, 0, 0, 0, 9, 8>>) == {:ok, 16_777_216, <<9, 8>>}
      assert Ex04PatternMatching.split_32(<<0, 0, 0, 255>>) == {:ok, 255, ""}
      assert Ex04PatternMatching.split_32(<<1, 2>>) == :error
    end
  end

  describe "match?/2 与推导式过滤" do
    test "ok?/1 永不抛错" do
      assert Ex04PatternMatching.ok?({:ok, 1})
      assert Ex04PatternMatching.ok?({:ok, :anything})
      refute Ex04PatternMatching.ok?({:error, :x})
      refute Ex04PatternMatching.ok?(:nope)
    end

    test "select_ok/1 只留下成功元组里的值，顺序不变" do
      assert Ex04PatternMatching.select_ok([{:ok, 1}, {:error, :x}, {:ok, 3}]) == [1, 3]
      assert Ex04PatternMatching.select_ok([{:error, :x}]) == []
    end

    test "match?/2 可直接用于 Enum.filter" do
      out = Enum.filter([{:ok, 1}, :bad, {:ok, 2}], &match?({:ok, _}, &1))
      assert out == [{:ok, 1}, {:ok, 2}]
    end
  end
end
