# 第 26 章驱动脚本：cd examples/26_closures && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex26Closures

IO.puts("==== 26 闭包与函数组合：捕获、遮蔽、& 捕获、compose ====")

# ------------------------------------------------------------
# 1. 函数作为参数：策略注入
# ------------------------------------------------------------
IO.puts("\n-- 1. 策略注入：total_price 吃价格，也吃「费用怎么算」--")

flat = Ex26Closures.fee(:flat)
proportional = Ex26Closures.fee(:proportional)
IO.puts("  fee(:flat).(1000)          => #{flat.(1000)}")
IO.puts("  fee(:proportional).(1000)  => #{proportional.(1000)}")
IO.puts("  total_price(1000, flat)        => #{Ex26Closures.total_price(1000, flat)}")
IO.puts("  total_price(1000, proportional) => #{Ex26Closures.total_price(1000, proportional)}")

# ------------------------------------------------------------
# 2. 捕获创建时刻的值：重绑不影响闭包
# ------------------------------------------------------------
IO.puts("\n-- 2. 闭包捕获创建时刻的值：之后重绑 x，闭包里的 10 不动 --")

f = Ex26Closures.freeze(10)
x = 10
IO.puts("  x = 10 时：f.() => #{f.()}，x => #{x}")
x = 999
IO.puts("  x 重绑 999 后：f.() => #{f.()}，x => #{x}（闭包里的 10 纹丝不动）")

{inner, outer_after} = Ex26Closures.inner_demo()
IO.puts("  单向镜：闭包内 other_answer => #{inner}，外部 answer 未被改 => #{outer_after}")

# ------------------------------------------------------------
# 3. 绑定变量遮蔽自由变量
# ------------------------------------------------------------
IO.puts("\n-- 3. 遮蔽：参数 quantity 赢过外部同名变量 --")

quantity = 2
calculate = Ex26Closures.calculator()
IO.puts("  外部 quantity = #{quantity}，calculate.(4) => #{calculate.(4)}")
IO.puts("  （4 传入参数 quantity；product_price = 200 是被捕获的自由变量）")

# ------------------------------------------------------------
# 4. 闭包工厂与无状态计数器
# ------------------------------------------------------------
IO.puts("\n-- 4. 闭包工厂吃配置吐函数；状态装进下一个闭包往下传 --")

hello = Ex26Closures.make_greeter("Hello")
hi = Ex26Closures.make_greeter("Hi")
IO.puts("  hello.(\"Ada\") => #{hello.("Ada")}；hi.(\"Ada\") => #{hi.("Ada")}")

IO.puts("  counter 前 5 步 => #{inspect(Ex26Closures.counter_values(Ex26Closures.counter(0), 5))}")

# ------------------------------------------------------------
# 5. & 捕获全形态
# ------------------------------------------------------------
IO.puts("\n-- 5. & 捕获：&Mod.fun/arity、&(&1 * &2)、腌进外部列表 --")

upcase = Ex26Closures.named_upcase()
IO.puts("  &String.upcase/1.(\"hello\") => #{upcase.("hello")}")
IO.puts("  &(&1 * &2).(10, 2)         => #{Ex26Closures.multiply().(10, 2)}")

heroes = ["Knight", "Wizard", "Rogue"]
find = Ex26Closures.find_by_index(heroes)
IO.puts("  find_by_index(heroes).(1)  => #{find.(1)}（列表被腌进了函数里）")

# ------------------------------------------------------------
# 6. 闭包与进程：spawn 没有参数通道，闭包是唯一的行李箱
# ------------------------------------------------------------
IO.puts("\n-- 6. spawn 的函数没法传参——要带的值只能靠闭包捕获 --")

parent = self()
message = "Hello from a spawned process!"

spawn(fn -> send(parent, {:msg, message}) end)

received =
  receive do
    {:msg, m} -> m
  after
    1_000 -> "timeout!"
  end

IO.puts("  子进程送回 => #{inspect(received)}")

# ------------------------------------------------------------
# 7. 函数组合
# ------------------------------------------------------------
IO.puts("\n-- 7. compose 拼积木；thread 把管道收进数据 --")

shout = Ex26Closures.compose(&String.trim/1, &String.upcase/1)
IO.puts("  compose(trim, upcase).(\"  hi  \") => #{shout.("  hi  ")}")

steps = [&String.trim/1, &String.upcase/1, &String.reverse/1]
IO.puts("  thread(\"  hi  \", 三步)         => #{Ex26Closures.thread("  hi  ", steps)}")
IO.puts("  （函数列表本身是数据：可存、可传、可动态拼装）")

IO.puts("\n==== 26 结束 ====")
