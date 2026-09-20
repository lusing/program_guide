defmodule Ex11Errors.ValidationError do
  @moduledoc "本章自定义异常：字段校验失败。"
  defexception [:field, :message]

  @impl true
  def message(%{field: field, message: message}), do: "#{field}: #{message}"
end

defmodule Ex11Errors do
  @moduledoc """
  第 11 章示例：错误处理与日志。

  Elixir 有两套并行的错误机制：

  1. **预期内错误**用 `{:ok, value}` / `{:error, reason}` 返回，配合 `with`
     在业务管道里短路——reason 是可匹配的数据；
  2. **预期外错误**才用异常（`raise`），由**边界层**（进程入口、HTTP 处理函数、
     脚本最外层）统一接住，库函数大胆 raise，这就是「let it crash」。

      iex> Ex11Errors.configure("8080")
      {:ok, %{port: 8080}}

  """

  # ============================================================
  # 1. tagged tuple 流水线：每步返回 ok/error，with 短路
  # ============================================================

  @doc """
  把字符串解析成整数端口。`Integer.parse/1` 允许部分解析，
  这里额外要求整串被吃完。

      iex> Ex11Errors.parse_port("8080")
      {:ok, 8080}

      iex> Ex11Errors.parse_port("80x")
      {:error, {:not_an_integer, "80x"}}

      iex> Ex11Errors.parse_port("abc")
      {:error, {:not_an_integer, "abc"}}

  """
  @spec parse_port(binary()) :: {:ok, integer()} | {:error, term()}
  def parse_port(s) do
    case Integer.parse(s) do
      {n, ""} -> {:ok, n}
      _ -> {:error, {:not_an_integer, s}}
    end
  end

  @doc """
  端口范围校验：成功回传原值，失败给可匹配的 reason。

      iex> Ex11Errors.bounded_port(8080)
      {:ok, 8080}

      iex> Ex11Errors.bounded_port(70000)
      {:error, {:out_of_range, 70000}}

  """
  @spec bounded_port(integer()) :: {:ok, 1..65535} | {:error, term()}
  def bounded_port(n) when n in 1..65535, do: {:ok, n}
  def bounded_port(n), do: {:error, {:out_of_range, n}}

  @doc """
  完整的配置流水线：with 任一步失败即短路返回该步的 reason。

      iex> Ex11Errors.configure("8080")
      {:ok, %{port: 8080}}

      iex> Ex11Errors.configure("70000")
      {:error, {:out_of_range, 70000}}

      iex> Ex11Errors.configure("nope")
      {:error, {:not_an_integer, "nope"}}

  """
  @spec configure(binary()) :: {:ok, map()} | {:error, term()}
  def configure(raw) do
    with {:ok, n} <- parse_port(raw),
         {:ok, port} <- bounded_port(n) do
      {:ok, %{port: port}}
    end
  end

  # ============================================================
  # 2. 异常：内置与自定义
  # ============================================================

  @doc """
  严格解析：把「预期外」的输入变成异常。注意 `!` 约定：
  函数名带 `!` 表示成功返回值、失败抛异常。

      iex> Ex11Errors.parse_int!("42")
      42

      iex> Ex11Errors.parse_int!("x")
      ** (ArgumentError) not an integer: "x"

  """
  @spec parse_int!(binary()) :: integer()
  def parse_int!(s) do
    case Integer.parse(s) do
      {n, ""} -> n
      _ -> raise ArgumentError, "not an integer: #{inspect(s)}"
    end
  end

  @doc """
  自定义异常带字段。`defexception` 生成的结构体可用在 rescue 的类型列表里。

      iex> Ex11Errors.validate_age(200)
      ** (Ex11Errors.ValidationError) age: got 200, must be 0..150

  """
  @spec validate_age(integer()) :: integer()
  def validate_age(age) when age in 0..150, do: age

  def validate_age(age) do
    raise __MODULE__.ValidationError, field: :age, message: "got #{age}, must be 0..150"
  end

  @doc """
  自定义异常的 message/1 可以被 `Exception.message/1` 调用。

      iex> Ex11Errors.validation_message(:email, "is required")
      "email: is required"

  """
  @spec validation_message(atom(), binary()) :: binary()
  def validation_message(field, message) do
    Exception.message(%__MODULE__.ValidationError{field: field, message: message})
  end

  # ============================================================
  # 3/4. rescue / else / after / catch
  # ============================================================

  @doc """
  边界层：把内部异常转换成 tagged tuple。库函数尽管 raise，
  由进程/请求边界统一调用本函数接住。

      iex> Ex11Errors.safe(fn -> 1 + 1 end)
      {:ok, 2}

      iex> Ex11Errors.safe(fn -> Ex11Errors.parse_int!("x") end)
      {:error, {ArgumentError, ~S{not an integer: "x"}}}

      iex> Ex11Errors.safe(fn -> Ex11Errors.validate_age(999) end)
      {:error, {Ex11Errors.ValidationError, "age: got 999, must be 0..150"}}

  """
  @spec safe((-> result)) :: {:ok, result} | {:error, {module(), binary()}} when result: var
  def safe(fun) do
    try do
      {:ok, fun.()}
    rescue
      e -> {:error, {e.__struct__, Exception.message(e)}}
    end
  end

  @doc """
  `try/after`：after 块无论成功、异常都会执行，用于资源释放。
  本函数无论是否 raise，都会给调用者进程发一条 `:cleaned_up` 消息。

      iex> Ex11Errors.with_cleanup()
      :recovered
      iex> receive do
      ...>   msg -> msg
      ...> end
      :cleaned_up

  """
  @spec with_cleanup() :: :recovered
  def with_cleanup do
    try do
      raise "boom"
    rescue
      RuntimeError -> :recovered
    after
      send(self(), :cleaned_up)
    end
  end

  @doc """
  `throw/1` 是非局部返回：在深层迭代里提前「抛」出一个值，
  由外层 catch 接住。库代码少用，`Enum.find/2` 这类需求优先用 Enum API。

      iex> Ex11Errors.find_even([1, 3, 4, 5])
      {:found, 4}

      iex> Ex11Errors.find_even([1, 3, 5])
      :not_found

  """
  @spec find_even([integer()]) :: {:found, integer()} | :not_found
  def find_even(list) do
    result =
      try do
        Enum.each(list, fn n ->
          if rem(n, 2) == 0, do: throw(n)
        end)

        :none
      catch
        :throw, n -> {:found, n}
      end

    if result == :none, do: :not_found, else: result
  end

  @doc """
  catch 同时能接 `:throw`、`:error`、`:exit` 三类信号；
  本函数只演示 `:exit`（进程退出理由）的捕获，不会让当前进程真的退出。

      iex> Ex11Errors.catch_exit(fn -> exit(:shutdown) end)
      {:caught, :exit, :shutdown}

  """
  @spec catch_exit((-> any())) :: {:caught, :exit, term()}
  def catch_exit(fun) do
    try do
      fun.()
    catch
      :exit, reason -> {:caught, :exit, reason}
    end
  end

  # ============================================================
  # 5. 栈迹与异常格式化
  # ============================================================

  @doc """
  把异常转成可记录的字符串（不带栈迹；要栈迹用
  `Exception.format/3` + `__STACKTRACE__`，见 run.exs 的日志一节）。

      iex> Ex11Errors.format_raised(fn -> raise ArgumentError, "x" end)
      {ArgumentError, "x"}

  """
  @spec format_raised((-> any())) :: {module(), binary()}
  def format_raised(fun) do
    try do
      fun.()
    rescue
      e -> {e.__struct__, Exception.message(e)}
    end
  end

  # ============================================================
  # 6. Logger
  # ============================================================

  require Logger

  @doc """
  按级别打三条结构化日志。Logger 事件的目的地由 handler 决定：
  run.exs 会把默认处理器重建为 standard_error + 去时间戳 formatter；
  测试里不调用本函数。
  """
  @spec log_demo() :: :logged
  def log_demo do
    Logger.info("service started", chapter: 11)
    Logger.warning("disk almost full")
    Logger.error("task failed: deterministic reason")
    :logged
  end

  @doc """
  记录异常的标准姿势：`Exception.format/3` 配合 `__STACKTRACE__`，
  把完整栈迹交给日志系统，而不是打给用户。
  """
  @spec log_exception((-> any())) :: :logged
  def log_exception(fun) do
    try do
      fun.()
    rescue
      e ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        :logged
    end
  end
end
