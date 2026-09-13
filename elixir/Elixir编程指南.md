# Elixir 编程指南（Windows）

本教程按 `guide` 统一标准组织：**Markdown 文档 + 独立示例 + 构建脚本 + 编译验证**。  
示例目录：`examples/`，统一编译入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [第一个模块](#第一个模块)
3. [类型与模式匹配](#类型与模式匹配)
4. [Enum 与管道](#enum-与管道)
5. [递归与模式拆分](#递归与模式拆分)
6. [Struct 与 Protocol](#struct-与-protocol)
7. [错误处理](#错误处理)
8. [模块组织：alias/import](#模块组织aliasimport)
9. [并发：Task](#并发task)
10. [状态：Agent](#状态agent)
11. [OTP：GenServer](#otpgenserver)
12. [监督树规格](#监督树规格)
13. [文件处理](#文件处理)
14. [正则与二进制](#正则与二进制)
15. [宏基础](#宏基础)
16. [惰性流 Stream](#惰性流-stream)
17. [统一编译验证](#统一编译验证)

---

## 环境准备

- Elixir 目录：`G:\scoop\apps\elixir\current`
- 编译器：`G:\scoop\apps\elixir\current\bin\elixirc.bat`
- 教程目录：`G:\code\guide\elixir`

先检查版本：

```powershell
G:\scoop\apps\elixir\current\bin\elixirc.bat --version
```

---

## 第一个模块

源码：`examples/01_hello.ex`

```elixir
defmodule Ex01Hello do
  def hello, do: "Hello, Elixir!"
end
```

---

## 类型与模式匹配

源码：`examples/02_types_pattern.ex`

```elixir
defmodule Ex02TypesPattern do
  def describe({:user, name, age}) when is_binary(name) and is_integer(age) do
    {:ok, "user=#{name}, age=#{age}"}
  end

  def describe(%{name: name, age: age}) when is_binary(name) and is_integer(age) do
    {:ok, "user=#{name}, age=#{age}"}
  end

  def describe(_), do: {:error, :invalid_data}
end
```

---

## Enum 与管道

源码：`examples/03_enum_pipeline.ex`

```elixir
defmodule Ex03EnumPipeline do
  def sum_even_squares(list) when is_list(list) do
    list
    |> Enum.filter(&(rem(&1, 2) == 0))
    |> Enum.map(&(&1 * &1))
    |> Enum.sum()
  end
end
```

---

## 递归与模式拆分

源码：`examples/04_recursion.ex`

```elixir
defmodule Ex04Recursion do
  def factorial(n) when is_integer(n) and n >= 0, do: do_factorial(n, 1)

  defp do_factorial(0, acc), do: acc
  defp do_factorial(n, acc), do: do_factorial(n - 1, n * acc)

  def len(list), do: do_len(list, 0)
  defp do_len([], acc), do: acc
  defp do_len([_ | rest], acc), do: do_len(rest, acc + 1)
end
```

---

## Struct 与 Protocol

源码：`examples/05_struct_protocol.ex`

```elixir
defmodule Ex05StructProtocol.User do
  defstruct [:name, :age]
end

defprotocol Ex05Stringify do
  def to_text(data)
end

defimpl Ex05Stringify, for: Ex05StructProtocol.User do
  def to_text(%Ex05StructProtocol.User{name: name, age: age}), do: "#{name}(#{age})"
end

defimpl Ex05Stringify, for: Integer do
  def to_text(v), do: "int:#{v}"
end
```

---

## 错误处理

源码：`examples/06_error_handling.ex`

```elixir
defmodule Ex06ErrorHandling do
  def safe_div(_a, 0), do: {:error, :divide_by_zero}
  def safe_div(a, b), do: {:ok, a / b}

  def safe_parse_int(text) when is_binary(text) do
    case Integer.parse(String.trim(text)) do
      {value, ""} -> {:ok, value}
      _ -> {:error, :invalid_integer}
    end
  end
end
```

---

## 模块组织：alias/import

源码：`examples/07_module_alias_import.ex`

```elixir
defmodule Ex07ModuleAliasImport.Math do
  def add(a, b), do: a + b
end

defmodule Ex07ModuleAliasImport.Use do
  alias Ex07ModuleAliasImport.Math, as: M
  import Kernel, except: [div: 2]

  def sum3(a, b, c), do: M.add(M.add(a, b), c)
  def quotient(a, b), do: Kernel.div(a, b)
end
```

---

## 并发：Task

源码：`examples/08_task_async.ex`

```elixir
defmodule Ex08TaskAsync do
  def parallel_sum(a, b) do
    t1 = Task.async(fn -> Enum.sum(1..a) end)
    t2 = Task.async(fn -> Enum.sum(1..b) end)
    Task.await(t1, 5_000) + Task.await(t2, 5_000)
  end
end
```

---

## 状态：Agent

源码：`examples/09_agent_state.ex`

```elixir
defmodule Ex09AgentState do
  def start_link(initial \\ 0) do
    Agent.start_link(fn -> initial end)
  end

  def inc(pid), do: Agent.update(pid, &(&1 + 1))
  def get(pid), do: Agent.get(pid, & &1)
end
```

---

## OTP：GenServer

源码：`examples/10_genserver_counter.ex`

```elixir
defmodule Ex10GenServerCounter do
  use GenServer

  def start_link(initial \\ 0) do
    GenServer.start_link(__MODULE__, initial, [])
  end

  def get(pid), do: GenServer.call(pid, :get)
  def inc(pid), do: GenServer.cast(pid, :inc)

  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast(:inc, state), do: {:noreply, state + 1}
end
```

---

## 监督树规格

源码：`examples/11_supervisor_spec.ex`

```elixir
defmodule Ex11SupervisorSpec do
  def child_specs do
    [
      %{
        id: :counter,
        start: {Ex10GenServerCounter, :start_link, [0]},
        restart: :permanent,
        shutdown: 5_000,
        type: :worker
      }
    ]
  end

  def supervisor_flags do
    %{strategy: :one_for_one, intensity: 5, period: 10}
  end
end
```

---

## 文件处理

源码：`examples/12_file_io.ex`

```elixir
defmodule Ex12FileIO do
  def write_lines(path, lines) when is_binary(path) and is_list(lines) do
    File.write(path, Enum.join(lines, "\n"))
  end

  def read_text(path) when is_binary(path) do
    File.read(path)
  end
end
```

---

## 正则与二进制

源码：`examples/13_regex_binary.ex`

```elixir
defmodule Ex13RegexBinary do
  def extract_numbers(text) when is_binary(text) do
    Regex.scan(~r/\d+/, text) |> List.flatten()
  end

  def packet(type, payload) when is_integer(type) and is_binary(payload) do
    <<type::8, byte_size(payload)::16, payload::binary>>
  end
end
```

---

## 宏基础

源码：`examples/14_macro_demo.ex`

```elixir
defmodule Ex14MacroDemo do
  defmacro unless_expr(condition, do: block) do
    quote do
      if !unquote(condition) do
        unquote(block)
      else
        :ok
      end
    end
  end
end

defmodule Ex14MacroUse do
  require Ex14MacroDemo

  def run(flag) do
    Ex14MacroDemo.unless_expr flag do
      :ran
    end
  end
end
```

---

## 惰性流 Stream

源码：`examples/15_streams.ex`

```elixir
defmodule Ex15Streams do
  def first_n_even_squares(n) when is_integer(n) and n >= 0 do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.filter(&(rem(&1, 2) == 0))
    |> Stream.map(&(&1 * &1))
    |> Enum.take(n)
  end
end
```

---

## 统一编译验证

在本目录执行：

```powershell
cd G:\code\guide\elixir
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 15_streams.ex
```

清理：

```powershell
.\build.ps1 -Clean
```

建议每次新增示例后执行一次 `-All`，确保教程示例持续可编译。

