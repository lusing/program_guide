defmodule Ex23MacrosTypesTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  require Ex23Macros

  doctest Ex23MacrosTypes
  doctest Ex23Macros.Money

  alias Ex23Macros
  alias Ex23Macros.{Greeting, Money}

  describe "宏" do
    test "debug 打印源码与值并原值返回" do
      output =
        capture_io(fn ->
          assert Ex23Macros.debug(1 + 2) == 3
        end)

      assert String.trim(output) == "1 + 2 => 3"
    end

    test "my_unless 真假两态" do
      assert Ex23Macros.my_unless(1 == 2, do: :ran) == :ran
      assert Ex23Macros.my_unless(1 == 1, do: :ran) == nil
    end
  end

  describe "use 注入" do
    test "greet 是编译期注入的函数" do
      assert Greeting.greet("世界") == "嗨，世界"
      assert function_exported?(Greeting, :greet, 1)
    end
  end

  describe "Money 类型模块" do
    test "pair_key 读私有类型 pair" do
      a = %Money{amount: 1, currency: :USD}
      assert Money.pair_key({a, %Money{}}) == :USD
    end

    test "同币种合计" do
      m1 = %Money{amount: 200, currency: :USD}
      m2 = %Money{amount: 300, currency: :USD}
      assert Money.add(m1, m2) == {:ok, %Money{amount: 500, currency: :USD}}
    end
  end

  describe "类型检查器演示" do
    test "checker_demo 返回归一化标签" do
      assert Ex23MacrosTypes.checker_demo() == [warning: true, always_a: true]
    end
  end
end
