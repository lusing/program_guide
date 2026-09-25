defmodule Ex28ErrorMonadTest do
  use ExUnit.Case, async: true

  import Ex28ErrorMonad, only: [ok: 1, error: 1, ok?: 1, bind: 2, ~>>: 2]
  doctest Ex28ErrorMonad
  doctest Ex28ErrorMonad.InvalidOptionError

  @batches [
    ["10", "20"],
    ["hot dog", "20"],
    ["10", "hot dog"],
    ["10"],
    [],
    ["3", "7", "unused"]
  ]

  describe "纯与非纯" do
    test "net_price 同参同果" do
      assert Ex28ErrorMonad.net_price(100, 10) == 90.0
      assert Ex28ErrorMonad.net_price(100, 10) == Ex28ErrorMonad.net_price(100, 10)
    end

    test "purity_table 覆盖常见副作用源" do
      table = Ex28ErrorMonad.purity_table()
      assert Enum.count(table) == 5
      assert {_, :pure} = List.first(table)
      assert Enum.all?(Enum.slice(table, 1..4//1), fn {_, tag} -> tag == :impure end)
    end
  end

  describe "依赖注入" do
    test "fetch/2 分流：数字 / 非数字 / 缺答案" do
      assert Ex28ErrorMonad.fetch(["10", "20"], 0) == {:ok, 10}
      assert Ex28ErrorMonad.fetch(["10", "20"], 1) == {:ok, 20}
      assert Ex28ErrorMonad.fetch(["hot dog"], 0) == {:error, :not_a_number}
      assert Ex28ErrorMonad.fetch(["10"], 1) == {:error, :missing_answer}
    end
  end

  describe "策略一：函数子句" do
    test "checkout_case 分门别类" do
      assert Ex28ErrorMonad.checkout_case(["10", "20"]) == {:ok, 200}
      assert Ex28ErrorMonad.checkout_case(["hot dog", "20"]) == {:error, :quantity_not_a_number}
      assert Ex28ErrorMonad.checkout_case(["10", "hot dog"]) == {:error, :price_not_a_number}
      assert Ex28ErrorMonad.checkout_case(["10"]) == {:error, :price_not_a_number}
    end
  end

  describe "策略二：try/rescue + defexception" do
    test "parse_answer!/1 成功直通" do
      assert Ex28ErrorMonad.parse_answer!("42") == 42
    end

    test "parse_answer!/1 抛自定义异常" do
      assert_raise Ex28ErrorMonad.InvalidOptionError, "Invalid option", fn ->
        Ex28ErrorMonad.parse_answer!("hot dog")
      end
    end

    test "异常结构体带默认消息" do
      e = %Ex28ErrorMonad.InvalidOptionError{}
      assert e.message == "Invalid option"
      assert Exception.message(e) == "Invalid option"
    end

    test "checkout_rescue 愉快路径与救援路径" do
      assert Ex28ErrorMonad.checkout_rescue(["10", "20"]) == {:ok, 200}
      assert Ex28ErrorMonad.checkout_rescue(["hot dog", "20"]) == {:error, "Invalid option"}
    end
  end

  describe "策略三：throw/catch" do
    test "checkout_throw 抛值被 catch 接住" do
      assert Ex28ErrorMonad.checkout_throw(["10", "20"]) == {:ok, 200}
      assert Ex28ErrorMonad.checkout_throw(["10", "hot dog"]) == {:error, "Invalid option"}
    end
  end

  describe "策略四：错误单子" do
    test "ok/error/ok? 包装与判别" do
      assert ok(42) == {:ok, 42}
      assert error("boom") == {:error, "boom"}
      assert ok?(ok(1))
      refute ok?(error("x"))
    end

    test "bind：成功续跑，失败短路" do
      assert bind({:ok, 3}, fn x -> {:ok, x * 2} end) == {:ok, 6}
      assert bind({:error, :boom}, fn x -> {:ok, x * 2} end) == {:error, :boom}
    end

    test "pipeline 短路实证：s3 在失败后未执行" do
      assert Ex28ErrorMonad.pipeline(:ok_path) == {:ok, [:s1, :s2, :s3]}
      assert Ex28ErrorMonad.pipeline(:fail_at_2) == {:error, :boom}
    end

    test "~>> 运算符等价于 bind" do
      assert ok(3) ~>> (&ok(&1 * 2)) ~>> (&ok(&1 + 1)) == {:ok, 7}
      assert error("wrong") ~>> (&ok(&1 * 2)) == {:error, "wrong"}
    end

    test "checkout_monad 与 ask_step 复用" do
      assert Ex28ErrorMonad.checkout_monad(["10", "20"]) == {:ok, 200}
      assert Ex28ErrorMonad.checkout_monad(["3", "7", "unused"]) == {:ok, 21}
      assert Ex28ErrorMonad.checkout_monad(["hot dog", "20"]) == {:error, "Invalid option"}
      assert Ex28ErrorMonad.checkout_monad(["10"]) == {:error, "Invalid option"}
    end
  end

  describe "策略五：with" do
    test "checkout_with 的三种出口" do
      assert Ex28ErrorMonad.checkout_with(["10", "20"]) == {:ok, 200}
      assert Ex28ErrorMonad.checkout_with(["hot dog", "20"]) == {:error, :not_a_number}
      assert Ex28ErrorMonad.checkout_with(["10"]) == {:error, :missing_answer}
    end
  end

  describe "五策略对照矩阵" do
    test "成功批：全部得到 {:ok, 数量×单价}" do
      for batch <- [["10", "20"], ["3", "7", "unused"]] do
        [q, p | _] = batch
        expected = {:ok, String.to_integer(q) * String.to_integer(p)}

        assert Ex28ErrorMonad.checkout_case(batch) == expected
        assert Ex28ErrorMonad.checkout_rescue(batch) == expected
        assert Ex28ErrorMonad.checkout_throw(batch) == expected
        assert Ex28ErrorMonad.checkout_monad(batch) == expected
        assert Ex28ErrorMonad.checkout_with(batch) == expected
      end
    end

    test "失败批：全部返回 :error（没有一个崩溃）" do
      for batch <- @batches,
          batch not in [["10", "20"], ["3", "7", "unused"]] do
        for f <- [
              &Ex28ErrorMonad.checkout_case/1,
              &Ex28ErrorMonad.checkout_rescue/1,
              &Ex28ErrorMonad.checkout_throw/1,
              &Ex28ErrorMonad.checkout_monad/1,
              &Ex28ErrorMonad.checkout_with/1
            ] do
          assert {:error, _} = f.(batch)
        end
      end
    end
  end
end
