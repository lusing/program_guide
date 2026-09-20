# 11 · 错误处理与日志

> 对应示例：`examples/11_errors/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）
>
> 本章是教程里**唯一允许往 stderr 写东西**的一章：`run-all.sh` 已把 `11_errors`
> 登记进 `STDERR_ALLOW` 白名单，且第 5 层逐字节比对只看 stdout。

Elixir 有两套并行的错误机制，新手最常犯的错就是把它们混用：

1. **预期内的业务失败**——端口号超范围、用户输入不是整数、记录不存在——
   它们不是「错误」，而是**正常返回值的一种**。用 `{:ok, value}` /
   `{:error, reason}` 返回，`reason` 是可模式匹配的数据，配合 `with` 在管道里短路；
2. **预期外的情况**——不变量被破坏、编程错误、依赖的进程崩了——才用异常（`raise`）。
   库函数尽管大胆 raise，由**边界层**（进程入口、请求处理函数、监督树）统一接住或
   干脆让它崩掉重启。这就是 Erlang/OTP 的 **let it crash**。

判断口诀：**调用方能拿这个 reason 做点什么 → 返回 `{:error, reason}`；
做不了任何事、只能记日志或崩 → raise。**

## 11.1 tagged tuple 与 `with` 短路

本章示例工程的前三个函数组成一条配置解析流水线，每一步失败都带一个
**可匹配的 reason 元组**：

```elixir
def parse_port(s) do
  case Integer.parse(s) do
    {n, ""} -> {:ok, n}
    _ -> {:error, {:not_an_integer, s}}
  end
end

def bounded_port(n) when n in 1..65535, do: {:ok, n}
def bounded_port(n), do: {:error, {:out_of_range, n}}

def configure(raw) do
  with {:ok, n} <- parse_port(raw),
       {:ok, port} <- bounded_port(n) do
    {:ok, %{port: port}}
  end
end
```

两个细节值得注意：

- `Integer.parse/1` 允许**部分解析**：`Integer.parse("80x")` 返回 `{80, "x"}` 而不报错。
  端口解析要求整串被吃完，所以额外匹配剩余串必须是 `""`；
- `with` 的每一支用 `<-`（不是 `=`）：匹配成功就继续，失败则**立即返回那个不匹配的值**，
  后面的步骤不再执行。失败点即返回值，不需要层层嵌套 `case`。

`run.exs` 第 1 节实测输出：

```text
-- 1. tagged tuple + with：错误是数据，在管道里短路 --
  configure("8080") => {:ok, %{port: 8080}}
  configure("70000") => {:error, {:out_of_range, 70000}}
  configure("nope") => {:error, {:not_an_integer, "nope"}}
```

reason 刻意做成元组而不是字符串（`{:out_of_range, 70000}` 而非
`"port out of range"`）：调用方可以继续按结构匹配，还能把 offending value 带出来。

## 11.2 raise：`!` 约定与 `defexception`

另一族函数名带 `!`：**成功返回裸值，失败直接抛异常**。这是全生态统一的约定
（`File.read!/1`、`Map.fetch!/2`、`Keyword.fetch!/2` 都遵守）：

```elixir
def parse_int!(s) do
  case Integer.parse(s) do
    {n, ""} -> n
    _ -> raise ArgumentError, "not an integer: #{inspect(s)}"
  end
end
```

需要领域专属的异常类型时，用 `defexception` 定义。它本质上是生成一个结构体
（`%Ex11Errors.ValidationError{}`），可以带任意字段，并可实现 `message/1`
定制 `Exception.message/1` 的结果：

```elixir
defmodule Ex11Errors.ValidationError do
  defexception [:field, :message]

  @impl true
  def message(%{field: field, message: message}), do: "#{field}: #{message}"
end

def validate_age(age) when age in 0..150, do: age
def validate_age(age) do
  raise __MODULE__.ValidationError, field: :age, message: "got #{age}, must be 0..150"
end
```

`run.exs` 第 2 节（注意异常已经被边界函数 `safe/1` 接住转成了元组）：

```text
-- 2. raise：! 约定与 defexception --
  => {:ok, 42}
  => {:error, {ArgumentError, "not an integer: \"x\""}}
  => {:error, {Ex11Errors.ValidationError, "age: got 200, must be 0..150"}}
  validation_message => "age: bad"
```

## 11.3 `try` 的 rescue / else / after

`try` 有四个子句，职责各不相同：

- `rescue`：按**异常类型**匹配（`RuntimeError`、`ArgumentError`、自定义异常……），
  像 case 一样可以多子句分派；
- `else`：try 体**没有抛异常**时，用结果做模式匹配；
- `after`：无论成功还是抛异常**必定执行**，用于资源清理（关文件、发通知）；
- `catch`：接的是另一套东西（见 11.4）。

```elixir
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
```

实测：

```text
-- 3. rescue / else / after --
  rescue+else 分支 => {:else_branch, 42}（else 只在 try 体未抛异常时运行）
  after 已执行？   => :got
  with_cleanup     => :recovered
  清理消息         => :got
```

本章的 `with_cleanup/0` 演示「raise → rescue → after 照跑」：它在 try 里 `raise "boom"`，
rescue 成 `:recovered`，after 里 `send(self(), :cleaned_up)`。
**doctest 里有一个坑**：两个 iex 提示之间**不能有空行**——空行会把 doctest
切成两个独立示例、跑在两个进程里，第一条消息就发给了已死的前一个进程，
第二条 `receive` 会挂到超时。

## 11.4 throw 与 exit：非局部返回与进程信号

BEAM 上有三类可以被 `catch` 接住的东西，`try` 里用两个元素的子句区分：

```elixir
catch
  :throw, value -> {:thrown, value}   # throw/1：非局部返回一个值
  :exit, reason -> {:exited, reason}  # exit/1：进程退出信号
  :error, error -> {:errored, error}  # 实际上就是 rescue 接住的那类异常
```

- **`throw/1`**：在深层迭代里提前「抛」出一个值。现代 Elixir 里绝大多数场景
  已被 `Enum.find/2`、`Enum.reduce_while/3` 取代，业务代码少用。本章的
  `find_even/1` 保留它做非局部返回演示；
- **`exit/1`**：这是**进程信号**，是 OTP 监督协议的内部语言。在普通函数里
  `catch :exit` 接住它，当前进程不会真的退出（测试里还断言了
  `Process.alive?(self()) == true`）。业务代码几乎不该直接调用 `exit/1`——
  让监督树去处理进程退出。

```text
-- 4. throw（非局部返回）/ exit（进程信号），由 catch 接住 --
  find_even([1,3,4,5]) => {:found, 4}
  catch_exit           => {:caught, :exit, :shutdown}
  当前进程仍存活       => true
```

## 11.5 边界转换与 let it crash

本章的 `safe/1` 是典型的**边界适配器**：内部函数尽管 raise，
到了进程/请求边界统一转成 tagged tuple：

```elixir
def safe(fun) do
  try do
    {:ok, fun.()}
  rescue
    e -> {:error, {e.__struct__, Exception.message(e)}}
  end
end
```

`e.__struct__` 取出异常的**类型模块**（而不是把异常整个 inspect 进字符串），
调用方仍能按类型匹配。**关键纪律是不要在库内部到处写防御性 rescue**：
在深层函数里吞掉异常，等于把「编程错误」伪装成「业务失败」，监督树也失去了
重启的机会。让错误一路冒到边界，要么转成 `{:error, _}` 回应调用方，要么
让进程崩掉由 supervisor 拉起一个干净的新进程。

```text
-- 5. 边界转换：库抛异常，边界接住，内部不写防御性 rescue --
  批量处理结果 => [ok: 42, error: {ArgumentError, "not an integer: \"bad\""}]
  format_raised => {ArgumentError, "x"}
```

## 11.6 Logger：级别、metadata 与异常栈迹（stderr）

Elixir 的 `Logger` 是 OTP `:logger` 之上的一层。基本用法是一组宏
（`require Logger` 后才能用）：

```elixir
Logger.info("service started", chapter: 11)   # 第二个参数是 metadata
Logger.warning("disk almost full")
Logger.error("task failed: deterministic reason")
```

记录异常的**标准姿势**是 `Exception.format/3` 配合 `__STACKTRACE__`，
把完整栈迹交给日志而不是丢给用户：

```elixir
rescue
  e ->
    Logger.error(Exception.format(:error, e, __STACKTRACE__))
    :logged
end
```

`__STACKTRACE__` 只能在 `rescue` 子句**内部**直接用，离开这个位置就拿不到了。

**本章在 Logger 上踩了整个教程最深的一个坑**，值得展开：

1. mix 工程里默认 handler 的输出类型是 `:standard_io`——它写的是**进程组长
   （group leader）**，而 `mix run` 时组长指向脚本的 stdout。于是 Logger 行和
   `IO.puts` 的行抢同一条管道，而 Logger 默认**异步投递**，行的相对位置在两次
   运行间会漂移，第 5 层单调度器重跑的逐字节比对必然失败；
2. 在线把 handler 配置改成 `:standard_error` 会被 `:logger_std_h` **静默忽略**
   （`type` 不允许热更新），必须 `remove_handler` + `add_handler` 重建；
3. 重建时又有一个陷阱：`add_handler` 新建的 `logger_std_h` 默认
   `filter_default: :stop`，自带的 domain 过滤器只放行「无域」和
   `[:otp, :sasl]` 域事件；而 **Logger 宏发出的事件域是 `[:elixir]`**，
   不显式声明 `filter_default: :log`，所有 `Logger.info/1` 调用都会被静默吞掉
   （而裸 `:logger.log/3` 的无域事件反而能出来，排查时极具迷惑性）。

`run.exs` 开头的最终配置：

```elixir
formatter =
  Logger.Formatter.new(
    format: "[$level] $metadata$message\n",  # 默认模板带时间戳，这里去掉
    colors: [enabled: false],                 # 确定性输出，不许带 ANSI 颜色
    metadata: [:chapter]
  )

:logger.remove_handler(:default)

:logger.add_handler(:default, :logger_std_h, %{
  config: %{type: :standard_error},
  formatter: formatter,
  level: :debug,
  filter_default: :log,                        # 否则 [:elixir] 域事件被吞
  filters: [remote_gl: {&:logger_filters.remote_gl/2, :stop}]
})

Logger.configure(level: :info)
# ... 日志演示结束后
Logger.flush()                                 # 退出前等异步投递排干
```

stdout 第 6 节只打印结论，真正的日志在 **stderr**：

```text
-- 6. Logger 输出在 stderr（去时间戳 formatter），下面只打印结论 --
  log_demo 返回     => :logged（info/warning/error 见 stderr）
  低于当前级别被过滤：debug 默认在 info 级别下不可见
  log_exception 返回 => :logged
```

```text
[info] chapter=11 service started
[warning] disk almost full
[error] task failed: deterministic reason
[error] ** (RuntimeError) disk full
    run.exs:124: anonymous fn/0 in :elixir_compiler_2.__FILE__/1
    (ex11_errors 0.1.0) lib/ex11_errors.ex:276: Ex11Errors.log_exception/1
    ...
```

生产环境里通常用 `config :logger, :console, ...` 或后端配置完成同样的事；
本章在脚本里手工配置，纯粹是为了让教程输出零时间戳、双通道分离、逐字节可复现。

## 11.7 错误处理选型

`run.exs` 末节直接打印了一张决策表：

```text
  调用方可恢复的业务失败  -> {:error, reason} + with（不要 raise）
  不变量被破坏/编程错误    -> raise，让它在边界崩，由监督树重启
  深层迭代提前返回        -> 优先 Enum API；确需非局部返回才 throw
  通知别的进程去死        -> exit/1（监督协议内部语言，业务代码少用）
  记录而非处理           -> Logger + Exception.format/3，栈迹进日志不进响应
```

## 11.8 坑位清单

1. **`Integer.parse/1` 会部分解析**：`"80x"` 得 `{80, "x"}`。要求整串吃完
   必须显式匹配剩余的 `""`，否则垃圾输入被静默截断。
2. **reason 要是数据不是字符串**。`{:error, {:out_of_range, n}}` 能继续匹配、
   能带上下文；`{:error, "bad port"}` 只能给人看。
3. **`!` 是契约不是装饰**：带 `!` 的函数失败必须 raise，不带的必须返回
   tagged tuple。自己写库时沿用同一约定，调用方看名字就知道怎么接。
4. **`with` 用 `<-`，不用 `=`**。用 `=` 时不匹配会直接 raise `MatchError`，
   短路语义就没了；`else` 子句也只对 `<-` 的失败负责。
5. **doctest 示例之间的空行是进程边界**。连续 `iex>` 行共享绑定与邮箱；
   一旦插入空行，前一个示例的 `send(self(), ...)` 就发给了已死进程。
6. **`catch` 有三类，别只写一个变量**。`catch value ->` 会把 throw/exit/error
   混在一起；写 `:throw, v ->` / `:exit, r ->` 两元素子句才能区分。
7. **不要在库内部到处 rescue**。在深层吞异常等于拆除监督树的保险丝；
   rescue 只写在边界，库代码遵循 let it crash。
8. **`__STACKTRACE__` 只在 rescue 子句内有效**；要在别处用必须先在 rescue
   里绑定出来（`e -> st = __STACKTRACE__`）。
9. **Logger handler 的三个静默陷阱**：`type` 不能热更（要 remove + add）；
   新建 `logger_std_h` 默认 `filter_default: :stop` 会吞掉 Logger 宏的
   `[:elixir]` 域事件；默认格式带时间戳且异步投递——确定性脚本必须换
   formatter、显式 `filter_default: :log`、结束时 `Logger.flush/0`。

---

下一章进入并发世界：[12 · 进程与消息](12-processes.md)——`spawn` / `send` /
`receive`、邮箱、link/monitor、命名进程，以及让进程持有状态的递归 loop。
