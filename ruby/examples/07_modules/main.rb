# 07 继承与模块：super、include 查找链、extend/prepend、命名空间、Comparable、冲突、to_s
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 7.1 继承与 super：super / super() / super 带参
sec("7.1 继承与 super：三种形式要分清")
class Vehicle
  attr_reader :wheels

  def initialize(wheels)
    @wheels = wheels
  end

  def describe(extra = "")
    "#{wheels} 个轮子#{extra}"
  end
end
class Bike < Vehicle
  def initialize
    super(2)                      # super(带参)：显式传参给父类同名方法
  end

  def describe
    super("，是自行车")            # super（不带括号）：原样转发当前方法的全部参数
  end
end
class Car < Vehicle
  def initialize(color)
    @color = color
    super(4)                      # 父类 initialize 只要 wheels，多出的字段自己存
  end

  def color = @color
end
ok Bike.new.describe == "2 个轮子，是自行车"
ok Car.new("红").wheels == 4 && Car.new("红").color == "红"
# super()（空括号）：一个参数都不传 —— 父类用默认值
class Tricycle < Vehicle
  def initialize
    @note = "三轮"
    super()                       # 不传参 → 父类收到 wheels=nil？不，这里父类必填，会抛错
  end
end
raised = false
begin; Tricycle.new; rescue ArgumentError; raised = true; end
ok raised, "super() 不传参而父类必填参数时应抛 ArgumentError"
ok Vehicle.new(18).describe == "18 个轮子"
puts "super：原样转发；super(2)：显式传；super()：不传 —— 参数错了运行期抛 ArgumentError"

# ═══ 7.2 include 与 ancestors：查找顺序 = 类 → 逆序 include 的模块 → 父类
sec("7.2 include / mixin 与方法查找链")
module Flyable
  def travel = "飞过去"
end
module Wheeled
  def travel = "开过去"
end
class Plane
  include Flyable
  include Wheeled                # 后 include 的排前面
  def travel                     # 类自己的方法永远最优先
    "自家引擎：" + super          # super 沿查找链找下一个 Flyable？不 —— 是 Wheeled
  end
end
ok Plane.ancestors.take(4) == [Plane, Wheeled, Flyable, Object]
ok Plane.new.travel == "自家引擎：开过去"       # 类 → 后 include 的 Wheeled
# 把类方法删掉，super 会继续沿链找到 Flyable
Plane.class_eval { remove_method :travel }
ok Plane.new.travel == "开过去"
puts "查找链：#{Plane.ancestors.take(4).inspect} —— 类最先，模块按 include 的逆序，父类殿后"

# ═══ 7.3 extend（单例类混入）与 prepend（插到接收者前面）
sec("7.3 extend 与 prepend")
module Announcer
  def announce = "【#{self}】"
end
ok String.include?(Announcer) == false
str = +"现场"                    # + 前缀拿未冻结副本 —— 冻结的字符串连单例类都建不了，extend 会抛 TypeError
str.extend(Announcer)            # 只给这一个对象加方法（混入其单例类）
ok str.announce == "【现场】"
ok "别人".respond_to?(:announce) == false
# extend 也常用于「模块当命名空间 + extend self」，或类级别 extend ClassMethods
class Gadget
  extend Announcer               # extend 在类体里：模块方法变成类方法
end
ok Gadget.announce == "【Gadget】"

module Loud
  def hello
    "Loud→" + super              # prepend 的模块排在类前面，super 找到的就是原方法
  end
end
class Base
  prepend Loud
  def hello = "base"
end
ok Base.ancestors.take(2) == [Loud, Base]
ok Base.new.hello == "Loud→base" # prepend 模块可以 super 回原实现 —— 这是它相对 include 的关键区别
puts "extend：单例混入（#{str.announce}）；prepend：插到类前面还能 super 回原方法（#{Base.new.hello}）"

# ═══ 7.4 模块做命名空间与 module_function
sec("7.4 命名空间与 module_function")
module Geometry
  PI = 3.14159_26535            # 常量也归命名空间管

  module TwoD                   # 模块可以嵌套，形成层级
    def self.area(w, h) = w * h
  end

  module_function               # 之后的 def 同时生成模块方法与私有实例方法
  def circle_area(r)
    PI * r * r
  end
end
ok Geometry::TwoD.area(3, 4) == 12
ok (Geometry::PI - Math::PI).abs < 1e-5
ok (Geometry.circle_area(1) - Math::PI).abs < 1e-5
ok Geometry.respond_to?(:circle_area)
# module_function 的实例副本是私有的：include 它的类不能用接收者形式调
module Greets
  module_function
  def hi = "你好"
end
class UsesGreets
  include Greets
  def call_hi = hi              # 无接收者调用：合法
end
ok UsesGreets.new.call_hi == "你好"
ok Greets.private_instance_methods.include?(:hi)   # 实例副本存在但私有
ok UsesGreets.new.respond_to?(:hi) == false        # respond_to? 默认只查 public，对外不可见
puts "Geometry::TwoD.area(3,4)=#{Geometry::TwoD.area(3, 4)}；module_function 一份给模块、一份私有给实例"

# ═══ 7.5 Comparable：<=> 换来全套比较运算符
sec("7.5 Comparable：一个 <=> 换全套")
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
v1 = Version.new("1.9.0")
v2 = Version.new("1.10.0")
ok v1 < v2 && v2 > v1            # 数组 <=> 按元素逐位比，9 < 10
ok v1 <= v2 && v1 >= Version.new("1.9.0")
ok v1 == Version.new("1.9.0")
ok v1.between?(Version.new("1.0"), v2)
ok [v2, v1, Version.new("2.0")].min == v1
ok [v2, v1, Version.new("2.0")].sort.last.parts == [2, 0]
ok v1.clamp(Version.new("1.5"), Version.new("1.8")) == Version.new("1.8")
puts "<=> 一到手：< > <= >= == between? min/max/sort/clamp 全部生效（#{v1} < #{v2}）"

# ═══ 7.6 模块方法冲突：后 include 者优先
sec("7.6 方法冲突：后 include 的模块赢")
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
class Bilingual2
  include English
  include Chinese
end
ok Bilingual1.new.greeting == "hello"   # English 后 include，查找链更靠前
ok Bilingual2.new.greeting == "你好"    # 顺序反过来结果也反过来
ok Bilingual1.ancestors.index(English) < Bilingual1.ancestors.index(Chinese)
# include 同一模块两次不会改变链，也不会重复
class Twice
  include Chinese
  include Chinese
end
ok Twice.ancestors.count(Chinese) == 1
puts "include Chinese + English：#{Bilingual1.new.greeting}（后者优先）；重复 include 不产生副本"

# ═══ 7.7 实用协议：实现 to_s 影响插值与 puts
sec("7.7 to_s：插值与 puts 的幕后功臣")
class Color
  attr_reader :r, :g, :b

  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end

  def to_s                      # to_s 管「给人看」：插值、puts 都调它
    "RGB(#{r},#{g},#{b})"
  end

  def inspect                   # inspect 管「给机器看」：p、数组打印用它的
    "#<Color #{self}>"
  end
end
red = Color.new(255, 0, 0)
ok "颜色是 #{red}" == "颜色是 RGB(255,0,0)"    # 插值走 to_s
ok "颜色是 " + red.to_s == "颜色是 RGB(255,0,0)"
ok red.inspect == "#<Color RGB(255,0,0)>"
ok [red].to_s == "[#<Color RGB(255,0,0)>]"     # 容器打印走 inspect
puts "插值：#{red}；数组形式：#{[red]}"
# 没定义 to_s 时默认走 Object#to_s（含类名与 id 的形式）—— 覆写它才有可读输出

puts
puts("==== 07 结束 ====")
