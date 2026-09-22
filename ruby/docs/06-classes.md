# 06 · 类与对象

> 对应示例：`examples/06_classes/`

Ruby 的类没有魔法：`attr_accessor` 是宏、`private` 只是「不许带显式接收者」、`Struct`/`Data` 是两条现成的记录类型捷径。本章主线：**一切字段访问都是方法调用**——`@name` 私有、`d.name` 走 reader、`b.title = x` 走 writer，看懂这一层，可见性与相等性规则就都顺了。

## 6.1 最小类：class、initialize、@、new

```ruby
class Dog
  def initialize(name)          # new 时被自动调用，负责初始化
    @name = name                # @ 开头是实例变量，只属于这一个对象
  end

  def bark                      # 实例方法：由对象调用
    "#{@name}：汪！"
  end
end
d = Dog.new("旺财")
ok d.bark == "旺财：汪！"
```

```text
---- 6.1 最小类：class、initialize、@、new ----
旺财：汪！
```

`Dog.new("旺财")` 做两件事：分配对象 → 调 `initialize`（实例变量 `@name` 在这里挂到这一个对象上）。要点：**没有字段声明**——实例变量首次赋值时才存在；**没有构造器重载**——就一个 `initialize`，可选参数/关键字参数当重载用；`new` 可反复调，各是独立对象。

## 6.2 attr_accessor / reader / writer

```ruby
class Book
  attr_accessor :title          # 同时生成 title 和 title=
  attr_reader :pages            # 只读：生成 pages，不生成 pages=
  attr_writer :isbn             # 只写：只生成 isbn=

  def initialize(title, pages)
    @title = title
    @pages = pages
  end
end
b.title = "Ruby 进阶"           # title= 是普通方法，= 结尾赋值写法是语法糖
begin; b.pages = 400; rescue NoMethodError; raised = true; end
```

```text
---- 6.2 attr_accessor / reader / writer ----
attr_* 只是「定义一对读写方法」的宏；pages= 已被 reader 拦下（NoMethodError）
```

`attr_*` 不是字段声明，是**定义方法的宏**：`attr_accessor :title` 生成 `title` 与 `title=` 两个方法，赋值号写法只是语法糖。所以「只读属性」就是 `attr_reader`——外界 `b.pages = 400` 抛 `NoMethodError`（方法压根不存在），值仍然安全地躺在 `@pages` 里（需要时 `instance_variable_get` 可取）。

## 6.3 self 的两种身份：类方法定义者与当前接收者

```ruby
class Counter
  @@total = 0                   # 类变量（比实例变量更「全局」，慎用，这里只作演示）
  def self.total                # 类体中 def self.x —— 定义类方法
    @@total
  end

  def bump
    @n += 1
    self                        # 方法体内 self = 当前接收者；返回 self 支持链式调用
  end
end
Counter.new.bump.bump          # bump 返回 self，所以能一直点下去
ok c.bump.equal?(c)            # self 就是接收者本人
```

```text
---- 6.3 self 的两种身份：类方法定义者与当前接收者 ----
def self.total 定义类方法（总数=3）；方法内 self 指接收者，bump 返回 self 可链式调用
```

`self` 在类体里指**类本身**——`def self.total` 定义的就是类方法（`Counter.total`）；在方法体内指**当前接收者**——`bump` 返回 `self` 是链式调用（Rails 风格）的根源，`c.bump.equal?(c)` 证明返回的就是接收者本人。顺带认识 `@@total` 类变量：所有实例共享，作用域却比想象中更全局（会被子类共享篡改），实际代码里**慎用**，类状态多用「类实例变量 + 类方法」承载（15 章展开）。

## 6.4 可见性：private 不能带显式接收者，protected 限「同类实例之间」

```ruby
class Account
  def withdraw(n)
    check(n)                    # private 方法只能「无显式接收者」调用
    @balance -= n
  end

  def rich?(other)
    balance > other.balance     # protected 方法允许「同类其他实例」作接收者
  end

  protected def balance_check = "protected"
  private def check(n)
    raise ArgumentError, "透支" if n > @balance
  end
end
begin; a1.helper; rescue NoMethodError; raised = true; end
```

```text
---- 6.4 可见性：private 不能带显式接收者，protected 限「同类实例之间」 ----
private：外部访问抛 NoMethodError；protected：同类实例间可互访（rich? 里 other.balance 合法）
```

三种可见性的实用差别：`private` 方法**不能带显式接收者调用**（连 `self.check(n)` 都不行——2.7 起仅当接收者恰为 `self` 才放行，但惯例是无接收者）；`protected` 允许**同类其他实例**作接收者（`rich?` 里比较 `other.balance` 必须用它，`private` 做不到）；`public` 默认。写法上 `private def check ... end` 单行修饰或独立一行 `private`（之后的方法全私有直到再写 `public`）都行。外部调私有方法抛 `NoMethodError`——它对 `respond_to?` 也不可见（`respond_to?(:helper) == false`）。

## 6.5 Struct vs Data：Struct 可变，Data（3.2+）不可变值对象

```ruby
Measure = Struct.new(:x, :y)                 # Struct：带名元组，字段可写
m1.x = 10                                    # Struct 默认可变
ok m1 == Measure.new(10, 2)                  # 按值比较，不是按引用

Point = Data.define(:x, :y)                  # Data：不可变，new 出来即 frozen
ok p1.frozen? && p1 == Point.new(1, 2)       # 相同字段即相等 —— 天然适合做 Hash 键
p2 = p1.with(x: 10)                          # 「修改」其实是生成新对象
ok p1.deconstruct == [1, 2] && p1.deconstruct_keys(nil) == { x: 1, y: 2 }
begin; p1.x = 5; rescue NoMethodError; raised = true; end
label = case p1
        in Point(x: 1, y:) then "原点右侧，y=#{y}"    # case/in 可直接解构 Data
        in Point then "别的点"
        end
```

```text
---- 6.5 Struct vs Data：Struct 可变，Data（3.2+）不可变值对象 ----
Struct：#<struct Measure x=10, y=2>（可变，== 按字段值比较）
Data：#<data Point x=1, y=2>（frozen），with(x: 10) 产出 #<data Point x=10, y=2>，原对象不动
```

两条记录类型捷径，选型口诀：**要改字段用 Struct，值语义/做哈希键/进模式匹配用 Data**。`Struct` 可变、按字段值比较相等；`Data`（3.2+）`new` 出来即 `frozen?`，「修改」是 `with(x: 10)` 产出新对象、原对象不动，字段写方法不存在（`p1.x = 5` 抛 `NoMethodError`）。`Data` 实现了 `deconstruct`/`deconstruct_keys` 协议，所以 `case/in` 能直接解构 `Point(x: 1, y:)`（`y:` 无值形式叫空捕获，直接绑定变量 `y`）。注意 `Data` **没有 `to_a`**（4.0.7 实测 `respond_to?(:to_a) == false`），要数组用 `deconstruct`。

## 6.6 相等性三件套：== / eql? / hash 与 Hash 键

```ruby
class Money
  attr_reader :cents
  def ==(other)                             # == 语义最宽：值相等即可
    other.is_a?(Money) && cents == other.cents
  end
  alias eql? ==                             # Hash 用 eql? 判键
  def hash                                  # eql? 相等必须给同一 hash 值
    [Money, cents].hash
  end
end
wallet = { m_a => "一百块" }
ok wallet[m_b] == "一百块"                   # 换一个「值相等」的对象照样命中
ok 1 == 1.0 && !1.eql?(1.0)
```

```text
---- 6.6 相等性三件套：== / eql? / hash 与 Hash 键 ----
== 管相等，eql?+hash 管做 Hash 键；1 == 1.0 为真但 eql? 为假（连类型一起比）
```

三层相等分工：`==` 语义最宽（值等即可）；**Hash 用 `eql?` 判键**（还连类型一起比——`1 == 1.0` 为真，`1.eql?(1.0)` 为假，所以 **`1` 与 `1.0` 不是同一个 Hash 键**）；`hash` 方法给散列值，**铁律是 `eql?` 相等的两个对象必须返回同一 `hash` 值**（否则值相等的键在哈希表里各找各的桶，查不到）。自定义类想做键，三件套一起写，模板就是上面的 `Money`。

## 6.7 dup vs clone

```ruby
bot = Robot.new
def bot.greet = "哔哔"                       # 单例方法：只挂在 bot 这一个对象上
ok !bot.dup.respond_to?(:greet)              # dup 不复制单例方法
ok bot.clone.respond_to?(:greet)             # clone 连 singleton 类一起复制
frozen_tag = "徽章".freeze
ok !frozen_tag.dup.frozen?                   # dup 给「未冻结」副本
ok frozen_tag.clone.frozen?                  # clone 保留 frozen 状态
mutable = +"固定开头"
mutable << "-可变尾巴"
```

```text
---- 6.7 dup vs clone ----
dup：普通副本；clone：连 frozen / 单例方法一起带走
```

`dup` 与 `clone` 都复制对象，差别两张表：**frozen 状态**——`dup` 给未冻结副本（所以 `frozen_str.dup << "x"` 合法，是解冻惯用法），`clone` 原样保留；**单例方法**——`clone` 连 singleton 类一起带走，`dup` 不带。另外冻结对象不能 `extend`（`"abc".freeze.extend(M)` 抛 `TypeError: can't define singleton`，07 章有详说）——先 `+str` 拿可变副本。`+"abc"` 与 `.dup` 在 frozen_string_literal 时代都是「要个能改的」的标准答案。

## 6.8 内省：运行时看看对象是什么、有什么

```ruby
cat = Cat.new("咪咪")
ok cat.class == Cat
ok Cat.ancestors.take(3) == [Cat, Animal, Object]   # 方法查找链
ok cat.is_a?(Animal) && !cat.is_a?(Dog)
ok cat.instance_variables == [:@name]
ok cat.public_send(:meow) == "咪咪：喵"
ok Cat.instance_method(:meow).owner == Cat   # 方法挂在谁身上
```

```text
---- 6.8 内省：运行时看看对象是什么、有什么 ----
class=Cat，ancestors=[Cat, Animal, Object]，ivars=[:@name]
```

Ruby 的运行时全开放：`class` 看类、`ancestors` 看方法查找链（07 章的主角）、`is_a?` 判归属、`instance_variables` 列实例变量、`respond_to?`/`methods` 查能力、`public_send` 无视私有地安全调用、`instance_method(:m).owner` 查方法定义在链上哪一环。调试与元编程（15 章）都靠这套内省 API 打底。

## 6.9 坑位清单

1. **`1` 与 `1.0` 不是同一 Hash 键**：`1 == 1.0` 为真但 `1.eql?(1.0)` 为假，Hash 按 eql? 判键——混型键值表里查不到（6.6）。
2. **`Data` 无 `to_a`**（4.0.7 实测）：转数组用 `deconstruct`，转哈希用 `deconstruct_keys(nil)`；`Struct` 才有 `to_a`（6.5）。
3. **冻结串不能 `extend`**：`"abc".freeze.extend(M)` 抛 `TypeError: can't define singleton`——先 `+str` 或 `.dup` 再 extend（6.7/07 章）。
4. **`dup` 不复制单例方法与 frozen，`clone` 都复制**：解冻惯用法是 `frozen_str.dup`；想保留单例类只能 `clone`（6.7）。
5. **`private` 方法不能带显式接收者调用**：连 `self.check(n)` 都受限（2.7 起仅接收者恰为 self 放行）；惯例无接收者（6.4）。
6. **`protected` 的唯一典型场景**：同类实例间互比字段（`other.balance`）；想用 `private` 实现它，直接 `NoMethodError`（6.4）。
7. **`attr_*` 不生成实例变量也不做校验**：它只定义方法；`@pages` 不赋值 reader 返回 `nil` 而不是报错（6.2）。
8. **Data 是 frozen 的，「修改」必须 `with`**：`p1.x = 5` 抛 `NoMethodError`；`with` 产出新对象、原对象不动（6.5）。
9. **自定义 Hash 键要三件套齐写**：只写 `==` 不写 `eql?`/`hash`，值相等的对象查不到同一个键；`eql?` 相等必须同 `hash` 值（6.6）。
10. **`@@` 类变量被整个继承树共享**：子类读写会污染父类状态；类状态优先用类实例变量（6.3/15 章）。
11. **`new` 与 `initialize` 是两步**：`initialize` 的返回值被丢弃，`new` 返回的是新分配的对象——想在「构造」里返回别的类型要走 `self.new` 的自定义类方法（6.1）。
12. **`instance_variables` 只列已赋值的**：类里「声明」过的名字不会出现（Ruby 根本没有声明），没赋值的 `@x` 读取返回 `nil`（6.8/6.1）。

---

**上一章**：[05 · 方法](05-methods.md) | **下一章**：[07 · 模块](07-modules.md)
