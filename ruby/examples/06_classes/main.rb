# 06 类与对象：class/new/initialize、attr 族、self、可见性、Struct/Data、相等性、dup/clone、内省
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 6.1 最小类：class / initialize / @实例变量 / new
sec("6.1 最小类：class、initialize、@、new")
class Dog
  def initialize(name)          # new 时被自动调用，负责初始化
    @name = name                # @ 开头是实例变量，只属于这一个对象
  end

  def bark                      # 实例方法：由对象调用
    "#{@name}：汪！"
  end
end
d = Dog.new("旺财")             # 分配对象 → 调 initialize
ok d.is_a?(Dog) && d.bark == "旺财：汪！"
puts d.bark
ok Dog.new("小黑").bark == "小黑：汪！"   # new 可多次调用，各是独立对象

# ═══ 6.2 attr_accessor / attr_reader / attr_writer
sec("6.2 attr_accessor / reader / writer")
class Book
  attr_accessor :title          # 同时生成 title 和 title=
  attr_reader :pages            # 只读：生成 pages，不生成 pages=
  attr_writer :isbn             # 只写：只生成 isbn=

  def initialize(title, pages)
    @title = title
    @pages = pages
  end
end
b = Book.new("Ruby 入门", 300)
ok b.title == "Ruby 入门" && b.pages == 300
b.title = "Ruby 进阶"           # title= 是普通方法，= 结尾赋值写法是语法糖
ok b.title == "Ruby 进阶"
b.isbn = "978-7-000"
ok b.instance_variable_get(:@isbn) == "978-7-000"   # 只写属性：读不到 reader，但值在
raised = false
begin; b.pages = 400; rescue NoMethodError; raised = true; end
ok raised, "attr_reader 不应生成 pages="
puts "attr_* 只是「定义一对读写方法」的宏；pages= 已被 reader 拦下（NoMethodError）"

# ═══ 6.3 self 的两种身份：类体中定义类方法、方法内指接收者
sec("6.3 self 的两种身份：类方法定义者与当前接收者")
class Counter
  @@total = 0                   # 类变量（比实例变量更「全局」，慎用，这里只作演示）
  attr_reader :n

  def initialize
    @n = 0
    @@total += 1
  end

  def self.total                # 类体中 def self.x —— 定义类方法（等价 Counter.total）
    @@total
  end

  def bump
    @n += 1
    self                        # 方法体内 self = 当前接收者；返回 self 支持链式调用
  end

  def describe
    "n=#{@n}，class=#{self.class}"   # self.class：向当前接收者要它的类
  end
end
Counter.new.bump.bump          # bump 返回 self，所以能一直点下去
ok Counter.new.bump.n == 1
ok Counter.total == 2          # 上面一共 new 了 2 次
c = Counter.new
ok c.describe == "n=0，class=Counter"
ok c.bump.equal?(c)            # self 就是接收者本人
puts "def self.total 定义类方法（总数=#{Counter.total}）；方法内 self 指接收者，bump 返回 self 可链式调用"

# ═══ 6.4 可见性：private / public / protected
sec("6.4 可见性：private 不能带显式接收者，protected 限「同类实例之间」")
class Account
  attr_reader :balance

  def initialize(amount)
    @balance = amount
  end

  def withdraw(n)
    check(n)                    # private 方法只能在「无显式接收者」的形式下调用
    @balance -= n
    "取走 #{n}，剩 #{@balance}"
  end

  def rich?(other)
    balance > other.balance     # protected 方法允许「同类其他实例」作接收者
  end

  protected def balance_check = "protected"

  private def check(n)          # 默认 public；private 之后的方法都私有（直到再写 public）
    raise ArgumentError, "透支" if n > @balance
  end

  private def helper = "hidden" # private + def 单行/常规写法效果一样，同样私有
end
a1 = Account.new(100)
ok a1.withdraw(30) == "取走 30，剩 70"
ok a1.rich?(Account.new(10))
raised = false
begin; a1.helper; rescue NoMethodError; raised = true; end
ok raised, "private 方法对外调用应抛 NoMethodError"
# 类内用 self.helper 的显式接收者形式调 private：2.7 起仅当接收者恰为 self 才放行
ok a1.respond_to?(:helper) == false
# protected：同类实例间可互调，外部依旧不行
ok Account.new(5).respond_to?(:balance_check) == false
puts "private：外部访问抛 NoMethodError；protected：同类实例间可互访（rich? 里 other.balance 合法）"

# ═══ 6.5 Struct vs Data：可变记录 vs 不可变值对象
sec("6.5 Struct vs Data：Struct 可变，Data（3.2+）不可变值对象")
Measure = Struct.new(:x, :y)                 # Struct：带名元组，字段可写
m1 = Measure.new(1, 2)
ok m1.x == 1 && m1.y == 2 && m1.to_a == [1, 2]
m1.x = 10                                    # Struct 默认可变
ok m1.x == 10 && m1 == Measure.new(10, 2)    # 按值比较，不是按引用
ok Measure.members == %i[x y]
puts "Struct：#{m1.inspect}（可变，== 按字段值比较）"

Point = Data.define(:x, :y)                  # Data：不可变，new 出来即 frozen
p1 = Point.new(1, 2)
ok p1.frozen? && p1 == Point.new(1, 2)       # 相同字段即相等 —— 天然适合做 Hash 键
p2 = p1.with(x: 10)                          # 「修改」其实是生成新对象
ok p2.x == 10 && p2.y == 2 && !p2.equal?(p1) && p1.x == 1
ok p1.deconstruct == [1, 2] && p1.deconstruct_keys(nil) == { x: 1, y: 2 }
raised = false
begin; p1.x = 5; rescue NoMethodError; raised = true; end
ok raised, "Data 字段不可写，应抛 NoMethodError"
# case/in 可直接解构 Data（deconstruct/deconstruct_keys 是协议方法）
label = case p1
        in Point(x: 1, y:) then "原点右侧，y=#{y}"
        in Point then "别的点"
        end
ok label == "原点右侧，y=2"
puts "Data：#{p1.inspect}（frozen），with(x: 10) 产出 #{p2.inspect}，原对象不动"

# ═══ 6.6 相等性三件套：== / eql? / hash 与作为 Hash 键
sec("6.6 相等性三件套：== / eql? / hash 与 Hash 键")
class Money
  attr_reader :cents

  def initialize(cents)
    @cents = cents
  end

  def ==(other)                             # == 语义最宽：值相等即可
    other.is_a?(Money) && cents == other.cents
  end
  alias eql? ==                             # Hash 用 eql? 判键 —— 想做键就得让 eql? 与 == 一致

  def hash                                  # eql? 相等的两个对象必须给同一个 hash 值
    [Money, cents].hash
  end
end
m_a = Money.new(100)
m_b = Money.new(100)
ok m_a == m_b && m_a.eql?(m_b) && m_a.hash == m_b.hash
wallet = { m_a => "一百块" }
ok wallet[m_b] == "一百块"                   # 换一个「值相等」的对象照样命中
# 标准库里的差异示例：1 == 1.0 为真，但 1.eql?(1.0) 为假（eql? 连类型一起比）
ok 1 == 1.0 && !1.eql?(1.0)
puts "== 管相等，eql?+hash 管做 Hash 键；1 == 1.0 为真但 eql? 为假（连类型一起比）"

# ═══ 6.7 dup vs clone：clone 保留 frozen / singleton 状态
sec("6.7 dup vs clone")
class Robot; end
bot = Robot.new
def bot.greet = "哔哔"                       # 单例方法：只挂在 bot 这一个对象上
ok bot.greet == "哔哔"
ok !bot.dup.respond_to?(:greet)              # dup 不复制单例方法
ok bot.clone.respond_to?(:greet)             # clone 连 singleton 类一起复制
frozen_tag = "徽章".freeze
ok !frozen_tag.dup.frozen?                   # dup 给「未冻结」副本
ok frozen_tag.clone.frozen?                  # clone 保留 frozen 状态
# frozen_string_literal: true 下要可变副本，用 +"abc" 或 .dup
mutable = +"固定开头"
mutable << "-可变尾巴"
ok mutable == "固定开头-可变尾巴"
puts "dup：普通副本；clone：连 frozen / 单例方法一起带走"

# ═══ 6.8 内省：class / ancestors / is_a? / instance_variables / methods
sec("6.8 内省：运行时看看对象是什么、有什么")
class Animal; end
class Cat < Animal
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def meow = "#{@name}：喵"
end
cat = Cat.new("咪咪")
ok cat.class == Cat
ok Cat.ancestors.take(3) == [Cat, Animal, Object]   # 方法查找链
ok cat.is_a?(Animal) && cat.is_a?(Cat) && !cat.is_a?(Dog)
ok cat.instance_variables == [:@name]
ok cat.respond_to?(:meow) && cat.methods.include?(:meow)
ok cat.public_send(:meow) == "咪咪：喵"
ok Cat.instance_method(:meow).owner == Cat   # 方法挂在谁身上
puts "class=#{cat.class}，ancestors=#{Cat.ancestors.take(3).inspect}，ivars=#{cat.instance_variables.inspect}"

puts
puts("==== 06 结束 ====")
