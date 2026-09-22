# 04 控制流：if/unless 表达式、while/until、case/when、case/in 模式匹配、loop
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 4.1 if / unless：都是表达式，都有值
sec("4.1 if / unless：条件是表达式")
grade = 85
label = if grade >= 90 then "优"
       elsif grade >= 80 then "良"
       elsif grade >= 60 then "及格"
       else "不及格"
       end
ok label == "良"
puts "grade=#{grade} → #{label}"
# unless = if not；Ruby 没有 ! not 的 else-if 变体，unless 不带 elsif
dry = "晴天" unless false
ok dry == "晴天"
# 条件修改器（后置 if）：一行流惯用法
count = 0
count += 1 while count < 3
ok count == 3
# 三元 ?: 与 and/or 短路：nil 守门惯用法 a && a.b
nilable = nil
safe = nilable && nilable.size        # nilable 为 nil 时右边不求值
ok safe.nil?
puts "短路守门：nilable && nilable.size → #{safe.inspect}"

# ═══ 4.2 真 / 假：只有 false 和 nil 为假
sec("4.2 真值语义：只有 false 和 nil 是假")
truthy = [0, 0.0, "", [], {}, :sym, true]
truthy.each { |v| ok v, "#{v.inspect} 应为真值" }   # 0 和 "" 都为真！
ok !false && !nil
puts "0、\"\"、[] 在 Ruby 里全为真 —— 与 C/JS/Python 都不同"

# ═══ 4.3 while / until / loop：循环家族
sec("4.3 while / until / loop")
sum, i = 0, 1
while i <= 10
  sum += i
  i += 1
end
ok sum == 55
n = 0
n += 1 until n >= 5                   # until = while not
ok n == 5
count2 = 0
loop do                               # loop do ... end 无限循环，靠 break 跳出
  count2 += 1
  break if count2 >= 3
end
ok count2 == 3
# break 可以带返回值：整个循环表达式的值
total = loop do
  break 100
end
ok total == 100
puts "while 累加 1..10 = #{sum}；loop break 可带值（#{total}）"

# ═══ 4.4 next / break / redo：循环控制三兄弟
sec("4.4 next / break / redo")
skipped = []
1.upto(5) do |k|
  next if k.odd?                      # 跳过本轮
  skipped << k
end
ok skipped == [2, 4]
puts "next 跳过奇数 → #{skipped.inspect}"

# ═══ 4.5 case/when：=== 是幕后功臣
sec("4.5 case/when：用 === 逐支匹配")
def classify(x)
  case x
  when 0...60  then "不及格"          # Range 的 === = include?（范围支要放在 Integer 前！）
  when 60..100 then "及格"
  when Integer then "整数"
  when /ru/    then "含 ru 的字符串"  # Regexp 的 === = match?
  when ->(v) { v.respond_to?(:call) } then "可调用"
  else "其他"
  end
end
ok classify(42) == "不及格"
ok classify(90) == "及格"
ok classify(10**30) == "整数"          # 大整数不在范围内，落到 Integer 支
ok classify("ruby") == "含 ru 的字符串"
ok classify(-> {}) == "可调用"
ok classify(nil) == "其他"
puts "classify(42)=#{classify(42)} classify(90)=#{classify(90)} classify(10**30)=#{classify(10**30)}"
# case 无值形式（case ... when 不带条件对象）：等价于一串 if
done = false
case
when 1 > 2 then done = :a
when 2 > 1 then done = :b
end
ok done == :b

# ═══ 4.6 case/in：模式匹配（2.7+ 的现代分支）
sec("4.6 case/in 模式匹配：解构数组与哈希")
def describe(payload)
  case payload
  in { type: "user", name: String => name }
    "用户 #{name}"
  in { type: "order", id: Integer => id, **rest } if rest.key?(:amount)
    "订单 #{id}，金额 #{rest[:amount]}"
  in [Integer, Integer] => pair
    "坐标 #{pair.inspect}"
  in Integer | Float => num
    "数字 #{num}"
  in nil
    "空"
  else
    "未知负载"
  end
end
ok describe({ type: "user", name: "小明" }) == "用户 小明"
ok describe({ type: "order", id: 7, amount: 99 }) == "订单 7，金额 99"
ok describe([3, 4]) == "坐标 [3, 4]"
ok describe(3.14) == "数字 3.14"
ok describe(nil) == "空"
ok describe("hi") == "未知负载"
puts describe({ type: "user", name: "小明" })
puts describe({ type: "order", id: 7, amount: 99 })
puts describe([3, 4])
# 找不到匹配分支时抛 NoMatchingPatternError（不是静默掉过）
raised = false
begin
  case 1                              # 实测坑：case/in 不能写成单行 `case 1 in String then :s end`
  in String then :s                   # —— in 之前必须换行（case/when 的单行形式反而合法）
  end
rescue NoMatchingPatternError
  raised = true
end
ok raised

# ═══ 4.7 for 几乎不用：作用域规则不同
sec("4.7 for 与块循环的作用域差异")
last = nil
for k in [1, 2, 3]
  last = k                            # for 不开新作用域，k 泄漏到外层
end
ok last == 3 && defined?(k)
[1, 2, 3].each do |m|
  last = m
end
ok last == 3
puts "for 循环变量泄漏到外层（k=#{defined?(k) ? k : "无"}）；块的循环变量只在块内 —— 生产代码几乎都用 each"

puts
puts("==== 04 结束 ====")
