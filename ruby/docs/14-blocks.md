# 14 · 块与闭包

> 对应示例：`examples/14_blocks/`

块是 Ruby 的灵魂语法：每个方法调用都能附带一段代码，而这段代码携带它出生时的作用域——这就是闭包。本章的主线只有一句话：**闭包绑定的是变量本身，不是值的拷贝**。围绕这句话展开 Proc/lambda 的语义差、`&` 转发、参数解构、变量遮蔽，最后用计数器工厂把「闭包 = 绑定」落到可运行的代码上。

## 14.1 闭包绑定变量本身，不是值的拷贝

块和 lambda 引用外层变量时，抓到的是**变量槽位**，不是当时的值：

```ruby
counter = 0
increment = -> { counter += 1 }      # lambda 捕获的是 counter 这个变量槽位
increment.call
increment.call
ok counter == 2
10.times { counter += 1 }            # 块同样直接读写外层变量
ok counter == 12
```

实测输出：

```text
调用两次后 counter = 2（闭包改的是外面的变量）
再让块加 10 次，counter = 12 —— 块和 lambda 看到的是同一格内存
```

这是全章的基石：闭包里的赋值能改变外部世界。反过来说，**闭包的生命期可以长于定义它的方法**——方法返回后，被它捕获的变量依然活着（见 14.9），局部变量第一次拥有了「堆上生命周期」。习惯了「函数参数是拷贝」的语言（C/Go）用户最容易在这里踩空：以为传进块的是快照，改了不影响外面。

## 14.2 arity、lambda? 与 curry 逐步应用

`Proc` 有两个亚种：lambda（`->() {}` 创建）和 proc（`proc {}` 创建），差别在参数检查与 return 语义：

```ruby
add3 = ->(a, b, c) { a + b + c }
ok add3.arity == 3 && add3.lambda?
curried = add3.curry                 # 柯里化：一次喂一个参数
ok curried[1][2][3] == 6
add10 = curried[10]                  # 部分应用：先固定前缀参数
ok add10[90][100] == 200
pr = proc { |a, b| [a, b] }
ok pr.arity == 2 && pr.call(1) == [1, nil]   # proc 宽松：缺参补 nil
```

实测输出：

```text
add3.curry 后 add10 = curried[10]，再喂 90、100 得 200
```

参数检查的实测规则（-e 探针验证过）：

- **lambda 严格 arity**：`->(a, b) {}.call(1)` 抛 `ArgumentError: wrong number of arguments (given 1, expected 2)`——参数个数说一不二。
- **proc 宽松**：缺参补 `nil`，多余参数静默丢弃，`proc { |a, b| }.call(1, 2, 3)` 不报错。

`curry` 把多参函数变成「一次一个参数」的链条，且 `curried.lambda?` 仍为 true（curry 保留 lambda 语义）。实战里 curry 最有用的形态是**部分应用**：先固定前缀参数得到专用函数（`add10`），再到处复用。

## 14.3 Proc#=== 与 case/when

`case/when` 的本质是语法糖：对每个 when 条件调 `===`，传 `case` 的值。`Proc#===` 就是 `call`，所以 Proc 可以直接当条件用：

```ruby
grade_label = ->(score) do
  case score
  when ->(x) { x > 90 } then "优"    # when 分支会对条件对象调 ===，Proc 的 === 即 call
  when ->(x) { x > 60 } then "及格"
  else "不及格"
  end
end
ok grade_label.call(95) == "优"
ok (->(x) { x > 90 }) === 95         # case/when 只是 === 的语法糖
```

实测输出：

```text
score=95 走 Proc 分支 → 优；自上而下，先命中先赢
```

同一个 `===`，在不同类上有不同含义：Range 的 `===` 是「是否落在区间内」、Class 的 `===` 是「是否是该类实例」、Regexp 的 `===` 是「是否匹配」——case/when 之所以能同时处理这几种条件，就是因为它们都实现了 `===`。坑：`===` 的方向是 **条件在左、值在右**，写反了就成了拿值调 `===`，Range 和 Proc 的结果完全不同。

## 14.4 define_method：循环里定义的方法各捕各的绑定

`define_method` 用块定义方法，而块是闭包——循环里每个 `define_method` 各捕各的循环变量：

```ruby
factory = Class.new do
  %i[a b c].each do |name|
    n = 0                            # n 在每轮循环都是新变量 → 每个方法闭包独享一份
    define_method("bump_#{name}") { n += 1; n }
  end
end
f = factory.new
2.times { f.bump_a }
a_val = f.bump_a                    # a 的计数器被摸过两次，这是第三次
b_val = f.bump_b
ok a_val == 3 && b_val == 1 && f.bump_c == 1    # b、c 各自从 0 开始 —— 互不串线
```

实测输出：

```text
bump_a 累到 3，bump_b 才 1 —— define_method 的块各捕各的循环变量
```

关键在 `n = 0` 写在循环体内：每轮迭代都是一个新变量，三个方法各自闭包一份。如果把 `n = 0` 挪到循环外，三个方法会**共享同一个计数器**——`bump_a` 调三次、`bump_b` 立刻返回 4。这不是 bug，是闭包语义的必然结果；想要共享就放循环外，想要隔离就放循环内。`def` 做不到这件事：`def` 里看不见循环变量（15.5 有实测对照）。

## 14.5 Method 对象与 & 转发

`method(:f)` 拿到一个绑定了接收者的 `Method` 对象，`&` 触发 `to_proc` 把它塞进块位：

```ruby
def shout(word)
  "#{word}!"
end
ok [1, 2, 3].map(&method(:shout)) == %w[1! 2! 3!]     # & 把 Method 转成 Proc 塞给块位
ok m.to_proc.call("hi") == "hi!"
ok m.to_proc.lambda?                                  # Method#to_proc 是 lambda 语义（严格 arity）
def record(&blk)
  [1, 2, 3].map(&blk)                                 # & 转发：把收到的块转手给 map
end
ok record { |n| n * 3 } == [3, 6, 9]
```

实测输出：

```text
method(:f) 拿到绑定接收者的 Method 对象，& 触发 to_proc 填进块位
```

示例源码里注明了一个实测坑：`map(&method(:itself))` 抛 `ArgumentError`——`Method#to_proc` 按 lambda 语义检查参数，`map` 每次传 1 个元素，而 `Integer#itself` 收 0 个参数，个数对不上直接炸。**符号版 `map(&:itself)` 没这个问题**（Symbol#to_proc 的参数检查宽松）。`&` 还有第二个用途：`def record(&blk)` 把块收进变量，`map(&blk)` 再转手出去——块的「转寄」全靠 `&`。

## 14.6 块参数解构：平铺与嵌套

块参数多于 1 个时，Ruby 对元素自动解构：

```ruby
pairs = [[1, 2], [3, 4]]
pairs.each { |a, b| sums << a + b }                  # 块参数多于 1 个 → 对元素自动解构
nested = [[[1, 2], 3], [[4, 5], 6]]
nested.each { |(a, b), c| flat << [a, b, c] }        # 括号嵌套解构：模式写得进去
```

实测输出：

```text
|(a, b), c| 一次拆开嵌套数组 —— 解构模式能嵌套任意层
```

解构模式可以像模式匹配一样层层嵌套，`|(a, b), c|` 一行拆开两层。坑：解构是**按位置、宽松匹配**的——元素比参数多，多的静默丢弃；比参数少，缺的补 `nil`，都不报错。要对结构做严格校验，用 04 章的 `case/in` 模式匹配，别指望块解构替你把关。

## 14.7 变量遮蔽与块局部变量

块参数永远是新变量，会遮住同名外层变量：

```ruby
x = "外层"
[1].each { |x| x = "块内" }                          # 块参数 x 是新变量，遮住外层 x
ok x == "外层"                                        # 块里改的只是影子，外层毫发无损
y = 100
[1, 2].each { |i; y| y = i * 10; shadowed << y }     # |i; y| 的 ; y 声明块局部变量
ok y == 100 && shadowed == [10, 20]                  # 外层 y 没被覆盖
```

实测输出：

```text
块参数 |x| 遮蔽外层 x；|i; y| 显式声明块局部，防误伤同名外层变量
```

两套机制方向相反：

1. **块参数遮蔽外层**：块里那个 `x` 是新的，赋值动不了外面的 `x`——但没写成参数的同名变量（如 `|i|` 里的另一个 `x`）会被读写，**外层被误伤**。
2. **`; y` 声明块局部**：`|i; y|` 里的 `y` 是块私有的，防的就是「块内临时变量不小心撞名外层」这种隐式耦合。

实战纪律：块内用到的临时变量，只要外层存在同名风险，就写进 `;` 后面。这是 Ruby 里少有的「显式声明作用域」的手段。

## 14.8 手写 each：yield 与多值 yield

迭代器的本质是 `while + yield`，自己写一遍就再也不会对 `each` 感到神秘：

```ruby
class Seq
  def initialize(items)
    @items = items.to_a
  end

  def my_each                                        # 最朴素的迭代器：while + yield
    i = 0
    while i < @items.length
      yield @items[i]                                # 不带块调用会抛 LocalJumpError
      i += 1
    end
    self                                             # 返回自身，可继续链式调用
  end

  def my_each_with_index
    i = 0
    while i < @items.length
      yield @items[i], i                             # yield 带两个值 → 块参数 |item, index|
      i += 1
    end
    self
  end
end
```

实测输出：

```text
0:甲 1:乙 2:丙
```

三个要点：`yield` 可以一次传多个值（块参数按 14.6 的解构规则接住）；`my_each` 返回 `self`，所以能 `seq.my_each { }.map { }` 链下去；**没传块就调用会抛 `LocalJumpError`**（示例里用 rescue 验证过）——`yield` 找不到块就是这个下场。想兼容「调用方没给块」的场景，用 `block_given?` 先判断。

## 14.9 make_counter：两个 Proc 共享一份绑定

闭包 = 绑定的最终形态：两个 Proc 共享同一份局部状态：

```ruby
def make_counter
  count = 0                        # 这个变量活在 make_counter 的绑定里
  increment = -> { count += 1; count }
  getter = -> { count }            # 与 increment 看到的是同一个 count
  [increment, getter]
end
inc, get = make_counter
inc.call
inc.call
ok get.call == 2                    # getter 看得见 increment 做的修改
fresh, fresh_get = make_counter     # 每次调用 make_counter 造一套全新绑定
ok fresh.call == 1 && fresh_get.call == 1
def make_adder(start)
  ->(n) { start += n }              # 累加器：状态就藏在闭包里
end
```

实测输出：

```text
inc 与 get 共享同一个 count（现在 = 3），这就是「闭包 = 绑定」的含义
```

`get` 看得见 `inc` 做的每一次自增——因为它们闭包的是**同一个 `count` 变量槽位**，不是各存一份值。每次调用 `make_counter` 都造一套全新绑定，所以 `fresh` 从 1 开始、与旧计数器互不干扰。这就是「对象不过是携带状态的过程」的最小实现：没有 class、没有 `@`，状态照样私有且持久。`make_adder` 再进一步——参数 `start` 也活在闭包里，累加器本质上是「把参数变成了状态」。

## 14.10 坑位清单

1. **闭包改的是外面的变量**：块/lambda 里的赋值直接读写外层变量槽位，不是拷贝——想在闭包里保住原值，先 `x = x` 复制成块局部（14.1、14.7）。
2. **proc 的 return 离开定义它的方法**：`proc { return }` 在方法里被调用时，直接从**那个方法**返回，方法体后半段被跳过；lambda 的 return 只离开 lambda 自己（实测于 -e 探针；14.2）。
3. **lambda 严格 arity、proc 宽松**：`->(a, b) {}.call(1)` 抛 `ArgumentError`；proc 缺参补 `nil` 多参丢弃，错误个数静默通过（14.2）。
4. **`Method#to_proc` 是 lambda 语义**：`map(&method(:itself))` 抛 `ArgumentError`（0 参方法接 1 参调用）——符号版 `map(&:itself)` 才安全（14.5）。
5. **块解构是宽松匹配**：元素多则丢弃、少则补 `nil`，都不报错——严格校验用 `case/in`（14.6）。
6. **`n = 0` 在循环内/外决定闭包共享还是隔离**：`define_method` 在循环里定义的方法，各捕各的循环内变量；变量挪到循环外就全体共享（14.4）。
7. **块参数遮蔽同名外层变量**：`|x|` 里的 x 是新变量，块内赋值动不了外层——但非参数的同名变量会被误伤，临时变量用 `|i; y|` 显式声明块局部（14.7）。
8. **`yield` 没有块就抛 `LocalJumpError`**：对外公开的迭代器方法要么先 `block_given?` 判断，要么文档里写明必须带块（14.8）。
9. **`===` 方向是条件在左、值在右**：`range === x` 和 `x === range` 语义完全不同，写反 case/when 就全部分支落空（14.3）。
10. **闭包延长局部变量生命期**：make_counter 返回后 `count` 依然活着且可变——闭包持有的大对象不释放就是内存泄漏（14.9、14.1）。
11. **`curry` 保留 lambda 语义**：柯里化后的链条仍然严格 arity，缺一环不报错但也不执行，取值必须喂满（14.2）。
12. **两个 Proc 共享绑定是特性不是 bug**：getter 看得见 increment 的修改——想「隔离」就换一次调用（新绑定），别在闭包里找拷贝语义（14.9）。

---

[上一章](13-exceptions.md) | [下一章](15-metaprogramming.md)
