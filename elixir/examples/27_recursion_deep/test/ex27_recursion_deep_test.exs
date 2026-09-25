defmodule Ex27RecursionDeepTest do
  use ExUnit.Case, async: true

  doctest Ex27RecursionDeep

  describe "有界递归" do
    test "up_to/1 等于 Enum.sum" do
      for n <- [0, 1, 5, 10, 100] do
        assert Ex27RecursionDeep.up_to(n) == Enum.sum(0..n//1)
        assert Ex27RecursionDeep.up_to_tail(n) == Enum.sum(0..n//1)
      end
    end

    test "尾递归百万级不爆栈" do
      assert Ex27RecursionDeep.up_to_tail(1_000_000) == 500_000_500_000
    end

    test "up_to/1 拒绝负数（守卫挡住）" do
      assert_raise FunctionClauseError, fn -> Ex27RecursionDeep.up_to(-1) end
    end
  end

  describe "魔法商店" do
    test "已施法的物品原样保留，未施法的 ×3 并改名" do
      [a, b, c, d] = Ex27RecursionDeep.enchant_for_sale(Ex27RecursionDeep.test_data())

      assert a == %{title: "Edwin's Longsword", price: 150, magic: true}
      assert b == %{title: "Healing Potion", price: 60, magic: true}
      assert c == %{title: "Edwin's Rope", price: 30, magic: true}
      assert d == %{title: "Dragon's Spear", price: 100, magic: true}
    end

    test "空列表是边界子句" do
      assert Ex27RecursionDeep.enchant_for_sale([]) == []
    end

    test "递归版与 Enum.map 版一致" do
      data = Ex27RecursionDeep.test_data()
      assert Ex27RecursionDeep.enchant_for_sale(data) == Ex27RecursionDeep.enchant_enum(data)
    end
  end

  describe "减治法" do
    test "手写版只认 0..4" do
      assert Ex27RecursionDeep.naive_factorial(0) == 1
      assert Ex27RecursionDeep.naive_factorial(4) == 24
      assert_raise FunctionClauseError, fn -> Ex27RecursionDeep.naive_factorial(5) end
    end

    test "factorial/1 与 factorial_tail/1 全域一致" do
      for n <- 0..20 do
        assert Ex27RecursionDeep.factorial(n) == Ex27RecursionDeep.factorial_tail(n)
      end

      assert Ex27RecursionDeep.factorial(10) == 3_628_800
    end

    test "负数被守卫挡下" do
      assert_raise FunctionClauseError, fn -> Ex27RecursionDeep.factorial(-1) end
      assert_raise FunctionClauseError, fn -> Ex27RecursionDeep.factorial_tail(-1) end
    end
  end

  describe "分治法：归并排序" do
    test "升序与 Enum.sort 一致（数字、重复、字符串、空表）" do
      lists = [
        [9, 5, 1, 5, 4],
        [2, 2, 3, 1],
        [1],
        [],
        [3, 3, 3],
        ["c", "d", "a", "c"]
      ]

      for list <- lists do
        assert Ex27RecursionDeep.ascending(list) == Enum.sort(list)
      end
    end

    test "降序是升序的反转" do
      list = [9, 5, 1, 5, 4]
      assert Ex27RecursionDeep.descending(list) == Enum.reverse(Enum.sort(list))
    end

    test "百元列表排序稳定通过" do
      list = Enum.map(1..100, &rem(&1 * 37, 101))
      assert Ex27RecursionDeep.ascending(list) == Enum.sort(list)
    end
  end

  describe "无界递归：虚拟文件系统" do
    test "max_depth 1：下钻一层，deep 被记录但不进入" do
      assert Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 1) == %{
               visited: ["/lib", "/lib/deep"],
               files: 3,
               symlink_skipped: ["loop -> lib"]
             }
    end

    test "max_depth 2：记录 deeper 但不进入，x.ex 数不上" do
      assert Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 2) == %{
               visited: ["/lib", "/lib/deep", "/lib/deep/deeper"],
               files: 3,
               symlink_skipped: ["loop -> lib"]
             }
    end

    test "max_depth 3：x.ex 被数到" do
      assert Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 3) == %{
               visited: ["/lib", "/lib/deep", "/lib/deep/deeper"],
               files: 4,
               symlink_skipped: ["loop -> lib"]
             }
    end

    test "空树与纯文件树" do
      assert Ex27RecursionDeep.walk([], 3) == %{visited: [], files: 0, symlink_skipped: []}

      assert Ex27RecursionDeep.walk([{:file, "a"}, {:file, "b"}], 1) == %{
               visited: [],
               files: 2,
               symlink_skipped: []
             }
    end
  end

  describe "匿名函数自递归" do
    test "make_factorial 自应用可用" do
      f = Ex27RecursionDeep.make_factorial()
      assert f.(0) == 1
      assert f.(5) == 120
      assert f.(10) == 3_628_800
    end

    test "named_factorial 与 factorial 一致" do
      f = Ex27RecursionDeep.named_factorial()
      assert is_function(f, 1)

      for n <- 0..10 do
        assert f.(n) == Ex27RecursionDeep.factorial(n)
      end
    end
  end

  describe "体递归 vs 尾递归" do
    test "十万级阶乘答案逐位一致" do
      assert Ex27RecursionDeep.factorial(100_000) == Ex27RecursionDeep.factorial_tail(100_000)
    end
  end
end
