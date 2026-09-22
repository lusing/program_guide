# 13 · 异常

> 对应示例：`examples/13_exceptions/`

异常是 Ruby 唯一的错误通道：没有错误码、没有 `Result` 类型，出错就抛对象、往上传播、有人接住就继续。这一章把异常的完整生命周期讲透——层级、四段式结构、raise 的三种形态、retry 与 ensure——最后落到两个比语法更重要的纪律：**异常里的机器信息怎么处理**、**异常消息怎么对外输出**。

## 13.1 异常层级与裸 rescue 的边界

Ruby 的异常是一棵以 `Exception` 为根的类树：`ScriptError` 和 `StandardError` 是两个主分支，日常错误（`ZeroDivisionError`、`RuntimeError`、`NoMethodError`……）几乎都在 `StandardError` 之下。关键事实：**裸 rescue（不写类名）只捕 `StandardError` 及其子孙**，`Exception` 本体直接穿墙：

```ruby
def bare_rescue_cannot_hold
  begin
    raise Exception, "Exception 试图穿墙"
  rescue
    return :caught          # 永远执行不到
  end
end
escaped = false
begin
  bare_rescue_cannot_hold
rescue Exception => e
  escaped = true
  puts "裸 rescue 放走了它，外层点名捕获：#{e.class}"
end
```

实测输出（build/13.out）：

```text
裸 rescue 放走了它，外层点名捕获：Exception
裸 rescue = rescue StandardError；要捕 Exception 得显式写出类名
```

这条规则的**为什么**：`NoMethodError`、`TypeError` 这类是程序员的笔误，裸 rescue 一网打尽正合适；但 `SystemStackError`、`SignalException`、`NoMemoryError` 直接继承 `Exception`，是「进程级别的事故」，语言设计者故意不让裸 rescue 把它们吞掉。反过来，想让裸 rescue 漏接的异常（比如自定义的退出信号）就该继承 `Exception` 而不是 `StandardError`。

## 13.2 begin / rescue / else / ensure

四段式各有分工，用执行日志把顺序钉死：

```ruby
log = []
begin
  log << :body
  raise "演示用异常"
rescue => e
  log << "rescue(#{e.class})"     # 抛了异常：rescue 接手
else
  log << :else                    # 没抛异常才执行
ensure
  log << :ensure                  # 无论有没有异常都执行
end
```

实测输出：

```text
有异常：body → rescue(RuntimeError) → ensure
无异常：body → else → ensure（else 只在风平浪静时跑）
```

两条记忆线：

1. **`else` 是「成功路径」**：body 一路无异常才会跑，把「正常但依赖 body 成功」的代码放这里，避免误捕 body 自己的异常。
2. **`ensure` 无条件执行**：异常穿过它、return 经过它，都拦不住。清理资源（关文件、解锁）只写在这里。

`rescue => e` 的 `=> e` 把异常对象绑进局部变量，作用域只到这个 rescue 块结束；出了块就没了，别在块外引用。

## 13.3 def 体内直接写 rescue

`def...end` 本身就是一个隐式的 `begin...end`，所以 rescue/ensure 可以直接写在方法体里，省一层缩进：

```ruby
def safe_div(a, b)
  a / b
rescue ZeroDivisionError         # def...end 本身就是隐式 begin...end
  :div_by_zero
end
```

实测输出：

```text
safe_div(1, 0) = div_by_zero —— 方法体自带隐式 begin，rescue 可以直接写在 def 里
```

这是 Ruby 代码里的高频惯用法（尤其 RailS 的 controller 方法）。等价于把整个方法体包进 `begin...rescue...end`——不要写成方法体一半在 begin 里、一半在 begin 外，两种写法行为不同（begin 外的代码不受 rescue 保护）。

## 13.4 多类型 rescue 与自定义异常

一个 begin 可以挂多个 rescue，**自上而下匹配，子类分支必须放在父类前面**：

```ruby
class PaymentError < StandardError          # 惯例：继承 StandardError，不继承 Exception
  attr_reader :code
  def initialize(message, code:)
    super(message)             # 把 message 交回上层（StandardError#initialize）处理
    @code = code
  end
end

def dispatch(err)
  raise err
rescue PaymentError => e        # 子类分支必须放在父类前面！
  "支付失败 code=#{e.code}"
rescue ArgumentError
  "参数不对"
rescue StandardError => e       # 兜底分支
  "兜底：#{e.class}"
end
```

实测输出：

```text
dispatch(余额不足) → 支付失败 code=1002
```

两个坑都埋在这段代码里：

- **顺序错了静默出错**：`rescue StandardError` 写在 `PaymentError` 前面，支付异常永远走进兜底分支，不报错、只是行为错——比崩溃更难查。
- **自定义异常忘了 `super`**：`initialize` 里接收了 message 却不调 `super(message)`，`e.message` 就变成类名，日志里全是一模一样的 `PaymentError`。

携带结构化数据（`code:`）是自定义异常的核心价值： rescue 方能读到机器可用的信息，而不是去解析 message 字符串。

## 13.5 raise 三形态与裸 raise 重抛

`raise` 有三种形态，语义完全不同：

```ruby
raise ArgumentError                     # 形态一：类 → message 默认为类名
raise ArgumentError, "显式消息"          # 形态二：类 + 消息
raise prebuilt                          # 形态三：实例（message、backtrace 都是现成的）
raise "裸字符串"                         # 便捷形态：等价 RuntimeError.new("裸字符串")
```

实测输出：

```text
re-raise 后仍是原异常：RuntimeError / 原始异常
```

re-raise 用**裸 raise**（不带任何参数）：把「当前正在处理的异常」原样重抛，类、消息、backtrace 全部保留：

```ruby
def forward
  raise "原始异常"
rescue
  raise                        # 裸 raise：把当前异常原样重抛（消息、类、backtrace 都保留）
end
```

坑：重抛时写 `raise e`（用绑定的变量）会**改写 backtrace**——新帧从当前 raise 处开始，原始案发现场被截断。想加日志再重抛，用裸 raise 加 ensure/rescue 中转，别用 `raise e` 造一个新的异常实例链。

## 13.6 retry 重试

`rescue` 里写 `retry`，从头重新执行整个 begin 块：

```ruby
attempts = 0
begin
  attempts += 1
  raise "第 #{attempts} 次失败" if attempts <= 2
rescue
  retry if attempts < 3        # 没有 if 就是无限死循环 —— retry 必须配退出条件
end
```

实测输出：

```text
重试了 3 次终于成功（前两次抛错，第三次通过）
```

retry 是 Ruby 里唯一能「回到过去」的语句，也因此是唯一能一行造成死循环的 rescue 写法——裸 `retry` 没有退出条件就是无限重试。生产里的重试几乎都要配：计数上限、退避间隔（sleep）、以及「重试前先判断这个异常值不值得重试」（网络超时值得，参数错误不值得）。重试逻辑超过几行，就该抽成专门的重试工具方法，别让 retry 散落各处。

## 13.7 ensure 陷阱：return 吞异常

本章最阴的坑：**ensure 里的 return 会让正在传播的异常凭空消失**：

```ruby
def careless
  begin
    raise "真正的异常"
  ensure
    return :from_ensure        # 陷阱！return 会让正在传播的异常凭空消失
  end
end
```

实测输出：

```text
异常被 ensure 吞了 —— 外层 rescue 根本没收到，方法安静地返回了 :from_ensure
对照：捕获：RuntimeError（ensure 没拦，异常正常抵达外层）
```

为什么：方法只能有一个「离开方式」。异常正在向外传播时，ensure 里的 return 相当于宣布「方法已经正常返回了」，传播中的异常被直接丢弃。调用方拿到一个看似正常的返回值，错误被无声掩埋——这是线上「日志里没有任何异常但业务结果不对」的经典成因。同理，ensure 里的 `raise`、`break`、`next` 也会打断传播（raise 是换成新异常）。

纪律：**ensure 里只做清理，不做流程控制**。需要在 ensure 里记录什么，用局部变量带出去，别用 return。

## 13.8 $! 与异常对象信息

`$!` 是全局的「刚刚被捕获的异常」，等价于 `rescue => e` 的绑定，适合无法改 rescue 签名的场景：

```ruby
begin
  raise KeyError, "缺失配置项"
rescue
  e = $!                       # $! 是「刚刚被捕获的那个异常」
  first_frame = e.backtrace.first
  line_no = first_frame[/:(\d+):/, 1]   # 只提取行号，路径不打印
end
```

实测输出：

```text
捕获：KeyError / message=缺失配置项 / backtrace 首帧行号=182（路径含机器信息，不打印原文）
```

backtrace 的每一帧形如 `main.rb:182:in 'block in <main>'`——**首帧以机器上的绝对路径开头**（示例跑在哪台机器，路径就是那台机器的），直接打印既泄露环境又不可复现。所以本教程的纪律是：**只提取行号等结构化信息，路径原文不进 stdout**。异常对象上还有 `e.class`、`e.message`、`e.cause`（被这个异常掩盖的前一个异常）可查。

## 13.9 输出纪律：不打异常原文，打「中文句子 + 类名」

示例的最后一节没有新语法，只有一条输出纪律：

```ruby
begin
  1 / 0
rescue ZeroDivisionError => e
  puts "捕获：#{e.class}"       # 对外只给类名；e.message 是英文原文，别整段打印
end
```

实测输出：

```text
捕获：ZeroDivisionError
捕获：NoMethodError
```

为什么不打 `e.message`？两个原因：一是 `divided by 0`、`undefined method ... for an instance of String` 这类英文原文是给开发者调试用的，混进程序对外输出既不确定（不同版本措辞会变）也不友好；二是打印完整消息等于把内部实现细节泄给外部。给用户看「中文句子 + 类名」，给日志留完整异常对象（类名 + message + backtrace），两条通道分开走。

## 13.10 坑位清单

1. **裸 rescue 只捕 `StandardError`**：`Exception` 本体直接穿墙（`SystemStackError`、`SignalException` 都拦不住）——要捕就得显式写类名（13.1）。
2. **自定义异常继承 `Exception` 而非 `StandardError`**：会被所有裸 rescue 漏掉，行为库/框架一致性全毁（13.1、13.4）。
3. **`else` 只在无异常时执行**：把可能抛异常的代码放 else 里，异常没人接——那部分代码该留在 body（13.2）。
4. **多 rescue 分支顺序错了静默出错**：父类分支写在子类前面，子类永远匹配不到，不报错只是行为错（13.4）。
5. **自定义异常 `initialize` 忘了 `super(message)`**：所有实例的 message 都退化成类名（13.4）。
6. **裸 `retry` 没有退出条件就是死循环**：retry 必须配计数上限或成功条件（13.6）。
7. **ensure 里 `return` 吞异常**：正在传播的异常凭空消失，方法安静返回 ensure 的值——ensure 只做清理，不做流程控制（13.7）。
8. **ensure 里 `raise`/`break` 同样打断传播**：raise 会把原异常换成新异常，原始现场丢失（13.7）。
9. **重抛用 `raise e` 会截断 backtrace**：新帧从当前 raise 处开始，案发现场丢失——重抛用裸 `raise`（13.5）。
10. **backtrace 首帧含机器绝对路径**：直接打印既泄露环境又不可复现——只提取行号等结构化信息（13.8）。
11. **`$!` 是全局状态**：嵌套 rescue 或延迟读取时它可能已经指向别的异常——能用 `rescue => e` 就别用 `$!`（13.8）。
12. **对外输出别打 `e.message` 原文**：英文措辞随版本变、还泄露内部细节——对外给「中文句子 + 类名」，完整对象进日志（13.9）。

---

[上一章](12-symbols-regex.md) | [下一章](14-blocks.md)
