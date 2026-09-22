# 05 方法：隐式返回、默认/可变/关键字参数、块与 &、Proc/lambda、方法对象
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 5.1 隐式返回：最后一个表达式的值就是返回值
sec("5.1 隐式返回：return 可省")
def add(a, b)
  a + b                # 没有 return —— 最后一行的值自动返回
end
def early(a)
  return :zero if a.zero?
  :nonzero             # 提前返回也常用，但同样是隐式的
end
ok add(2, 3) == 5 && early(0) == :zero && early(9) == :nonzero
puts "add(2,3) = #{add(2, 3)}；def 里 return 主要用于提前返回"

# ═══ 5.2 参数全家桶：默认、可变、关键字、双 splat
sec("5.2 参数全家桶")
def greet(name, greeting = "你好", punct: "！", **extra)
  tail = extra.empty? ? "" : "（附注：#{extra[:note]}）"
  "#{greeting}，#{name}#{punct}#{tail}"
end
ok greet("小明") == "你好，小明！"
ok greet("小明", "早上好") == "早上好，小明！"
ok greet("小明", punct: "。") == "你好，小明。"
ok greet("小明", note: "测试模式") == "你好，小明！（附注：测试模式）"
def demo(*args, **kw)
  [args, kw]
end
ok demo(1, 2, a: 3) == [[1, 2], { a: 3 }]
puts "greet(\"小明\", \"早上好\") = #{greet("小明", "早上好")}"
puts "demo(1, 2, a: 3) = #{demo(1, 2, a: 3).inspect}"
# 关键字参数 3.0 起与哈希彻底分离：不写 ** 收不到 trailing hash
strictly = ->(a:, b: 2) { a + b }
ok strictly.call(a: 1) == 3
raised = false
begin; strictly.call({ a: 1 }); rescue ArgumentError; raised = true; end
ok raised, "位置哈希传给关键字参数应抛 ArgumentError（3.0 语义）"
puts "关键字参数与位置哈希已彻底分离（3.0 起）：传哈希不写 ** 会抛 ArgumentError"

# ═══ 5.3 问号与叹号命名约定
sec("5.3 命名约定：? 谓词、! 危险")
ok 42.is_a?(Integer) && [].empty? && 2.even?
src = +"abc"                          # + 前缀：产出一个「未冻结」的字面量副本
bang = src.upcase!                    # ! 版本原地修改，无变化时返回 nil
ok bang == "ABC" && src == "ABC"
puts "empty?/even? 是谓词；+\"abc\" 拿到未冻结副本后 upcase! 原地修改 —— ! 不代表「更危险地抛错」"

# ═══ 5.4 块：方法的隐形参数
sec("5.4 块：yield 与 &blk")
def twice
  yield
  yield
end
n = 0
twice { n += 1 }
ok n == 2
def count_calls(&blk)                 # & 把块抓成 Proc 对象
  blk ? blk.call : :no_block
end
ok count_calls { 42 } == 42
ok count_calls == :no_block
def takes_block?
  block_given?                        # block_given? 只在方法体里有意义
end
ok takes_block? { 1 } && !takes_block?
puts "twice { n += 1 } → n = #{n}；block_given? 在方法体里判断有没有传块"
# 显式传递：方法之间转发块
def with_prefix(prefix, &blk)
  [1, 2, 3].map(&blk).map { |s| "#{prefix}#{s}" }
end
ok with_prefix("N") { |x| x * 10 } == %w[N10 N20 N30]
puts "with_prefix(\"N\") { |x| x * 10 } = #{with_prefix("N") { |x| x * 10 }.inspect}"

# ═══ 5.5 Proc 与 lambda：arity 检查与 return 语义
sec("5.5 Proc 与 lambda")
pr = proc { |a, b| [a, b] }
lm = ->(a, b) { [a, b] }              # lambda 字面量
ok pr.call(1) == [1, nil]             # proc：宽松，缺参补 nil
ok lm.arity == 2
raised = false
begin; lm.call(1); rescue ArgumentError; raised = true; end
ok raised, "lambda 缺参应抛 ArgumentError"
puts "proc.call(1) = #{pr.call(1).inspect}（宽松）；lambda 严格查 arity"
# return 语义：lambda 的 return 只离开自身；proc 的 return 会离开**定义它的方法**
def lambda_return_demo
  f = -> { return :from_lambda }
  f.call
  :method_continues
end
ok lambda_return_demo == :method_continues
ok lm.lambda? && !pr.lambda?          # lambda? 区分两种对象
puts "lambda 的 return 只离开 lambda 本身；proc 的 return 离开定义它的方法（易炸，慎用）"

# ═══ 5.6 方法对象：method / to_proc / &
sec("5.6 方法对象与 Symbol#to_proc")
upcase = "abc".method(:upcase)        # Method 对象：绑定接收者
ok upcase.call == "ABC"
ok %w[a b c].map(&:upcase) == %w[A B C]     # Symbol#to_proc
ok [3, 1, 2].sort_by(&:-@) == [3, 2, 1]     # &:-@ → method(:-@).to_proc
ok [1, "a", :b].map(&:itself) == [1, "a", :b]   # Symbol#to_proc 是「接收者.符号」语义
puts "map(&:upcase) 的 & 触发 to_proc；method(:f) 拿到可传递的 Method 对象"

# ═══ 5.7 运算符即方法：可整体自定义
sec("5.7 运算符即方法")
ok 3 + 4 == 3.+(4)                    # a + b 只是 a.+(b) 的语法糖
ok [1, 2].length == [1, 2].size
vec = Struct.new(:x, :y) do
  def +(other) = self.class.new(x + other.x, y + other.y)
  def -@ = self.class.new(-x, -y)
end
v = vec.new(1, 2) + vec.new(10, 20)
ok v.x == 11 && v.y == 22 && (-vec.new(1, 2)).x == -1
puts "vec(1,2) + vec(10,20) = (#{v.x}, #{v.y}) —— + 与 -@ 都是普通方法"

# ═══ 5.8 define_method：用代码写方法
sec("5.8 define_method 动态定义")
registry = Class.new do
  %i[open close read].each do |op|
    define_method("can_#{op}?") { true }
  end
end
obj = registry.new
ok obj.can_open? && obj.can_close? && obj.can_read?
puts "循环 define_method 生成 can_open?/can_close?/can_read? 三个方法（15 章细讲）"

puts
puts("==== 05 结束 ====")
