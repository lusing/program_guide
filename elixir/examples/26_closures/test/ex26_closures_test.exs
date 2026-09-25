defmodule Ex26ClosuresTest do
  use ExUnit.Case, async: true

  doctest Ex26Closures

  describe "策略注入" do
    test "total_price/2 按注入的费用函数计价" do
      flat = Ex26Closures.fee(:flat)
      proportional = Ex26Closures.fee(:proportional)

      assert Ex26Closures.total_price(1000, flat) == 1005
      assert Ex26Closures.total_price(1000, proportional) == 1120.0
    end

    test "费用函数是普通值：可以存进 map" do
      fees = %{flat: Ex26Closures.fee(:flat), proportional: Ex26Closures.fee(:proportional)}
      assert is_function(fees.flat, 1)
      assert Map.get(fees, :flat).(100) == 5
    end
  end

  describe "捕获创建时刻的值" do
    test "freeze/1 之后重绑外部变量不影响闭包" do
      f = Ex26Closures.freeze(10)
      x = 10
      assert {f.(), x} == {11, 10}
      x = 999
      assert x == 999
      assert f.() == 11
    end

    test "每个闭包独立持有自己的那份值" do
      f1 = Ex26Closures.freeze(1)
      f2 = Ex26Closures.freeze(2)
      assert f1.() == 2
      assert f2.() == 3
    end

    test "inner_demo/0：内部绑定不影响外部" do
      assert Ex26Closures.inner_demo() == {130, 42}
    end
  end

  describe "遮蔽" do
    test "同名时参数（绑定变量）赢" do
      quantity = 2
      calculate = Ex26Closures.calculator()
      assert quantity == 2
      assert calculate.(4) == 800
      assert calculate.(2) == 400
    end
  end

  describe "闭包工厂与计数器" do
    test "两份问候互不干扰" do
      hello = Ex26Closures.make_greeter("Hello")
      hi = Ex26Closures.make_greeter("Hi")
      assert hello.("Ada") == "Hello, Ada!"
      assert hi.("Ada") == "Hi, Ada!"
    end

    test "counter：状态装进下一个闭包往下传" do
      c0 = Ex26Closures.counter(0)
      {v1, c1} = c0.()
      {v2, c2} = c1.()
      {v3, _c3} = c2.()
      assert {v1, v2, v3} == {0, 1, 2}
    end

    test "counter_values/2 收前 n 步的值" do
      assert Ex26Closures.counter_values(Ex26Closures.counter(0), 5) == [0, 1, 2, 3, 4]
      assert Ex26Closures.counter_values(Ex26Closures.counter(7), 3) == [7, 8, 9]
      assert Ex26Closures.counter_values(Ex26Closures.counter(0), 0) == []
    end
  end

  describe "& 捕获" do
    test "named_upcase/0 是 String.upcase/1 的引用" do
      assert Ex26Closures.named_upcase().("hello") == "HELLO"
      assert is_function(Ex26Closures.named_upcase(), 1)
    end

    test "multiply/0 由 &1/&2 推断出二元函数" do
      assert Ex26Closures.multiply().(10, 2) == 20
      assert is_function(Ex26Closures.multiply(), 2)
    end

    test "find_by_index/1 把列表腌进函数" do
      find = Ex26Closures.find_by_index(["Knight", "Wizard", "Rogue"])
      assert find.(0) == "Knight"
      assert find.(1) == "Wizard"
      assert find.(9) == nil
    end
  end

  describe "函数组合" do
    test "compose/2 先内后外" do
      shout = Ex26Closures.compose(&String.trim/1, &String.upcase/1)
      assert shout.("  hi  ") == "HI"
    end

    test "compose 满足结合律（同一串函数两种括法同结果）" do
      inc = &(&1 + 1)
      double = &(&1 * 2)
      tenx = &(&1 * 10)

      left = Ex26Closures.compose(Ex26Closures.compose(inc, double), tenx)
      right = Ex26Closures.compose(inc, Ex26Closures.compose(double, tenx))

      assert left.(3) == right.(3)
      assert left.(3) == 80
    end

    test "thread/2 依次应用一串函数" do
      assert Ex26Closures.thread("  hi  ", [&String.trim/1, &String.upcase/1]) == "HI"

      assert Ex26Closures.thread("  hi  ", [&String.trim/1, &String.upcase/1, &String.reverse/1]) ==
               "IH"

      assert Ex26Closures.thread(1, []) == 1
    end
  end
end
