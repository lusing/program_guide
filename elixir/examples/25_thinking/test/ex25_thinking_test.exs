defmodule Ex25ThinkingTest do
  use ExUnit.Case, async: true

  doctest Ex25Thinking
  doctest Ex25Thinking.MySet

  describe "不可变数据" do
    test "without_last/1 与 append/2 都不动原列表" do
      list = [1, 2, 3, 4]
      assert Ex25Thinking.without_last(list) == [1, 2, 3]
      assert Ex25Thinking.append(list, 5) == [1, 2, 3, 4, 5]
      assert list == [1, 2, 3, 4]
    end

    test "cons 出的新列表与旧列表共享尾部（结构共享）" do
      base = Ex25Thinking.runtime_list()
      newer = Ex25Thinking.cons_ahead(base)
      assert newer == [0, 1, 2, 3]
      assert :erts_debug.same(tl(newer), base)
    end

    test "++ 拼接复制左表，尾部与旧列表不共享" do
      base = Ex25Thinking.runtime_list()
      copy = Ex25Thinking.append_copy(base)
      assert copy == [1, 2, 3, 4]
      assert Enum.take(copy, 3) == base
      refute :erts_debug.same(tl(copy), tl(base))
    end

    test "字面量前缀的 ++ 被编译器重写为 cons，也共享尾部" do
      base = Ex25Thinking.runtime_list()
      appended = [0] ++ base
      assert :erts_debug.same(tl(appended), base)
    end
  end

  describe "纯函数" do
    test "同参同果：多次调用结果一致" do
      assert Ex25Thinking.add2(2) == 4
      assert Ex25Thinking.tax(100, 8) == Ex25Thinking.tax(100, 8)
      assert Ex25Thinking.tax(100, 8) == 8.0
    end

    test "纯函数的坏输入永远得到同一个异常" do
      # 用 apply 绕开静态类型：1.20 检查器对字面量 nil 传参报「类型不兼容」
      assert_raise ArithmeticError, fn -> apply(Ex25Thinking, :tax, [nil, 8]) end
    end
  end

  describe "MySet：状态显式流动" do
    test "push 返回新集合，旧集合不变" do
      set0 = %Ex25Thinking.MySet{}
      set1 = Ex25Thinking.MySet.push(set0, "apple")
      set2 = Ex25Thinking.MySet.push(set1, "pie")

      assert set1.items == ["apple"]
      assert set2.items == ["apple", "pie"]
      assert set1 != set2
    end

    test "push 幂等：重复元素不加" do
      set = %Ex25Thinking.MySet{} |> Ex25Thinking.MySet.push("apple")
      assert Ex25Thinking.MySet.push(set, "apple") == set
    end

    test "member?/2 查询无副作用" do
      set = %Ex25Thinking.MySet{} |> Ex25Thinking.MySet.push("apple")
      assert Ex25Thinking.MySet.member?(set, "apple")
      refute Ex25Thinking.MySet.member?(set, "pie")
      assert set.items == ["apple"]
    end

    test "myset_demo/0 是 push 的流水线" do
      assert Ex25Thinking.myset_demo() == ["apple", "pie"]
    end
  end

  describe "声明式三写法" do
    test "upcase_rec 与 upcase_map 等价" do
      words = ["dogs", "hot dogs", "bananas"]

      assert Ex25Thinking.upcase_rec(words) == Ex25Thinking.upcase_map(words)
      assert Ex25Thinking.upcase_rec(words) == ["DOGS", "HOT DOGS", "BANANAS"]
      assert Ex25Thinking.upcase_rec([]) == []
    end

    test "upcase_rec 与 Enum.map + &String.upcase/1 语义相同" do
      for words <- [["a"], [], ["x", "y", "z"], ["你好", "world"]] do
        assert Ex25Thinking.upcase_rec(words) == Enum.map(words, &String.upcase/1)
      end
    end
  end

  describe "管道" do
    test "capitalize_words 管道版与嵌套版等价" do
      for title <- ["the dark tower", "a", "", "hello world again"] do
        assert Ex25Thinking.capitalize_words(title) == Ex25Thinking.capitalize_words_nested(title)
      end

      assert Ex25Thinking.capitalize_words("the dark tower") == "The Dark Tower"
      assert Ex25Thinking.capitalize_words("") == ""
    end
  end
end
