defmodule Ex28ErrorMonad.InvalidOptionError do
  @moduledoc """
  自定义异常（策略二的演示）。`defexception` 生成异常结构体，
  默认消息 "Invalid option"。书里用它取代宽泛的 MatchError——
  救**具体的**错，别救「反正出错了」。
  """

  defexception message: "Invalid option"
end

defmodule Ex28ErrorMonad do
  @moduledoc """
  第 28 章示例：纯函数纪律与错误单子。

  对应《函数式编程入门：使用 Elixir》第 7 章「处理非纯函数」。世界
  不可预测：用户输入 hot dog、文件不存在、网络超时。编写可靠代码的
  主策略是**识别并隔离非纯函数**，本章用同一个「读数量与单价算总价」
  的场景对比四种策略（书用交互式 CLI，这里把输入做成数据注入——
  这本身就是纯函数纪律的实战）：

  * **case / 函数子句**——简单场景够用，嵌套多了变迷宫；
  * **try + rescue**——驯服会 raise 的第三方代码，配 defexception；
  * **throw + catch**——抛值不抛错，像流程控制；少用；
  * **错误单子**——`{:ok, _} / {:error, _}` 包装值 + bind 短路，
    愉快路径一条线、错误集中一处；
  * **with**——Elixir 内建，模式匹配链 + else 收错误，多数场景最实用。

      iex> Ex28ErrorMonad.checkout_monad(["10", "20"])
      {:ok, 200}
      iex> Ex28ErrorMonad.checkout_monad(["hot dog", "20"])
      {:error, "Invalid option"}

  """

  # ============================================================
  # 1. 纯与非纯：判据
  # ============================================================

  @doc """
  纯函数：同参同果、无副作用。调用可以被结果原样替换（引用透明，
  第 25 章）：

      iex> Ex28ErrorMonad.net_price(100, 10)
      90.0
      iex> Ex28ErrorMonad.net_price(100, 10) == Ex28ErrorMonad.net_price(100, 10)
      true

  纯函数也可能出错，但错误**可预测**；非纯函数连结果都不可预测——
  同样的参数每次调用都可能不同。见 `purity_table/0`。
  """
  @spec net_price(number(), number()) :: float()
  def net_price(gross, tax_rate), do: gross - gross * tax_rate / 100

  @doc """
  纯度速查表。判据一句话：**引用了函数参数之外的值（并受其变化
  影响）→ 非纯**。读输入、读时钟、读随机源、读文件系统都是与世界
  交互——副作用。闭包捕获外部变量不在此列（第 26 章）：不可变性
  令捕获的是**定值**，输出仍只受输入影响。

      iex> Ex28ErrorMonad.purity_table() |> Enum.count()
      5

  """
  @spec purity_table() :: [{String.t(), :pure | :impure}]
  def purity_table do
    [
      {"net_price/2 —— 同参同果", :pure},
      {"IO.gets/1 —— 读用户输入", :impure},
      {"DateTime.utc_now/0 —— 读全局时钟", :impure},
      {":rand.uniform/1 —— 读随机源", :impure},
      {"File.read/1 —— 读外部世界", :impure}
    ]
  end

  # ============================================================
  # 2. 依赖注入：把非纯推到边界
  # ============================================================

  @doc """
  书里用 `IO.gets/1` 向用户提问；这里把「答案序列」当参数传进来——
  **交互是数据**，四种策略吃同一批输入、必须给出同样的结论（测试
  里有对照矩阵）。这是隔离非纯的第一招：纯核心 + 边界注入：

      iex> Ex28ErrorMonad.fetch(["10", "20"], 0)
      {:ok, 10}
      iex> Ex28ErrorMonad.fetch(["hot dog", "20"], 0)
      {:error, :not_a_number}
      iex> Ex28ErrorMonad.fetch(["10"], 1)
      {:error, :missing_answer}

  """
  @spec fetch([String.t()], non_neg_integer()) ::
          {:ok, integer()} | {:error, :not_a_number | :missing_answer}
  def fetch(answers, index) do
    case Enum.at(answers, index) do
      nil ->
        {:error, :missing_answer}

      answer ->
        case Integer.parse(answer) do
          :error -> {:error, :not_a_number}
          {value, _rest} -> {:ok, value}
        end
    end
  end

  # ============================================================
  # 3. 策略一：case 嵌套 → 函数子句
  # ============================================================

  @doc """
  最直觉的策略：case 检查每一步。两个输入还好，五个输入嵌套五层
  case 就是迷宫（书 7.2 的原话：难以理解）。解法是把检查下放到
  **函数子句**——每条子句一种情形：

      iex> Ex28ErrorMonad.checkout_case(["10", "20"])
      {:ok, 200}
      iex> Ex28ErrorMonad.checkout_case(["hot dog", "20"])
      {:error, :quantity_not_a_number}
      iex> Ex28ErrorMonad.checkout_case(["10", "hot dog"])
      {:error, :price_not_a_number}

  """
  @spec checkout_case([String.t()]) :: {:ok, number()} | {:error, atom()}
  def checkout_case(answers) do
    quantity = fetch(answers, 0)
    price = fetch(answers, 1)
    calculate(quantity, price)
  end

  defp calculate({:ok, q}, {:ok, p}), do: {:ok, q * p}
  defp calculate({:error, _}, _price), do: {:error, :quantity_not_a_number}
  defp calculate(_quantity, {:error, _}), do: {:error, :price_not_a_number}

  # ============================================================
  # 4. 策略二：try + rescue + defexception
  # ============================================================

  @doc """
  会 raise 的函数用 `!` 结尾（社区约定）。解析失败抛**自定义异常**，
  而不是让 MatchError 满天飞——rescue MatchError 太宽，救等于瞎救：

      iex> Ex28ErrorMonad.parse_answer!("42")
      42
      iex> Ex28ErrorMonad.parse_answer!("hot dog")
      ** (Ex28ErrorMonad.InvalidOptionError) Invalid option

  """
  @spec parse_answer!(String.t()) :: integer()
  def parse_answer!(answer) do
    case Integer.parse(answer) do
      :error -> raise Ex28ErrorMonad.InvalidOptionError
      {value, _rest} -> value
    end
  end

  @doc """
  try 块里写**愉快路径**（happy path，只有成功场景的代码），rescue
  集中处理异常。这是 OO 程序员最熟悉的形态，适合驯服不受你控制的
  库；自家代码尽量少 raise（第 11 章）：

      iex> Ex28ErrorMonad.checkout_rescue(["10", "20"])
      {:ok, 200}
      iex> Ex28ErrorMonad.checkout_rescue(["hot dog", "20"])
      {:error, "Invalid option"}

  """
  @spec checkout_rescue([String.t()]) :: {:ok, number()} | {:error, String.t()}
  def checkout_rescue(answers) do
    try do
      quantity = parse_answer!(Enum.at(answers, 0, ""))
      price = parse_answer!(Enum.at(answers, 1, ""))
      {:ok, quantity * price}
    rescue
      e in Ex28ErrorMonad.InvalidOptionError -> {:error, e.message}
    end
  end

  # ============================================================
  # 5. 策略三：throw + catch
  # ============================================================

  @doc """
  throw 抛的是**值**不是错误，catch 按模式接住——像流程控制结构，
  而非异常机制。函数体只有一个 try 块时可省略 `try do`（隐式 try）：

      iex> Ex28ErrorMonad.checkout_throw(["10", "20"])
      {:ok, 200}
      iex> Ex28ErrorMonad.checkout_throw(["10", "hot dog"])
      {:error, "Invalid option"}

  Elixir 程序员极少用 throw/catch——函数直接**返回**值就好，
  抛接是绕路（第 11 章的结论在这里依然成立）。
  """
  @spec checkout_throw([String.t()]) :: {:ok, number()} | {:error, String.t()}
  def checkout_throw(answers) do
    quantity = parse_answer_throw(Enum.at(answers, 0, ""))
    price = parse_answer_throw(Enum.at(answers, 1, ""))
    {:ok, quantity * price}
  catch
    {:error, message} -> {:error, message}
  end

  defp parse_answer_throw(answer) do
    case Integer.parse(answer) do
      :error -> throw({:error, "Invalid option"})
      {value, _rest} -> value
    end
  end

  # ============================================================
  # 6. 策略四：错误单子（从零手写）
  # ============================================================

  @doc """
  包装：`ok/1` 装成功值，`error/1` 装失败原因。值带上「气氛标签」，
  下游函数据此自动决定执行还是跳过：

      iex> Ex28ErrorMonad.ok(42)
      {:ok, 42}
      iex> Ex28ErrorMonad.error("boom")
      {:error, "boom"}
      iex> Ex28ErrorMonad.ok?(Ex28ErrorMonad.ok(1))
      true
      iex> Ex28ErrorMonad.ok?(Ex28ErrorMonad.error("x"))
      false

  书里用第三方库 MonadEx；本教程零依赖，直接手写——单子核心就
  这么大点：一个包装 + 一个 bind。
  """
  @spec ok(a) :: {:ok, a} when a: var
  def ok(value), do: {:ok, value}

  @spec error(b) :: {:error, b} when b: var
  def error(reason), do: {:error, reason}

  @spec ok?(term()) :: boolean()
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false

  @doc """
  bind——单子的心脏。成功：拆出值交给函数，函数的返回继续是单子；
  失败：**跳过函数**，错误原样传递（短路）：

      iex> Ex28ErrorMonad.bind({:ok, 3}, fn x -> {:ok, x * 2} end)
      {:ok, 6}
      iex> Ex28ErrorMonad.bind({:error, :boom}, fn x -> {:ok, x * 2} end)
      {:error, :boom}

  """
  @spec bind({:ok, a} | {:error, b}, (a -> {:ok, c} | {:error, b})) :: {:ok, c} | {:error, b}
        when a: var, b: var, c: var
  def bind({:ok, value}, fun), do: fun.(value)
  def bind({:error, _reason} = failure, _fun), do: failure

  @doc """
  `~>>` 是 bind 的中缀写法（宏展开成 bind，Elixir 允许定义这个
  保留运算符）。管道 `|>` 的单子版——错误自动跳过后续步骤：

      iex> import Ex28ErrorMonad
      iex> ok(3) ~>> (&ok(&1 * 2)) ~>> (&ok(&1 + 1))
      {:ok, 7}
      iex> error("wrong") ~>> (&ok(&1 * 2)) ~>> (&ok(&1 + 1))
      {:error, "wrong"}

  """
  defmacro left ~>> right do
    quote do: Ex28ErrorMonad.bind(unquote(left), unquote(right))
  end

  @doc """
  短路实证：每个步骤把自己的标签收进结果。中途出错，后面的步骤
  **不再执行**——标签链在出错处截断：

      iex> Ex28ErrorMonad.pipeline(:ok_path)
      {:ok, [:s1, :s2, :s3]}
      iex> Ex28ErrorMonad.pipeline(:fail_at_2)
      {:error, :boom}

  """
  @spec pipeline(:ok_path | :fail_at_2) :: {:ok, [atom()]} | {:error, :boom}
  def pipeline(mode) do
    result =
      ok([])
      |> bind(tag_step(:s1, mode))
      |> bind(tag_step(:s2, mode))
      |> bind(tag_step(:s3, mode))

    case result do
      {:ok, labels} -> {:ok, Enum.reverse(labels)}
      failure -> failure
    end
  end

  defp tag_step(:s2, :fail_at_2), do: fn _acc -> {:error, :boom} end
  defp tag_step(label, _mode), do: fn acc -> {:ok, [label | acc]} end

  @doc """
  结账的单子版：`ask_step/0` 是「问一个问题」的单子步骤，**同一个
  步骤复用两次**（先问数量、再问单价），最后一步算乘积。中途任何
  一步失败，后续步骤自动跳过——愉快路径一条线，错误在出口统一出现：

      iex> Ex28ErrorMonad.checkout_monad(["10", "20"])
      {:ok, 200}
      iex> Ex28ErrorMonad.checkout_monad(["hot dog", "20"])
      {:error, "Invalid option"}
      iex> Ex28ErrorMonad.checkout_monad(["10"])
      {:error, "Invalid option"}

  """
  @spec checkout_monad([String.t()]) :: {:ok, number()} | {:error, String.t()}
  def checkout_monad(answers) do
    ok({answers, []})
    |> bind(ask_step())
    |> bind(ask_step())
    |> bind(product_step())
  end

  defp ask_step do
    fn {answers, values} ->
      case ask(answers) do
        {:ok, {value, rest}} -> {:ok, {rest, [value | values]}}
        {:error, _} = failure -> failure
      end
    end
  end

  defp product_step do
    fn {_answers, values} -> ok(Enum.product(Enum.reverse(values))) end
  end

  defp ask([answer | rest]) do
    case Integer.parse(answer) do
      :error -> {:error, "Invalid option"}
      {value, _rest} -> {:ok, {value, rest}}
    end
  end

  defp ask([]), do: {:error, "Invalid option"}

  # ============================================================
  # 7. 策略五：with——Elixir 内建
  # ============================================================

  @doc """
  `with` 组合多个匹配子句：全部匹配 → 走 do 块；任何一步不匹配 →
  停下、把**不匹配的值**交给 else。不需要新数据结构、新概念、新库，
  这是多数场景最实用的策略：

      iex> Ex28ErrorMonad.checkout_with(["10", "20"])
      {:ok, 200}
      iex> Ex28ErrorMonad.checkout_with(["hot dog", "20"])
      {:error, :not_a_number}
      iex> Ex28ErrorMonad.checkout_with(["10"])
      {:error, :missing_answer}

  else 里**显式列出**每种失败（`:error`、`nil`），不用通配 `_`——
  有意识地决定每个错误怎么办（书 7.5 的忠告）。缺点：不能与 `|>`
  连用，愉快路径的链式美感打折。
  """
  @spec checkout_with([String.t()]) :: {:ok, number()} | {:error, :not_a_number | :missing_answer}
  def checkout_with(answers) do
    with {:ok, quantity} <- fetch(answers, 0),
         {:ok, price} <- fetch(answers, 1) do
      {:ok, quantity * price}
    else
      {:error, :not_a_number} -> {:error, :not_a_number}
      {:error, :missing_answer} -> {:error, :missing_answer}
    end
  end
end
