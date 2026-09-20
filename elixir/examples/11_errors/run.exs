# 第 11 章驱动脚本：cd examples/11_errors && mix run --no-compile run.exs
# 注意：本章把 Logger 输出重建到 stderr（mix 下默认处理器写 standard_io，
# 会与脚本自身的 IO.puts 抢同一条 stdout，异步投递时行顺序不确定）。
# stderr 已登记在 run-all.sh 的 STDERR_ALLOW 白名单，且不参与第 5 层逐字节比对。
:io.setopts(:standard_io, encoding: :utf8)

alias Ex11Errors

require Logger

# 去时间戳、去颜色、带 metadata 的确定性 formatter（默认格式带时间戳）。
formatter =
  Logger.Formatter.new(
    format: "[$level] $metadata$message\n",
    colors: [enabled: false],
    metadata: [:chapter]
  )

# 重建默认处理器：standard_error + 自定义 formatter。
# 关键坑：add_handler 新建的 logger_std_h 默认 filter_default: :stop，
# 只放行「无域」与 [:otp,:sasl] 域事件；而 Logger 宏的事件域是 [:elixir]，
# 不显式 filter_default: :log 的话，所有 Logger.xxx 调用都会被静默吞掉。
:logger.remove_handler(:default)

:logger.add_handler(:default, :logger_std_h, %{
  config: %{type: :standard_error},
  formatter: formatter,
  level: :debug,
  filter_default: :log,
  filters: [remote_gl: {&:logger_filters.remote_gl/2, :stop}]
})

Logger.configure(level: :info)

IO.puts("==== 11 错误处理与日志：tagged tuple / raise / try / Logger ====")

# ------------------------------------------------------------
# 1. 预期内错误：{:ok, _} / {:error, reason} 与 with 短路
# ------------------------------------------------------------
IO.puts("\n-- 1. tagged tuple + with：错误是数据，在管道里短路 --")

for input <- ["8080", "70000", "nope"] do
  IO.puts("  configure(#{inspect(input)}) => #{inspect(Ex11Errors.configure(input))}")
end

# ------------------------------------------------------------
# 2. 预期外错误：raise 内置异常与自定义异常
# ------------------------------------------------------------
IO.puts("\n-- 2. raise：! 约定与 defexception --")

for attempt <- [
      fn -> Ex11Errors.parse_int!("42") end,
      fn -> Ex11Errors.parse_int!("x") end,
      fn -> Ex11Errors.validate_age(200) end
    ] do
  IO.puts("  => #{inspect(Ex11Errors.safe(attempt))}")
end

IO.puts("  validation_message => #{inspect(Ex11Errors.validation_message(:age, "bad"))}")

# ------------------------------------------------------------
# 3. try 的 rescue / else / after
# ------------------------------------------------------------
IO.puts("\n-- 3. rescue / else / after --")

branch =
  try do
    Ex11Errors.parse_int!("42")
  rescue
    ArgumentError -> :rescued
  else
    n when is_integer(n) -> {:else_branch, n}
  after
    send(self(), :after_always)
  end

IO.puts("  rescue+else 分支 => #{inspect(branch)}（else 只在 try 体未抛异常时运行）")

assert_received = fn expected ->
  receive do
    msg when msg == expected -> :got
  after
    0 -> :missing
  end
end

IO.puts("  after 已执行？   => #{inspect(assert_received.(:after_always))}")
IO.puts("  with_cleanup     => #{inspect(Ex11Errors.with_cleanup())}")
IO.puts("  清理消息         => #{inspect(assert_received.(:cleaned_up))}")

# ------------------------------------------------------------
# 4. throw 与 exit：非局部返回与进程信号
# ------------------------------------------------------------
IO.puts("\n-- 4. throw（非局部返回）/ exit（进程信号），由 catch 接住 --")
IO.puts("  find_even([1,3,4,5]) => #{inspect(Ex11Errors.find_even([1, 3, 4, 5]))}")
IO.puts("  catch_exit           => #{inspect(Ex11Errors.catch_exit(fn -> exit(:shutdown) end))}")
IO.puts("  当前进程仍存活       => #{Process.alive?(self())}")

# ------------------------------------------------------------
# 5. 边界层：库函数 raise，边界统一转 tagged tuple（let it crash）
# ------------------------------------------------------------
IO.puts("\n-- 5. 边界转换：库抛异常，边界接住，内部不写防御性 rescue --")

results =
  Enum.map(["42", "bad"], fn raw ->
    Ex11Errors.safe(fn -> Ex11Errors.parse_int!(raw) end)
  end)

IO.puts("  批量处理结果 => #{inspect(results)}")

IO.puts(
  "  format_raised => #{inspect(Ex11Errors.format_raised(fn -> raise ArgumentError, "x" end))}"
)

# ------------------------------------------------------------
# 6. Logger：级别 / 元数据 / 异常栈迹（输出在 stderr）
# ------------------------------------------------------------
IO.puts("\n-- 6. Logger 输出在 stderr（去时间戳 formatter），下面只打印结论 --")
IO.puts("  log_demo 返回     => #{inspect(Ex11Errors.log_demo())}（info/warning/error 见 stderr）")
IO.puts("  低于当前级别被过滤：debug 默认在 info 级别下不可见")

# 异常栈迹走 Logger.error + Exception.format/3 + __STACKTRACE__
IO.puts(
  "  log_exception 返回 => #{inspect(Ex11Errors.log_exception(fn -> raise RuntimeError, "disk full" end))}"
)

# 日志默认异步投递；脚本退出前 flush，保证 stderr 内容完整。
Logger.flush()

# ------------------------------------------------------------
# 7. 决策表
# ------------------------------------------------------------
IO.puts("""
-- 7. 错误处理选型 --
  调用方可恢复的业务失败  -> {:error, reason} + with（不要 raise）
  不变量被破坏/编程错误    -> raise，让它在边界崩，由监督树重启
  深层迭代提前返回        -> 优先 Enum API；确需非局部返回才 throw
  通知别的进程去死        -> exit/1（监督协议内部语言，业务代码少用）
  记录而非处理           -> Logger + Exception.format/3，栈迹进日志不进响应
""")

IO.puts("==== 11 结束 ====")
