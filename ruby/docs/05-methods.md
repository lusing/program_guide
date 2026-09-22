# 05 · 方法

> 对应示例：`examples/05_methods/`

Ruby 的方法系统比看起来深：**隐式返回、五类参数、块作为隐形参数、Proc 与 lambda 两套语义、运算符也是方法**。本章主线一条——方法的一切行为都是消息传递的产物；理解了这一点，`&`、`to_proc`、`define_method` 都不再神秘。

## 5.1 隐式返回：return 可省

```ruby
def add(a, b)
  a + b                # 没有 return —— 最后一行的值自动返回
end
def early(a)
  return :zero if a.zero?
  :nonzero             # 提前返回也常用，但同样是隐式的
end
```

```text
---- 5.1 隐式返回：return 可省 ----
add(2,3) = 5；def 里 return 主要用于提前返回
```

方法体的**最后一个表达式的值就是返回值**，`return` 可省。这不是偷懒，而是「一切皆表达式」在方法层的直接推论（02.7）。惯用法：`return` 只用于**提前返回**（卫语句），主干不写。多行方法里随手加 `return` 反而是 C/Java 痕迹。

## 5.2 参数全家桶

```ruby
def greet(name, greeting = "你好", punct: "！", **extra)
  tail = extra.empty? ? "" : "（附注：#{extra[:note]}）"
  "#{greeting}，#{name}#{punct}#{tail}"
end
ok greet("小明", punct: "。") == "你好，小明。"
def demo(*args, **kw)
  [args, kw]
end
ok demo(1, 2, a: 3) == [[1, 2], { a: 3 }]
```

```text
---- 5.2 参数全家桶 ----
greet("小明", "早上好") = 早上好，小明！
demo(1, 2, a: 3) = [[1, 2], {a: 3}]
关键字参数与位置哈希已彻底分离（3.0 起）：传哈希不写 ** 会抛 ArgumentError
```

参数五种形态一句话记法：位置参数（`name`）、默认值（`greeting = "你好"`）、可变位置（`*args` 收进数组）、关键字（`punct: "！"`）、双 splat（`**extra` 收进哈希）。一张表定案：

| 形态 | 写法 | 实参去向 |
|---|---|---|
| 位置 | `def f(a, b)` | 按序传入 |
| 默认值 | `def f(a, b = 1)` | 缺省时启用 |
| 可变位置 | `def f(*a)` | 收进 Array |
| 关键字 | `def f(a:, b: 1)` | 按 `key:` 传 |
| 双 splat | `def f(**kw)` | 收进 Hash |

**3.0 起关键字参数与位置哈希彻底分离**：定义了 `a:, b:` 的方法，传 `{ a: 1 }`（位置哈希）直接抛 `ArgumentError`，不再 2.x 时代的「trailing hash 自动转关键字」——旧代码迁移的高危区，显式写 `**hash` 才能转发。示例用 lambda `strictly` 复现了这条 3.0 语义并断言它必须抛错。

## 5.3 命名约定：? 谓词、! 危险

```ruby
ok 42.is_a?(Integer) && [].empty? && 2.even?
src = +"abc"                          # + 前缀：产出一个「未冻结」的字面量副本
bang = src.upcase!                    # ! 版本原地修改，无变化时返回 nil
ok bang == "ABC" && src == "ABC"
```

```text
---- 5.3 命名约定：? 谓词、! 危险 ----
empty?/even? 是谓词；+"abc" 拿到未冻结副本后 upcase! 原地修改 —— ! 不代表「更危险地抛错」
```

`?` 后缀是谓词约定（返回真/假），纯社区惯例。`!` 后缀约定是「**原地修改的危险版本**」——与同名无叹号方法成对出现（`upcase` 返回新串，`upcase!` 原地改），**不表示「更易抛错」**。全书示例带 `frozen_string_literal: true`，字面量即冻结，要可变副本用 `+"abc"`（或 `.dup`）——这个 `+` 前缀惯用法在 4.0 的 chilled strings 时代（01.3）是必备写法。

## 5.4 块：yield 与 &blk

```ruby
def twice
  yield
  yield
end
n = 0
twice { n += 1 }                      # n == 2
def count_calls(&blk)                 # & 把块抓成 Proc 对象
  blk ? blk.call : :no_block
end
def takes_block?
  block_given?                        # block_given? 只在方法体里有意义
end
def with_prefix(prefix, &blk)
  [1, 2, 3].map(&blk).map { |s| "#{prefix}#{s}" }
end
```

```text
---- 5.4 块：yield 与 &blk ----
twice { n += 1 } → n = 2；block_given? 在方法体里判断有没有传块
with_prefix("N") { |x| x * 10 } = ["N10", "N20", "N30"]
```

块是方法的**隐形参数**：方法体内 `yield` 调用它；`&blk` 把它抓成 Proc 对象（可保存、可转发）；`block_given?` 判断调用方传没传块。三种用法各有适用场景：纯就地执行写 `yield`（最快、最惯用）；要把块存下来或判断存在性写 `&blk`；`block_given?` 让同一个方法兼容「带块调用途中计算」与「不带块给默认行为」两种调用风格。

转发块的标准姿势就是 `&blk`——`with_prefix` 把外部块转给 `map`，再链一步加工。`&` 是双向闸门：定义处「块 → Proc」，调用处「Proc/Symbol → 块」（5.6 见 `&:upcase`）。注意 `blk ? ... : ...` 判空：没传块时 `&blk` 的 `blk` 是 `nil`，这与「顶层 `block_given?` 恒为假」一样，都只能在方法体内判断。

## 5.5 Proc 与 lambda

```ruby
pr = proc { |a, b| [a, b] }
lm = ->(a, b) { [a, b] }              # lambda 字面量
ok pr.call(1) == [1, nil]             # proc：宽松，缺参补 nil
ok lm.arity == 2
begin; lm.call(1); rescue ArgumentError; raised = true; end
ok lm.lambda? && !pr.lambda?
```

```text
---- 5.5 Proc 与 lambda ----
proc.call(1) = [1, nil]（宽松）；lambda 严格查 arity
lambda 的 return 只离开 lambda 本身；proc 的 return 离开定义它的方法（易炸，慎用）
```

块抓成 Proc 后有**两种子语义**：`proc` 宽松——参数不查 arity，缺的补 `nil`；`lambda` 严格——`call(1)` 对双参 lambda 抛 `ArgumentError`，`lambda?` 可区分。`return` 语义差异更要命：**lambda 的 `return` 只离开它自己**（方法继续跑完）；**proc 的 `return` 会离开定义它的方法**——在已被调用的上下文里触发就是 `LocalJumpError` 事故现场。通用建议：可复用的匿名函数写 `->()`（lambda），别依赖 proc 的宽容。

## 5.6 方法对象与 Symbol#to_proc

```ruby
upcase = "abc".method(:upcase)        # Method 对象：绑定接收者
ok upcase.call == "ABC"
ok %w[a b c].map(&:upcase) == %w[A B C]     # Symbol#to_proc
ok [3, 1, 2].sort_by(&:-@) == [3, 2, 1]     # &:-@ → method(:-@).to_proc
ok [1, "a", :b].map(&:itself) == [1, "a", :b]
```

```text
---- 5.6 方法对象与 Symbol#to_proc ----
map(&:upcase) 的 & 触发 to_proc；method(:f) 拿到可传递的 Method 对象
```

`obj.method(:f)` 返回绑定好的 Method 对象，可以存进变量、传给别处。`map(&:upcase)` 的 `&` 触发 `Symbol#to_proc`，语义是「**对每个元素调用 `.upcase`**」——等价于 `map { |x| x.upcase }`，连运算符都能用（`&:-@` 取负，即 `method(:-@).to_proc`）。`&:itself` 返回元素本身，是「原样收集/去重计数」的惯用件。常见误用：`map(&method(:itself))` 抛 `ArgumentError`（Method#to_proc 按位置塞参数，`itself` 不收参数），写 `map(&:itself)` 就好——`&:` 与 `&method()` 不是同一种东西。

性能顺带一提：`&:sym` 有解释器层面的专门优化路径，通常不慢于带块形式，但可读性才是选它的第一理由——`map { |x| x.name.upcase }` 这种复杂逻辑别硬拆成 `&:` 链。

## 5.7 运算符即方法

```ruby
ok 3 + 4 == 3.+(4)                    # a + b 只是 a.+(b) 的语法糖
vec = Struct.new(:x, :y) do
  def +(other) = self.class.new(x + other.x, y + other.y)
  def -@ = self.class.new(-x, -y)
end
v = vec.new(1, 2) + vec.new(10, 20)
ok v.x == 11 && v.y == 22
```

```text
---- 5.7 运算符即方法 ----
vec(1,2) + vec(10,20) = (11, 22) —— + 与 -@ 都是普通方法
```

`a + b` 只是 `a.+(b)` 的语法糖，所以**运算符可以整体自定义**：给类定义 `+` 实例方法就得到向量加法，`-@` 是一元负号的方法名。限制：`&&`/`||`/`!` 不可重定义（短路求值是语法层面的），赋值类（`=`）也不行。示例用 `Struct.new` 加块一行定义带运算符的类型——`def +(other) = ...` 是 3.0 的 endless method 写法。

## 5.8 define_method 动态定义

```ruby
registry = Class.new do
  %i[open close read].each do |op|
    define_method("can_#{op}?") { true }
  end
end
obj = registry.new
ok obj.can_open? && obj.can_close? && obj.can_read?
```

```text
---- 5.8 define_method 动态定义 ----
循环 define_method 生成 can_open?/can_close?/can_read? 三个方法（15 章细讲）
```

`define_method` 用代码**生成**方法：名字是字符串/符号（可拼接），体是块。上面的循环一次造出三个谓词——手写三遍 vs 一行循环，这是元编程最朴素的收益。闭包捕获 `op` 是它的关键机制：三个块各记着各自的 `op`，生成的三个方法互不串扰——这也是「用块还是用字符串 eval」的分水岭，块捕获词法作用域，eval 什么都能塞（15 章展开）。

方法生成的另一层意义：`can_#{op}?` 这种「命名有规律、实现全相同」的方法族，永远不该手写——规律应该由循环表达，而不是靠复制粘贴维护。

## 5.9 坑位清单

1. **关键字参数与位置哈希已彻底分离（3.0）**：传 `{ a: 1 }` 给只收 `a:` 的方法直接 `ArgumentError`，转发必须显式 `**hash`——2.x 旧代码迁移头号雷（5.2）。
2. **`!` 方法是「原地修改」不是「更易抛错」**：`upcase!` 原地改并返回 self，无变化时返回 `nil`（易被当布尔用）（5.3）。
3. **frozen_string_literal 下改字面量抛 FrozenError**：可变副本用 `+"abc"` 或 `.dup`；4.0 没写魔法注释则只发弃用告警（chilled strings），但本书标准是 stderr 必须为空（5.3/01.3）。
4. **proc 与 lambda 语义不同**：参数宽容度（缺参补 nil vs `ArgumentError`）与 `return` 范围（离开定义方法 vs 只离开自身）都不同，`lambda?` 可区分（5.5）。
5. **proc 的 `return` 会离开定义它的方法**：把带 `return` 的 proc 存起来跨方法调用就是事故现场，匿名函数优先写 `->()`（5.5）。
6. **顶层 `block_given?` 恒为假**：它只在方法体里有意义（4.0.7 实测）；判断有没有块必须写在方法内（5.4）。
7. **`&` 的方向别搞反**：定义处 `&blk` 把块抓成 Proc；调用处 `&:upcase`/`&blk` 把 Proc/Symbol 转回块——同一个符号两个方向（5.4/5.6）。
8. **`map(&method(:itself))` 抛 ArgumentError**：`Method#to_proc` 按位置传参，与 `map(&:itself)` 不等价（5.6）。
9. **隐式返回的是「最后一个表达式」**：中间的 `puts`/赋值都有值，最后一行是 `puts` 的方法返回的是 `nil`——别让调试输出挤掉了真正的返回表达式（5.1）。
10. **`&&`/`||`/`!` 与赋值不可重定义**：运算符重载只覆盖 `+`/`-`/`==`/`<=>` 这类方法型运算符（5.7）。
11. **endless method（`def f = ...`）只能一行**：多逻辑硬塞一行可读性崩塌，复杂方法体还是老老实实 `def ... end`（5.7）。
12. **`define_method` 的块捕获的是定义时变量**：循环里每个块闭包捕获各自的 `op`——写成「引用循环变量本身」的时序 bug 在 15 章有专节（5.8）。

---

**上一章**：[04 · 控制流](04-control.md) | **下一章**：[06 · 类与对象](06-classes.md)
