defmodule Ex11ErrorsTest do
  use ExUnit.Case, async: true

  doctest Ex11Errors

  alias Ex11Errors

  describe "tagged tuple 流水线" do
    test "parse_port 的三种结果" do
      assert Ex11Errors.parse_port("8080") == {:ok, 8080}
      assert Ex11Errors.parse_port("80x") == {:error, {:not_an_integer, "80x"}}
      assert Ex11Errors.parse_port("abc") == {:error, {:not_an_integer, "abc"}}
    end

    test "bounded_port 范围外给 reason" do
      assert Ex11Errors.bounded_port(1) == {:ok, 1}
      assert Ex11Errors.bounded_port(65535) == {:ok, 65535}
      assert Ex11Errors.bounded_port(0) == {:error, {:out_of_range, 0}}
      assert Ex11Errors.bounded_port(70000) == {:error, {:out_of_range, 70000}}
    end

    test "configure 用 with 短路，失败点即返回" do
      assert Ex11Errors.configure("8080") == {:ok, %{port: 8080}}
      assert Ex11Errors.configure("70000") == {:error, {:out_of_range, 70000}}
      assert Ex11Errors.configure("nope") == {:error, {:not_an_integer, "nope"}}
    end
  end

  describe "异常" do
    test "parse_int! 成功返回裸值，失败抛 ArgumentError" do
      assert Ex11Errors.parse_int!("42") == 42

      assert_raise ArgumentError, ~S{not an integer: "x"}, fn ->
        Ex11Errors.parse_int!("x")
      end
    end

    test "自定义异常带字段与 message 实现" do
      e =
        assert_raise Ex11Errors.ValidationError, "age: got 200, must be 0..150", fn ->
          Ex11Errors.validate_age(200)
        end

      assert e.field == :age
      assert e.message == "got 200, must be 0..150"
      assert Ex11Errors.validate_age(0) == 0
      assert Ex11Errors.validation_message(:email, "is required") == "email: is required"
    end

    test "KeyError 与 FunctionClauseError 的标准形态" do
      assert_raise KeyError, fn -> Keyword.fetch!([], :missing) end

      # 注意：bounded_port/1 有 catch-all 子句，跨类型输入只会走到失败分支，
      # 不抛 FunctionClauseError；这里用 Code.eval_string 在运行时给
      # parse_int!/1 喂一个 atom（绕开静态类型检查器），由 Integer.parse/1
      # 的守卫拒绝并抛 FunctionClauseError。
      assert_raise FunctionClauseError, fn ->
        Code.eval_string("Ex11Errors.parse_int!(v)", v: :not_a_binary)
      end
    end
  end

  describe "rescue / catch / after" do
    test "safe/1 在边界把异常转成 {:error, {异常类型, 消息}}" do
      assert Ex11Errors.safe(fn -> 1 + 1 end) == {:ok, 2}

      assert Ex11Errors.safe(fn -> Ex11Errors.parse_int!("x") end) ==
               {:error, {ArgumentError, ~S{not an integer: "x"}}}

      assert Ex11Errors.safe(fn -> Ex11Errors.validate_age(999) end) ==
               {:error, {Ex11Errors.ValidationError, "age: got 999, must be 0..150"}}
    end

    test "with_cleanup 的 after 必定发清理消息" do
      assert Ex11Errors.with_cleanup() == :recovered
      assert_receive :cleaned_up
    end

    test "不抛异常时 after 同样执行" do
      result =
        try do
          :ok
        after
          send(self(), :cleaned_always)
        end

      assert result == :ok
      assert_receive :cleaned_always
    end

    test "find_even 用 throw 做非局部返回" do
      assert Ex11Errors.find_even([1, 3, 4, 5]) == {:found, 4}
      assert Ex11Errors.find_even([1, 3, 5]) == :not_found
    end

    test "catch_exit 接住 :exit 信号且当前进程不死" do
      assert Ex11Errors.catch_exit(fn -> exit(:shutdown) end) ==
               {:caught, :exit, :shutdown}

      assert Process.alive?(self())
    end

    test "catch 能区分三类信号" do
      result =
        try do
          throw({:nonlocal, 1})
        catch
          :throw, value -> {:thrown, value}
          :exit, reason -> {:exited, reason}
          :error, error -> {:errored, error}
        end

      assert result == {:thrown, {:nonlocal, 1}}
    end

    test "format_raised 取出异常类型与消息" do
      assert Ex11Errors.format_raised(fn -> raise ArgumentError, "x" end) ==
               {ArgumentError, "x"}
    end
  end
end
