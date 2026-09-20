defmodule Ex06ControlFlowTest do
  use ExUnit.Case, async: true

  doctest Ex06ControlFlow

  describe "case" do
    test "describe/1 按模式+守卫分派" do
      assert Ex06ControlFlow.describe({:ok, 1}) == :ok_tuple
      assert Ex06ControlFlow.describe({:error, :x}) == :error_tuple
      assert Ex06ControlFlow.describe(42) == {:integer, 42}
      assert Ex06ControlFlow.describe([1, 2]) == :non_empty_list
      assert Ex06ControlFlow.describe([]) == :empty_list
      assert Ex06ControlFlow.describe(:atom) == {:other, :atom}
    end

    test "tier/1 分支按顺序判定" do
      assert Ex06ControlFlow.tier(100) == :A
      assert Ex06ControlFlow.tier(90) == :A
      assert Ex06ControlFlow.tier(89) == :B
      assert Ex06ControlFlow.tier(0) == :C
      assert Ex06ControlFlow.tier(-1) == :invalid
      assert Ex06ControlFlow.tier(nil) == :invalid
    end

    test "case 没有分支匹配时抛 CaseError" do
      # 字面量必败匹配会被 1.20 静态判定为告警，放到运行时编译的字符串里
      assert_raise CaseClauseError, fn ->
        Code.eval_string("""
        case :unmatched do
          :other -> :never
        end
        """)
      end
    end
  end

  describe "cond" do
    test "fizzbuzz/1 对 1..15 的完整序列" do
      out = Enum.map(1..15, &Ex06ControlFlow.fizzbuzz/1)

      assert out == [
               1,
               2,
               "fizz",
               4,
               "buzz",
               "fizz",
               7,
               8,
               "fizz",
               "buzz",
               11,
               "fizz",
               13,
               14,
               "fizzbuzz"
             ]
    end

    test "classify_temp/1 四段" do
      assert Ex06ControlFlow.classify_temp(-10) == :freezing
      assert Ex06ControlFlow.classify_temp(0) == :cold
      assert Ex06ControlFlow.classify_temp(27) == :mild
      assert Ex06ControlFlow.classify_temp(28) == :hot
    end

    test "cond 没有 true 分支时抛 CondClauseError" do
      assert_raise CondClauseError, fn ->
        Code.eval_string("""
        cond do
          false -> :never
        end
        """)
      end
    end
  end

  describe "if / unless" do
    test "greeting/1 空串与非字符串都走 else" do
      assert Ex06ControlFlow.greeting("Ada") == "hello Ada"
      assert Ex06ControlFlow.greeting("") == "hello stranger"
      assert Ex06ControlFlow.greeting(nil) == "hello stranger"
    end

    test "positive_only/1 只放行正整数" do
      assert Ex06ControlFlow.positive_only(42) == 42
      assert Ex06ControlFlow.positive_only(0) == nil
      assert Ex06ControlFlow.positive_only(3.14) == nil
    end

    test "truthy_label/1：0 和空容器都是 truthy" do
      assert Ex06ControlFlow.truthy_label(0) == :truthy
      assert Ex06ControlFlow.truthy_label([]) == :truthy
      assert Ex06ControlFlow.truthy_label("") == :truthy
      assert Ex06ControlFlow.truthy_label(nil) == :falsy
      assert Ex06ControlFlow.truthy_label(false) == :falsy
    end
  end

  describe "with" do
    test "register/1 成功链与各步失败" do
      assert Ex06ControlFlow.register(%{name: "  Ada  "}) ==
               {:ok, %{id: :deterministic_id, name: "Ada"}}

      assert Ex06ControlFlow.register(%{name: ""}) == {:error, :invalid_name}

      assert Ex06ControlFlow.register(%{name: "   "}) ==
               {:error, {:unexpected, :blank_after_trim}}

      assert Ex06ControlFlow.register(%{}) == {:error, :invalid_name}
      assert Ex06ControlFlow.register(:not_a_map) == {:error, :invalid_name}

      assert Ex06ControlFlow.register(%{name: "this-name-is-way-too-long"}) ==
               {:error, :name_too_long}
    end

    test "chain/2 无 else 时失败值直接成为返回值" do
      assert Ex06ControlFlow.chain({:ok, 1}, {:ok, 2}) == 3
      assert Ex06ControlFlow.chain({:error, :x}, {:ok, 2}) == {:error, :x}
      assert Ex06ControlFlow.chain({:ok, 1}, :oops) == :oops
    end
  end

  describe "作用域" do
    test "if 块内重绑定不影响块外同名变量" do
      assert Ex06ControlFlow.rebind_inside(10) == 10
    end

    test "块内首次赋值的变量在块外不可见（编译期错误）" do
      # 编译诊断会写向 stderr，用 capture_io 收走，保证 mix test 的 stderr 干净
      diagnostic =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert_raise CompileError, fn ->
            Code.eval_string("""
            if true do
              y = 1
              y
            end
            y + 1
            """)
          end
        end)

      assert diagnostic =~ "undefined variable \"y\""
    end
  end
end
