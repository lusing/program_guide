# 第 10 章驱动脚本：cd examples/10_protocols && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex10Protocols
alias Ex10Protocols.{Bag, Box, MemoryStorage, Secret, Storage}

IO.puts("==== 10 协议与行为：protocol / defimpl / derive / @behaviour ====")

# ------------------------------------------------------------
# 1. 协议：只声明函数头，按第一个参数的运行时类型分派
# ------------------------------------------------------------
IO.puts("\n-- 1. 协议定义与内置类型实现 --")

for value <- [42, 3.14, "hello", [1, 2]] do
  {cat, desc} = Ex10Protocols.report(value)
  IO.puts("  #{String.pad_trailing(inspect(value), 9)} => #{cat} / #{desc}")
end

# ------------------------------------------------------------
# 2. 给 struct 实现协议：名义类型分派
# ------------------------------------------------------------
IO.puts("\n-- 2. struct 的显式实现 --")
box = %Box{item: 1}
IO.puts("  #{inspect(box)} => #{inspect(Ex10Protocols.report(box))}")
IO.puts("  describe_all 混合列表 =>")

for report <- Ex10Protocols.describe_all([1, "a", box]) do
  IO.puts("    #{inspect(report)}")
end

# ------------------------------------------------------------
# 3. Any 兜底与 @derive
# ------------------------------------------------------------
IO.puts("\n-- 3. @fallback_to_any 与 @derive --")
IO.puts("  没有专门实现的原子 => #{inspect(Ex10Protocols.report(:hello))}")
bag = %Bag{items: [1, 2, 3]}
IO.puts("  @derive 的 Bag（复用 Any 函数体）=> #{inspect(Ex10Protocols.report(bag))}")

# ------------------------------------------------------------
# 4. 分派表与协议合并
# ------------------------------------------------------------
IO.puts("\n-- 4. impl_for 查询与 consolidation --")
IO.puts("  impl_module(42)     => #{inspect(Ex10Protocols.impl_module(42))}")
IO.puts("  impl_module(:hello) => #{inspect(Ex10Protocols.impl_module(:hello))}")
info = Ex10Protocols.impl_summary()
IO.puts("  consolidated?       => #{info.consolidated?}")
IO.puts("  impls（排序后）      => #{inspect(Enum.map(info.impls, &Module.split/1))}")
IO.puts("  Enumerable impl_for(box) => #{inspect(Enumerable.impl_for(box))}（struct 默认没有）")

# ------------------------------------------------------------
# 5. 内置协议：Enumerable / Collectable / String.Chars / Inspect
# ------------------------------------------------------------
IO.puts("\n-- 5. 内置协议 --")
IO.puts("  safe_count([1,2,3]) => #{inspect(Ex10Protocols.safe_count([1, 2, 3]))}")
IO.puts("  safe_count(box)     => #{inspect(Ex10Protocols.safe_count(box))}")
IO.puts("  safe_to_string(box) => #{inspect(Ex10Protocols.safe_to_string(box))}")
secret = %Secret{value: 42}
IO.puts("  自定义 Inspect      => #{inspect(secret)}")
IO.puts("  自定义 String.Chars => #{inspect(Ex10Protocols.safe_to_string(secret))}")
into_result = Enum.into([1, 2, 1], MapSet.new())
IO.puts("  Enum.into/2 走 Collectable => #{inspect(MapSet.to_list(into_result) |> Enum.sort())}")

# ------------------------------------------------------------
# 6. @behaviour：编译期契约
# ------------------------------------------------------------
IO.puts("\n-- 6. @behaviour：按模块分派、编译期检查回调 --")

store =
  MemoryStorage.new()
  |> MemoryStorage.put(:a, 1)
  |> MemoryStorage.put(:b, 2)

IO.puts(
  "  get :a / :missing   => #{inspect(MemoryStorage.get(store, :a))} / #{inspect(MemoryStorage.get(store, :missing))}"
)

IO.puts("  keys（可选回调）     => #{inspect(MemoryStorage.keys(store))}")
IO.puts("  Storage.fetch!      => #{Storage.fetch!(MemoryStorage, store, :a)}")

msg = Ex10Protocols.missing_callback_diagnostic()
IO.puts("  漏写回调的编译诊断   => #{String.trim(msg)}")

# ------------------------------------------------------------
# 7. 对比
# ------------------------------------------------------------
IO.puts("""
-- 7. 协议 vs 行为 --
  分派依据    协议：值的运行时类型        行为：调用方显式传入模块
  检查时机    协议：运行时 Protocol 错误   行为：编译期缺回调告警
  开放程度    协议：可给任何类型后补实现    行为：模块自己声明 @behaviour
  典型用途    Enumerable / Jason.Encoder  存储后端 / Strategy 插件
""")

IO.puts("==== 10 结束 ====")
