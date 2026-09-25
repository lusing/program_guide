defmodule Ex26Closures do
  @moduledoc """
  第 26 章示例：闭包与函数组合。

  对应《函数式编程入门：使用 Elixir》第 2 章 2.4 节的深挖。函数是
  一等公民：可以当参数传、当返回值收、存进数据结构、被 `&` 捕获。
  匿名函数「记住」创建它时的词法作用域——这就是闭包：

  * 闭包捕获的是**创建时刻的值**，之后重绑外部变量不影响已创建的闭包；
  * 参数是**绑定变量**，会遮蔽同名的外部**自由变量**；
  * 没有可变状态也能「计数」：状态装进下一个闭包里往下传；
  * 小函数用 `compose` 拼成大函数，管道收进数据里。

      iex> greeter = Ex26Closures.make_greeter("Hello")
      iex> greeter.("World")
      "Hello, World!"

  """

  # ============================================================
  # 1. 函数作为参数：策略注入
  # ============================================================

  @doc """
  书的经典例子：总价 = 价格 + 费用。费用**怎么算**被当作函数注入——
  同一个 `total_price/2`，装上不同的费用策略就是不同的计费系统：

      iex> flat = Ex26Closures.fee(:flat)
      iex> flat.(1000)
      5
      iex> proportional = Ex26Closures.fee(:proportional)
      iex> proportional.(1000)
      120.0
      iex> Ex26Closures.total_price(1000, flat)
      1005
      iex> Ex26Closures.total_price(1000, proportional)
      1120.0

  注意调用匿名函数要用 `.()`——`flat(1000)` 会去找具名函数 `flat/1`。
  """
  @spec total_price(number(), (number() -> number())) :: number()
  def total_price(price, fee), do: price + fee.(price)

  @doc """
  费用策略工厂：返回闭包。固定费用无视价格；比例费用按 12% 计算：

      iex> Ex26Closures.fee(:flat).(100)
      5
      iex> Ex26Closures.fee(:proportional).(100)
      12.0

  """
  @spec fee(:flat | :proportional) :: (number() -> number())
  def fee(:flat), do: fn _price -> 5 end
  def fee(:proportional), do: fn price -> price * 0.12 end

  # ============================================================
  # 2. 捕获创建时刻的值
  # ============================================================

  @doc """
  闭包记住的是**创建时刻**的绑定。之后再给外部同名变量换新值（重绑），
  闭包里的那份纹丝不动：

      iex> f = Ex26Closures.freeze(10)
      iex> x = 10
      iex> {f.(), x}
      {11, 10}
      iex> x = 999
      iex> {f.(), x}
      {11, 999}

  Elixir 没有可变变量——「重绑」只是让名字指向新值；旧值 10 还被闭包
  持有着，所以 `f.()` 永远是 11。这是闭包与「引用可变变量」的关键区别。
  """
  @spec freeze(number()) :: (-> number())
  def freeze(x), do: fn -> x + 1 end

  @doc """
  词法作用域是**单向镜**：函数内部能看见外部变量，外部看不见函数
  内部定义的变量（在外面访问 `other_answer` 会得到 CompileError——
  undefined variable）。函数只能看到**自己定义之前**的外部变量。
  `inner_demo/0` 把「内部定义、外部不可见」固化成返回值对比：

      iex> {inner, outer_after} = Ex26Closures.inner_demo()
      iex> inner
      130
      iex> outer_after
      42

  闭包里 `other_answer = 88 + answer` 是内部绑定，跑完就随作用域消失；
  外部的 `answer`（42）自始至终没被改写。
  """
  @spec inner_demo() :: {number(), number()}
  def inner_demo do
    answer = 42

    make = fn ->
      other_answer = 88 + answer
      other_answer
    end

    inner = make.()
    {inner, answer}
  end

  # ============================================================
  # 3. 绑定变量遮蔽自由变量
  # ============================================================

  @product_price 200

  @doc """
  函数体里：来自参数（或函数体局部定义）的是**绑定变量**；其余引用
  的都是**自由变量**（被闭包捕获）。书的原例：外部有
  `product_price = 200`、`quantity = 2`，而函数参数也叫 `quantity`——
  参数（绑定）遮蔽外部的同名（自由），调用 `.(4)` 得 800：

      iex> quantity = 2
      iex> calculate = Ex26Closures.calculator()
      iex> {quantity, calculate.(4)}
      {2, 800}

  遮蔽不是好实践（读者要数清楚哪个 quantity 是哪个），这里只为看清
  规则：**同名时，参数赢**。
  """
  @spec calculator() :: (number() -> number())
  def calculator do
    product_price = @product_price
    fn quantity -> product_price * quantity end
  end

  # ============================================================
  # 4. 闭包工厂：吃配置，吐函数
  # ============================================================

  @doc """
  闭包工厂的日常形态：把配置「腌」进函数。两份问候互不干扰：

      iex> hello = Ex26Closures.make_greeter("Hello")
      iex> hi = Ex26Closures.make_greeter("Hi")
      iex> hello.("Ada")
      "Hello, Ada!"
      iex> hi.("Ada")
      "Hi, Ada!"

  """
  @spec make_greeter(String.t()) :: (String.t() -> String.t())
  def make_greeter(greeting), do: fn name -> "#{greeting}, #{name}!" end

  @type counter :: (-> {integer(), counter})

  @doc """
  没有可变状态也能「计数」：每次调用返回 `{当前值, 下一个计数器}`，
  状态被装进下一个闭包往下传——第 18 章 `Stream.iterate/2` 的种子
  就是这个形状：

      iex> c0 = Ex26Closures.counter(0)
      iex> {v1, c1} = c0.()
      iex> v1
      0
      iex> {v2, _c2} = c1.()
      iex> v2
      1

  """
  @spec counter(integer()) :: counter()
  def counter(start) do
    fn -> {start, counter(start + 1)} end
  end

  @doc """
  走 n 步，收前 n 个值——「不可变状态机」的驱动循环：

      iex> Ex26Closures.counter_values(Ex26Closures.counter(0), 5)
      [0, 1, 2, 3, 4]

  """
  @spec counter_values(counter(), non_neg_integer()) :: [integer()]
  def counter_values(counter, n), do: counter_values(counter, n, [])
  defp counter_values(_counter, 0, acc), do: Enum.reverse(acc)

  defp counter_values(counter, n, acc) do
    {value, next} = counter.()
    counter_values(next, n - 1, [value | acc])
  end

  # ============================================================
  # 5. & 捕获：具名函数当值用
  # ============================================================

  @doc """
  `&Mod.fun/arity` 取具名函数的引用。直接写 `upcase = String.upcase`
  是在**调用**零参版本（UndefinedFunctionError：不存在 upcase/0），
  必须用 `&` 拿引用：

      iex> upcase = Ex26Closures.named_upcase()
      iex> upcase.("hello")
      "HELLO"

  """
  @spec named_upcase() :: (String.t() -> String.t())
  def named_upcase, do: &String.upcase/1

  @doc """
  `&表达式` 形态：`&1`/`&2` 是位置参数，编译器据此推断元数。适合
  一行小函数；注意**无法**用 `&` 造零参函数（`&(true)` 直接编译错），
  零参只能 `fn -> ... end`：

      iex> mult = Ex26Closures.multiply()
      iex> mult.(10, 2)
      20

  """
  @spec multiply() :: (number(), number() -> number())
  def multiply, do: &(&1 * &2)

  @doc """
  `&` 捕获还能顺手把外部变量「腌」进去：管道里没法直接塞 `Enum.at/2`
  （它要的是列表在前），包一层闭包就通了——书第 6 章选英雄的管道
  正是这么写的：

      iex> heroes = ["Knight", "Wizard", "Rogue"]
      iex> find = Ex26Closures.find_by_index(heroes)
      iex> is_function(find, 1)
      true
      iex> find.(1)
      "Wizard"

  """
  @spec find_by_index(list()) :: (integer() -> term() | nil)
  def find_by_index(list), do: &Enum.at(list, &1)

  # ============================================================
  # 6. 函数组合
  # ============================================================

  @doc """
  函数组合：`compose(f, g)` 返回「先 f 后 g」的新函数。小积木拼
  大积木，中间不落地：

      iex> shout = Ex26Closures.compose(&String.trim/1, &String.upcase/1)
      iex> shout.("  hi  ")
      "HI"

  """
  @spec compose((a -> b), (b -> c)) :: (a -> c) when a: var, b: var, c: var
  def compose(f, g), do: fn x -> g.(f.(x)) end

  @doc """
  `|>` 的函数版：把一串函数依次应用于值，管道被收进**数据**里——
  函数列表本身可以存、可以传、可以动态拼装：

      iex> Ex26Closures.thread("  hi  ", [&String.trim/1, &String.upcase/1, &String.reverse/1])
      "IH"

  """
  @spec thread(a, [(a -> a)]) :: a when a: var
  def thread(value, steps), do: Enum.reduce(steps, value, fn step, acc -> step.(acc) end)
end
