defmodule Ex10ProtocolsTest do
  use ExUnit.Case, async: true

  doctest Ex10Protocols

  alias Ex10Protocols
  alias Ex10Protocols.{Bag, Box, Describable, Secret}

  describe "协议按数据类型分派" do
    test "内置类型" do
      assert Ex10Protocols.report(42) == {:number, "number 42"}
      assert Ex10Protocols.report(3.14) == {:number, "number 3.14"}
      assert Ex10Protocols.report("hello") == {:text, "string of 5 grapheme(s)"}
      assert Ex10Protocols.report([1, 2]) == {:sequence, "list of 2 element(s)"}
    end

    test "struct 的显式实现" do
      assert Ex10Protocols.report(%Box{item: 1}) == {:container, "box holding 1"}
    end

    test "没有专门实现的类型落到 Any" do
      assert Ex10Protocols.report(:hello) == {:unknown, "unknown :hello"}
      assert Ex10Protocols.report({1, 2}) == {:unknown, "unknown {1, 2}"}
    end

    test "@derive 复用 Any 实现" do
      bag = %Bag{items: [1]}
      assert Ex10Protocols.report(bag) == {:unknown, "unknown #{inspect(bag)}"}
    end

    test "describe_all 逐项分派" do
      assert Ex10Protocols.describe_all([1, "a"]) ==
               [{:number, "number 1"}, {:text, "string of 1 grapheme(s)"}]
    end
  end

  describe "协议的运行时机制" do
    test "impl_for 返回实现模块，fallback 让任何类型都有归属" do
      assert Ex10Protocols.impl_module(42) == Ex10Protocols.Describable.Integer
      assert Ex10Protocols.impl_module(%Box{}) == Ex10Protocols.Describable.Ex10Protocols.Box
      assert Ex10Protocols.impl_module(:x) == Ex10Protocols.Describable.Any
    end

    test "没有 Any 兜底的内置协议查 struct 返回 nil，调用抛 Protocol.UndefinedError" do
      assert Enumerable.impl_for(%Box{}) == nil

      assert_raise Protocol.UndefinedError, fn ->
        Code.eval_string("Enum.count(%Ex10Protocols.Box{})")
      end
    end

    test "协议在 mix 下被合并" do
      assert Protocol.consolidated?(Describable)
      info = Ex10Protocols.impl_summary()
      assert info.consolidated?
      # :impls 清单给的是「类型」模块名，impl_for/1 给的才是实现模块名
      assert Integer in info.impls
      assert Ex10Protocols.Bag in info.impls
      assert Any in info.impls
    end
  end

  describe "内置协议" do
    test "自定义 Inspect 改变 inspect 输出" do
      assert inspect(%Secret{value: 42}) == "#Secret<masked:42>"
    end

    test "自定义 String.Chars 让 to_string 可用" do
      assert to_string(%Secret{value: 7}) == "secret(7)"
    end

    test "普通 struct 两种协议都没有，safe_* 转成标签" do
      assert Ex10Protocols.safe_count(%Box{}) == {:raised, Protocol.UndefinedError}
      assert Ex10Protocols.safe_to_string(%Box{}) == {:raised, Protocol.UndefinedError}
    end

    test "列表正常实现 Enumerable 与 Collectable" do
      assert Ex10Protocols.safe_count([1, 2, 3]) == 3
      assert Enum.into([1, 2], MapSet.new()) |> MapSet.equal?(MapSet.new([1, 2]))
    end
  end

  describe "行为是编译期契约" do
    alias Ex10Protocols.{MemoryStorage, Storage}

    test "MemoryStorage 完整实现 Storage" do
      s = MemoryStorage.new() |> MemoryStorage.put(:a, 1) |> MemoryStorage.put(:b, 2)
      assert MemoryStorage.get(s, :a) == {:ok, 1}
      assert MemoryStorage.get(s, :z) == :error
      assert MemoryStorage.keys(s) == [:a, :b]
      assert Storage.fetch!(MemoryStorage, s, :a) == 1

      assert_raise KeyError, fn ->
        Storage.fetch!(MemoryStorage, s, :missing)
      end
    end

    test "行为回调清单含可选回调" do
      callbacks = Storage.behaviour_info(:callbacks)
      assert {:get, 2} in callbacks
      assert {:put, 3} in callbacks
      assert {:keys, 1} in callbacks
    end

    # 动态编译会注册全局模块名，不能与其他用例并行。
    @tag :compile_diagnostic
    test "漏写必选回调会产生编译诊断" do
      msg = Ex10Protocols.missing_callback_diagnostic()
      assert msg =~ "required by behaviour Ex10Protocols.Storage"
      assert msg =~ "is not implemented"
    end
  end
end
