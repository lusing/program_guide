# 第 28 章驱动脚本：cd examples/28_error_monad && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex28ErrorMonad

IO.puts("==== 28 纯函数纪律与错误单子：case / rescue / throw / 单子 / with ====")

batches = [["10", "20"], ["hot dog", "20"], ["10", "hot dog"], ["10"]]

# 脚本按顺序执行，辅助函数先用 fn 绑定成局部变量
tag_of = fn
  {:ok, value} -> "ok(#{value})"
  {:error, reason} -> "error(#{inspect(reason)})"
end

# ------------------------------------------------------------
# 1. 纯与非纯：判据
# ------------------------------------------------------------
IO.puts("\n-- 1. 纯度速查：引用了参数之外的值并受其影响 => 非纯 --")

Enum.each(Ex28ErrorMonad.purity_table(), fn {desc, tag} ->
  IO.puts("  [#{tag}] #{desc}")
end)

IO.puts(
  "  net_price(100, 10) 调两次 => #{Ex28ErrorMonad.net_price(100, 10)} / #{Ex28ErrorMonad.net_price(100, 10)}"
)

# ------------------------------------------------------------
# 2. 依赖注入：交互是数据
# ------------------------------------------------------------
IO.puts("\n-- 2. 依赖注入：答案序列是数据，五种策略吃同一批输入 --")

for batch <- batches do
  IO.puts(
    "  输入 #{inspect(batch)} => fetch(batch, 0) => #{inspect(Ex28ErrorMonad.fetch(batch, 0))}"
  )
end

# ------------------------------------------------------------
# 3. 策略一：case 嵌套 → 函数子句
# ------------------------------------------------------------
IO.puts("\n-- 3. 策略一（case/函数子句）：检查下放到子句，错误分门别类 --")

for batch <- batches do
  IO.puts("  checkout_case(#{inspect(batch)}) => #{inspect(Ex28ErrorMonad.checkout_case(batch))}")
end

# ------------------------------------------------------------
# 4. 策略二：try + rescue + defexception
# ------------------------------------------------------------
IO.puts("\n-- 4. 策略二（try/rescue）：愉快路径进 try，rescue 具体异常 --")

rescued =
  try do
    Ex28ErrorMonad.parse_answer!("hot dog")
  rescue
    e in Ex28ErrorMonad.InvalidOptionError -> "rescued: #{e.message}"
  end

IO.puts("  parse_answer!(\"hot dog\") => #{rescued}")

for batch <- batches do
  IO.puts(
    "  checkout_rescue(#{inspect(batch)}) => #{inspect(Ex28ErrorMonad.checkout_rescue(batch))}"
  )
end

# ------------------------------------------------------------
# 5. 策略三：throw + catch
# ------------------------------------------------------------
IO.puts("\n-- 5. 策略三（throw/catch）：抛值不抛错，函数体隐式 try --")

for batch <- batches do
  IO.puts(
    "  checkout_throw(#{inspect(batch)}) => #{inspect(Ex28ErrorMonad.checkout_throw(batch))}"
  )
end

# ------------------------------------------------------------
# 6. 策略四：错误单子
# ------------------------------------------------------------
IO.puts("\n-- 6. 策略四（错误单子）：ok/error 包装 + bind 短路，手写不引库 --")

IO.puts(
  "  bind({:ok, 3}, 翻倍) => #{inspect(Ex28ErrorMonad.bind({:ok, 3}, fn x -> {:ok, x * 2} end))}"
)

IO.puts(
  "  bind({:error, :boom}, 翻倍) => #{inspect(Ex28ErrorMonad.bind({:error, :boom}, fn x -> {:ok, x * 2} end))}（跳过）"
)

IO.puts("  pipeline(:ok_path)   => #{inspect(Ex28ErrorMonad.pipeline(:ok_path))}")
IO.puts("  pipeline(:fail_at_2) => #{inspect(Ex28ErrorMonad.pipeline(:fail_at_2))}（s3 被短路，未执行）")

for batch <- batches do
  IO.puts(
    "  checkout_monad(#{inspect(batch)}) => #{inspect(Ex28ErrorMonad.checkout_monad(batch))}"
  )
end

# ------------------------------------------------------------
# 7. 策略五：with
# ------------------------------------------------------------
IO.puts("\n-- 7. 策略五（with）：模式匹配链 + else 显式收错误，多数场景最实用 --")

for batch <- batches do
  IO.puts("  checkout_with(#{inspect(batch)}) => #{inspect(Ex28ErrorMonad.checkout_with(batch))}")
end

# ------------------------------------------------------------
# 8. 五策略对照：同一批输入，殊途同归
# ------------------------------------------------------------
IO.puts("\n-- 8. 对照：成功批全部得到 200；失败批各自报错但都「返回值」而非崩溃 --")

for batch <- batches do
  tags =
    [
      Ex28ErrorMonad.checkout_case(batch),
      Ex28ErrorMonad.checkout_rescue(batch),
      Ex28ErrorMonad.checkout_throw(batch),
      Ex28ErrorMonad.checkout_monad(batch),
      Ex28ErrorMonad.checkout_with(batch)
    ]
    |> Enum.map(tag_of)

  IO.puts("  #{inspect(batch)} => #{inspect(tags)}")
end

IO.puts("  （五策略同为 :ok/:error 两类出口；成功值一致，失败标签各有语义）")

IO.puts("\n==== 28 结束 ====")
