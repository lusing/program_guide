# 15 · 元编程

> 对应示例：`examples/15_metaprogramming/`

Ruby 的方法查找发生在运行时，「方法名」本身就是一个可以传递、生成、拦截的数据。元编程就是利用这一点：让代码在运行时定义代码。本章从 `send` 动态派发出发，经 `method_missing` 代理、`define_method` 批量生成、`eval/binding` 字符串求值，最后合成一个微 DSL——每一站都配上「什么时候不该用」的警告，因为元编程的坑几乎都来自「该静态的地方动态了」。

## 15.1 send / public_send：白名单动态派发

`obj.name(args)` 只是 `obj.send(:name, args)` 的语法糖；用 `send`，方法名可以是运行时才确定的字符串或符号：

```ruby
calc = ->(op, a, b) { a.send(op, b) }
ok calc.call(:+, 3, 4) == 7 && calc.call(:*, 3, 4) == 12
# 实战惯例：外部输入派发要走白名单，绝不能把用户字符串直接 send
ALLOWED = %i[+ - *].freeze
def safe_calc(op, a, b)
  raise(ArgumentError, "不允许的操作") unless ALLOWED.include?(op.to_sym)
  a.send(op, b)
end
```

实测输出：

```text
白名单派发：safe_calc("+",2,5) = 7
secret_m 是 private：public_send 抛 NoMethodError，send 才可达；respond_to? 要传 true 才认
```

可见性三件套（示例里逐条断言过）：

- `public_send` 调 private 方法抛 `NoMethodError`；`send` 能穿透 private（内省/桥接场景专用）。
- `respond_to?` 默认**不认** private 方法，第二参数传 `true` 才算进来。

安全红线：`send` 的参数一旦来自用户输入，就等于把「调用任意方法」的权限交给外部（`send("system", ...)` 这类）。**外部输入派发必须先过白名单**（`ALLOWED.include?(op.to_sym)`），这条没有例外。

## 15.2 method_missing 动态代理

对象收到找不到的方法时，调用链最后一站是 `method_missing`。覆写它就能「缺什么补什么」：

```ruby
class Proxy
  def initialize(data) = @data = data
  # get_xxx 风格的方法不用逐个写，缺什么补什么（哈希键是 Symbol，注意 to_sym 对齐）
  def method_missing(name, *args, &blk)
    key = name.to_s.delete_prefix("get_").to_sym
    if name.to_s.start_with?("get_") && @data.key?(key)
      @data[key]
    else
      super    # 链尾 super：不认识的消息原样往上抛
    end
  end
  def respond_to_missing?(name, include_private = false)
    key = name.to_s.delete_prefix("get_").to_sym
    (name.to_s.start_with?("get_") && @data.key?(key)) || super
  end
end
```

实测输出：

```text
px.get_name = 小明（method_missing 现场生成，类里根本没有这个方法）
不认识的消息链尾 super 抛出：NoMethodError
```

两条铁律：

1. **必须同时覆写 `respond_to_missing?`**：否则 `px.get_name` 能调、`px.respond_to?(:get_name)` 却是 false，对象行为不一致，依赖 `respond_to?` 的库（序列化、mock 框架）全部失灵。
2. **不认识的消息必须链尾 `super`**：把 NoMethodError 原样往上抛。吞掉不认识的消息（返回 nil 之类），拼写错误就再也查不出来。

`Proxy` 的哈希键是 Symbol，方法名进来是 Symbol，但 `delete_prefix` 之后的操作在 String 上做——所以有 `to_s`/`to_sym` 的往返对齐，这个细节漏了就永远查不到键。

## 15.3 define_method：属性包装器

`define_method` 用块定义方法，块是闭包，能捕获循环变量——`def` 做不到（15.5 有对照实验）：

```ruby
wrapper = Class.new do
  def initialize(attrs) = @attrs = attrs
  %i[name price].each do |key|
    define_method(key) { @attrs[key] }            # 读
    define_method("#{key}=") { |v| @attrs[key] = v }   # 写
  end
end
```

实测输出：

```text
define_method 循环生成 name/price 读写器：price = 120
```

两轮循环生成 `name`/`name=`、`price`/`price=` 四个方法，每个闭包各捕各的 `key`（14.4 已详述绑定规则）。这是 ActiveRecord 式「字段驱动方法生成」的原始形态。注意 `define_method` 的块内**不能用 return**（它不是 lambda，return 会离开定义上下文），需要提前退出就用条件表达式写。

## 15.4 实例变量的内省

对象内部对调试器和序列化工具是开放的：

```ruby
holder = Object.new
holder.instance_variable_set(:@secret, 42)
ok holder.instance_variable_get(:@secret) == 42
ok holder.instance_variables == [:@secret]
ok holder.instance_variable_defined?(:@secret)
```

实测输出：

```text
instance_variables = [:@secret]，@secret = 42
```

四个 API 构成最小内省集：`instance_variable_get/set`（读写）、`instance_variables`（枚举）、`instance_variable_defined?`（探测）。变量名必须带 `@` 前缀（`:secret` 会抛 `NameError`，不是返回 nil）。这套 API 是序列化器、调试器、对象检查器的地基；**业务代码请走公开读写器**——绕过封装读 `@secret`，类的演进（改名、拆字段）会直接砸在你脸上。

## 15.5 instance_eval / class_eval

`instance_eval` 把块的 `self` 换成指定对象，让外部代码「像在对象内部一样」执行：

```ruby
box = Struct.new(:value).new(7)
r = box.instance_eval { value * 6 }   # 块内 self = box，可像在对象内部一样写代码
ok r == 42 && box.value == 7
```

`class_eval` 在已有类上批量开方法。示例里有一组关键对照实验：

```ruby
outer = "外层捕获"
c2 = Class.new
c2.class_eval do
  define_method(:by_define) { outer }   # 闭包：能拿到 outer
end
c2.class_eval do
  def by_def = outer                    # def 开新作用域：outer 在这里变成方法调用，调用时抛 NameError
end
```

实测输出：

```text
box.instance_eval { value * 6 } = 42（对象上下文 DSL 的基石）
def 看不见块变量：调用 by_def 抛 NameError
class_eval 字符串批量定义 pick_0/pick_1 成功
```

**`def` 开新作用域，看不见外层块变量**——`def by_def = outer` 里的 `outer` 不再是那个局部变量，而是一次方法调用，运行时抛 `NameError`。这是元编程里最高频的认知坑：块里写 `define_method` 有闭包，写 `def` 就断线。`class_eval` 还能收字符串（`class_eval("def pick_#{i} = ...")`）一次性生成一串方法——字符串版本更强但也更危险（插值内容直接当代码执行，外部输入禁入）。

## 15.6 eval 与 binding

`eval` 在当前作用域求值字符串；`binding` 是「此刻作用域的快照」，能让 `eval` 在别处还原这个作用域：

```ruby
x = 10
ok eval("x * 3") == 30                        # eval 在当前作用域求值字符串
b = binding                                   # binding = 此刻作用域的快照
ok eval("x + 1", b) == 11                     # 带上 binding 就能在别处还原这个作用域
```

实测输出：

```text
eval 只能求值可信输入（一行演示即可）：eval("x * 3") = 30
```

示例源码里写明了危险边界：`eval("system('rm -rf ~')")` 这类字符串注入等同自毁——**外部输入永远别进 eval**。生产代码里 eval 的合理用途极少（REPL、模板引擎、irb 本身），多数场景 `send` + 白名单或 `class_eval` 块版本就能覆盖且更可控。`binding` 的日常出场位置是 ERB 模板和 `binding.irb` 断点调试。

## 15.7 微 DSL：settings 块

把前面所有零件装起来，合成一个「块内裸调方法即配置」的 DSL：

```ruby
Config = Class.new do
  def initialize = (@store = {})
  def self.settings(&blk)
    cfg = new
    cfg.instance_eval(&blk)     # 块内裸调 server "..." 时 self 是实例
    cfg
  end
  def method_missing(name, *args)
    if args.size == 1
      @store[name] = args.first       # settings { server "localhost" } → 存键
    else
      super
    end
  end
  # DSL 里所有配置键都是「现场生成」的，一律对外报告可响应
  def respond_to_missing?(name, include_private = false)
    true
  end
  def to_h = @store.dup
end
```

实测输出：

```text
settings { server "localhost"; port 8080 } → {server: "localhost", port: 8080}
```

设计分解：`settings` 用 `instance_eval(&blk)` 让块内 `self` 变成配置实例，于是裸调 `server "localhost"` 就是对实例发消息；实例上没有 `server` 方法，落到 `method_missing`，单参数就存键。这里 `respond_to_missing?` 恒真——因为配置键本来就是「现场生成」的，任何键都合法（与 15.2 的 Proxy 相反，Proxy 的键集是固定的）。注意 `to_h` 返回 `@store.dup`：DSL 对外交副本，防止调用方绕过 DSL 直接改内部状态。

## 15.8 摘方法与方法对象内省

运行时不只能加方法，还能摘：

```ruby
base.send(:remove_method, :legacy)    # remove_method：只摘本类，父类还有就还能找到
child.send(:undef_method, :current)   # undef_method：连父类的也一起封死
```

实测输出：

```text
undef_method 后连继承链一起查无此方法（NoMethodError）
method(:upcase).owner = String，parameters = [[:rest]]（source_location 为 nil，C 方法无源码）
```

`remove_method` 只摘本类定义（父类的实现重新露出）；`undef_method` 把整个继承链一起封死（调用直接 NoMethodError，哪怕父类有）。两者都只能通过 `send` 调——它们是 private 的，这个可见性本身就是警告：摘方法是补丁手段，不是日常工具。

`Method` 对象三件套用于内省：`owner`（定义在哪个类）、`parameters`（参数表，`[[:req, :a], [:opt, :b], [:rest, :rest], [:key, :kw]]` 对应 `def f(a, b = 1, *rest, kw: 2)`）、`source_location`。坑：**C 实现的方法 `source_location` 是 nil**（如 `String#upcase`）——工具代码打印它之前必须判空。

## 15.9 坑位清单

1. **用户输入直接 `send` 等于交出任意方法调用权**：`send("system", ...)` 就是命令执行——外部输入派发必须先过白名单（15.1）。
2. **`respond_to?` 默认不认 private 方法**：`respond_to?(:secret_m)` 为 false 但方法存在——要探测 private 传第二参数 `true`（15.1）。
3. **覆写 `method_missing` 不同时覆写 `respond_to_missing?`**：能调却报告「无此方法」，依赖 `respond_to?` 的库全部失灵——两者成对出现（15.2、15.7）。
4. **`method_missing` 不认识的分支忘了 `super`**：拼写错误被吞成 nil，NoMethodError 永远不抛——链尾必须 super（15.2）。
5. **method_missing 代理每次调用都走完整方法查找失败流程**：热路径被拖慢——高频调用应在其上定义实体方法（`class_eval` 批量生成）或改用 Struct（16.6 实测倍数）（15.2、15.7）。
6. **`def` 开新作用域，看不见外层块变量**：`class_eval { def f = outer }` 里的 outer 变成方法调用，运行时抛 `NameError`——需要闭包就用 `define_method`（15.5）。
7. **`instance_variable_get` 的名字必须带 `@`**：传 `:secret` 抛 `NameError` 而不是返回 nil（15.4）。
8. **`class_eval` 字符串版本把插值当代码执行**：外部输入进插值就是代码注入——动态定义优先用块 + `define_method`（15.5）。
9. **`eval` 对外部输入等同自毁**：`eval("system('rm -rf ~')")` 不是段子——eval 只吃可信输入（15.6）。
10. **`undef_method` 连父类实现一起封死**：只是想「本类不再提供」就用 `remove_method`，用错会把继承来的能力一起炸掉（15.8）。
11. **C 方法 `source_location` 是 nil**：打印前不判空，工具代码对内建方法直接崩（15.8）。
12. **DSL 对外要交副本**：`to_h` 不 `dup`，调用方改了返回值就绕过了整个 DSL 的写入路径（15.7）。

---

[上一章](14-blocks.md) | [下一章](16-performance.md)
