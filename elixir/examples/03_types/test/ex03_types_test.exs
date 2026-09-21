defmodule Ex03TypesTest do
  # async: false —— 本文件里有两个测试要观察全局原子表（atom_count），
  # 不能与其他测试并发跑，否则计数会被别人搅动。
  use ExUnit.Case, async: false

  doctest Ex03Types
  doctest Ex03Types.Point

  test "/ 永远返回浮点；div/rem 是向零截断（同 C，非 Python 的向下取整）" do
    assert Ex03Types.divide(4, 2) == 2.0
    assert is_float(Ex03Types.divide(4, 2))
    assert Ex03Types.int_div(-7, 2) == -3
    assert Ex03Types.remainder(-7, 2) == -1
    assert Ex03Types.int_div(7, -2) == -3
    assert Ex03Types.remainder(7, -2) == 1
    # div/rem 恒等式
    assert Ex03Types.int_div(-7, 2) * 2 + Ex03Types.remainder(-7, 2) == -7
  end

  test "整数任意精度：超过 64 位不回绕" do
    assert Ex03Types.pow2(64) == 18_446_744_073_709_551_616
    assert Ex03Types.pow2(128) - Ex03Types.pow2(127) == Ex03Types.pow2(127)
    assert is_integer(Ex03Types.pow2(1000))
    assert Ex03Types.pow2(1000) |> Integer.digits() |> length() == 302
  end

  test "**/2：整数底+非负整数指数走精确整数；混入浮点或负指数才走浮点" do
    # 整数情形与 Integer.pow 完全等价（精确、不丢精度）
    assert is_integer(2 ** 64)
    assert 2 ** 64 == Ex03Types.pow2(64)
    assert 2 ** 100 == Ex03Types.pow2(100)
    # 一旦混入浮点 —— 立刻掉进 IEEE 754，大指数丢精度
    assert is_float(2.0 ** 64)
    assert is_float(2 ** 64.0)
    # 2 的幂在 double 里恰能精确表示，要用非 2 的幂才看得出丢精度：
    # 3^40 的浮点结果比精确整数少 33（低位被 double 的 52 位尾数吞掉）
    refute 3.0 ** 40 == Integer.pow(3, 40)
    assert trunc(3.0 ** 40) == 12_157_665_459_056_928_768
    assert Integer.pow(3, 40) == 12_157_665_459_056_928_801
    # 负指数：** 静默给浮点，Integer.pow 直接 ArithmeticError（强制整数语义）
    assert 2 ** -1 == 0.5
    assert_raise ArithmeticError, fn -> Integer.pow(2, -1) end
  end

  test "浮点相等陷阱与容差比较" do
    refute 0.1 + 0.2 == 0.3
    assert inspect(0.1 + 0.2) == "0.30000000000000004"
    assert Ex03Types.nearly_equal(0.1 + 0.2, 0.3)
    refute Ex03Types.nearly_equal(0.1 + 0.2, 0.31)
    assert Ex03Types.nearly_equal(1.0, 1)
  end

  test "原子表上限是 1048576（只在测试里断言，绝不打印）" do
    assert :erlang.system_info(:atom_limit) == 1_048_576
  end

  test "to_existing_atom 不新建原子；to_atom 会新建 —— DoS 风险的来源" do
    before_count = :erlang.system_info(:atom_count)
    assert Ex03Types.atom_from("no_such_atom_for_sure_9x7") == {:error, :no_such_atom}
    assert :erlang.system_info(:atom_count) == before_count

    # to_atom 对任意输入都照单全收：原子数真的 +1，而且再也收不回来
    junk = String.to_atom("demo_junk_atom_#{:erlang.unique_integer([:positive])}")
    assert is_atom(junk)
    assert :erlang.system_info(:atom_count) == before_count + 1

    # 预定义原子本来就在表里
    assert Ex03Types.atom_from("nil") == {:ok, nil}
    assert Ex03Types.atom_from("true") == {:ok, true}
    # 模块名的真身是 :"Elixir.Ex03Types"，裸名字是另一个原子
    assert Ex03Types.atom_from("Ex03Types") == {:ok, :Ex03Types}
    refute Ex03Types.atom_from("Ex03Types") == {:ok, Ex03Types}
  end

  test "真假值：只有 false 与 nil 是假" do
    assert Ex03Types.truthy?(0)
    assert Ex03Types.truthy?(0.0)
    assert Ex03Types.truthy?("")
    assert Ex03Types.truthy?([])
    assert Ex03Types.truthy?([nil])
    refute Ex03Types.truthy?(false)
    refute Ex03Types.truthy?(nil)

    # && / || 返回的是操作数本身，不是布尔
    assert (nil || "默认值") == "默认值"
    assert (0 || "默认值") == 0
    assert ("a" && "b") == "b"
    assert (nil && "b") == nil
  end

  test "charlist 就是码点列表；字符串是 UTF-8 二进制" do
    assert ~c"abc" == [97, 98, 99]
    assert is_list(~c"abc")
    assert is_binary("abc")
    refute is_binary(~c"abc")
    # "é"（U+00E9）占 2 个 UTF-8 字节
    assert byte_size("é") == 2
    assert String.length("é") == 1
    # "e" + 组合重音（U+0301）：3 字节 / 2 码点 / 1 字素
    combined = "e\u0301"
    assert byte_size(combined) == 3
    # 数码点要用 codepoints/1；String.length/1 数的是字素簇（grapheme）不是码点
    assert length(String.codepoints(combined)) == 2
    assert String.length(combined) == 1
    assert length(String.graphemes(combined)) == 1
  end

  test "元组：定长、elem/2 按位取值；put_elem/3 返回新元组" do
    t = {:ok, 42, "extra"}
    assert tuple_size(t) == 3
    assert elem(t, 1) == 42
    t2 = put_elem(t, 1, 99)
    # 原元组不动 —— 不可变性
    assert t == {:ok, 42, "extra"}
    assert t2 == {:ok, 99, "extra"}
  end

  test "列表：cons 分解、++/-- 的语义" do
    assert Ex03Types.list_parts([1, 2, 3]) == {:ok, 1, [2, 3]}
    assert Ex03Types.list_parts([]) == {:error, :empty}
    assert hd([1, 2]) == 1
    assert tl([1, 2]) == [2]
    # -- 只移除每个元素的**第一次**出现
    assert [1, 2, 1, 3] -- [1] == [2, 1, 3]
    assert [1, 1, 1] -- [1, 1] == [1]
    assert Ex03Types.keyword_is_sugar()
    assert Keyword.get([name: "x", name: "y"], :name) == "x"
    assert length([1, 2, 3]) == 3
  end

  test "不可变性：更新永远返回新值，原值永在" do
    original = %{count: 1}
    {was, updated} = Ex03Types.bump(original, :count)
    assert was == original
    assert original == %{count: 1}
    assert updated == %{count: 2}

    s = "abc"
    s2 = s <> "d"
    assert s == "abc"
    assert s2 == "abcd"
  end

  test "struct 是带 :__struct__ 键的 map；is_exception/1 认出异常 struct" do
    # struct/2 动态构造：字面量 %Point{} 的静态类型太精确，1.20.4 的类型
    # 检查器会把 assert is_struct(p) 重写出的失败分支证明为不可达而告警
    # （stderr 非空）；动态构造既抹掉类型又演示了 struct/2 本身。
    p = struct(Ex03Types.Point, x: 1, y: 2)
    assert is_struct(p)
    assert is_struct(p, Ex03Types.Point)
    assert is_map(p)
    assert p == %{__struct__: Ex03Types.Point, x: 1, y: 2}
    assert Ex03Types.type_of(p) == :struct
    assert is_exception(%ArgumentError{})
    assert is_exception(%ArgumentError{}, ArgumentError)
    refute is_exception({:error, :oops})
    refute is_struct(%{a: 1})
  end

  test "type_of：判定顺序决定了结论的精确度" do
    assert Ex03Types.type_of(nil) == nil
    assert Ex03Types.type_of(true) == :boolean
    assert Ex03Types.type_of(:ok) == :atom
    assert Ex03Types.type_of(42) == :integer
    assert Ex03Types.type_of(3.14) == :float
    assert Ex03Types.type_of("bin") == :binary
    assert Ex03Types.type_of(<<1::1>>) == :bitstring
    assert Ex03Types.type_of(~c"abc") == :list
    assert Ex03Types.type_of({1}) == :tuple
    assert Ex03Types.type_of(%{a: 1}) == :map
    assert Ex03Types.type_of(fn -> :ok end) == :function
    assert Ex03Types.type_of(self()) == :pid
    assert Ex03Types.type_of(make_ref()) == :reference

    # is_number 是「父类」判定 —— 字面量交给 number?/1 探针，躲开 1.20 的 always-succeed 告警
    assert Ex03Types.number?(42) and Ex03Types.number?(3.14)
    assert is_bitstring("bin")
    # 布尔同时也是原子 —— 这就是 type_of 里 is_boolean 必须放前面的原因
    assert is_atom(true)
  end

  test "term 全序：number < atom < reference < function < port < pid < tuple < map < list < binary" do
    # 跨类型比较全部走 lt/2 探针（参数 term()），躲开 1.20 的 distinct-types 告警
    assert Ex03Types.lt(1, :a)
    assert Ex03Types.lt(1.5, :a)
    assert Ex03Types.lt(:a, make_ref())
    assert Ex03Types.lt(make_ref(), fn -> :ok end)
    assert Ex03Types.lt(fn -> :ok end, self())
    assert Ex03Types.lt(self(), {1})
    assert Ex03Types.lt({1}, %{})
    assert Ex03Types.lt(%{}, [1])
    assert Ex03Types.lt([1], "a")

    # == 跨数字类型比较值，=== 还要求类型一致（走探针，躲开 distinct-types 告警）
    assert 1 == 1.0
    refute Ex03Types.strict_equal?(1, 1.0)
    assert Ex03Types.strict_equal?(1, 1)
    # 同类型内部再按各自的规则（列表按元素、元组按位、map 按大小）；
    # 两个 map 形状不同也会触发 distinct-types 告警，故 map 比较也走 lt/2
    assert [1, 2] < [1, 3]
    assert {1, 2} < {1, 3}
    assert Ex03Types.lt(%{a: 1}, %{a: 1, b: 2})
  end

  test "混合类型 Enum.sort 不崩，且结果符合类型全序" do
    terms = [42, 3.14, :ok, make_ref(), fn -> :ok end, self(), {1}, %{a: 1}, [1], "bin"]

    # number 内部不再区分 int/float、按数值排：3.14 < 42，故 float 标签排在 integer 前
    assert Ex03Types.sort_labels(terms) ==
             [:float, :integer, :atom, :reference, :function, :pid, :tuple, :map, :list, :binary]

    # 换成整数更小的值，integer 就排到 float 前 —— 证明 number 子类顺序由数值决定
    assert Ex03Types.sort_labels([42, 3.14]) == [:float, :integer]
    assert Ex03Types.sort_labels([1, 3.14]) == [:integer, :float]
  end
end
