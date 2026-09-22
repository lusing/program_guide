# 14 块与闭包：闭包绑定、Proc/lambda/curry、case 条件、define_method、Method#to_proc、参数解构、变量遮蔽、手写 each、计数器工厂
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 14.1 闭包是绑定不是拷贝：块内外共享同一个变量
sec("14.1 闭包绑定变量本身，不是值的拷贝")
counter = 0
increment = -> { counter += 1 }      # lambda 捕获的是 counter 这个变量槽位
increment.call
increment.call
ok counter == 2
puts "调用两次后 counter = #{counter}（闭包改的是外面的变量）"
10.times { counter += 1 }            # 块同样直接读写外层变量
ok counter == 12
puts "再让块加 10 次，counter = #{counter} —— 块和 lambda 看到的是同一格内存"

# ═══ 14.2 Proc / lambda 深挖：arity、lambda?、curry
sec("14.2 arity、lambda? 与 curry 逐步应用")
add3 = ->(a, b, c) { a + b + c }
ok add3.arity == 3 && add3.lambda?
curried = add3.curry                 # 柯里化：一次喂一个参数
ok curried[1][2][3] == 6
ok curried.call(1, 2).call(3) == 6
add10 = curried[10]                  # 部分应用：先固定前缀参数
ok add10[90][100] == 200
ok curried.lambda?                   # curry 出来的仍是 lambda 语义（严格 arity）
pr = proc { |a, b| [a, b] }
ok pr.arity == 2 && pr.call(1) == [1, nil]   # proc 宽松：缺参补 nil
puts "add3.curry 后 add10 = curried[10]，再喂 90、100 得 #{add10[90][100]}"

# ═══ 14.3 Proc 作 case 条件：=== 的另一副面孔
sec("14.3 Proc#=== 与 case/when")
grade_label = ->(score) do
  case score
  when ->(x) { x > 90 } then "优"    # when 分支会对条件对象调 ===，Proc 的 === 即 call
  when ->(x) { x > 60 } then "及格"
  else "不及格"
  end
end
ok grade_label.call(95) == "优" && grade_label.call(70) == "及格" && grade_label.call(40) == "不及格"
ok (->(x) { x > 90 }) === 95         # case/when 只是 === 的语法糖
ok(((->(x) { x > 90 }) === 80) == false)
puts "score=95 走 Proc 分支 → #{grade_label.call(95)}；自上而下，先命中先赢"

# ═══ 14.4 define_method 与闭包：每个方法各捕各的变量
sec("14.4 define_method：循环里定义的方法各捕各的绑定")
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
lookup = Class.new do
  %i[open close read].each do |op|
    define_method("can_#{op}?") { true }
  end
end
obj = lookup.new
ok obj.can_open? && obj.can_close? && obj.can_read?
puts "bump_a 累到 #{a_val}，bump_b 才 #{b_val} —— define_method 的块各捕各的循环变量"

# ═══ 14.5 Method#to_proc 与 & 转发
sec("14.5 Method 对象与 & 转发")
def shout(word)
  "#{word}!"
end
ok [1, 2, 3].map(&method(:shout)) == %w[1! 2! 3!]     # & 把 Method 转成 Proc 塞给块位
m = method(:shout)
ok m.to_proc.call("hi") == "hi!"
ok m.to_proc.lambda?                                  # Method#to_proc 是 lambda 语义（严格 arity）
def record(&blk)
  [1, 2, 3].map(&blk)                                 # & 转发：把收到的块转手给 map
end
ok record { |n| n * 3 } == [3, 6, 9]
# 坑：map(&method(:itself)) 抛 ArgumentError —— Method#to_proc 按位置传参，
# map 每次传 1 个参数，而 Integer#itself 收 0 个。符号版 map(&:itself) 没这个问题。
puts "method(:f) 拿到绑定接收者的 Method 对象，& 触发 to_proc 填进块位"

# ═══ 14.6 Proc 的参数解构：数组自动拆包
sec("14.6 块参数解构：平铺与嵌套")
pairs = [[1, 2], [3, 4]]
sums = []
pairs.each { |a, b| sums << a + b }                  # 块参数多于 1 个 → 对元素自动解构
ok sums == [3, 7]
ok({ a: 1, b: 2 }.map { |k, v| "#{k}=#{v}" } == ["a=1", "b=2"])
nested = [[[1, 2], 3], [[4, 5], 6]]
flat = []
nested.each { |(a, b), c| flat << [a, b, c] }        # 括号嵌套解构：模式写得进去
ok flat == [[1, 2, 3], [4, 5, 6]]
ok([[1, 2], [3, 4]].map { |(a, b)| a * b } == [2, 12])
puts "|(a, b), c| 一次拆开嵌套数组 —— 解构模式能嵌套任意层"

# ═══ 14.7 块内变量遮蔽：块参数盖住同名外层变量
sec("14.7 变量遮蔽与块局部变量")
x = "外层"
[1].each { |x| x = "块内" }                          # 块参数 x 是新变量，遮住外层 x
ok x == "外层"                                        # 块里改的只是影子，外层毫发无损
shadowed = []
y = 100
[1, 2].each { |i; y| y = i * 10; shadowed << y }     # |i; y| 的 ; y 声明块局部变量
ok y == 100 && shadowed == [10, 20]                  # 外层 y 没被覆盖
puts "块参数 |x| 遮蔽外层 x；|i; y| 显式声明块局部，防误伤同名外层变量"

# ═══ 14.8 手写 each / each_with_index：yield 的多值传递
sec("14.8 手写 each：yield 与多值 yield")
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
seq = Seq.new(%w[甲 乙 丙])
collected = []
ok seq.my_each { |item| collected << item } == seq   # 返回 self
ok collected == %w[甲 乙 丙]
indexed = []
seq.my_each_with_index { |item, idx| indexed << "#{idx}:#{item}" }
ok indexed == ["0:甲", "1:乙", "2:丙"]
puts indexed.join(" ")
# 没传块就调 my_each 会抛 LocalJumpError（yield 找不到块）
raised = false
begin
  seq.my_each
rescue LocalJumpError
  raised = true
end
ok raised

# ═══ 14.9 闭包计数器 / 累加器工厂：两个 Proc 共享同一绑定
sec("14.9 make_counter：两个 Proc 共享一份绑定")
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
ok inc.call == 3                    # increment 也在原来的基础上继续
fresh, fresh_get = make_counter     # 每次调用 make_counter 造一套全新绑定
ok fresh.call == 1 && fresh_get.call == 1
def make_adder(start)
  ->(n) { start += n }              # 累加器：状态就藏在闭包里
end
adder = make_adder(100)
ok adder.call(1) == 101 && adder.call(1) == 102
puts "inc 与 get 共享同一个 count（现在 = #{get.call}），这就是「闭包 = 绑定」的含义"

puts
puts("==== 14 结束 ====")
