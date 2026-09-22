# 07 · 模块（Module）：mixin、extend/prepend 与命名空间

> 对应示例：`examples/07_modules/`

Ruby 没有「多继承」，但有比多继承更可控的工具：模块（Module）。`include` 把实例方法混进查找链，`extend` 混进单例类，`prepend` 直接插到类前面。这章的主线只有一条——**方法查找链（ancestors）决定一切**，看懂了链，三种混入方式的区别就是链上位置的区别。

## 7.1 继承与 super：三种形式要分清

```ruby
class Vehicle
  def initialize(wheels)
    @wheels = wheels
  end
end

class Bike < Vehicle
  def initialize
    super(2)                      # super(带参)：显式传参给父类同名方法
  end
end

class Car < Vehicle
  def initialize(color)
    @color = color
    super(4)                      # 父类 initialize 只要 wheels，多出的字段自己存
  end
end
```

`super` 的三种形式差别全在参数上，是面试重灾区也是日常 bug 重灾区：

| 写法 | 行为 |
|---|---|
| `super`（不带括号） | **原样转发**当前方法的全部参数 |
| `super(2)` | 只把括号里的参数传给父类 |
| `super()` | 一个参数都不传，父类用默认值 |

```text

---- 7.1 继承与 super：三种形式要分清 ----
super：原样转发；super(2)：显式传；super()：不传 —— 参数错了运行期抛 ArgumentError
```

实测于 `build/07.out`。注意 `super()` 不传参不是「安全跳过」：父类 `initialize` 必填参数时，运行期照样抛 `ArgumentError`（示例里 `Tricycle` 就是这么验证的）。还有一条容易忘：`super` 只在子类方法体里调父类**同名**方法，写错了名字不会报「找不到 super」，而是静默不走父类逻辑。

## 7.2 include / mixin 与方法查找链

`include` 把模块插进类的查找链。规则一句话：**类自己的方法永远最优先，模块按 include 的逆序排列，父类殿后**。

```ruby
module Flyable
  def travel = "飞过去"
end
module Wheeled
  def travel = "开过去"
end

class Plane
  include Flyable
  include Wheeled                # 后 include 的排前面
  def travel
    "自家引擎：" + super          # super 沿查找链找下一个 —— 是 Wheeled，不是 Flyable
  end
end
```

```text

---- 7.2 include / mixin 与方法查找链 ----
查找链：[Plane, Wheeled, Flyable, Object] —— 类最先，模块按 include 的逆序，父类殿后
```

两个实测细节值得咀嚼：

1. `Plane.new.travel` 是 `"自家引擎：开过去"`——类方法挡在链头，`super` 找到的是**后 include** 的 `Wheeled`。很多人的直觉是「先 include 的 Flyable 更近」，反了：链是**逆序**压进去的，`ancestors.take(4)` 打出来一目了然。
2. 用 `Plane.class_eval { remove_method :travel }` 把类自己的方法删掉后，`travel` 返回 `"开过去"`；再删 Wheeled 的才会轮到 Flyable。查找链是严格线性的，逐级下探。

## 7.3 extend 与 prepend

`extend` 给**单个对象**混入（方法进它的单例类）；`prepend` 把模块插到类的**前面**，并且能 `super` 回原实现。

```ruby
str = +"现场"                    # + 前缀拿未冻结副本 —— 冻结的字符串连单例类都建不了，extend 会抛 TypeError
str.extend(Announcer)            # 只给这一个对象加方法
str.announce                     # => "【现场】"
"别人".respond_to?(:announce)    # => false，别的字符串不受影响

class Base
  prepend Loud                   # Loud 排在 Base 前面
  def hello = "base"
end
Base.ancestors.take(2)           # => [Loud, Base]
Base.new.hello                   # => "Loud→base"（Loud#hello 里 super 找到 Base#hello）
```

```text

---- 7.3 extend 与 prepend ----
extend：单例混入（【现场】）；prepend：插到类前面还能 super 回原方法（Loud→base）
```

三条实测过的坑：

1. **冻结串不能 extend**：`"abc".freeze.extend(M)` 抛 `TypeError: can't define singleton`（实测于 4.0.7 `-e` 探针）——冻结对象根本建不了单例类。所以示例里先 `+"现场"` 拿可变副本。
2. **include 与 prepend 的链位置相反**：`include M` 后 `[Base, M, ...]`，`prepend M` 后 `[M, Base, ...]`。prepend 模块里写 `super` 找到的是原方法，include 模块里写 `super` 找到的是父类/更早的模块——这就是 prepend 能做「方法包装/日志切面」而 include 做不了的原因。
3. **类体里 `extend M` = 模块方法变类方法**（`Gadget.announce` 直接可调），Rails 的 `ClassMethods` 惯用法全部建立在这条上。

## 7.4 命名空间与 module_function

模块的第一身份是**命名空间**：常量、嵌套模块、方法统统归它管。

```ruby
module Geometry
  PI = 3.14159_26535

  module TwoD
    def self.area(w, h) = w * h
  end

  module_function               # 之后的 def 同时生成模块方法与私有实例方法
  def circle_area(r)
    PI * r * r
  end
end

Geometry::TwoD.area(3, 4)        # => 12
Geometry.circle_area(1)          # => π
```

```text

---- 7.4 命名空间与 module_function ----
Geometry::TwoD.area(3,4)=12；module_function 一份给模块、一份私有给实例
```

`module_function` 生成的是**两份**方法：一份是模块方法（`Geometry.circle_area` 可调），另一份是**私有**实例方法——include 它的类只能无接收者调用（`hi` 合法，`obj.hi` 抛 `NoMethodError`，`respond_to?(:hi)` 是 false）。想要「既能当模块函数又能混入实例方法」且实例方法为 public 的，用 `def self.xxx` + `module_function` 换成 `extend self` 的写法（本教程示例只实测了 `module_function` 路线，`extend self` 见 7.3 的 extend 语义自行推导）。

## 7.5 Comparable：一个 <=> 换全套

只实现 `<=>`，`include Comparable` 后 `< > <= >= == between? min/max/sort/clamp` 全部解锁：

```ruby
class Version
  include Comparable
  attr_reader :parts

  def initialize(str)
    @parts = str.split(".").map(&:to_i)
  end

  def <=>(other)                # 返回 -1/0/1（或 nil 表示不可比）
    parts <=> other.parts
  end

  def to_s = parts.join(".")    # 不写 to_s，puts/插值会打出对象 id
end
```

```text

---- 7.5 Comparable：一个 <=> 换全套 ----
<=> 一到手：< > <= >= == between? min/max/sort/clamp 全部生效（1.9.0 < 1.10.0）
```

`"1.9.0" < "1.10.0"` 按字典序是假的，`Version` 把字符串拆成整数数组交给 `<=>` 逐位比，`9 < 10` 才成立——这是 Comparable 的典型用法：**把业务比较归约到已有类型的 `<=>` 上**。别忘了 `to_s`：不覆写，插值和 puts 打出来的是 `#<Version:0x...>` 这种对象表示。

## 7.6 方法冲突：后 include 的模块赢

```ruby
module Chinese
  def greeting = "你好"
end
module English
  def greeting = "hello"
end

class Bilingual1
  include Chinese
  include English
end

Bilingual1.new.greeting          # => "hello"
Bilingual2.new.greeting          # => "你好"（include 顺序反过来结果也反过来）
```

```text

---- 7.6 方法冲突：后 include 的模块赢 ----
include Chinese + English：hello（后者优先）；重复 include 不产生副本
```

查找链 `[Bilingual1, English, Chinese, Object]` 决定了「后 include 者优先」。另有一条安静的好性质：**include 同一模块两次，链不变、不重复**（`Twice.ancestors.count(Chinese) == 1`）——所以库代码里可以放心地重复声明依赖。冲突本身是设计味道：两个模块定义了同名方法又在同一个类里 include，说明职责该拆；真要共存，用 7.3 的 prepend 显式分层。

## 7.7 to_s：插值与 puts 的幕后功臣

```ruby
class Color
  def to_s                      # to_s 管「给人看」：插值、puts 都调它
    "RGB(#{r},#{g},#{b})"
  end

  def inspect                   # inspect 管「给机器看」：p、容器打印用它的
    "#<Color #{self}>"
  end
end

red = Color.new(255, 0, 0)
"颜色是 #{red}"                   # => "颜色是 RGB(255,0,0)"   （插值走 to_s）
[red].to_s                        # => "[#<Color RGB(255,0,0)>]"（容器打印走 inspect）
```

```text

---- 7.7 to_s：插值与 puts 的幕后功臣 ----
插值：RGB(255,0,0)；数组形式：[#<Color RGB(255,0,0)>]
```

分工记法与 julia 教程一脉相承：**to_s 给人看，inspect 给机器看**。字符串插值 `#{red}`、`puts red` 走 `to_s`；`p red`、`[red]` 整体打印、REPL 回显走 `inspect`。两个都不定义时是 Object 的默认实现（类名 + 对象 id），调试信息基本不可读——认真写的类至少给 `inspect` 留个自定义版本。

## 7.8 坑位清单

1. **`super`、`super()`、`super(x)` 三义**：不带括号是「原样转发全部参数」，空括号才是「一个都不传」——父类必填参数时 `super()` 运行期抛 `ArgumentError`（7.1）。
2. **include 逆序压链**：后 include 的模块排在查找链前面，同名方法「后 include 者赢」——依赖顺序的 mixin 是隐形地雷（7.2、7.6）。
3. **类自己的方法永远挡在链头**：模块方法被类方法遮蔽时，`super` 不会绕过它，只会沿链找到下一个模块（7.2）。
4. **模块不能实例化**：`M.new` 抛 `NoMethodError: undefined method 'new' for module M`（实测于 4.0.7 探针）；别跟 `Module.new`（创建匿名模块）混淆（7.2）。
5. **冻结串不能 extend**：`"abc".freeze.extend(M)` 抛 `TypeError: can't define singleton`——先 `+str` 拿可变副本再 extend（7.3）。
6. **include 与 prepend 的链位置相反**：`prepend` 才能包装原方法（`super` 回原实现），include 模块里的 `super` 找到的是链上更后面的东西（7.3）。
7. **类体里 `extend M` 让模块方法变类方法**：忘了这条会把「单例混入」误当「实例混入」排查半天（7.3）。
8. **`module_function` 的实例副本是私有的**：include 后 `obj.hi` 抛 `NoMethodError`，只有无接收者调用合法（7.4）。
9. **Comparable 只给 `<=>` 发工资**：不实现 `<=>`，比较运算符全是 `NoMethodError`；`<=>` 可返回 `nil` 表示不可比（7.5）。
10. **自定义类不覆写 `to_s`/`inspect` 就打印对象 id**：插值走 `to_s`、容器打印走 `inspect`，两套别混（7.7）。
11. **重复 include 同一模块不产生副本**：链上只有一份，不必担心「include 两次冲突」（7.6）。

---

**上一章**：[06 · 类与对象](../06-classes.md) | **下一章**：[08 · 字符串](08-strings.md)
