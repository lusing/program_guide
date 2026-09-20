# 第 09 章驱动脚本：cd examples/09_collections && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex09Collections
alias Ex09Collections.{Point, User}

IO.puts("==== 09 集合：Keyword / Map / Struct / MapSet / Access ====")

# ------------------------------------------------------------
# 1. Keyword：选项列表的真身
# ------------------------------------------------------------
IO.puts("\n-- 1. Keyword：原子键二元组列表，允许重复键、有序、线性查找 --")
IO.inspect([a: 1, b: 2], label: "inspect 真身")

kw = [a: 1, b: 2, a: 3]
IO.puts("重复键 opts=#{inspect(kw)}")
IO.puts("  Keyword.get(:a)   => #{Keyword.get(kw, :a)}（取第一个）")
IO.puts("  get_values(:a)    => #{inspect(Keyword.get_values(kw, :a))}")
IO.puts("  [b:2,a:1]==[a:1,b:2] => #{inspect([b: 2, a: 1] == [a: 1, b: 2])}（顺序敏感）")
IO.puts("  set_option 去重并置顶 => #{inspect(Ex09Collections.set_option(kw, :a, 9))}")

IO.puts(
  "  greet 用法        => #{inspect(Ex09Collections.greet("Ada", prefix: "Hola", shout?: true))}"
)

# ------------------------------------------------------------
# 2. Map：通用键值结构，相等与顺序无关，展示顺序不保证
# ------------------------------------------------------------
IO.puts("\n-- 2. Map：任意键、无序；展示顺序不保证，教程一律排序后打印 --")
m = %{z: 1, a: 2, m: 3}
IO.puts("  字面量 %{z:1,a:2,m:3} 的 inspect 顺序不保证（+S1:1 下实测不同），本工程一律排序打印")
IO.puts("  sorted_pairs 排序输出 => #{inspect(Ex09Collections.sorted_pairs(m))}")
IO.puts("  键序无关的相等        => #{inspect(%{z: 1, a: 2} == %{a: 2, z: 1})}")

# 33 个键以上会切换内部存储（flatmap -> hashmap），两种存储键值集合一致。
big = Map.new(1..40, fn i -> {i, i * i} end)
IO.puts("  40 键大 map map_size => #{map_size(big)}，取 key=33 => #{big[33]}")

merged = Ex09Collections.merge_counters(%{a: 1, b: 2}, %{b: 10, c: 3})

IO.puts("  merge_counters 冲突求和 => #{inspect(Ex09Collections.sorted_pairs(merged))}（排序后输出）")

# ------------------------------------------------------------
# 3. Struct：编译期固定字段 + __struct__ 标记的名义类型
# ------------------------------------------------------------
IO.puts("\n-- 3. Struct：固定字段、构造检查、按名分派 --")
user = Ex09Collections.user_from_map(%{id: 7, name: "Ada"})
IO.puts("  user_from_map => #{inspect(user)}")
IO.puts("  promote 更新 => #{inspect(Ex09Collections.promote(user))}")

IO.puts(
  "  add_tag 去重 => #{inspect(user |> Ex09Collections.add_tag("beam") |> Ex09Collections.add_tag("beam"))}"
)

IO.puts(
  "  shape 分派: point/user/plain_map => #{Ex09Collections.shape(%Point{x: 1})} / #{Ex09Collections.shape(user)} / #{Ex09Collections.shape(%{x: 1})}"
)

IO.puts("  点语法 1.20 => #{user.name}；去掉 __struct__ 退回普通 map")
IO.puts("  struct! 未知键抛 KeyError；@enforce_keys 漏键抛 ArgumentError；未知字段展开即报错")

# ------------------------------------------------------------
# 4. MapSet：去重与集合代数
# ------------------------------------------------------------
IO.puts("\n-- 4. MapSet：去重、并交差、成员判定 --")
IO.puts("  uniq_sorted([3,1,3,2,1]) => #{inspect(Ex09Collections.uniq_sorted([3, 1, 3, 2, 1]))}")
IO.puts("  venn([1,2,3],[2,3,4])    => #{inspect(Ex09Collections.venn([1, 2, 3], [2, 3, 4]))}")

IO.puts(
  "  member? 2 / 9            => #{Ex09Collections.set_member?([1, 2], 2)} / #{Ex09Collections.set_member?([1, 2], 9)}"
)

# ------------------------------------------------------------
# 5. Access：data[key] 的规则
# ------------------------------------------------------------
IO.puts("\n-- 5. Access：data[key] 的规则（nil 安全，struct 除外）--")

IO.puts(
  "  map[:missing] => #{inspect(%{a: 1}[:missing])}；nil[:b] => #{inspect(nil[:b])}（一路 nil 下去）"
)

struct_access =
  try do
    %User{id: 1}[:id]
  rescue
    UndefinedFunctionError -> :raises_undefined_function_error
  end

IO.puts("  %User{}[:id] => #{inspect(struct_access)}（struct 不实现 Access）")

IO.puts(
  "  Map.get 三参可给默认值 => #{inspect(Map.get(%{a: nil}, :a, :default))}（值是 nil 与缺失不同：Access 分不清）"
)

# ------------------------------------------------------------
# 6. get_in / put_in 家族：路径式深取深改
# ------------------------------------------------------------
IO.puts("\n-- 6. get_in / put_in / update_in / pop_in：路径片段可组合 --")

json = %{"users" => [%{"name" => "Ada"}]}

IO.puts(
  "  dig 字符串键 + Access.at => #{inspect(Ex09Collections.dig(json, ["users", Access.at(0), "name"]))}"
)

IO.puts(
  "  dig 缺失一路 nil          => #{inspect(Ex09Collections.dig(json, ["users", Access.at(9), "name"]))}"
)

data = %{stats: %{count: 1}}

IO.puts(
  "  bump_in 沿路径 +1         => #{inspect(Ex09Collections.bump_in(data, [:stats, :count], &(&1 + 1)))}"
)

IO.puts("  pluck Access.all 批量取   => #{inspect(Ex09Collections.pluck([%{v: 1}, %{v: 2}], :v))}")
IO.puts("  tuple_nth Access.elem     => #{inspect(Ex09Collections.tuple_nth({:a, :b}, 1))}")
IO.puts("  pop_in 取出并删除         => #{inspect(pop_in(%{a: 1, b: 2}, [:a]))}")

# ------------------------------------------------------------
# 7. 选型决策
# ------------------------------------------------------------
IO.puts("""
-- 7. 选型决策 --
  函数的可选参数      -> Keyword（opts :: keyword()）
  外部数据/通用键值   -> Map（键类型混合、需要哈希查找）
  有明确字段的实体     -> Struct（模式分派、编译期字段检查）
  只需去重/集合运算    -> MapSet
  深层嵌套的 JSON     -> get_in + Access.at/all（nil 安全）
  编译期已知的深路径   -> put_in(data.a.b, v) 宏形式
""")

IO.puts("==== 09 结束 ====")
