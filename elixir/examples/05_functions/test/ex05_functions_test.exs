defmodule Ex05FunctionsTest do
  use ExUnit.Case, async: true

  doctest Ex05Functions

  describe "多子句分派与守卫" do
    test "sign/1 覆盖正、零、负与非数字" do
      assert Ex05Functions.sign(5) == :positive
      assert Ex05Functions.sign(3.14) == :positive
      assert Ex05Functions.sign(0) == :zero
      assert Ex05Functions.sign(-3) == :negative
      assert Ex05Functions.sign(-3.14) == :negative
      assert Ex05Functions.sign("x") == :not_a_number
      assert Ex05Functions.sign(:atom) == :not_a_number
    end

    test "http_label/1 按区间分派" do
      assert Ex05Functions.http_label(200) == :success
      assert Ex05Functions.http_label(204) == :success
      assert Ex05Functions.http_label(301) == :redirect
      assert Ex05Functions.http_label(404) == :client_error
      assert Ex05Functions.http_label(503) == :server_error
      assert Ex05Functions.http_label(600) == :unknown
      assert Ex05Functions.http_label(:not_a_code) == :unknown
    end

    test "守卫里 hd([]) 出错只让子句落选，不抛异常" do
      assert Ex05Functions.first_is_ok?([:ok])
      refute Ex05Functions.first_is_ok?([:no])
      refute Ex05Functions.first_is_ok?([])
      refute Ex05Functions.first_is_ok?(:not_a_list)
    end
  end

  describe "默认参数与函数头" do
    test "join/2 用默认分隔符，join/3 可覆盖" do
      assert Ex05Functions.join("a", "b") == "a, b"
      assert Ex05Functions.join("a", "b", "-") == "a-b"
      assert Ex05Functions.join(1, 2, "-") == {:non_binary, 1, 2}
    end

    test "默认参数同时产生 join/2 与 join/3 两个 arity" do
      assert function_exported?(Ex05Functions, :join, 2)
      assert function_exported?(Ex05Functions, :join, 3)
    end
  end

  describe "递归" do
    test "fact/1 与 fact_tail/1 结果一致" do
      for n <- 0..20 do
        assert Ex05Functions.fact(n) == Ex05Functions.fact_tail(n)
      end

      assert Ex05Functions.fact(10) == 3_628_800
    end

    test "sum/1 与 sum_tail/1 结果一致且与 Enum.sum 相同" do
      list = [3, -1, 7, 0, 4]
      assert Ex05Functions.sum(list) == 13
      assert Ex05Functions.sum_tail(list) == 13
      assert Ex05Functions.sum([]) == 0
    end

    test "my_length/1 等同 length/1" do
      assert Ex05Functions.my_length([]) == 0
      assert Ex05Functions.my_length([:a, :b, :c]) == 3
    end

    test "my_reverse/1 等同 Enum.reverse/1" do
      assert Ex05Functions.my_reverse([]) == []
      assert Ex05Functions.my_reverse([1, 2, 3]) == [3, 2, 1]
    end
  end

  describe "高阶函数" do
    test "twice/2 连续作用两次" do
      assert Ex05Functions.twice(fn x -> x <> x end, "ab") == "abababab"
    end

    test "adder/1 返回捕获 n 的闭包" do
      add10 = Ex05Functions.adder(10)
      assert add10.(5) == 15
      assert is_function(add10, 1)
    end

    test "my_map/2 等同 Enum.map/2" do
      list = [1, 2, 3, 4]
      assert Ex05Functions.my_map(list, fn x -> x * x end) == [1, 4, 9, 16]
      assert Ex05Functions.my_map([], fn x -> x end) == []
    end

    test "my_filter/2 等同 Enum.filter/2" do
      list = [1, 2, 3, 4, 5, 6]
      assert Ex05Functions.my_filter(list, fn x -> rem(x, 2) == 0 end) == [2, 4, 6]
      assert Ex05Functions.my_filter(list, fn _ -> false end) == []
    end

    test "my_reduce/3 等同 Enum.reduce/3" do
      list = ["a", "b", "c"]

      assert Ex05Functions.my_reduce(list, "", fn x, acc -> acc <> x end) == "abc"
    end

    test "my_take/2 处理 0、越界与非法参数" do
      assert Ex05Functions.my_take([1, 2, 3, 4], 0) == []
      assert Ex05Functions.my_take([1, 2, 3, 4], 2) == [1, 2]
      assert Ex05Functions.my_take([1], 5) == [1]
      assert Ex05Functions.my_take([], 3) == []
      assert Ex05Functions.my_take([1, 2], -1) == :error
      assert Ex05Functions.my_take(:not_a_list, 1) == :error
    end

    test "捕获操作符 & 可以直接当函数参数传" do
      assert Ex05Functions.my_map([1, 2, 3], &(&1 + 1)) == [2, 3, 4]
      assert Ex05Functions.my_reduce([1, 2, 3], 0, &+/2) == 6
    end
  end

  describe "嵌套递归" do
    test "deep_sum/1 递归进入嵌套列表，跳过非数字" do
      assert Ex05Functions.deep_sum([1, [2, [3]], 4, [5, [6]]]) == 21
      assert Ex05Functions.deep_sum([1, :skip, [2, nil]]) == 3
      assert Ex05Functions.deep_sum([]) == 0
    end
  end

  describe "TCO：尾递归与相互递归" do
    test "count_down/1 百万次级尾递归不爆栈" do
      assert Ex05Functions.count_down(1_000_000) == :done
    end

    test "even?/1 与 odd?/1 相互尾递归" do
      assert Ex05Functions.even?(1_000_000)
      refute Ex05Functions.odd?(1_000_000)
      refute Ex05Functions.even?(999_999)
      assert Ex05Functions.odd?(999_999)
    end

    test "体递归与尾递归在百万列表上答案相同" do
      big = Enum.to_list(1..1_000_000)
      answer = 500_000_500_000
      assert Ex05Functions.sum(big) == answer
      assert Ex05Functions.sum_tail(big) == answer
    end
  end
end
