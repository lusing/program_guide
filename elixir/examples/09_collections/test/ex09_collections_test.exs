defmodule Ex09CollectionsTest do
  use ExUnit.Case, async: true

  doctest Ex09Collections

  alias Ex09Collections
  alias Ex09Collections.{Point, User}

  describe "Keyword" do
    test "真身是原子键二元组列表" do
      assert [{:a, 1}] = [a: 1]
    end

    test "允许重复键，get 取第一个，get_values 全取" do
      kw = [a: 1, b: 2, a: 3]
      assert Keyword.get(kw, :a) == 1
      assert Keyword.get_values(kw, :a) == [1, 3]
      assert kw[:missing] == nil
    end

    test "顺序敏感：同样键值不同排列不相等" do
      refute [b: 2, a: 1] == [a: 1, b: 2]
    end

    test "greet/2 的选项默认值与 shout? 选项" do
      assert Ex09Collections.greet("Ada") == "Hello, Ada"
      assert Ex09Collections.greet("Ada", prefix: "Hola") == "Hola, Ada"
      assert Ex09Collections.greet("Ada", shout?: true) == "HELLO, ADA"
    end

    test "set_option 走 Keyword.put" do
      assert Ex09Collections.set_option([a: 1, a: 2], :a, 9) == [a: 9]
      assert Ex09Collections.set_option([b: 2], :a, 1) == [a: 1, b: 2]
    end
  end

  describe "Map" do
    test "相等与键顺序无关" do
      assert %{z: 1, a: 2} == %{a: 2, z: 1}
    end

    test "value_or 区分不了缺失与 nil——第三参数只在键缺失时生效" do
      assert Ex09Collections.value_or(%{a: nil}, :a, :default) == nil
      assert Ex09Collections.value_or(%{}, :a, :default) == :default
    end

    test "merge_counters 对冲突键求和，后者默认覆盖在 merge/2" do
      assert Ex09Collections.merge_counters(%{a: 1, b: 2}, %{b: 10, c: 3}) ==
               %{a: 1, b: 12, c: 3}

      assert Map.merge(%{a: 1}, %{a: 2}) == %{a: 2}
    end

    test "sorted_pairs 把任意 map 排成有序键值对" do
      assert Ex09Collections.sorted_pairs(%{z: 1, a: 2}) == [a: 2, z: 1]
    end

    test "小 map 与大 map 两种内部存储，键值集合一致" do
      small = Map.new(1..32, fn i -> {i, i * i} end)
      large = Map.new(1..40, fn i -> {i, i * i} end)
      assert small[5] == 25
      assert large[33] == 1089
      assert map_size(small) == 32
      assert map_size(large) == 40
    end
  end

  describe "Struct" do
    test "user_from_map 走 struct!" do
      assert Ex09Collections.user_from_map(%{id: 7, name: "Ada"}) ==
               %User{id: 7, name: "Ada"}
    end

    test "struct! 遇未知键抛 KeyError，struct/2 静默忽略" do
      assert_raise KeyError, fn ->
        Ex09Collections.user_from_map(%{id: 1, bogus: 2})
      end

      assert struct(User, %{id: 1, bogus: 2}) == %User{id: 1}
    end

    test "@enforce_keys 漏键抛 ArgumentError（运行时构造也一样）" do
      assert_raise ArgumentError, ~r"must also be given when building struct", fn ->
        Code.eval_string("%Ex09Collections.User{}")
      end
    end

    test "未知字段在展开时抛 KeyError，运行时构造就过不去" do
      assert_raise KeyError, "key :bogus not found", fn ->
        Code.eval_string("%Ex09Collections.User{id: 1, bogus: 2}")
      end
    end

    test "shape 按结构体名分派，普通 map 不匹配 %User{}" do
      assert Ex09Collections.shape(%Point{x: 1}) == :point
      assert Ex09Collections.shape(%User{id: 1}) == :user
      assert Ex09Collections.shape(%{x: 1, y: 2}) == :plain_map
    end

    test "promote 用结构体更新语法" do
      assert Ex09Collections.promote(%User{id: 1}) == %User{id: 1, admin: true}
    end

    test "add_tag 追加并去重，非 User 进不来" do
      u = %User{id: 1}
      assert Ex09Collections.add_tag(u, "x") == %User{id: 1, tags: ["x"]}

      assert u |> Ex09Collections.add_tag("x") |> Ex09Collections.add_tag("x") ==
               %User{id: 1, tags: ["x"]}

      assert_raise FunctionClauseError, fn ->
        Code.eval_string("Ex09Collections.add_tag(%{tags: []}, \"x\")")
      end
    end

    test "Struct 不实现 Access：[] 取值抛 UndefinedFunctionError" do
      assert_raise UndefinedFunctionError, ~r"does not implement the Access behaviour", fn ->
        %User{id: 1}[:id]
      end
    end

    test "1.20 的 struct.field 点语法可用" do
      assert %User{id: 7, name: "Ada"}.name == "Ada"
    end

    test "去掉 __struct__ 就退回普通 map" do
      plain = Map.delete(%User{id: 1}, :__struct__)
      refute Map.has_key?(plain, :__struct__)
      assert Ex09Collections.shape(plain) == :plain_map
      assert Map.from_struct(%User{id: 1}) == %{id: 1, name: "anonymous", tags: [], admin: false}
    end
  end

  describe "MapSet" do
    test "uniq_sorted 去重排序" do
      assert Ex09Collections.uniq_sorted([3, 1, 3, 2, 1]) == [1, 2, 3]
    end

    test "venn 并交差" do
      assert Ex09Collections.venn([1, 2, 3], [2, 3, 4]) ==
               %{union: [1, 2, 3, 4], inter: [2, 3], only_left: [1]}
    end

    test "成员与包含关系" do
      assert Ex09Collections.set_member?([1, 2], 2)
      refute Ex09Collections.set_member?([1, 2], 9)
      assert MapSet.subset?(MapSet.new([1]), MapSet.new([1, 2]))
    end
  end

  describe "Access 与 get_in 家族" do
    test "dig 对 keyword、map、字符串键、列表下标都成立" do
      assert Ex09Collections.dig([db: [port: 5432]], [:db, :port]) == 5432
      assert Ex09Collections.dig(%{db: %{port: 5432}}, [:db, :port]) == 5432

      assert Ex09Collections.dig(%{"users" => [%{"name" => "Ada"}]}, [
               "users",
               Access.at(0),
               "name"
             ]) == "Ada"
    end

    test "任何一层缺失都返回 nil，不抛" do
      assert Ex09Collections.dig(%{db: %{}}, [:db, :host, :domain]) == nil
      assert Ex09Collections.dig(%{"users" => []}, ["users", Access.at(9), "name"]) == nil
      assert nil[:anything] == nil
    end

    test "下标越界通过动态路径下钻得到 nil（Access 语义）" do
      assert Ex09Collections.dig([%{v: 1}], [Access.at(9)]) == nil
    end

    test "bump_in / put_deep 沿路径更新写入" do
      assert Ex09Collections.bump_in(%{stats: %{count: 1}}, [:stats, :count], &(&1 + 1)) ==
               %{stats: %{count: 2}}

      assert Ex09Collections.put_deep(%{db: %{port: 5432}}, [:db, :port], 6543) ==
               %{db: %{port: 6543}}
    end

    test "pluck 用 Access.all 批量取字段" do
      assert Ex09Collections.pluck([%{v: 1}, %{v: 2}], :v) == [1, 2]
    end

    test "tuple_nth 用 Access.elem" do
      assert Ex09Collections.tuple_nth({:a, :b, :c}, 1) == :b
    end

    test "pop_in 与 get_and_update_in 的函数形式" do
      assert pop_in(%{a: 1, b: 2}, [:a]) == {1, %{b: 2}}

      assert get_and_update_in(%{a: 1}, [:a], fn v -> {v, v + 1} end) ==
               {1, %{a: 2}}
    end

    test "编译期已知路径的宏形式" do
      assert put_in(%{a: %{b: 1}}.a.b, 9) == %{a: %{b: 9}}
    end

    test "动态键用 Access.key 包一层" do
      key = :port
      assert get_in(%{db: %{port: 5432}}, [:db, Access.key(key, nil)]) == 5432
    end
  end
end
